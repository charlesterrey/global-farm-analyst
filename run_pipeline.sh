#!/usr/bin/env bash
# =============================================================================
# Global Farm Analyst — Orchestrateur de pipeline
# =============================================================================
#
# Enchaine les 16 skills dans l'ordre du pipeline.
# Arrete automatiquement si un skill renvoie un statut BLOQUANT.
#
# Usage:
#   ./run_pipeline.sh                  Lancer tout le pipeline (01 a 16)
#   ./run_pipeline.sh --from 07        Reprendre a partir du skill 07
#   ./run_pipeline.sh --only 03        Lancer uniquement le skill 03
#   ./run_pipeline.sh --to 06          Lancer de 01 a 06 inclus
#   ./run_pipeline.sh --from 07 --to 13  Lancer de 07 a 13 inclus
#   ./run_pipeline.sh --dry-run        Afficher les skills sans les executer
#   ./run_pipeline.sh --status         Afficher l'etat du pipeline
#
# =============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------

PIPELINE_DIR="./pipeline"
INPUTS_DIR="./inputs"
OUTPUTS_DIR="./outputs"
LOG_DIR="./pipeline/logs"

# Skills ordonnes du pipeline
declare -a SKILLS=(
  "01-controle-extraction"
  "02-extraction-anc"
  "03-controle-coherence"
  "04-audit-legal"
  "05-database-homogeneisation"
  "06-normalisation-excel"
  "07-analyse-financiere"
  "08-analyse-agronomique"
  "09-analyse-risques"
  "10-stress-tests"
  "11-modelisations"
  "12-manda-prospective"
  "13-previsionnel-10ans"
  "14-validation-expert-comptable"
  "15-rapport-mckinsey"
  "16-modele-excel-final"
)

# Skills parallelisables (Layer 3)
declare -a PARALLEL_SKILLS=(
  "07-analyse-financiere"
  "08-analyse-agronomique"
  "09-analyse-risques"
  "10-stress-tests"
  "11-modelisations"
  "12-manda-prospective"
  "13-previsionnel-10ans"
)

# Fichiers de sortie attendus par skill
declare -A SKILL_OUTPUTS=(
  ["01"]="pipeline/01_classification_pdfs.json"
  ["02"]="pipeline/02_extraction_anc.json"
  ["03"]="pipeline/03_controles_coherence.json"
  ["04"]="pipeline/04_audit_legal.json"
  ["05"]="pipeline/05_database_normee.json"
  ["06"]="pipeline/06_dataset_excel.xlsx"
  ["07"]="pipeline/07_analyse_financiere.json"
  ["08"]="pipeline/08_analyse_agronomique.json"
  ["09"]="pipeline/09_analyse_risques.json"
  ["10"]="pipeline/10_stress_tests.json"
  ["11"]="pipeline/11_modelisations.json"
  ["12"]="pipeline/12_manda_prospective.json"
  ["13"]="pipeline/13_previsionnel_10ans.json"
  ["14"]="pipeline/14_validation.json"
  ["15"]="outputs/rapport_*.docx"
  ["16"]="outputs/modele_*.xlsx"
)

# --- Couleurs ----------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Fonctions utilitaires ---------------------------------------------------

print_header() {
  echo ""
  echo -e "${BOLD}=================================================================${NC}"
  echo -e "${BOLD}  GLOBAL FARM ANALYST — Pipeline d'analyse agricole${NC}"
  echo -e "${BOLD}=================================================================${NC}"
  echo ""
}

print_step() {
  local step_num="$1"
  local step_name="$2"
  local total="$3"
  echo ""
  echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
  echo -e "${BOLD}  [${step_num}/${total}] ${step_name}${NC}"
  echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
}

print_success() {
  echo -e "${GREEN}  ✓ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}  ⚠ $1${NC}"
}

print_error() {
  echo -e "${RED}  ✗ $1${NC}"
}

print_info() {
  echo -e "${BLUE}  ➜ $1${NC}"
}

timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

get_skill_number() {
  echo "$1" | grep -oE '^[0-9]+'
}

# Verifie si un skill fait partie du groupe parallelisable
is_parallel_skill() {
  local skill="$1"
  for ps in "${PARALLEL_SKILLS[@]}"; do
    if [[ "$ps" == "$skill" ]]; then
      return 0
    fi
  done
  return 1
}

