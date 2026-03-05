---
name: 16-modele-excel-final
description: >
  Modele Excel Dynamique Final. Genere un fichier Excel complet avec dashboard, hypotheses
  modifiables, historique certifie verrouille, previsionnel lie aux hypotheses, stress tests,
  40+ ratios avec benchmark, sensibilite et tracabilite complete. Prerequis : GO du skill 14.
  Utiliser apres la validation expert-comptable.
disable-model-invocation: true
allowed-tools: Read, Bash(python *), Write, Glob
argument-hint: "[nom de l'exploitation ou vide]"
---

# Skill 16 — Modele Excel Dynamique Final

## Prerequis absolu

Avant toute generation :
1. Lire `./pipeline/14_validation_go_nogo.json`
2. Verifier que `decision` = `"GO"`
3. Si `decision` ≠ `"GO"` → **ARRET IMMEDIAT**

## Role et positionnement

Tu generes le **second livrable** du systeme : un modele Excel dynamique et interactif
permettant a l'utilisateur de modifier les hypotheses et de voir instantanement l'impact
sur les projections financieres.

## Positionnement dans le pipeline

```
01-13 → 14 (GO) → 15 + [16 MODELE EXCEL FINAL]
                         ^^^ TU ES ICI
```

- **Input** : `./pipeline/06_dataset_final.xlsx` + `./pipeline/10_stress_tests.json` + `./pipeline/13_previsionnel.json`
- **Output** : `./outputs/modele_excel_final.xlsx`
- **Librairie** : `openpyxl` exclusivement

## Architecture des onglets (16 onglets)

### Onglet 1 — DASHBOARD

**Objectif** : vue synthetique instantanee de l'exploitation.

**Section haute — KPIs cles (annee N)**

| KPI | Valeur | Tendance | Benchmark | Feu |
|---|---|---|---|---|
| EBE | ... EUR | ↑ ou ↓ | ... EUR | VERT/ORANGE/ROUGE |
| Resultat net | ... EUR | | | |
| CAF | ... EUR | | | |
| Tresorerie nette | ... EUR | | | |
| Ratio endettement | ...x | | < 7x | |
| Autonomie financiere | ...% | | > 35% | |
| Couverture annuites | ...x | | > 1.2x | |
| Marge EBE | ...% | | > 20% | |

Mise en forme conditionnelle :
- VERT : ratio dans la norme ou mieux
- ORANGE : ratio en zone d'alerte
- ROUGE : ratio en zone critique

Les seuils sont definis dans un onglet PARAMETRES (ou directement dans les formules).

**Section basse — Graphiques (generes avec openpyxl charts)**
- Graphique 1 : Evolution CA, EBE, RN sur N exercices (barres groupees)
- Graphique 2 : Evolution tresorerie nette (ligne)
- Graphique 3 : Repartition charges (camembert)

### Onglet 2 — HYPOTHESES (cellules modifiables)

**C'est le coeur du modele dynamique.** Toute modification ici se propage automatiquement.

**Mise en forme** : cellules d'hypotheses sur fond JAUNE (#FFF2CC) avec bordure epaisse.
Toutes les autres cellules sont verrouillees.

| Parametre | N+1 | N+2 | N+3 | N+4 | N+5 | N+6 | N+7 | N+8 | N+9 | N+10 |
|---|---|---|---|---|---|---|---|---|---|---|
| **PRODUITS** | | | | | | | | | | |
| Taux croissance CA (%) | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 | 1.5 |
| Evolution PAC (%) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **CHARGES** | | | | | | | | | | |
| Evolution charges ope (%) | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 |
| Evolution charges personnel (%) | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 | 2.5 |
| Evolution fermages (%) | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 | 1.0 |
| **INVESTISSEMENTS** | | | | | | | | | | |
| Investissement annuel (EUR) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| **FINANCEMENT** | | | | | | | | | | |
| Taux interet moyen (%) | 3.0 | 3.0 | 3.0 | 3.0 | 3.0 | 3.0 | 3.0 | 3.0 | 3.0 | 3.0 |
| Nouvel emprunt (EUR) | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Duree nouvel emprunt (ans) | 15 | 15 | 15 | 15 | 15 | 15 | 15 | 15 | 15 | 15 |
| **FISCALITE** | | | | | | | | | | |
| Taux IS/IR (%) | 25 | 25 | 25 | 25 | 25 | 25 | 25 | 25 | 25 | 25 |
| **PRELEVEMENTS** | | | | | | | | | | |
| Prelevements prives annuels | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Valeurs pre-remplies = hypotheses base du skill 13.

