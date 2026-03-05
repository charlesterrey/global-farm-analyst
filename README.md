# Global Farm Analyst

**Pipeline d'analyse financiere et agronomique d'exploitations agricoles**
16 skills Claude Code | Zero hallucination | Tracabilite de bout en bout

---

## Principe

Deposer des PDFs comptables agricoles dans `./inputs/`.
Obtenir automatiquement :

1. Un **rapport Word de 100+ pages** de niveau cabinet de conseil
2. Un **modele Excel dynamique** de projection financiere a 10 ans

Chaque valeur chiffree est tracee a son verbatim dans le PDF source.
Toute valeur non verifiable est supprimee du pipeline.

---

## Architecture

```
LAYER 1 — Extraction & Audit
  01  Controle extraction        Classification des PDFs (sans extraction)
  02  Extraction ANC             Extraction poste par poste (Plan Comptable Agricole)
  03  Controle coherence         25+ controles comptables automatiques
  04  Audit legal                Certification verbatim — suppression des non-verifiables

LAYER 2 — Database
  05  Homogeneisation            Structuration normee multi-exercices
  06  Normalisation Excel        Dataset Excel verrouille (source unique de verite)

LAYER 3 — Analyses (parallelisables)
  07  Analyse financiere         45+ ratios avec benchmarks RICA
  08  Analyse agronomique        Assolement, materiel, dimension sociale
  09  Analyse risques            7 risques, matrice Probabilite x Impact
  10  Stress tests               6 scenarios de stress sur 3 ans
  11  Modelisations              Projections P&L, bilan, tresorerie (5 ans)
  12  M&A / Prospective          Valorisation (3 methodes) + megatendances
  13  Previsionnel 10 ans        3 scenarios evolutifs avec corridors

LAYER 4 — Validation
  14  Validation expert          Audit GO/NO-GO (5 axes, seuil 98%)

LAYER 5 — Livrables
  15  Rapport McKinsey           Rapport Word 100-150 pages
  16  Modele Excel final         Excel dynamique 16 onglets
```

### Flux d'execution

```
01 → 02 → 03 → 04 → 05 → 06 → [07+08+09+10+11+12+13] → 14 → [15+16]
                                 ^^^^^^^^^^^^^^^^^^^^^^^^
                                 Parallelisables
```

- Les skills 07 a 13 sont independants et s'executent en parallele.
- Les skills 15 et 16 sont conditionnes au **GO** du skill 14.
- Une anomalie **BLOQUANT** arrete le pipeline et attend une correction humaine.

---

## Demarrage rapide

### 1. Installation

```bash
pip install -r requirements.txt
```

Dependances principales : `pdfplumber`, `PyMuPDF`, `camelot-py`, `openpyxl`, `python-docx`, `matplotlib`, `pandas`, `numpy`, `pydantic`.

### 2. Deposer les documents

Placer les PDFs comptables dans `./inputs/`. Minimum requis :

| Document | Format | Statut |
|---|---|---|
| Liasse fiscale (2050-2059) | PDF | **Obligatoire** |
| Grand livre | PDF | Recommande |
| Declaration PAC / RPG | PDF | Recommande |
| Cotisations MSA | PDF | Optionnel |
| Releves bancaires | PDF | Optionnel |
| Tableaux d'amortissement | PDF | Optionnel |
| Factures, contrats | PDF | Optionnel |

Minimum absolu : **bilan + compte de resultat** pour au moins **2 exercices**.

### 3. Executer le pipeline

Lancer chaque skill sequentiellement dans Claude Code :

```
/01-controle-extraction
/02-extraction-anc
/03-controle-coherence
/04-audit-legal
/05-database-homogeneisation
/06-normalisation-excel
/07-analyse-financiere        # \
/08-analyse-agronomique       # |  Parallelisables
/09-analyse-risques           # |
/10-stress-tests              # |
/11-modelisations             # |
/12-manda-prospective         # |
/13-previsionnel-10ans        # /
/14-validation-expert-comptable
/15-rapport-mckinsey
/16-modele-excel-final
```

### 4. Recuperer les livrables

Les fichiers generes se trouvent dans `./outputs/`.

---

## Referentiels integres

### RICA — Ratios financiers

Le fichier `benchmarks/rica_ratios.json` contient les medianes, quartiles et seuils d'alerte pour 25+ ratios financiers, segmentes par OTEX :

- Grandes cultures (OTEX 15)
- Polyculture-elevage (OTEX 61)
- Bovins lait (OTEX 45)
- Bovins viande (OTEX 46)
- Viticulture (OTEX 35)

### Arvalis — Rendements culturaux

Le fichier `benchmarks/arvalis_rendements.json` fournit les rendements moyens par culture et par region (Q1, mediane, Q3), les prix indicatifs et les charges operationnelles pour 10 cultures : ble tendre, orge hiver/printemps, colza, tournesol, mais grain, pois, betterave, lin, luzerne.

---

## Structure du projet

```
global-farm-analyst/
├── CLAUDE.md                          Regles globales anti-hallucination
├── README.md                          Ce fichier
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
├── pipeline/                          Fichiers intermediaires JSON
├── inputs/                            PDFs comptables (confidentiel)
└── outputs/                           Livrables finaux
```

---

## Principes fondateurs

### Anti-hallucination absolue

Chaque valeur chiffree doit etre tracee a un verbatim extrait d'un PDF source. Structure de tracabilite :

```json
{
  "valeur": 125000,
  "source_doc": "liasse_2024.pdf",
  "source_page": 3,
  "verbatim": "Total actif immobilise : 125 000 EUR",
  "confiance": 0.95
}
```

Toute valeur dont la confiance est inferieure au seuil est **supprimee**, pas estimee.

### Pipeline bloquant

Le systeme classe chaque anomalie detectee :

| Niveau | Action |
|---|---|
| **VERT** | OK — le pipeline continue |
| **ORANGE** | Alerte — signal dans le rapport, pipeline continue |
| **ROUGE / BLOQUANT** | Arret du pipeline, correction humaine requise |

### Dataset verrouille

A partir du skill 06, le dataset Excel historique est en **lecture seule**. Les analyses (skills 07-16) ne peuvent pas modifier la source de verite. Toute projection est stockee dans des fichiers separes.

### Normes comptables

- **PCG** — Plan Comptable General
- **ANC** — Autorite des Normes Comptables (specificites agricoles)
- **Liasses fiscales** — Cerfa 2050 a 2059
- **RICA** — Reseau d'Information Comptable Agricole (benchmarks)
- **OTEX** — Orientation Technico-Economique (classification sectorielle)

---

## Confidentialite

Les donnees comptables sont strictement confidentielles. Les dossiers `inputs/`, `pipeline/` et `outputs/` sont exclus du versionning Git via `.gitignore`. Aucune donnee client ne transite en dehors de l'environnement local.

---

## Documentation

Voir [docs/GUIDE_UTILISATION.md](docs/GUIDE_UTILISATION.md) pour le guide detaille d'utilisation de chaque skill.