# Verifie le statut de sortie d'un skill (cherche BLOQUANT dans le JSON)
check_skill_status() {
  local skill_num="$1"
  local output_file="${SKILL_OUTPUTS[$skill_num]}"

  # Gerer les patterns glob pour skills 15/16
  local resolved_file
  resolved_file=$(ls $output_file 2>/dev/null | head -1)

  if [[ -z "$resolved_file" ]]; then
    return 1  # Fichier non trouve
  fi

  # Verifier si le fichier contient un statut BLOQUANT
  if [[ "$resolved_file" == *.json ]]; then
    if grep -qi '"BLOQUANT"\|"ROUGE"\|"NO-GO"' "$resolved_file" 2>/dev/null; then
      return 2  # Statut bloquant
    fi
  fi

  return 0  # OK
}

# Affiche l'etat actuel du pipeline
show_pipeline_status() {
  print_header
  echo -e "${BOLD}  Etat du pipeline :${NC}"
  echo ""

  for skill in "${SKILLS[@]}"; do
    local num
    num=$(get_skill_number "$skill")
    local output="${SKILL_OUTPUTS[$num]}"
    local resolved
    resolved=$(ls $output 2>/dev/null | head -1)

    if [[ -n "$resolved" ]]; then
      local mod_time
      mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$resolved" 2>/dev/null || stat -c "%y" "$resolved" 2>/dev/null | cut -d'.' -f1)

      if check_skill_status "$num"; then
        echo -e "  ${GREEN}●${NC} ${skill}  ${DIM}(${mod_time})${NC}"
      else
        echo -e "  ${RED}●${NC} ${skill}  ${DIM}(${mod_time}) — BLOQUANT${NC}"
      fi
    else
      echo -e "  ${DIM}○${NC} ${skill}  ${DIM}(non execute)${NC}"
    fi
  done

  echo ""

  # Verifier les inputs
  local pdf_count
  pdf_count=$(find "$INPUTS_DIR" -name "*.pdf" 2>/dev/null | wc -l | tr -d ' ')
  echo -e "  ${BOLD}Documents en entree :${NC} ${pdf_count} PDF(s) dans ${INPUTS_DIR}/"
  echo ""
}

# Execute un skill via Claude Code CLI
run_skill() {
  local skill="$1"
  local skill_num
  skill_num=$(get_skill_number "$skill")
  local log_file="${LOG_DIR}/${skill}_$(date +%Y%m%d_%H%M%S).log"
  local start_time
  start_time=$(date +%s)

  print_info "Lancement: /${skill}"
  print_info "Log: ${log_file}"

  # Executer le skill via Claude Code CLI
  if claude -p "/${skill}" > "$log_file" 2>&1; then
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    print_success "Termine en ${duration}s"
  else
    local exit_code=$?
    print_error "Claude Code a retourne le code ${exit_code}"
    print_error "Consulter le log : ${log_file}"
    return 1
  fi

  # Verifier le fichier de sortie
  local output="${SKILL_OUTPUTS[$skill_num]}"
  local resolved
  resolved=$(ls $output 2>/dev/null | head -1)

  if [[ -z "$resolved" ]]; then
    print_warning "Fichier de sortie attendu non trouve : ${output}"
    return 1
  fi

  # Verifier le statut
  check_skill_status "$skill_num"
  local status=$?

  if [[ $status -eq 2 ]]; then
    print_error "BLOQUANT detecte dans ${resolved}"
    print_error "Corriger le probleme puis relancer : ./run_pipeline.sh --from ${skill_num}"
    return 2
  fi

  return 0
}

# Execute les skills parallelisables en parallele
run_parallel_batch() {
  local skills_to_run=("$@")
  local pids=()
  local skill_map=()
  local all_success=true

  print_info "Lancement en parallele de ${#skills_to_run[@]} skills..."
  echo ""

  for skill in "${skills_to_run[@]}"; do
    local log_file="${LOG_DIR}/${skill}_$(date +%Y%m%d_%H%M%S).log"
    echo -e "  ${BLUE}◐${NC} ${skill} ${DIM}(en cours...)${NC}"

    claude -p "/${skill}" > "$log_file" 2>&1 &
    pids+=($!)
    skill_map+=("$skill")
  done

  # Attendre tous les processus
  for i in "${!pids[@]}"; do
    local pid=${pids[$i]}
    local skill=${skill_map[$i]}
    local skill_num
    skill_num=$(get_skill_number "$skill")

    if wait "$pid"; then
      # Verifier le statut du skill
      check_skill_status "$skill_num"
      local status=$?
      if [[ $status -eq 2 ]]; then
        print_error "${skill} — BLOQUANT"
        all_success=false
      else
        print_success "${skill} — OK"
      fi
    else
      print_error "${skill} — ECHEC"
      all_success=false
    fi
  done

  if [[ "$all_success" == false ]]; then
    return 1
  fi
  return 0
}

