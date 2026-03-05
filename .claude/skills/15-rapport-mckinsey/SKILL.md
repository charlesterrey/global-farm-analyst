---
name: 15-rapport-mckinsey
description: >
  Rapport McKinsey 100+ pages. Genere un rapport Word professionnel de niveau cabinet de conseil
  couvrant analyse financiere, agronomique, risques, stress tests, valorisation et prospective
  10 ans. Chaque chiffre est source en note de bas de page. Prerequis : GO du skill 14.
  Utiliser apres la validation expert-comptable.
disable-model-invocation: true
allowed-tools: Read, Bash(python *), Write, Glob
argument-hint: "[nom de l'exploitation ou vide]"
---

# Skill 15 — Rapport McKinsey 100+ pages

## Prerequis absolu

Avant toute generation :
1. Lire `./pipeline/14_validation_go_nogo.json`
2. Verifier que `decision` = `"GO"`
3. Si `decision` ≠ `"GO"` → **ARRET IMMEDIAT** avec message :
   "Le skill 14 n'a pas delivre un GO. Decision actuelle : [X]. Corrections requises : [liste]."

## Role et positionnement

Tu generes le **livrable principal** du systeme : un rapport Word de 100 a 150 pages,
de qualite professionnelle comparable aux rapports de McKinsey, JP Morgan ou Lazard.

## Positionnement dans le pipeline

```
01-13 → 14 (GO) → [15 RAPPORT McKINSEY] + 16
                    ^^^ TU ES ICI
```

- **Input** : TOUS les fichiers `./pipeline/` de 01 a 14 + `./pipeline/06_dataset_final.xlsx`
- **Output** : `./outputs/rapport_mckinsey.docx`
- **Librairies** : `python-docx` pour le document, `matplotlib` pour les graphiques

## Structure exacte du rapport

---

### PAGE DE COUVERTURE

```
[Logo espace reserve]

ANALYSE FINANCIERE ET STRATEGIQUE
[NOM DE L'EXPLOITATION]

Exercices [20XX] a [20XX]

[Date de generation]

CONFIDENTIEL — DIFFUSION RESTREINTE
```

Style : fond sobre, typographie premium, alignement centre.

---

### PAGE 2 — SOMMAIRE AUTOMATIQUE

Genere automatiquement par python-docx avec les niveaux de titres.
Profondeur : 3 niveaux (Partie > Chapitre > Section).

---

### PAGE 3 — DECLARATION D'AUTHENTICITE ET DE METHODOLOGIE

```
DECLARATION D'AUTHENTICITE

Les donnees presentees dans ce rapport sont extraites de documents comptables originaux
fournis par [entite]. Elles ont ete soumises au processus de certification suivant :

1. Classification documentaire (Skill 01) — [N] documents traites
2. Extraction comptable ANC (Skill 02) — [N] valeurs extraites
3. Controle de coherence (Skill 03) — [N] controles executes, [N] conformes
4. Audit legal anti-hallucination (Skill 04) — Taux de certification : [X]%
5. Validation expert-comptable (Skill 14) — Decision : GO

Taux de certification global des donnees : [X]%
Nombre de valeurs supprimees par l'audit : [N]
Nombre de valeurs douteuses conservees avec reserve : [N]

Convention : chaque valeur chiffree dans ce rapport est tracee a sa source
via une note de bas de page indiquant le document et la page d'origine.
Les valeurs estimees sont signalees par un asterisque (*).
```

---

### EXECUTIVE SUMMARY (5-6 pages)

Structure imposee :

**Page 1 — Fiche d'identite synthetique**
- Tableau : Raison sociale, forme juridique, SIRET, localisation, SAU, OTEX, exercices analyses

**Page 2 — Les 5 constats financiers majeurs**
Chaque constat = 1 phrase chiffree avec source + 2 phrases de contexte.
Format : icone feu tricolore (vert/orange/rouge) + texte.

