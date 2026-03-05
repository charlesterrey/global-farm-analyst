# Guide d'utilisation des skills

Ce guide detaille le fonctionnement de chaque skill du pipeline Global Farm Analyst.

---

## Table des matieres

- [Vue d'ensemble](#vue-densemble)
- [Avant de commencer](#avant-de-commencer)
- [Layer 1 — Extraction & Audit](#layer-1--extraction--audit)
  - [01 Controle Extraction](#01-controle-extraction)
  - [02 Extraction ANC](#02-extraction-anc)
  - [03 Controle Coherence](#03-controle-coherence)
  - [04 Audit Legal](#04-audit-legal)
- [Layer 2 — Database](#layer-2--database)
  - [05 Homogeneisation](#05-homogeneisation)
  - [06 Normalisation Excel](#06-normalisation-excel)
- [Layer 3 — Analyses](#layer-3--analyses)
  - [07 Analyse Financiere](#07-analyse-financiere)
  - [08 Analyse Agronomique](#08-analyse-agronomique)
  - [09 Analyse Risques](#09-analyse-risques)
  - [10 Stress Tests](#10-stress-tests)
  - [11 Modelisations](#11-modelisations)
  - [12 M&A / Prospective](#12-ma--prospective)
  - [13 Previsionnel 10 ans](#13-previsionnel-10-ans)
- [Layer 4 — Validation](#layer-4--validation)
  - [14 Validation Expert-Comptable](#14-validation-expert-comptable)
- [Layer 5 — Livrables](#layer-5--livrables)
  - [15 Rapport McKinsey](#15-rapport-mckinsey)
  - [16 Modele Excel Final](#16-modele-excel-final)
- [Gestion des erreurs](#gestion-des-erreurs)
- [Bonnes pratiques](#bonnes-pratiques)

---

## Vue d'ensemble

Le pipeline s'execute en 16 etapes sequentielles (sauf Layer 3, parallelisable) :

```
01 → 02 → 03 → 04 → 05 → 06 → [07..13] → 14 → [15+16]
```

Chaque skill :
- Lit les outputs du skill precedent dans `./pipeline/`
- Produit un fichier JSON structure dans `./pipeline/`
- Inclut un bloc `metadata` avec statut, date, version
- Inclut un dictionnaire `sources` tracant chaque valeur a son verbatim PDF

Conventions de nommage des fichiers intermediaires :

| Skill | Fichier produit |
|---|---|
| 01 | `pipeline/01_classification_pdfs.json` |
| 02 | `pipeline/02_extraction_anc.json` |
| 03 | `pipeline/03_controles_coherence.json` |
| 04 | `pipeline/04_audit_legal.json` |
| 05 | `pipeline/05_database_normee.json` |
| 06 | `pipeline/06_dataset_excel.xlsx` |
| 07 | `pipeline/07_analyse_financiere.json` |
| 08 | `pipeline/08_analyse_agronomique.json` |
| 09 | `pipeline/09_analyse_risques.json` |
| 10 | `pipeline/10_stress_tests.json` |
| 11 | `pipeline/11_modelisations.json` |
| 12 | `pipeline/12_manda_prospective.json` |
| 13 | `pipeline/13_previsionnel_10ans.json` |
| 14 | `pipeline/14_validation.json` |
| 15 | `outputs/rapport_[exploitation].docx` |
| 16 | `outputs/modele_[exploitation].xlsx` |

---

## Avant de commencer

### Prerequis techniques

```bash
pip install -r requirements.txt
```

### Preparation des documents

1. Placer tous les PDFs comptables dans `./inputs/`
2. S'assurer d'avoir au minimum :
   - **Bilan** (cerfa 2050) pour 2+ exercices
   - **Compte de resultat** (cerfa 2052-2053) pour 2+ exercices
3. Documents recommandes pour une analyse complete :
   - Grand livre
   - Declaration PAC / RPG
   - Cotisations MSA
   - Tableaux d'amortissement

### Lancer un skill

Dans Claude Code, taper :

```
/01-controle-extraction
```

Le skill s'execute automatiquement. En cas de blocage (statut ROUGE), corriger le probleme signale puis relancer le meme skill.

---

## Layer 1 — Extraction & Audit

### 01 Controle Extraction

**Commande** : `/01-controle-extraction`

**Role** : Classifie chaque PDF depose dans `./inputs/` sans extraire de donnees chiffrees. Premiere etape du pipeline.

**Ce qu'il fait** :
- Identifie le type de document parmi 15 categories (liasse fiscale, grand livre, declaration PAC, MSA, releves bancaires, etc.)
- Determine la periode comptable et l'entite
- Evalue la lisibilite sur 5 niveaux (EXCELLENT, BON, MOYEN, FAIBLE, ILLISIBLE)
- Detecte les doublons et les documents manquants

**Output** : `pipeline/01_classification_pdfs.json`

**Conditions de blocage** :
- Aucun bilan detecte → BLOQUANT
- Aucun compte de resultat → BLOQUANT
- Moins de 2 exercices → BLOQUANT

---

### 02 Extraction ANC

**Commande** : `/02-extraction-anc`

**Role** : Extrait les donnees poste par poste selon le Plan Comptable Agricole (ANC).

**Ce qu'il fait** :
- Extrait 80+ postes du PCG (comptes 10xx a 77xx)
- Decompose les subventions PAC en 7 types (DPB, paiement vert, redistributif, JA, couplees animales, couplees vegetales, eco-regimes)
- Extrait les cotisations MSA, provisions DPA/DEP, stocks agricoles
- Chaque valeur extraite contient : `source_doc`, `source_page`, `verbatim`, `confiance`

**Output** : `pipeline/02_extraction_anc.json`

**Conditions de blocage** :
- Ecart actif/passif > 1% → BLOQUANT
- Valeur extraite avec confiance < 0.60 → BLOQUANT (valeur supprimee)

---

### 03 Controle Coherence

**Commande** : `/03-controle-coherence`

**Role** : Execute 25+ controles comptables automatiques sur les donnees extraites.

**Ce qu'il fait** :
- **Bloc A** — Equilibres fondamentaux : actif = passif, resultat net coherent entre bilan et CR
- **Bloc B** — Inter-exercices : continuite du bilan de cloture N-1 vers ouverture N
- **Bloc C** — Plausibilite agricole : rendements dans les fourchettes Arvalis, charges/ha coherentes
- **Bloc D** — Specificites agricoles : DPB/ha dans la fourchette nationale, MSA proportionnelle, variation stocks coherente
- **Bloc E** — Completude : presence des postes obligatoires, annees couvertes

Chaque controle renvoie un statut : **VERT** (OK), **ORANGE** (alerte), **ROUGE** (bloquant).

**Output** : `pipeline/03_controles_coherence.json`

---

### 04 Audit Legal

**Commande** : `/04-audit-legal`

**Role** : Certification anti-hallucination. Verifie que chaque valeur du pipeline est tracee a un verbatim PDF.

**Ce qu'il fait** :
- Attribue un verdict a chaque donnee :
  - **CERTIFIE** — Verbatim exact retrouve dans le PDF
  - **CERTIFIE_CORRIGE** — Erreur mineure corrigee (ex: OCR), correction documentee
  - **DOUTEUX** — Verbatim approximatif, confiance degradee
  - **RELOCALISE** — Source retrouvee dans un autre document
  - **SUPPRIME** — Aucune source fiable → valeur retiree du pipeline
- Calcule le taux de certification global

**Output** : `pipeline/04_audit_legal.json`

**Conditions de blocage** :
- Taux de certification < 95% → BLOQUANT

---

## Layer 2 — Database

### 05 Homogeneisation

**Commande** : `/05-database-homogeneisation`

**Role** : Structure les donnees certifiees en une base normee multi-exercices.

**Ce qu'il fait** :
- Aligne les exercices sur un referentiel commun
- Calcule les SIG (Soldes Intermediaires de Gestion) : marge brute, VA, EBE, resultat courant, resultat exceptionnel
- Construit le bilan fonctionnel : FRNG, BFR exploitation, BFR hors exploitation, tresorerie nette
- Reconstitue le tableau de flux de tresorerie
- Normalise les montants (arrondi, devise, periodicite)

**Output** : `pipeline/05_database_normee.json`

---

### 06 Normalisation Excel

**Commande** : `/06-normalisation-excel`

**Role** : Produit le fichier Excel qui sert de **source unique de verite** pour toutes les analyses.

**Ce qu'il fait** :
- Cree un classeur Excel avec 4 categories d'onglets :
  - **Historiques** (verrouilles) : bilan, CR, SIG, flux
  - **Referentiels** : benchmarks RICA, rendements Arvalis
  - **META** : tracabilite source pour chaque cellule
  - **Formules** : calculs intermediaires
- Applique la mise en forme conditionnelle (vert/orange/rouge)
- Verrouille les onglets historiques en ecriture

**Output** : `pipeline/06_dataset_excel.xlsx`

**Regle critique** : Ce fichier est en **LECTURE SEULE** a partir de ce point. Aucun skill ulterieur ne peut le modifier.

---

## Layer 3 — Analyses

Les skills 07 a 13 sont **independants** et peuvent s'executer en parallele. Ils lisent tous le dataset du skill 06 sans le modifier.

### 07 Analyse Financiere

**Commande** : `/07-analyse-financiere`

**Role** : Calcule 45+ ratios financiers et les compare aux benchmarks RICA.

**Ce qu'il fait** :
- 6 familles de ratios :
  - **Solvabilite** : autonomie financiere, taux d'endettement, capacite de remboursement
  - **Liquidite** : ratio courant, tresorerie nette, BFR en jours
  - **Rentabilite** : ROA, ROE, marge nette, marge EBE
  - **Structure des charges** : charges fixes/variables, point mort
  - **Specifiques agricoles** : annuites/EBE, MSA/EBE, subventions/CA, foncier/CA
  - **Dynamique** : evolution N/N-1 de chaque ratio
- Benchmarking RICA par OTEX : position vs mediane, Q1, Q3
- Attribution d'une note de synthese par famille

**Output** : `pipeline/07_analyse_financiere.json`

---

### 08 Analyse Agronomique

**Commande** : `/08-analyse-agronomique`

**Role** : Analyse l'assolement, le parc materiel et la dimension sociale.

**Ce qu'il fait** :
- **Assolement** : repartition des cultures, concentration (HHI), rendements vs referentiels Arvalis, marges brutes par culture
- **Materiel** : age moyen du parc, taux de vetuste, cout/ha de mecanisation vs baremes CUMA, strategie (propriete vs CUMA vs ETA)
- **Social** : UTH, productivite par UTH, cout salarial, saisonnalite

**Output** : `pipeline/08_analyse_agronomique.json`

---

### 09 Analyse Risques

**Commande** : `/09-analyse-risques`

**Role** : Cartographie 7 risques avec matrice Probabilite x Impact.

**Les 7 risques** :
1. **Liquidite** — tresorerie nette negative, BFR non couvert
2. **Endettement** — annuites/EBE > 50%, duration dette
3. **PAC** — dependance aux subventions, sensibilite reforme
4. **Concentration** — HHI des cultures ou clients
5. **Taux d'interet** — part dette a taux variable, sensibilite +250bp
6. **Succession** — age exploitant, absence de repreneur identifie
7. **Climat** — historique de sinistres, couverture assurantielle

Chaque risque recoit une probabilite (1-5) et un impact (1-5). La matrice P x I determine le niveau : **FAIBLE**, **MODERE**, **ELEVE**, **CRITIQUE**.

**Output** : `pipeline/09_analyse_risques.json`

---

### 10 Stress Tests

**Commande** : `/10-stress-tests`

**Role** : Simule 6 scenarios de stress sur 3 ans + scenario de base.

**Les 6 scenarios** :
1. **Climat** — chute de 30% du CA vegetal (secheresse/inondation)
2. **Prix baissier** — prix de vente -20%, intrants +15%
3. **Taux** — hausse de 250 points de base sur la dette variable
4. **PAC** — reduction de 35% des subventions
5. **Combine** — climat + prix + taux simultanes
6. **Social** — hausse de 20% des cotisations MSA

Pour chaque scenario : impact sur EBE, tresorerie nette, ratio annuites/EBE, et point de rupture (annee ou la tresorerie devient negative).

**Output** : `pipeline/10_stress_tests.json`

---

### 11 Modelisations

**Commande** : `/11-modelisations`

**Role** : Projections P&L, bilan et tresorerie sur 5 ans avec modele integre a 3 etats financiers.

**Ce qu'il fait** :
- **Modele a 3 etats** : P&L → Bilan → Tresorerie → Bilan (boucle iterative)
- **Hierarchie des hypotheses** :
  - Niveau 1 : Contractuel (baux, prets, subventions signees)
  - Niveau 2 : Tendanciel (prolongation des tendances historiques)
  - Niveau 3 : Hypothetique (scenarios de marche)
- Projections poste par poste au niveau PCG
- Verification croisee : Total bilan = Total passif a chaque annee
- **Analyse de sensibilite** :
  - Tornado chart sur 7 variables cles
  - Matrices de sensibilite croisee (CA x Charges, CA x PAC)
  - Calcul des elasticites
  - Seuil de rentabilite et marge de securite

**Output** : `pipeline/11_modelisations.json`

---

### 12 M&A / Prospective

**Commande** : `/12-manda-prospective`

**Role** : Valorisation de l'exploitation (3 methodes) et analyse prospective.

**Ce qu'il fait** :
- **Valorisation ANC** : actif net corrige avec prix SAFER par region, traitement fiscal des plus-values (art. 151 septies CGI)
- **Valorisation DCF** : actualisation des flux libres, WACC 7-9%, table d'ajustements (decote liquidite, prime taille, etc.)
- **Valorisation Comparables** : multiples EBE et CA du secteur agricole
- **Capacite d'investissement** : a 3 durees (7, 15, 25 ans) avec contrainte annuites/EBE < 50%
- **8 simulations d'investissement** : foncier, materiel, batiment, conversion bio, irrigation, diversification, photovoltaique, robotique — chacune avec test de faisabilite
- **6 megatendances** : PAC post-2027, transition ecologique, digital/precision, foncier/demographie, marches/volatilite, climat — avec grille d'analyse structuree
- **3 scenarios strategiques** : dimensionnement financier et seuil de rentabilite pour chacun

**Output** : `pipeline/12_manda_prospective.json`

---

### 13 Previsionnel 10 ans

**Commande** : `/13-previsionnel-10ans`

**Role** : 3 scenarios (pessimiste / base / optimiste) sur 10 ans avec taux evolutifs.

**Ce qu'il fait** :
- **Taux evolutifs** : les hypotheses ne sont pas plates mais evoluent par periode (CT 1-3 ans, MT 4-6 ans, LT 7-10 ans)
- **Analyse de convergence/divergence** : ecarts entre scenarios a chaque horizon
- **Methodologie corridor** : fourchette min-max annuelle, percentiles 10/25/50/75/90
- **6 seuils de rupture** : tresorerie < 0, annuites/EBE > 60%, capitaux propres < 0, ratio courant < 0.8, perte nette > 2 ans, endettement > 80%
- **Tipping points** : annee ou un seuil bascule selon le scenario
- **Modele de degradation de confiance** : la fiabilite des projections diminue avec l'horizon (facteurs d'erosion : volatilite historique, nombre d'hypotheses, sensibilite)
- **Graphiques** : corridors matplotlib avec zones de confiance

**Output** : `pipeline/13_previsionnel_10ans.json`

---

## Layer 4 — Validation

### 14 Validation Expert-Comptable

**Commande** : `/14-validation-expert-comptable`

**Role** : Audit GO/NO-GO avant generation des livrables finaux.

**Ce qu'il fait** :
- Audite l'ensemble du pipeline sur 5 axes :
  1. **Tracabilite** — Chaque valeur a-t-elle un verbatim source ?
  2. **Formules** — Les calculs sont-ils corrects et reproductibles ?
  3. **Coherence des projections** — Les hypotheses sont-elles raisonnables ?
  4. **Conformite ANC** — Le plan comptable agricole est-il respecte ?
  5. **Affirmations non sourcees** — Y a-t-il des assertions sans preuve ?
- Calcule un score de certification global
- Decision :
  - **GO** (score >= 98%) → Les skills 15 et 16 peuvent s'executer
  - **NO-GO** (score < 98%) → Liste des corrections requises

**Output** : `pipeline/14_validation.json`

**Regle critique** : Sans GO explicite du skill 14, les skills 15 et 16 **refusent de s'executer**.

---

## Layer 5 — Livrables

### 15 Rapport McKinsey

**Commande** : `/15-rapport-mckinsey`

**Role** : Genere un rapport Word de 100 a 150 pages de niveau cabinet de conseil.

**Prerequis** : GO du skill 14.

**Ce qu'il fait** :
- Rapport Word (`python-docx`) avec mise en page professionnelle :
  - Police Calibri 11pt, marges 2.5cm
  - En-tetes et pieds de page avec nom d'exploitation et pagination
- 7 parties :
  1. Synthese executive
  2. Analyse financiere historique
  3. Analyse agronomique
  4. Cartographie des risques
  5. Stress tests et resilience
  6. Valorisation et prospective
  7. Previsionnel 10 ans et recommandations
- Graphiques matplotlib integres a 300 DPI
- **Chaque chiffre cite est source en note de bas de page** (document, page, verbatim)

**Output** : `outputs/rapport_[exploitation].docx`

---

### 16 Modele Excel Final

**Commande** : `/16-modele-excel-final`

**Role** : Genere un modele Excel dynamique avec 16 onglets.

**Prerequis** : GO du skill 14.

**Ce qu'il fait** :
- 16 onglets structures :
  - **DASHBOARD** — Vue synthese avec indicateurs cles
  - **HYPOTHESES** — Cellules jaunes modifiables par l'utilisateur
  - **HISTORIQUE** — Donnees certifiees verrouillees
  - **SIG** — Soldes Intermediaires de Gestion
  - **BILAN_FONCTIONNEL** — FRNG, BFR, tresorerie nette
  - **RATIOS** — 45+ ratios avec benchmark RICA
  - **PREV_CR** — Previsionnel compte de resultat
  - **PREV_BILAN** — Previsionnel bilan
  - **PREV_TRESORERIE** — Previsionnel tresorerie
  - **STRESS** — Comparaison des 6 scenarios
  - **VALORISATION** — ANC, DCF, Comparables
  - **SENSIBILITE** — Matrices croisees
  - **INVESTISSEMENTS** — Simulations d'investissement
  - **CORRIDORS** — Previsionnel 10 ans (3 scenarios)
  - **META** — Tracabilite des sources
  - **CHANGELOG** — Historique des modifications
- Toutes les cellules previsionnelles sont liees aux HYPOTHESES par formules (zero valeur en dur)
- Mise en forme conditionnelle sur les ratios (vert/orange/rouge)
- Onglets historiques proteges en ecriture

**Output** : `outputs/modele_[exploitation].xlsx`

---

## Gestion des erreurs

### Niveaux d'alerte

| Niveau | Signification | Action |
|---|---|---|
| **VERT** | Controle passe | Pipeline continue |
| **ORANGE** | Alerte non bloquante | Signal dans le rapport, pipeline continue |
| **ROUGE / BLOQUANT** | Anomalie critique | Pipeline arrete, correction humaine requise |

### Que faire en cas de blocage

1. Lire le message d'erreur dans le JSON du skill bloquant
2. Identifier le document source concerne
3. Corriger le probleme (remplacer le PDF, ajouter un document manquant)
4. Relancer le skill bloquant : `/XX-nom-du-skill`
5. Le pipeline reprend normalement

### Erreurs frequentes

| Erreur | Cause | Solution |
|---|---|---|
| "Aucun bilan detecte" | PDF manquant ou illisible | Ajouter le cerfa 2050 dans `./inputs/` |
| "Ecart actif/passif > 1%" | Extraction incomplete | Verifier la qualite du PDF, relancer skill 02 |
| "Taux certification < 95%" | Trop de valeurs non tracees | Ajouter les documents sources manquants |
| "Score validation < 98%" | Anomalies dans le pipeline | Corriger les erreurs listees dans skill 14 |

---

## Bonnes pratiques

### Qualite des PDFs

- Privilegier les PDFs natifs (pas de scans si possible)
- Pour les scans, s'assurer d'une resolution minimale de 300 DPI
- Eviter les PDFs proteges par mot de passe

### Organisation des inputs

- Un dossier `./inputs/` par exploitation
- Nommer les fichiers de facon explicite : `liasse_2023.pdf`, `grand_livre_2023.pdf`
- Fournir au moins 2 exercices pour une analyse pertinente, 3+ pour une analyse optimale

### Interpretation des resultats

- Les projections a 10 ans perdent en fiabilite avec l'horizon : le modele de confiance du skill 13 quantifie cette degradation
- Les valorisations sont des fourchettes, pas des prix fermes : les 3 methodes donnent des ordres de grandeur
- Les stress tests sont calibres sur des scenarios historiques reels (secheresse 2003/2022, crise laitiere 2015)

### Securite et confidentialite

- Les dossiers `inputs/`, `pipeline/` et `outputs/` sont exclus du Git (`.gitignore`)
- Ne jamais commiter de donnees comptables
- Supprimer les fichiers intermediaires apres livraison si necessaire
