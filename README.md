# Global Farm Analyst

**Pipeline d'analyse financiere et agronomique d'exploitations agricoles**
16 skills Claude Code | Zero hallucination | Tracabilite de bout en bout

---

## Principe

```
  ┌──────────────┐                    ┌──────────────────────────────────┐
  │              │                    │          LIVRABLES               │
  │  PDFs dans   │    16 skills       │                                  │
  │  ./inputs/   │ ──────────────►    │  Rapport Word 100+ pages         │
  │              │   automatiques     │  Modele Excel dynamique 10 ans   │
  └──────────────┘                    │                                  │
                                      └──────────────────────────────────┘
```

Deposer des PDFs comptables agricoles → obtenir un rapport et un modele Excel.
Chaque valeur chiffree est tracee a son verbatim dans le PDF source.
Toute valeur non verifiable est supprimee du pipeline.

---

## Architecture du pipeline

### Vue globale des 5 layers

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║  LAYER 1 — EXTRACTION & AUDIT                                         ║
║  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐                  ║
║  │   01    │  │   02    │  │   03    │  │   04    │                  ║
║  │ Controle│→│Extract. │→│Coherence│→│  Audit  │                  ║
║  │   PDF   │  │   ANC   │  │  25+    │  │  Legal  │                  ║
║  │         │  │  80+    │  │controles│  │Verbatim │                  ║
║  └─────────┘  │ postes  │  └─────────┘  └────┬────┘                  ║
║               └─────────┘                     │                        ║
║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ║
║                                               │                        ║
║  LAYER 2 — DATABASE                           ▼                        ║
║  ┌─────────────────┐  ┌─────────────────────────┐                     ║
║  │       05        │  │          06             │                     ║
║  │ Homogeneisation │→│  Normalisation Excel    │                     ║
║  │  SIG + Bilan    │  │  SOURCE UNIQUE VERITE   │                     ║
║  │  fonctionnel    │  │  (verrouille)           │                     ║
║  └─────────────────┘  └────────────┬────────────┘                     ║
║                                     │                                  ║
║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ║
║                                     │                                  ║
║  LAYER 3 — ANALYSES      ┌─────────┼─────────┐   (PARALLELISABLES)   ║
║                           ▼         ▼         ▼                        ║
║  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        ║
║  │   07    │ │   08    │ │   09    │ │   10    │ │   11    │        ║
║  │Finance  │ │Agro     │ │Risques  │ │ Stress  │ │Modelis. │        ║
║  │45+ratios│ │Assolem. │ │7 risques│ │6 scenar.│ │P&L+Bilan│        ║
║  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └────┬────┘        ║
║  ┌─────────┐ ┌─────────┐                              │              ║
║  │   12    │ │   13    │                              │              ║
║  │  M&A    │ │ Prev.   │                              │              ║
║  │3 valori.│ │ 10 ans  │                              │              ║
║  └────┬────┘ └────┬────┘                              │              ║
║       └───────────┴──────────────────┬────────────────┘              ║
║                                       │                                ║
║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┼─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ║
║                                       ▼                                ║
║  LAYER 4 — VALIDATION   ┌─────────────────────────┐                  ║
║                          │          14             │                  ║
║                          │  Expert-Comptable       │                  ║
║                          │  GO/NO-GO (seuil 98%)   │                  ║
║                          └────────────┬────────────┘                  ║
║                                  GO ? │                                ║
║                              ┌────────┴────────┐                      ║
║                              ▼                  ▼                      ║
║ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ║
║                              │                  │                      ║
║  LAYER 5 — LIVRABLES   ┌────┴────┐        ┌────┴────┐                ║
║                         │   15    │        │   16    │                ║
║                         │ Rapport │        │ Modele  │                ║
║                         │  Word   │        │  Excel  │                ║
║                         │100+pages│        │16 onglet│                ║
║                         └─────────┘        └─────────┘                ║
║                                                                        ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### Flux d'execution

```
SEQUENTIEL           PARALLELE              SEQ.        SEQ.
─────────── ─────────────────────────── ─────────── ───────────

01 → 02 → 03 → 04 → 05 → 06 ─┬→ 07 ─┐
                                ├→ 08 ─┤
                                ├→ 09 ─┤
                                ├→ 10 ─┼→ 14 ─┬→ 15
                                ├→ 11 ─┤  GO?  └→ 16
                                ├→ 12 ─┤
                                └→ 13 ─┘
```

### Detail des skills