Exemples de constats :
- "L'autonomie financiere s'eleve a X%, superieure de Y points au benchmark RICA (source)."
- "La duree theorique de remboursement de la dette atteint X annees, au-dessus du seuil de 7 ans."

**Page 3 — Les 3 risques prioritaires**
Extraits de la matrice de risque (skill 09). Pour chaque risque :
- Nom du risque + Score (P×I)
- 1 phrase d'impact + 1 phrase de quantification

**Page 4 — Les 3 opportunites identifiees**
Extraites des analyses (skills 07-12).

**Page 5 — Valorisation synthetique**
- Fourchette basse / haute avec methode
- Capacite d'investissement residuelle

**Page 6 — Radar de performance**
Graphique radar (matplotlib) avec 6-8 axes : solvabilite, liquidite, rentabilite, efficacite,
diversification, resilience. Valeurs normalisees 0-100 avec benchmark RICA en overlay.

---

### PARTIE I — L'EXPLOITATION (10-15 pages)

**1.1 Fiche d'identite**
Toutes les donnees d'identification extraites par le skill 01.

**1.2 Evolution sur [N] exercices**
- Tableau synthetique des KPIs cles (CA, EBE, RN, CAF, dettes, FP) sur N exercices
- Graphique d'evolution (barres + ligne de tendance)

**1.3 Structure juridique et capitaux**
- Forme juridique et implications
- Evolution des fonds propres
- Politique de distribution (si identifiable)

**1.4 Productions et marches**
- Assolement (si disponible via PAC)
- Structure du CA par type de production
- Positionnement marche

---

### PARTIE II — ANALYSE FINANCIERE (25-30 pages)

**2.1 Bilan — Evolution pluriannuelle**
- Graphique : barres empilees actif (immo, circulant) et passif (FP, dettes LT, CT)
- Tableau detaille par exercice
- Commentaire analytique des evolutions

**2.2 Compte de resultat — Waterfall EBE**
- Graphique waterfall : du CA a l'EBE (+ subventions, - charges ope, - personnel, - impots)
- Graphique waterfall : de l'EBE au resultat net (- DAP, - charges fin., +/- except., - IS)
- Tableau SIG complet avec variations

**2.3 Flux de tresorerie**
- Tableau des flux (operationnels, investissement, financement)
- Graphique d'evolution de la tresorerie

**2.4 Les 45+ ratios — Tableau complet avec benchmark**
- Tableau organise par famille (solvabilite, liquidite, rentabilite, etc.)
- Colonnes : Ratio | Valeur N | Valeur N-1 | Benchmark RICA | Ecart | Verdict
- Code couleur (vert/orange/rouge)

**2.5 Structure de financement et dette**
- Decomposition de la dette par nature et echeance
- Graphique : evolution dettes financieres et annuites
- Analyse du cout de la dette

**2.6 BFR et cycle d'exploitation**
- Evolution du BFR et de ses composantes
- BFR en jours de CA
- Graphique FRNG vs BFR vs Tresorerie

---

### PARTIE III — ANALYSE AGRONOMIQUE ET TECHNIQUE (15-20 pages)

**3.1 Assolement et performances culturales**
- Graphique camembert de l'assolement (si disponible)
- Tableau des charges operationnelles
- Comparaison aux references

**3.2 Parc materiel**
- Tableau des immobilisations corporelles
- Taux d'usure et anciennete
- Graphique cout complet de mecanisation
- Comparaison aux references CUMA

**3.3 Ressources humaines et organisation**
- Estimation des UTAs
- Productivite par UTA
- Graphique comparatif VA/UTA, EBE/UTA

---

### PARTIE IV — RISQUES ET RESILIENCE (10-15 pages)

**4.1 Matrice des risques**
- Graphique matriciel probabilite × impact (bulles)
- Tableau detaille par risque

**4.2 Resultats des 6 stress tests**
- Tableau comparatif des scenarios
- Graphique : EBE et tresorerie sous chaque scenario (3 ans)
- Graphique : "corridor de resilience" (enveloppe min/max)

