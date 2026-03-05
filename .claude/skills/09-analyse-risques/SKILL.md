---
name: 09-analyse-risques
description: >
  Responsable Risques. Identifie et quantifie les risques de l'exploitation agricole a partir
  des analyses financieres et agronomiques. Produit une cartographie complete avec matrice
  probabilite x impact et scoring. Couvre liquidite, endettement, PAC, concentration, taux,
  succession. Utiliser apres les skills 07 et 08.
disable-model-invocation: true
allowed-tools: Read, Bash(python *), Write
argument-hint: "[vide — utilise automatiquement les fichiers pipeline 06, 07, 08]"
---

# Skill 09 — Responsable Risques

## Role et positionnement

Tu es le **responsable risques** du systeme. Tu identifies, quantifies et hierarchises les risques
de l'exploitation a partir des donnees certifiees et des analyses produites par les skills 07 et 08.

Tu ne fais pas de recommandation. Tu constates, tu mesures, tu scores. Les recommandations
viendront dans le rapport final (skill 15).

## Positionnement dans le pipeline

```
01-06 → 07 + 08 + [09 ANALYSE RISQUES] + 10 + 11 + 12 + 13 → 14 → 15+16
                    ^^^ TU ES ICI (parallelisable avec 07-08, 10-13)
```

- **Input** : `./pipeline/06_dataset_final.xlsx` + `./pipeline/07_analyse_financiere.json` + `./pipeline/08_analyse_agronomique.json`
- **Output** : `./pipeline/09_analyse_risques.json`

## Cartographie complete des risques

### RISQUE 1 — Liquidite et tresorerie

**Objectif** : evaluer la capacite de l'exploitation a faire face a ses engagements a court terme.

| Indicateur | Formule | Source | Seuils |
|---|---|---|---|
| Point mort tresorerie | Charges fixes incompressibles mensuelles | Charges structure / 12 | |
| Coussin de securite | Disponibilites / Charges fixes mensuelles | Bilan + CR | < 1 mois = CRITIQUE |
| Variation tresorerie | Tresorerie N vs N-1 vs N-2 | Bilan | 3 baisses consecutives = ELEVE |
| Liquidite generale | Actif circulant / Dettes CT | Skill 07 ratio L1 | < 1.0 = CRITIQUE |
| BFR en jours de CA | (BFR / CA) x 360 | Skill 07 ratio L4 | > 120 jours = ELEVE |

**Charges fixes incompressibles a identifier** :
- Fermages et loyers fonciers (non negociables a CT)
- Annuites de remboursement (engagement contractuel)
- Cotisations MSA exploitant (obligatoire)
- Assurances (engagement annuel)
- Charges de personnel permanent (engagement contractuel)
- Impots fonciers (non differables)

**Scoring** :
| Situation | Score |
|---|---|
| Tresorerie > 3 mois charges fixes + tendance stable/hausse | FAIBLE (1) |
| Tresorerie 1-3 mois + tendance stable | MODERE (2) |
| Tresorerie 1-3 mois + tendance baisse | ELEVE (3) |
| Tresorerie < 1 mois | CRITIQUE (4) |

### RISQUE 2 — Endettement et solvabilite

**Objectif** : evaluer la soutenabilite de la dette et la capacite a y faire face dans la duree.

| Indicateur | Source | Seuils critiques |
|---|---|---|
| Dettes financieres / EBE | Skill 07 S4 | > 7 ans = ELEVE, > 10 ans = CRITIQUE |
| Annuites / EBE | Skill 07 A7 | > 50% = ELEVE, > 65% = CRITIQUE |
| Couverture annuites (CAF/Annuites) | Skill 07 S5 | < 1.2 = ELEVE, < 1.0 = CRITIQUE |
| Endettement global (Dettes/FP) | Skill 07 S2 | > 200% = ELEVE, > 300% = CRITIQUE |
| Sensibilite CAF -20% | Si CAF baisse de 20%, ratio annuites/CAF | Calculer le seuil de rupture |

**Analyse complementaire** :
- Echeancier de la dette (si disponible via liasse 2057) : identifier les pics de remboursement
- Nature de la dette : bancaire LT vs CT vs comptes courants associes
- Garanties mentionnees dans les documents (hypotheques, cautions)
- Capacite de refinancement : la banque accepterait-elle de restructurer ?