```
LAYER   #   SKILL                        ENTREE                      SORTIE                        ROLE
─────   ──  ───────────────────────────  ──────────────────────────  ────────────────────────────   ─────────────────────────────────
  1     01  controle-extraction          ./inputs/*.pdf              01_classification_pdfs.json    Classification sans extraction
  1     02  extraction-anc               01 + PDFs                   02_extraction_anc.json         80+ postes PCG agricole
  1     03  controle-coherence           02                          03_controles_coherence.json    25+ controles comptables
  1     04  audit-legal                  02 + 03                     04_audit_legal.json            Certification verbatim
─────   ──  ───────────────────────────  ──────────────────────────  ────────────────────────────   ─────────────────────────────────
  2     05  homogeneisation              04                          05_database_normee.json        SIG, bilan fonctionnel, flux
  2     06  normalisation-excel          05                          06_dataset_excel.xlsx          Dataset verrouille (SSOT)
─────   ──  ───────────────────────────  ──────────────────────────  ────────────────────────────   ─────────────────────────────────
  3     07  analyse-financiere           06                          07_analyse_financiere.json     45+ ratios + benchmarks RICA
  3     08  analyse-agronomique          06                          08_analyse_agronomique.json    Assolement, materiel, social
  3     09  analyse-risques              06                          09_analyse_risques.json        7 risques, matrice P x I
  3     10  stress-tests                 06                          10_stress_tests.json           6 scenarios sur 3 ans
  3     11  modelisations                06                          11_modelisations.json          P&L + Bilan + Tresorerie 5 ans
  3     12  manda-prospective            06                          12_manda_prospective.json      Valorisation + megatendances
  3     13  previsionnel-10ans           06                          13_previsionnel_10ans.json     3 scenarios, corridors
─────   ──  ───────────────────────────  ──────────────────────────  ────────────────────────────   ─────────────────────────────────
  4     14  validation-expert-comptable  07..13                      14_validation.json             Audit GO/NO-GO (98%)
─────   ──  ───────────────────────────  ──────────────────────────  ────────────────────────────   ─────────────────────────────────
  5     15  rapport-mckinsey             06..14                      rapport_[nom].docx             Word 100-150 pages
  5     16  modele-excel-final           06..14                      modele_[nom].xlsx              Excel 16 onglets dynamique
```

---

## Systeme anti-hallucination

```
                          CHAQUE VALEUR DU PIPELINE
                                    │
                    ┌───────────────┴───────────────┐
                    ▼                               ▼
            Source trouvee ?                  Pas de source
                    │                               │
            ┌───────┴───────┐                       ▼
            ▼               ▼               ┌──────────────┐
     Verbatim exact    Verbatim approx.     │  SUPPRIMEE   │
            │               │               │  du pipeline  │
            ▼               ▼               └──────────────┘
     ┌────────────┐  ┌─────────────┐
     │  CERTIFIE  │  │  DOUTEUX    │
     │ confiance  │  │ confiance   │
     │  >= 0.90   │  │  0.60-0.89  │
     └────────────┘  └─────────────┘
```

Structure de tracabilite pour chaque donnee :

```json
{
  "valeur": 125000,
  "source_doc": "liasse_2024.pdf",
  "source_page": 3,
  "verbatim": "Total actif immobilise : 125 000 EUR",
  "confiance": 0.95
}
```

---

## Systeme de controle du pipeline

```
  Anomalie detectee
        │
        ├── VERT ────────► OK, le pipeline continue
        │
        ├── ORANGE ──────► Alerte signalee dans le rapport
        │                  Le pipeline continue
        │
        └── ROUGE ───────► BLOQUANT
                           Le pipeline s'arrete
                           Correction humaine requise
                           Relancer avec --from XX
```

### Points de blocage par skill

```
Skill 01 ── Aucun bilan detecte ─────────────────────────── BLOQUANT
         ── Moins de 2 exercices ─────────────────────────── BLOQUANT

Skill 02 ── Ecart actif/passif > 1% ─────────────────────── BLOQUANT
         ── Confiance extraction < 0.60 ──────────────────── BLOQUANT

Skill 04 ── Taux certification < 95% ────────────────────── BLOQUANT

Skill 14 ── Score validation < 98% ──────────────────────── NO-GO
             Skills 15+16 refuses tant que NO-GO
```

---

## Demarrage rapide

### 1. Installation

```bash
git clone https://github.com/charlesterrey/global-farm-analyst.git
cd global-farm-analyst
pip install -r requirements.txt
```

### 2. Deposer les documents

```
./inputs/
  ├── liasse_2022.pdf          (obligatoire)
  ├── liasse_2023.pdf          (obligatoire)
  ├── grand_livre_2023.pdf     (recommande)
  ├── declaration_pac_2023.pdf (recommande)
  ├── msa_2023.pdf             (optionnel)
  └── ...
```