**4.3 Points de rupture identifies**
- Pour chaque scenario : seuil de defaillance
- Graphique : marge de securite par type de choc

**4.4 Dispositifs de protection**
- Assurance recolte : presente/absente
- DEP/DPA : montant disponible
- Diversification : indice de concentration

---

### PARTIE V — STRATEGIE ET VALEUR (10-15 pages)

**5.1 Valorisation (3 methodes)**
- Tableau comparatif ANC / DCF / Comparables
- Graphique fourchette de valorisation (horizontal bar)

**5.2 Capacite d'investissement**
- Capacite d'emprunt theorique
- Simulations d'investissement type

**5.3 Trois scenarios strategiques**
- Tableau comparatif : Maintien / Developpement / Transformation
- Pour chaque : prerequis, avantages, risques, implications financieres

---

### PARTIE VI — PROSPECTIVE 10 ANS (15-20 pages)

**6.1 Megatendances et impacts**
- Matrice d'impact (probabilite × gravite × sens)
- Analyse par tendance

**6.2 Projections financieres (3 scenarios)**
- Graphique : corridor de projection CA (pessimiste/base/optimiste) sur 10 ans
- Graphique : corridor de projection EBE
- Graphique : corridor de projection tresorerie cumulee
- Tableau annuel complet par scenario
- Avertissement explicite sur la degradation de la confiance

**6.3 Roadmap indicative par horizon temporel**
- Court terme (0-12 mois) : actions immediates
- Moyen terme (1-3 ans) : ajustements structurels
- Long terme (3-10 ans) : orientations strategiques

---

### PARTIE VII — SYNTHESE ET POINTS D'ATTENTION (5 pages)

**Actions a court terme (0-12 mois)** — chiffrees
- Tableau : Action | Impact estime | Effort | Priorite

**Actions a moyen terme (1-3 ans)** — chiffrees
- Idem

**Axes de vigilance long terme**
- Liste hierarchisee

---

### ANNEXES (15-20 pages)

**Annexe A — Donnees comptables certifiees (extrait)**
- Bilan et CR du dernier exercice (format liasse)
- Source et taux de certification

**Annexe B — Methodologie des ratios**
- Tableau : Ratio | Formule | Norme de reference | Source bibliographique

**Annexe C — Certificat de validation expert-comptable**
- Reproduction du certificat du skill 14

**Annexe D — Registre des hypotheses previsionnelles**
- Tableau complet du registre du skill 11

**Annexe E — Glossaire**
- Definitions des termes techniques utilises

---

## Regles redactionnelles imperatives

1. **Chaque chiffre cite dans le texte** → note de bas de page : "Source : [document] page [X]"
2. **Zero formulation vague non chiffree** : jamais "l'exploitation va bien", toujours "l'EBE s'eleve a X EUR, en hausse de Y% (source)"
3. **Graphiques generes avec matplotlib** : integres en PNG haute resolution (300 dpi) dans le docx
4. **Minimum 100 pages**, viser 120-150 pages
5. **Ton factuel, analytique, professionnel** : aucune promesse, aucune certitude sur le futur
6. **Pas de premiere personne** : "l'analyse montre que..." (pas "nous avons constate que...")
7. **Titres numerotes** : 1.1, 1.2, 2.1, etc.
8. **En-tetes et pieds de page** : nom de l'exploitation | Confidentiel | N° de page

## Specifications techniques python-docx

- Police principale : Calibri 11pt
- Titres : Calibri Bold, tailles 18pt (Partie), 14pt (Chapitre), 12pt (Section)
- Marges : 2.5 cm partout
- Interligne : 1.15
- Tableaux : bordures fines (0.5pt), en-tetes avec fond #1F4E79 texte blanc
- Graphiques : 15 cm de large, ratio 16:9 ou 4:3 selon le type
- Notes de bas de page : Calibri 8pt
- Sauts de page avant chaque Partie

## Output

Creer : `./outputs/rapport_mckinsey.docx`

$ARGUMENTS
