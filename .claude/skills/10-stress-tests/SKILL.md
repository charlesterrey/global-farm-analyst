---
name: 10-stress-tests
description: >
  Stress Tests. Execute 6 scenarios de stress sur les donnees financieres historiques pour
  tester la resilience de l'exploitation. Couvre alea climatique, crise prix, hausse taux,
  reforme PAC, scenario combine et hausse charges sociales. Projection sur 3 ans par scenario.
  Utiliser apres les skills 07 et 08.
disable-model-invocation: true
allowed-tools: Read, Bash(python *), Write
argument-hint: "[vide — utilise automatiquement les fichiers pipeline 06 et 07]"
---

# Skill 10 — Stress Tests

## Role et positionnement

Tu executes **6 scenarios de stress** sur les donnees financieres historiques pour tester
la resilience de l'exploitation agricole. Chaque scenario simule un choc specifique
et mesure ses consequences sur 3 ans (N+1, N+2, N+3).

Tu ne fais pas de recommandation. Tu quantifies les impacts.

## Positionnement dans le pipeline

```
01-06 → 07 + 08 + 09 + [10 STRESS TESTS] + 11 + 12 + 13 → 14 → 15+16
                          ^^^ TU ES ICI (parallelisable)
```

- **Input** : `./pipeline/06_dataset_final.xlsx` (annee N comme base) + `./pipeline/07_analyse_financiere.json`
- **Output** : `./pipeline/10_stress_tests.json`

## Methodologie generale

### Base de reference

L'annee N = dernier exercice disponible dans le dataset. Tous les chocs sont appliques
a partir de cette base.

### Variables du modele simplifie

Pour chaque scenario, recalculer annee par annee :

```
CA_stress = CA_base × facteur_CA
Charges_ope_stress = Charges_ope_base × facteur_charges_ope
Charges_personnel_stress = Charges_personnel_base × facteur_personnel
Charges_fin_stress = Charges_fin_base × facteur_taux
Subventions_stress = Subventions_base × facteur_pac
VA_stress = CA_stress - Charges_ope_stress
EBE_stress = VA_stress + Subventions_stress - Charges_personnel_stress - Impots
REX_stress = EBE_stress - DAP (constant)
RN_stress = REX_stress - Charges_fin_stress - IS
CAF_stress = RN_stress + DAP
Tresorerie_stress = Tresorerie_N-1 + CAF_stress - Annuites - Var_BFR
Ratio_endettement_stress = Dettes_fin / EBE_stress
```

### Hypotheses communes a tous les scenarios

| Parametre | Hypothese | Justification |
|---|---|---|
| DAP | Constant (= annee N) | Pas de nouvel investissement en stress |
| Annuites | Constant (= annee N) | Engagement contractuel |
| Variation BFR | Proportionnel a la variation du CA | Hypothese standard |
| IS/IR | Taux constant | Simplification |
| Investissements | 0 | En stress, gel des investissements |
| Dividendes/prelevements | 0 | En stress, pas de distribution |

---

## LES 6 SCENARIOS

### SCENARIO BASE — Evolution tendancielle

| Parametre | N+1 | N+2 | N+3 |
|---|---|---|---|
| CA | Tendance historique (TCAM) | Idem | Idem |
| Charges ope | +3%/an (inflation) | +3% | +3% |
| Charges personnel | +2.5%/an | +2.5% | +2.5% |
| Subventions PAC | Stable (0%) | Stable | Stable |
| Charges financieres | Stable | Stable | Stable |

Ce scenario sert de **reference** pour mesurer l'impact des chocs.

### SCENARIO STRESS 1 — Alea climatique severe

**Choc** : une annee de rendements catastrophiques (secheresse, gel, inondation).

| Parametre | N+1 (annee choc) | N+2 (reprise) | N+3 (retour normal) |
|---|---|---|---|
| CA | **-30%** | -5% (reprise partielle) | Retour base |
| Charges ope | -10% (moins de recolte, mais charges engagees) | Base | Base |
| Variation stocks | -50% du stock de recolte | Reconstitution progressive | Base |
| Assurance recolte | Activation si poste 6161 present (indemnisation ≈ 30% de la perte) | | |

**Impact a calculer** :
- Chute du CA et de l'EBE en N+1
- Tresorerie en fin N+1 : positive ou negative ?
- Capacite a servir les annuites en N+1
- Temps de retour a la situation pre-choc

### SCENARIO STRESS 2 — Crise prix des matieres agricoles

**Choc** : chute des prix de vente + hausse des prix des intrants (scenario type 2014-2016).

| Parametre | N+1 | N+2 | N+3 |
|---|---|---|---|
| CA | **-20%** | -15% | -10% |
| Charges ope (intrants) | **+15%** | +10% | +5% |
| Charges personnel | Stable | Stable | Stable |
| PAC | Stable | Stable | Stable |

**Effet ciseau** : le CA baisse ET les charges augmentent → double pression sur l'EBE.

### SCENARIO STRESS 3 — Hausse des taux d'interet

**Choc** : remontee brutale des taux (+250 points de base).

| Parametre | N+1 | N+2 | N+3 |
|---|---|---|---|
| Charges financieres sur dette variable | **+250bp sur encours variable** | Maintien | Maintien |
| Charges financieres sur dette fixe | Stable | Stable | Stable |
| Nouveaux emprunts (si renouvellement) | +250bp | +250bp | +250bp |

**Calcul** :
```
Si dette variable connue : Surcout = Dette_variable × 2.5%
Si dette variable inconnue : Hypothese 50% variable → Surcout = Dettes_fin × 50% × 2.5%
```

### SCENARIO STRESS 4 — Reforme PAC majeure