| Document | Statut |
|---|---|
| Liasse fiscale (cerfa 2050-2059) | **Obligatoire** — minimum 2 exercices |
| Grand livre | Recommande |
| Declaration PAC / RPG | Recommande |
| Cotisations MSA | Optionnel |
| Releves bancaires | Optionnel |
| Tableaux d'amortissement | Optionnel |
| Factures, contrats | Optionnel |

### 3. Lancer le pipeline

**Option A — Pipeline automatique (recommande)**

```bash
./run_pipeline.sh               # Tout le pipeline de 01 a 16
```

**Option B — Controle partiel**

```bash
./run_pipeline.sh --from 07             # Reprendre au skill 07
./run_pipeline.sh --only 03             # Relancer un seul skill
./run_pipeline.sh --from 07 --to 13     # Uniquement les analyses
./run_pipeline.sh --status              # Voir l'avancement
./run_pipeline.sh --dry-run             # Plan sans execution
./run_pipeline.sh --no-parallel         # Forcer le sequentiel
```

**Option C — Skill par skill dans Claude Code**

```
/01-controle-extraction
/02-extraction-anc
...
```

### 4. Recuperer les livrables

```
./outputs/
  ├── rapport_[exploitation].docx    Rapport Word 100-150 pages
  └── modele_[exploitation].xlsx     Excel dynamique 16 onglets
```

---

## Modele de donnees

### Flux de transformation des donnees

```
PDFs bruts          Donnees structurees          Dataset           Analyses          Livrables
────────────        ────────────────────         ──────────        ─────────         ──────────

┌──────────┐        ┌──────────────────┐        ┌────────┐       ┌─────────┐       ┌─────────┐
│ Liasse   │───────►│ 80+ postes PCG   │───────►│ Excel  │──┬───►│ 45+     │──┐    │ Rapport │
│ fiscale  │  02    │ avec verbatim    │  05-06 │ SSOT   │  │    │ ratios  │  │    │ Word    │
└──────────┘        └──────────────────┘        │ verrou.│  │    └─────────┘  │    │ 100+pg  │
┌──────────┐        ┌──────────────────┐        │        │  │    ┌─────────┐  │    └─────────┘
│ Grand    │───────►│ SIG calculees    │───────►│        │  ├───►│ 7       │  │         ▲
│ livre    │  02    │ Bilan fonctionnel│  05    │        │  │    │ risques │  ├────────►│
└──────────┘        └──────────────────┘        │        │  │    └─────────┘  │    ┌─────────┐
┌──────────┐        ┌──────────────────┐        │        │  │    ┌─────────┐  │    │ Excel   │
│ PAC /    │───────►│ 7 types aides   │───────►│        │  ├───►│ Stress  │  │    │ 16      │
│ RPG      │  02    │ decomposees     │  05    │        │  │    │ tests   │  │    │ onglets │
└──────────┘        └──────────────────┘        │        │  │    └─────────┘  │    └─────────┘
┌──────────┐        ┌──────────────────┐        │        │  │    ┌─────────┐  │         ▲
│ MSA /    │───────►│ Charges sociales │───────►│        │  ├───►│ Modele  │  │         │
│ Autres   │  02    │ detaillees      │  05    │        │  │    │ 5 ans   │  ├────────►│
└──────────┘        └──────────────────┘        └────────┘  │    └─────────┘  │
                                                            │    ┌─────────┐  │
                                                            ├───►│ Valori- │  │
                                                            │    │ sation  │  │
                                                            │    └─────────┘  │
                                                            │    ┌─────────┐  │
                                                            └───►│ Prev.   │──┘
                                                                 │ 10 ans  │
                                                                 └─────────┘
```

### Integrite des donnees

```
              WRITE                          READ-ONLY
        ◄─────────────────►          ◄──────────────────────►

        Skills 01  02  03  04  05  06 │ 07  08  09  10  11  12  13  14  15  16
                                      │
        Extraction & construction     │  Analyses & livrables
        du dataset                    │  lisent le dataset sans le modifier
                                      │
                                      │  ┌─────────────────────────────────┐
                                      └──│  DATASET VERROUILLE (SSOT)     │
                                         │  06_dataset_excel.xlsx          │
                                         │  Aucune modification possible   │
                                         └─────────────────────────────────┘
```

---

## Referentiels integres

### RICA — Ratios financiers

Le fichier `benchmarks/rica_ratios.json` contient les medianes, quartiles et seuils d'alerte pour 25+ ratios financiers :

