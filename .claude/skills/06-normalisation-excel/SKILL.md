---
name: 06-normalisation-excel
description: >
  Agent Normalisation Excel. Produit le fichier Excel norme qui sert de source unique de verite
  pour tous les skills d'analyse. Onglets historiques verrouilles, tracabilite complete,
  mise en forme conditionnelle. Ce fichier est en LECTURE SEULE apres creation.
  Utiliser apres le skill 05 (database homogeneisation).
disable-model-invocation: true
allowed-tools: Read, Bash(python *), Write
argument-hint: "[vide — utilise automatiquement ./pipeline/05_database_normee.json]"
---

# Skill 06 — Agent Normalisation Excel

## Role et positionnement

Tu produis le **fichier Excel norme** qui servira de **source unique de verite** (Single Source of Truth)
pour tous les skills d'analyse (07 a 16). Une fois cree, ce fichier est en **LECTURE SEULE**.

C'est le pivot central du systeme : toutes les analyses lisent ce fichier, aucune ne le modifie.

## Positionnement dans le pipeline

```
01 → 02 → 03 → 04 → 05 → [06 NORMALISATION EXCEL] → 07-13 → 14 → 15+16
                            ^^^ TU ES ICI
```

- **Input** : `./pipeline/05_database_normee.json`
- **Output** : `./pipeline/06_dataset_final.xlsx` + `./pipeline/06_dataset_final_meta.json`
- **Librairie** : `openpyxl` exclusivement
- **Apres creation** : le fichier est verrouille. Les skills suivants le lisent uniquement.

## Architecture des onglets

Le fichier Excel comporte **4 categories d'onglets** :

### Categorie 1 — Donnees historiques (VERROUILLEES)

#### Onglet `BILAN_[YYYY]` (un par exercice)

| Ligne | Poste | N Brut | N Amort/Deprec | N Net | N-1 Net |
|---|---|---|---|---|---|
| **ACTIF IMMOBILISE** | | | | | |
| 1 | Immobilisations incorporelles | ... | ... | ... | ... |
| 2 | Terrains | ... | ... | ... | ... |
| ... | ... | ... | ... | ... | ... |
| **ACTIF CIRCULANT** | | | | | |
| ... | Stocks et en-cours | ... | ... | ... | ... |
| ... | Creances | ... | ... | ... | ... |
| ... | Disponibilites | ... | ... | ... | ... |
| **TOTAL ACTIF** | | **=SOMME** | **=SOMME** | **=SOMME** | **=SOMME** |
| | | | | | |
| **CAPITAUX PROPRES** | | | | N | N-1 |
| ... | Capital | ... | | ... | ... |
| ... | Reserves | ... | | ... | ... |
| ... | Resultat | ... | | ... | ... |
| **PROVISIONS** | | | | | |
| **DETTES** | | | | | |
| **TOTAL PASSIF** | | | | **=SOMME** | **=SOMME** |
| | | | | | |
| **CONTROLE** | Actif - Passif | | | **=ACTIF-PASSIF** | |

Mise en forme :
- Cellule CONTROLE : fond VERT si = 0, fond ROUGE si ≠ 0
- Commentaire Excel sur chaque cellule de donnee : `"Source: [doc] p.[page] — [verbatim]"`
- Cellules avec verdict DOUTEUX : fond JAUNE
- Cellules NULL : fond GRIS, texte "N/D"

#### Onglet `CR_[YYYY]` (un par exercice)