**Scoring** :
| Situation | Score |
|---|---|
| Dettes/EBE < 5 + Couverture > 1.5 + tendance stable | FAIBLE (1) |
| Dettes/EBE 5-7 + Couverture 1.2-1.5 | MODERE (2) |
| Dettes/EBE 7-10 + Couverture 1.0-1.2 | ELEVE (3) |
| Dettes/EBE > 10 OU Couverture < 1.0 | CRITIQUE (4) |

### RISQUE 3 — Dependance aux subventions PAC

**Objectif** : mesurer la vulnerabilite de l'exploitation a une reforme ou reduction des aides.

| Indicateur | Formule | Source |
|---|---|---|
| Part PAC dans EBE | Subventions / EBE | Skill 07 A1 |
| Part PAC dans resultat net | Subventions / RN | Calcul |
| EBE hors PAC | EBE - Subventions | Skill 07 A2 |
| RN hors PAC | RN - Subventions | Skill 07 A3 |
| Marge de securite PAC | (RN hors PAC > 0) ? OUI : NON | Calcul |

**Analyse de decomposition** :
- Quelle part des aides est liee aux DPB (plus stable) vs aides couplees (plus volatiles) ?
- L'eco-regime est-il conditionnel a des pratiques specifiques ?
- Les MAEC arrivent-elles a echeance prochainement ?

**Scoring** :
| Part PAC / EBE | Score |
|---|---|
| < 20% | FAIBLE (1) |
| 20-40% | MODERE (2) |
| 40-60% | ELEVE (3) |
| > 60% ou RN hors PAC < 0 | EXISTENTIEL (4) — l'exploitation n'est pas viable sans PAC |

### RISQUE 4 — Concentration (productions et marches)

**Objectif** : evaluer la vulnerabilite a un choc sectoriel specifique.

| Indicateur | Source | Calcul |
|---|---|---|
| Part de la 1ere culture dans le CA | Assolement + CA ventile | Si > 60% = ELEVE |
| Indice de diversification (Herfindahl) | Surfaces par culture | HHI = Somme(part_i^2) |
| Dependance a un type de marche | Analyse CA | Cereales vs oleagineux vs elevage |

**Indice de Herfindahl-Hirschman (HHI)** :
```
HHI = Somme de (part de chaque culture dans la SAU)^2
HHI = 1 → monoculture totale (risque maximal)
HHI < 0.25 → bonne diversification
HHI 0.25-0.50 → diversification moderee
HHI > 0.50 → forte concentration
```

**Scoring** :
| HHI | Score |
|---|---|
| < 0.25 | FAIBLE (1) |
| 0.25-0.40 | MODERE (2) |
| 0.40-0.60 | ELEVE (3) |
| > 0.60 | CRITIQUE (4) |

### RISQUE 5 — Taux d'interet

**Objectif** : mesurer la sensibilite au risque de taux.

| Indicateur | Source | Calcul |
|---|---|---|
| Part dette a taux variable | Onglet DETTES si disponible | Variable / Total |
| Cout moyen actuel de la dette | Skill 07 P1 | Charges fin. / Dettes fin. moyennes |
| Impact hausse +200bp | Calcul | Dette variable x 2% supplementaire |
| Impact hausse +200bp sur resultat net | Calcul | Charges fin. additionelles / RN |

Si l'information sur la nature des taux n'est pas dans les documents :
- Hypothese conservative : 50% de la dette a taux variable
- Marquer comme "HYPOTHESE — nature des taux non documentee"

**Scoring** :
| Part variable × Impact | Score |
|---|---|
| Impact +200bp < 5% du RN | FAIBLE (1) |
| Impact +200bp 5-15% du RN | MODERE (2) |
| Impact +200bp 15-30% du RN | ELEVE (3) |
| Impact +200bp > 30% du RN ou bascule en perte | CRITIQUE (4) |

### RISQUE 6 — Succession et transmission

**Objectif** : evaluer le risque lie au facteur humain et a la perennite.

| Indicateur | Source | Disponibilite |
|---|---|---|
| Age de l'exploitant | Documents MSA, statuts | Souvent non disponible |
| Forme juridique | Skill 01 | Disponible |
| Nombre d'associes | Statuts, MSA | Parfois disponible |
| Fonds propres disponibles | Bilan | Disponible |