```
OTEX supportes :
  ├── 15  Grandes cultures
  ├── 61  Polyculture-elevage
  ├── 45  Bovins lait
  ├── 46  Bovins viande
  └── 35  Viticulture

Ratios par famille :
  ├── Solvabilite      autonomie financiere, endettement, remboursement
  ├── Liquidite        ratio courant, tresorerie nette, BFR jours
  ├── Rentabilite      ROA, ROE, marge nette, marge EBE
  ├── Charges          charges fixes/variables, point mort
  ├── Agricoles        annuites/EBE, MSA/EBE, subventions/CA
  └── Dynamique        variations N/N-1
```

### Arvalis — Rendements culturaux

Le fichier `benchmarks/arvalis_rendements.json` fournit rendements, prix et charges pour 10 cultures :

```
Cultures :
  ├── Ble tendre         73 q/ha nationale   220 EUR/t
  ├── Orge hiver         68 q/ha nationale   200 EUR/t
  ├── Orge printemps     58 q/ha nationale   230 EUR/t
  ├── Colza              33 q/ha nationale   460 EUR/t
  ├── Tournesol          23 q/ha nationale   420 EUR/t
  ├── Mais grain         90 q/ha nationale   195 EUR/t
  ├── Pois               38 q/ha nationale   250 EUR/t
  ├── Betterave          80 t/ha nationale    28 EUR/t
  ├── Lin fibre         6.8 t/ha nationale   280 EUR/t
  └── Luzerne            10 tMS/ha nationale  150 EUR/t

Regions : IDF, Centre, Hauts-de-France, Beauce, Champagne,
          Normandie, Grand Est, Sud-Ouest, Sud-Est, Alsace
```

---

## Structure du projet

```
global-farm-analyst/
├── CLAUDE.md                          Regles globales anti-hallucination
├── README.md                          Ce fichier
├── run_pipeline.sh                    Orchestrateur du pipeline
├── requirements.txt                   Dependances Python
├── .claude/skills/                    16 skills Claude Code
│   ├── 01-controle-extraction/
│   ├── 02-extraction-anc/
│   ├── 03-controle-coherence/
│   ├── 04-audit-legal/
│   ├── 05-database-homogeneisation/
│   ├── 06-normalisation-excel/
│   ├── 07-analyse-financiere/
│   ├── 08-analyse-agronomique/
│   ├── 09-analyse-risques/
│   ├── 10-stress-tests/
│   ├── 11-modelisations/
│   ├── 12-manda-prospective/
│   ├── 13-previsionnel-10ans/
│   ├── 14-validation-expert-comptable/
│   ├── 15-rapport-mckinsey/
│   └── 16-modele-excel-final/
├── benchmarks/
│   ├── rica_ratios.json               Ratios RICA par OTEX
│   └── arvalis_rendements.json        Rendements par culture et region
├── docs/
│   └── GUIDE_UTILISATION.md           Guide detaille des skills
├── pipeline/                          Fichiers intermediaires JSON
│   └── logs/                          Logs d'execution du pipeline
├── inputs/                            PDFs comptables (confidentiel)
└── outputs/                           Livrables finaux
```

---

## Normes comptables

```
┌──────────────────────────────────────────────────────────┐
│                  REFERENTIEL NORMATIF                     │
│                                                          │
│  PCG ──── Plan Comptable General                         │
│  ANC ──── Autorite des Normes Comptables (agricole)      │
│                                                          │
│  Liasses fiscales :                                      │
│    2050 ── Bilan actif                                   │
│    2051 ── Bilan passif                                  │
│    2052 ── Compte de resultat (charges)                  │
│    2053 ── Compte de resultat (produits)                 │
│    2054 ── Immobilisations                               │
│    2055 ── Amortissements                                │
│    2056 ── Provisions                                    │
│    2057 ── Etat des echeances                            │
│    2058 ── Affectation du resultat                       │
│    2059 ── Filiales et participations                    │
│                                                          │
│  RICA ──── Benchmarks sectoriels (medianes, quartiles)   │
│  OTEX ──── Classification par orientation productive     │
└──────────────────────────────────────────────────────────┘
```

---

## Confidentialite

Les donnees comptables sont strictement confidentielles.

```
VERSIONNE (git)              NON VERSIONNE (.gitignore)
─────────────────            ──────────────────────────
.claude/skills/              inputs/     ← PDFs clients
benchmarks/                  pipeline/   ← JSON intermediaires
docs/                        outputs/    ← Livrables
CLAUDE.md
README.md
run_pipeline.sh
requirements.txt
```

Aucune donnee client ne transite en dehors de l'environnement local.

---

## Documentation

- [Guide d'utilisation des skills](docs/GUIDE_UTILISATION.md) — description detaillee de chaque skill, entrees/sorties, erreurs frequentes
- [CLAUDE.md](CLAUDE.md) — regles anti-hallucination et contraintes globales du pipeline