# --- Parsing des arguments ---------------------------------------------------

FROM_SKILL=1
TO_SKILL=16
ONLY_SKILL=""
DRY_RUN=false
SHOW_STATUS=false
PARALLEL_MODE=true

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --from NUM      Demarrer a partir du skill NUM (defaut: 01)"
  echo "  --to NUM        Arreter apres le skill NUM (defaut: 16)"
  echo "  --only NUM      Executer uniquement le skill NUM"
  echo "  --no-parallel   Desactiver l'execution parallele des skills 07-13"
  echo "  --dry-run       Afficher le plan sans executer"
  echo "  --status        Afficher l'etat actuel du pipeline"
  echo "  --help          Afficher cette aide"
  echo ""
  echo "Exemples:"
  echo "  $0                       Lancer tout le pipeline"
  echo "  $0 --from 07             Reprendre au skill 07"
  echo "  $0 --from 07 --to 13    Lancer uniquement les analyses"
  echo "  $0 --only 03             Relancer le skill 03 seul"
  echo "  $0 --status              Voir l'avancement"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      FROM_SKILL=$(echo "$2" | sed 's/^0*//')
      shift 2
      ;;
    --to)
      TO_SKILL=$(echo "$2" | sed 's/^0*//')
      shift 2
      ;;
    --only)
      ONLY_SKILL=$(echo "$2" | sed 's/^0*//')
      shift 2
      ;;
    --no-parallel)
      PARALLEL_MODE=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --status)
      SHOW_STATUS=true
      shift
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Option inconnue: $1"
      usage
      ;;
  esac
done

# --- Execution principale ----------------------------------------------------

# Creer les repertoires necessaires
mkdir -p "$PIPELINE_DIR" "$LOG_DIR" "$INPUTS_DIR" "$OUTPUTS_DIR"

# Mode status
if [[ "$SHOW_STATUS" == true ]]; then
  show_pipeline_status
  exit 0
fi

# Construire la liste des skills a executer
declare -a RUN_LIST=()