**Analyse** :
- Forme juridique adaptee a la transmission ? (EARL = transmissible, individuel = plus complexe)
- Niveau de fonds propres : permet-il une transmission sans decote majeure ?
- Existe-t-il un successeur identifie ? (rarement dans les documents comptables)

Si l'age de l'exploitant est inconnu → scorer INDETERMINE (ne pas deviner)

### RISQUE 7 — Climat et aleas (analyse structurelle)

**Objectif** : evaluer la resilience historique face aux aleas.

| Indicateur | Source | Calcul |
|---|---|---|
| Volatilite du CA | Historique CA | Ecart-type / Moyenne |
| Volatilite de l'EBE | Historique EBE | Ecart-type / Moyenne |
| Pire annee vs moyenne | Min(EBE) / Moyenne(EBE) | Ratio de chute maximale |
| Assurance recolte | Poste 6161 | Present / Absent |
| DEP/DPA constitue | Bilan | Reserve de precaution disponible |

## Matrice de risque finale

Pour chaque risque :

| Risque | Probabilite (1-5) | Impact (1-5) | Score (P×I) | Niveau |
|---|---|---|---|---|
| 1. Liquidite | ... | ... | ... | ... |
| 2. Endettement | ... | ... | ... | ... |
| 3. Dependance PAC | ... | ... | ... | ... |
| 4. Concentration | ... | ... | ... | ... |
| 5. Taux d'interet | ... | ... | ... | ... |
| 6. Succession | ... | ... | ... | ... |
| 7. Climat/aleas | ... | ... | ... | ... |

**Grille de lecture** :

| Score | Niveau | Code |
|---|---|---|
| 1-4 | FAIBLE | Vert |
| 5-9 | MODERE | Jaune |
| 10-15 | ELEVE | Orange |
| 16-25 | CRITIQUE | Rouge |

**Regles de scoring** :
- Probabilite : basee sur les indicateurs quantitatifs mesures
- Impact : base sur les consequences financieres si le risque se materialise
- Le scoring doit etre justifie : chaque note P et I doit citer l'indicateur qui la fonde
- Un risque INDETERMINE (donnees manquantes) n'est PAS score a 0 → il est marque INDETERMINE

## Schema de sortie

Ecrire dans `./pipeline/09_analyse_risques.json` :

```json
{
  "skill_id": "09_analyse_risques",
  "timestamp": "[ISO 8601]",
  "statut": "OK | AVERTISSEMENT",
  "risques": {
    "liquidite": {
      "indicateurs": {},
      "scoring": {"probabilite": 0, "impact": 0, "score": 0, "niveau": "..."},
      "justification_p": "...",
      "justification_i": "...",
      "detail": "..."
    },
    "endettement": {},
    "dependance_pac": {},
    "concentration": {},
    "taux_interet": {},
    "succession": {},
    "climat_aleas": {}
  },
  "matrice_risque": {
    "synthese": [
      {"risque": "...", "p": 0, "i": 0, "score": 0, "niveau": "..."}
    ],
    "score_global": 0,
    "nb_critiques": 0,
    "nb_eleves": 0,
    "nb_moderes": 0,
    "nb_faibles": 0,
    "nb_indetermines": 0
  },
  "points_rupture": [
    {
      "scenario": "Baisse de CA de X%",
      "seuil": "-25%",
      "consequence": "Tresorerie negative, incapacite a servir les annuites",
      "source": "CAF actuelle X EUR, annuites Y EUR, marge Z EUR"
    }
  ],
  "anomalies": [],
  "sources": {},
  "metriques": {
    "nb_valeurs_traitees": 0,
    "nb_valeurs_certifiees": 0,
    "nb_risques_evalues": 0,
    "nb_risques_indetermines": 0,
    "nb_anomalies": 0,
    "duree_execution_sec": 0
  }
}
```

## Checklist de sortie

- [ ] Les 7 risques sont evalues (ou marques INDETERMINE si donnees manquantes)
- [ ] Chaque scoring est justifie par un indicateur chiffre
- [ ] La matrice de risque est complete avec P × I
- [ ] Les points de rupture sont identifies et quantifies
- [ ] Les risques INDETERMINES ne sont pas scores a 0
- [ ] Aucune donnee n'a ete inventee

$ARGUMENTS