**Choc** : reduction significative des aides directes.

| Parametre | N+1 | N+2 | N+3 |
|---|---|---|---|
| DPB | **-15%** | **-25%** | **-35%** |
| Eco-regime | Stable (conditionnel) | Stable | Stable |
| Aides couplees | **-10%** | **-20%** | **-30%** |
| MAEC | Stable | Stable | Stable |

**Reduction progressive** : modelise une reforme s'etalant sur 3 ans.
**Reduction totale en N+3** : environ -35% du montant PAC initial.

### SCENARIO STRESS 5 — Combine (1+2+4) — Crise systemique

**Choc** : cumul des stress climatique, prix et PAC simultanement.

| Parametre | N+1 | N+2 | N+3 |
|---|---|---|---|
| CA | **-30% (climat) -20% (prix) → -44%** | -15% | -5% |
| Charges ope | +15% (prix intrants) -10% (moins de recolte) → +3.5% | +5% | Base |
| PAC | -15% | -25% | -35% |
| Charges fin | Stable | Stable | Stable |

**Note** : les effets ne sont pas simplement additifs. Par exemple, une baisse de rendement
de 30% ET une baisse de prix de 20% donne une baisse de CA de 1-(0.70×0.80) = -44%.

**Ce scenario est le test ultime de resilience.**

### SCENARIO STRESS 6 — Hausse des charges sociales

**Choc** : reforme MSA + hausse des charges salariales.

| Parametre | N+1 | N+2 | N+3 |
|---|---|---|---|
| Cotisations MSA exploitant | **+20%** | +20% | +20% |
| Charges salariales (si salaries) | **+10%** | +10% | +10% |
| Autres charges | Stable | Stable | Stable |

## Resultats a produire pour chaque scenario

Pour chaque scenario ET chaque annee (N+1, N+2, N+3), calculer :

| Indicateur | Formule | Unite |
|---|---|---|
| CA stress | CA_base × facteur | EUR |
| EBE stress | Calcul complet | EUR |
| Variation EBE vs base | (EBE_stress - EBE_base) / EBE_base | % |
| Resultat net stress | Calcul complet | EUR |
| CAF stress | RN_stress + DAP | EUR |
| Tresorerie cumulee | Treso_N-1 + CAF - Annuites | EUR |
| Ratio endettement stress | Dettes_fin / EBE_stress | x |
| Couverture annuites stress | CAF_stress / Annuites | x |
| Point de rupture | Tresorerie < 0 ? Annuites > CAF ? | OUI/NON |

## Analyse de sensibilite croisee

Pour chaque scenario, identifier :
1. **Le point de basculement** : a quelle intensite du choc l'exploitation passe en defaillance ?
   - Ex: "L'exploitation supporte une baisse de CA jusqu'a -18%. Au-dela, la CAF ne couvre plus les annuites."
2. **Le delai de defaillance** : en combien de mois/annees le stress conduit a la rupture de tresorerie ?
3. **La variable la plus sensible** : quel parametre a le plus d'impact sur la resilience ?

## Tableau comparatif de synthese

| Indicateur | Base | S1 Climat | S2 Prix | S3 Taux | S4 PAC | S5 Combine | S6 Social |
|---|---|---|---|---|---|---|---|
| EBE N+1 | ... | ... | ... | ... | ... | ... | ... |
| EBE N+3 | ... | ... | ... | ... | ... | ... | ... |
| RN N+1 | ... | ... | ... | ... | ... | ... | ... |
| Treso N+3 | ... | ... | ... | ... | ... | ... | ... |
| Rupture ? | NON | ? | ? | ? | ? | ? | ? |

## Schema de sortie

Ecrire dans `./pipeline/10_stress_tests.json` :

```json
{
  "skill_id": "10_stress_tests",
  "timestamp": "[ISO 8601]",
  "statut": "OK",
  "base_reference": {
    "exercice": "2023",
    "ca": 0,
    "ebe": 0,
    "rn": 0,
    "caf": 0,
    "tresorerie": 0,
    "annuites": 0,
    "dettes_financieres": 0
  },
  "scenarios": {
    "base": {
      "hypotheses": {},
      "resultats": {"n1": {}, "n2": {}, "n3": {}},
      "point_rupture": null
    },
    "stress_1_climat": {
      "hypotheses": {},
      "resultats": {"n1": {}, "n2": {}, "n3": {}},
      "point_rupture": {"atteint": false, "seuil": "-X%", "delai_mois": null}
    },
    "stress_2_prix": {},
    "stress_3_taux": {},
    "stress_4_pac": {},
    "stress_5_combine": {},
    "stress_6_social": {}
  },
  "sensibilite": {
    "variable_plus_impactante": "...",
    "seuil_defaillance_ca": "-X%",
    "seuil_defaillance_ebe": "X EUR",
    "marge_securite_annuites": "X EUR"
  },
  "tableau_comparatif": {},
  "anomalies": [],
  "sources": {},
  "metriques": {
    "nb_valeurs_traitees": 0,
    "nb_valeurs_certifiees": 0,
    "nb_scenarios_simules": 7,
    "nb_anomalies": 0,
    "duree_execution_sec": 0
  }
}
```

## Checklist de sortie

- [ ] Les 6 scenarios + le scenario base sont simules sur 3 ans
- [ ] Chaque hypothese est explicitement documentee
- [ ] Les points de rupture sont identifies pour chaque scenario
- [ ] Le tableau comparatif de synthese est complet
- [ ] L'analyse de sensibilite identifie la variable la plus impactante
- [ ] Le scenario combine (S5) n'additionne pas simplement les effets
- [ ] Les donnees manquantes utilisent des hypotheses conservatives documentees

$ARGUMENTS