### Onglets 3-5 — HISTORIQUE (VERROUILLES)

#### Onglet `HISTORIQUE_CR`

Compte de resultat N-3 a N (selon exercices disponibles).
- Toutes les cellules : verrouillees, fond blanc
- Commentaire Excel sur chaque cellule : source_doc, page, verbatim
- Colonnes de variation automatiques

#### Onglet `HISTORIQUE_BILAN`

Bilan complet N-3 a N.
- Controle Actif = Passif en derniere ligne (fond vert si OK, rouge si KO)

#### Onglet `HISTORIQUE_FLUX`

Flux de tresorerie reconstitues (si calculables).

### Onglets 6-8 — PREVISIONNEL (lies aux HYPOTHESES)

#### Onglet `PREV_CR`

P&L previsionnel N+1 a N+10.

**Regle absolue** : AUCUNE valeur hardcodee. Chaque cellule est une formule referencant :
- L'onglet HYPOTHESES pour les taux d'evolution
- L'onglet HISTORIQUE_CR pour la base de depart (annee N)

```
Exemple :
CA N+1 = HISTORIQUE_CR!CA_N × (1 + HYPOTHESES!Taux_croissance_CA_N1)
CA N+2 = PREV_CR!CA_N1 × (1 + HYPOTHESES!Taux_croissance_CA_N2)
```

Structure du P&L previsionnel :

| Poste | N (historique) | N+1 | N+2 | ... | N+10 |
|---|---|---|---|---|---|
| CA | =ref historique | =formule | =formule | | |
| Subventions PAC | =ref | =formule | | | |
| Total produits | =somme | =somme | | | |
| Charges ope | =ref | =formule | | | |
| Charges personnel | =ref | =formule | | | |
| ... | | | | | |
| VA | =formule | =formule | | | |
| EBE | =formule | =formule | | | |
| DAP | =ref | =formule | | | |
| REX | =formule | =formule | | | |
| Charges financieres | =ref | =formule | | | |
| RN | =formule | =formule | | | |
| CAF | =formule | =formule | | | |

#### Onglet `PREV_BILAN`

Bilan previsionnel N+1 a N+10.
- Actif immobilise = N + Investissements - DAP
- Stocks = proportionnel au CA (ratio historique)
- Fonds propres = N + Resultat net previsionnel
- Dettes = N - Remboursements + Nouveaux emprunts
- Controle equilibre en derniere ligne

#### Onglet `PREV_TRESORERIE`

Cash flow previsionnel cumulatif.

| Flux | N+1 | N+2 | ... | N+10 |
|---|---|---|---|---|
| CAF | =ref PREV_CR | | | |
| - Variation BFR | =formule | | | |
| Flux operationnels | =somme | | | |
| - Investissements | =ref HYPOTHESES | | | |
| + Nouveaux emprunts | =ref HYPOTHESES | | | |
| - Remboursements dette | =formule | | | |
| - Prelevements prives | =ref HYPOTHESES | | | |
| Variation tresorerie | =somme | | | |
| **Tresorerie cumulee** | =N + variation | | | |

**Mise en forme conditionnelle** : tresorerie cumulee en ROUGE si < 0.

### Onglet 9 — CULTURES (si donnees disponibles)