| Ligne | Poste | Montant N | Montant N-1 | Variation | Variation % |
|---|---|---|---|---|---|
| **PRODUITS D'EXPLOITATION** | | | | | |
| | Ventes produits vegetaux | ... | ... | =N-N1 | =VAR/N1 |
| | Ventes produits animaux | ... | ... | | |
| | Subventions exploitation | ... | ... | | |
| | ...dont DPB | ... | ... | | |
| | ...dont Eco-regime | ... | ... | | |
| | ...dont Aides couplees | ... | ... | | |
| **TOTAL PRODUITS** | | **=SOMME** | | | |
| | | | | | |
| **CHARGES D'EXPLOITATION** | | | | | |
| | Achats semences | ... | ... | | |
| | Achats engrais | ... | ... | | |
| | ... | | | | |
| **TOTAL CHARGES** | | **=SOMME** | | | |
| | | | | | |
| **SOLDES INTERMEDIAIRES** | | | | | |
| | Valeur Ajoutee | =formule | | | |
| | EBE | =formule | | | |
| | REX | =formule | | | |
| | Resultat financier | =formule | | | |
| | RCAI | =formule | | | |
| | Resultat exceptionnel | =formule | | | |
| | Resultat net | =formule | | | |
| | CAF | =formule | | | |

#### Onglet `FLUX_[YYYY]` (un par exercice, si calculable)

| Ligne | Poste | Montant |
|---|---|---|
| **FLUX OPERATIONNELS** | | |
| | CAF | =ref vers CR |
| | Variation BFR | =calcul |
| | **Flux operationnels nets** | **=CAF-varBFR** |
| **FLUX D'INVESTISSEMENT** | | |
| | Acquisitions immobilisations | ... |
| | Cessions immobilisations | ... |
| | **Flux d'investissement nets** | **=SOMME** |
| **FLUX DE FINANCEMENT** | | |
| | Nouveaux emprunts | ... |
| | Remboursements capital | ... |
| | **Flux de financement nets** | **=SOMME** |
| **VARIATION TRESORERIE** | | **=SOMME 3 flux** |
| **Tresorerie debut** | | ... |
| **Tresorerie fin** | | =debut+variation |

#### Onglet `AGREGATS` — Tableau recapitulatif multi-annees

| Indicateur | 2021 | 2022 | 2023 | Var. 22/21 | Var. 23/22 | TCAM |
|---|---|---|---|---|---|---|
| Chiffre d'affaires | | | | | | |
| Production totale | | | | | | |
| VA | | | | | | |
| EBE | | | | | | |
| REX | | | | | | |
| Resultat net | | | | | | |
| CAF | | | | | | |
| FRNG | | | | | | |
| BFR | | | | | | |
| Tresorerie nette | | | | | | |
| Fonds propres | | | | | | |
| Dettes financieres | | | | | | |
| Total bilan | | | | | | |

TCAM = Taux de Croissance Annuel Moyen = (Valeur finale / Valeur initiale)^(1/nb annees) - 1

### Categorie 2 — Onglets de reference

#### Onglet `PAC_SUBVENTIONS`

| Exercice | DPB | Eco-regime | Aides couplees vegetales | Aides couplees animales | MAEC | ICHN | DJA | Autres | Total PAC |
|---|---|---|---|---|---|---|---|---|---|

#### Onglet `IMMOBILISATIONS`

| Categorie | Brut N | Acquisitions | Cessions | Brut N fin | Amort cumul | Dotation N | VNC |
|---|---|---|---|---|---|---|---|
| Terrains | | | | | | | |
| Constructions | | | | | | | |
| Materiel agricole | | | | | | | |
| Materiel transport | | | | | | | |
| Autres | | | | | | | |

#### Onglet `DETTES`

| Exercice | Nature | Organisme | Montant initial | Taux | Type taux | Duree | Echeance annuelle | Capital restant du | Dont < 1 an | Dont 1-5 ans | Dont > 5 ans |
|---|---|---|---|---|---|---|---|---|---|---|---|

#### Onglet `STOCKS`

| Exercice | Nature | Categorie (vivant/mort) | Montant N | Montant N-1 | Variation | Methode valorisation |
|---|---|---|---|---|---|---|

### Categorie 3 — Onglet META (tracabilite)

#### Onglet `META_TRACABILITE`