if [[ -n "$ONLY_SKILL" ]]; then
  for skill in "${SKILLS[@]}"; do
    local_num=$(get_skill_number "$skill")
    local_num_clean=$(echo "$local_num" | sed 's/^0*//')
    if [[ "$local_num_clean" -eq "$ONLY_SKILL" ]]; then
      RUN_LIST+=("$skill")
      break
    fi
  done
  if [[ ${#RUN_LIST[@]} -eq 0 ]]; then
    print_error "Skill ${ONLY_SKILL} non trouve."
    exit 1
  fi
else
  for skill in "${SKILLS[@]}"; do
    local_num=$(get_skill_number "$skill")
    local_num_clean=$(echo "$local_num" | sed 's/^0*//')
    if [[ "$local_num_clean" -ge "$FROM_SKILL" && "$local_num_clean" -le "$TO_SKILL" ]]; then
      RUN_LIST+=("$skill")
    fi
  done
fi

# Afficher le header
print_header

# Verifier les inputs
pdf_count=$(find "$INPUTS_DIR" -name "*.pdf" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$pdf_count" -eq 0 && "$FROM_SKILL" -le 1 ]]; then
  print_error "Aucun PDF trouve dans ${INPUTS_DIR}/"
  print_error "Deposer les documents comptables avant de lancer le pipeline."
  exit 1
fi
print_info "${pdf_count} PDF(s) detecte(s) dans ${INPUTS_DIR}/"

# Afficher le plan d'execution
echo ""
echo -e "${BOLD}  Plan d'execution :${NC}"
echo ""

total=${#RUN_LIST[@]}
parallel_batch=()

for i in "${!RUN_LIST[@]}"; do
  skill="${RUN_LIST[$i]}"
  num=$((i + 1))

  if is_parallel_skill "$skill" && [[ "$PARALLEL_MODE" == true ]]; then
    if [[ ${#parallel_batch[@]} -eq 0 ]]; then
      echo -e "  ${CYAN}${num}-$((num + 6))${NC}. ${DIM}[PARALLELE]${NC} Skills 07 a 13 (analyses)"
    fi
    parallel_batch+=("$skill")
  else
    if [[ ${#parallel_batch[@]} -gt 0 ]]; then
      parallel_batch=()
    fi
    echo -e "  ${CYAN}${num}${NC}. ${skill}"
  fi
done

echo ""

# Mode dry-run : s'arreter ici
if [[ "$DRY_RUN" == true ]]; then
  print_info "Mode dry-run — aucune execution."
  exit 0
fi

# Confirmation
echo -e "${YELLOW}  Lancer l'execution de ${total} skill(s) ? [O/n]${NC} "
read -r confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
  print_info "Annule."
  exit 0
fi

# Execution
pipeline_start=$(date +%s)
step=0
parallel_batch=()

for skill in "${RUN_LIST[@]}"; do
  step=$((step + 1))
  skill_num=$(get_skill_number "$skill")
  skill_num_clean=$(echo "$skill_num" | sed 's/^0*//')

  # Gestion du batch parallele
  if is_parallel_skill "$skill" && [[ "$PARALLEL_MODE" == true ]]; then
    parallel_batch+=("$skill")

    # Si c'est le dernier skill parallele dans la liste, lancer le batch
    local_next_idx=$step
    local_next_skill=""
    if [[ $local_next_idx -lt ${#RUN_LIST[@]} ]]; then
      local_next_skill="${RUN_LIST[$local_next_idx]}"
    fi

    if [[ -z "$local_next_skill" ]] || ! is_parallel_skill "$local_next_skill"; then
      print_step "$step" "BATCH PARALLELE — Skills 07 a 13" "$total"
      if ! run_parallel_batch "${parallel_batch[@]}"; then
        print_error "Un ou plusieurs skills paralleles ont echoue."
        print_error "Corriger puis relancer : ./run_pipeline.sh --from 07"
        exit 1
      fi
      parallel_batch=()
    fi
    continue
  fi

  # Execution sequentielle
  print_step "$step" "$skill" "$total"

  # Verification du prerequis GO pour skills 15-16
  if [[ "$skill_num_clean" -ge 15 ]]; then
    if [[ -f "${SKILL_OUTPUTS[14]}" ]]; then
      if grep -qi '"NO-GO"' "${SKILL_OUTPUTS[14]}" 2>/dev/null; then
        print_error "Le skill 14 a rendu un verdict NO-GO."
        print_error "Corriger les anomalies puis relancer : ./run_pipeline.sh --from 14"
        exit 1
      fi
    else
      print_error "Le skill 14 n'a pas encore ete execute (prerequis pour skill ${skill_num})."
      exit 1
    fi
  fi

  if ! run_skill "$skill"; then
    exit_code=$?
    if [[ $exit_code -eq 2 ]]; then
      # Bloquant — message deja affiche par run_skill
      exit 1
    fi
    print_error "Le skill ${skill} a echoue."
    print_error "Consulter les logs dans ${LOG_DIR}/"
    exit 1
  fi
done

# Resume final
pipeline_end=$(date +%s)
pipeline_duration=$((pipeline_end - pipeline_start))
pipeline_minutes=$((pipeline_duration / 60))
pipeline_seconds=$((pipeline_duration % 60))

echo ""
echo -e "${GREEN}=================================================================${NC}"
echo -e "${GREEN}  PIPELINE TERMINE AVEC SUCCES${NC}"
echo -e "${GREEN}=================================================================${NC}"
echo ""
echo -e "  ${BOLD}Duree totale :${NC} ${pipeline_minutes}m ${pipeline_seconds}s"
echo -e "  ${BOLD}Skills executes :${NC} ${total}"
echo -e "  ${BOLD}Livrables :${NC}"

if ls outputs/rapport_*.docx 1>/dev/null 2>&1; then
  echo -e "    ${GREEN}●${NC} $(ls outputs/rapport_*.docx)"
fi
if ls outputs/modele_*.xlsx 1>/dev/null 2>&1; then
  echo -e "    ${GREEN}●${NC} $(ls outputs/modele_*.xlsx)"
fi

echo ""
echo -e "  ${DIM}Logs disponibles dans ${LOG_DIR}/${NC}"
echo ""