P&L par culture avec surfaces, rendements, prix, charges ope, marge brute.
Si donnees non disponibles → onglet present mais vide avec mention "Donnees non disponibles dans les documents fournis".

### Onglet 10 — MATERIEL

Tableau du parc materiel :
- Categorie, valeur brute, amort cumule, VNC, taux d'usure
- Plan de renouvellement indicatif (renouvellement quand VNC < 10% du brut)

### Onglet 11 — DETTE

Tableau d'amortissement complet :
- Par pret identifie (si disponible)
- Ou : echeancier global (si detail non disponible)
- Colonnes : annee, capital debut, interet, capital rembourse, capital fin

### Onglets 12-13 — STRESS_TESTS

#### Onglet `STRESS_SYNTHESE`

Tableau comparatif des 6 scenarios :

| Indicateur | Base | S1 Climat | S2 Prix | S3 Taux | S4 PAC | S5 Combine | S6 Social |
|---|---|---|---|---|---|---|---|
| EBE N+1 | | | | | | | |
| EBE N+3 | | | | | | | |
| RN N+1 | | | | | | | |
| Tresorerie N+3 | | | | | | | |
| Rupture ? | | | | | | | |

Code couleur : vert si tresorerie > 0, rouge si rupture.

#### Onglet `STRESS_DETAIL`

Detail annuel de chaque scenario (6 blocs sur un meme onglet ou 6 sous-onglets).

### Onglet 14 — RATIOS

Les 45+ ratios calcules automatiquement depuis les onglets historiques ET previsionnels.

| Famille | Ratio | N-2 | N-1 | N | N+1 prev | N+5 prev | Benchmark RICA | Verdict |
|---|---|---|---|---|---|---|---|---|

Mise en forme conditionnelle :
- VERT : ratio meilleur que benchmark
- ORANGE : dans la norme (±10%)
- ROUGE : sous le benchmark de plus de 10%

### Onglet 15 — SENSIBILITE

Tableau croise dynamique : variation de chaque hypothese de -20% a +20% par pas de 5%.

| | -20% | -15% | -10% | -5% | Base | +5% | +10% | +15% | +20% |
|---|---|---|---|---|---|---|---|---|---|
| Impact sur EBE N+1 | | | | | | | | | |
| Impact sur RN N+1 | | | | | | | | | |
| Impact sur Tresorerie N+3 | | | | | | | | | |

Variables testees :
- Croissance CA
- Evolution charges ope
- Evolution PAC
- Charges financieres
- Prelevements prives

### Onglet 16 — SOURCES

Tracabilite complete de chaque cellule historique :

| Onglet | Cellule | Valeur | Source doc | Page | Verbatim | Confiance | Verdict audit |
|---|---|---|---|---|---|---|---|

## Regles Excel imperatives

### Protection
- Onglets HISTORIQUE : **proteges en ecriture** (mot de passe vide)
- Onglet SOURCES : **protege**
- Onglet HYPOTHESES : **seules les cellules jaunes sont modifiables**
- Onglets PREV : **proteges** (formules non modifiables)

### Formules
- **ZERO valeur hardcodee** dans les onglets previsionnels
- Tout est lie aux HYPOTHESES ou aux HISTORIQUES
- Les formules doivent utiliser des references nommees quand possible

### Mise en forme
- En-tetes : fond #1F4E79, texte blanc, gras
- Totaux : fond #D6E4F0, gras
- Cellules modifiables : fond #FFF2CC (jaune)
- Cellules NULL : fond #D9D9D9, texte "N/D"
- Mise en forme conditionnelle sur les ratios et la tresorerie
- Colonnes : largeur ajustee au contenu
- Figeage des volets : premiere ligne + premiere colonne

### Graphiques (openpyxl charts)
- Graphique CA/EBE/RN historique + previsionnel (barre + ligne)
- Graphique tresorerie cumulee (aire)
- Graphique radar de performance
- Graphique stress tests comparatif

## Output

Creer : `./outputs/modele_excel_final.xlsx`

$ARGUMENTS