| Onglet | Cellule | Valeur | Source doc | Source page | Verbatim | Confiance | Verdict audit | Flag |
|---|---|---|---|---|---|---|---|---|
| BILAN_2023 | C5 | 125000 | liasse_2023.pdf | 3 | "Terrains : 125 000" | 0.98 | CERTIFIE | |
| BILAN_2023 | C12 | N/D | | | | | SUPPRIME | "Non certifiable" |

### Categorie 4 — Onglet FORMULES (documentation)

#### Onglet `FORMULES_REFERENCE`

| Agregat | Formule complete | Composantes PCG | Norme |
|---|---|---|---|
| VA | Production + Marge comm. - Conso. interm. | 70+71+72-60-61-62 | PCG/ANC |
| EBE | VA + 74 - 63 - 64 | | PCG/ANC |
| ... | | | |

## Regles de mise en forme

| Element | Style |
|---|---|
| En-tetes de colonnes | Fond bleu fonce (#1F4E79), texte blanc, gras |
| Lignes de totaux | Fond bleu clair (#D6E4F0), gras |
| Lignes de sous-totaux | Italique |
| Donnees certifiees | Fond blanc |
| Donnees DOUTEUSES | Fond jaune (#FFF2CC) |
| Donnees NULL / N/D | Fond gris (#D9D9D9), texte "N/D" |
| Formules de controle ERREUR | Fond rouge (#FF0000), texte blanc |
| Formules de controle OK | Fond vert (#92D050) |
| Colonnes de variation negative | Texte rouge |
| Colonnes de variation positive | Texte vert fonce |

## Protection et verrouillage

- Tous les onglets de donnees historiques : **proteges en ecriture** (mot de passe vide pour deblocage admin)
- Les cellules de formules de controle : **non modifiables**
- L'onglet META : **protege**
- Largeur des colonnes : ajustee au contenu
- Figeage des volets : premiere ligne + premiere colonne figees

## Schema de sortie complementaire

Ecrire dans `./pipeline/06_dataset_final_meta.json` :

```json
{
  "skill_id": "06_normalisation_excel",
  "timestamp": "[ISO 8601]",
  "statut": "OK",
  "fichier_excel": "./pipeline/06_dataset_final.xlsx",
  "inventaire_onglets": [
    {
      "nom": "BILAN_2023",
      "categorie": "historique",
      "nb_lignes": 45,
      "nb_colonnes": 6,
      "protege": true,
      "nb_cellules_donnees": 120,
      "nb_cellules_null": 5,
      "nb_cellules_douteuses": 2
    }
  ],
  "controles_integrite": {
    "equilibres_bilan": [
      {"exercice": "2023", "actif": 450000, "passif": 450000, "ecart": 0, "ok": true}
    ],
    "coherence_sig": [
      {"exercice": "2023", "sig": "EBE", "calcule": 85000, "source": 85000, "ecart": 0, "ok": true}
    ]
  },
  "anomalies": [],
  "sources": {},
  "metriques": {
    "nb_valeurs_traitees": 0,
    "nb_valeurs_certifiees": 0,
    "nb_onglets_crees": 0,
    "nb_anomalies": 0,
    "duree_execution_sec": 0
  }
}
```

## Checklist de sortie

- [ ] Le fichier Excel est cree dans `./pipeline/06_dataset_final.xlsx`
- [ ] Tous les onglets historiques sont presents et remplis
- [ ] Les onglets de reference (PAC, immobilisations, dettes, stocks) sont presents
- [ ] L'onglet META contient la tracabilite de chaque cellule
- [ ] Les formules de controle (actif=passif, SIG) sont en place et correctes
- [ ] La mise en forme conditionnelle est appliquee
- [ ] Les onglets historiques sont proteges en ecriture
- [ ] Le fichier meta JSON est coherent avec le contenu Excel
- [ ] Les colonnes de variation sont calculees automatiquement
- [ ] Le TCAM est calcule sur l'onglet AGREGATS

$ARGUMENTS
