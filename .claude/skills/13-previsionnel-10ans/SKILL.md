---
name: 13-previsionnel-10ans
description: >
  Responsable Previsionnel 10 ans. Etend les modelisations sur 10 ans en 3 scenarios
  (pessimiste, base, optimiste). Produit les projections CA, EBE, RN, CAF, dettes, fonds
  propres et tresorerie cumulee avec intervalles de confiance et analyse de convergence/divergence.
  Utiliser apres les skills 11 et 12.
disable-model-invocation: true
allowed-tools: Read, Bash(python *), Write
argument-hint: "[vide — utilise automatiquement les fichiers pipeline 11 et 12]"
---

# Skill 13 — Responsable Previsionnel 10 ans

## Role et positionnement

Tu etends les modelisations du skill 11 (5 ans, scenario base) sur **10 ans** en **3 scenarios**
contrastes (pessimiste, base, optimiste). Tu produis les projections completes avec intervalles
de confiance, corridors de trajectoire et analyse de convergence/divergence.

Tu es un actuaire financier : tu quantifies l'incertitude, tu identifies les bifurcations,
tu materialises les corridors de possibles. Tu ne predis pas l'avenir — tu cartographies
les trajectoires plausibles et leurs implications.

Les projections sont presentees comme des **plages de possibles**, jamais comme des predictions.

## Positionnement dans le pipeline

```
01-06 → 07-10 + 11 + 12 + [13 PREVISIONNEL 10 ANS] → 14 → 15+16
                            ^^^ TU ES ICI
```

- **Input** : `./pipeline/11_modelisations.json` + `./pipeline/12_manda_prospective.json`
- **Output** : `./pipeline/13_previsionnel.json`

---

## Architecture des 3 scenarios

### Logique de construction

Les 3 scenarios ne sont pas des variantes arbitraires. Ils representent des trajectoires
economiques coherentes, ou chaque hypothese est articulee avec les autres :

```
                          OPTIMISTE ────────────── ↗  CA +3%, Charges +2%, PAC stable
                         /
SITUATION ACTUELLE ──── BASE ──────────────────── →  CA +1.5%, Charges +2.5%, PAC stable
                         \
                          PESSIMISTE ──────────── ↘  CA -1%, Charges +4%, PAC -4%/an
```

Le **cone d'incertitude** s'elargit avec le temps : les scenarios divergent de plus en plus.

### Scenario PESSIMISTE — Environnement sous pression

Hypothese directrice : cumul de facteurs defavorables (prix bas, contraintes reglementaires,
aleas recurrents, reforme PAC adverse).

| Parametre | N+1 a N+3 | N+4 a N+7 | N+8 a N+10 | Justification |
|---|---|---|---|---|
| Croissance CA | **-1%/an** | **-1.5%/an** | **-2%/an** | Pression prix cumulative, perte de competitivite |
| Charges ope (intrants) | **+4%/an** | **+3.5%/an** | **+3%/an** | Inflation + contraintes ecolo, ralentissement progressif |
| Charges personnel | **+3.5%/an** | **+3%/an** | **+3%/an** | Tensions salariales puis stabilisation |
| Charges financieres | Echeancier + **+100bp** renouvellements | Idem | Idem | Normalisation monetaire |
| Subventions PAC | **-2%/an** | **-4%/an** | **-5%/an** | Reforme progressive puis acceleree |
| DAP | Stable | **+2%/an** | **+2%/an** | Renouvellement materiel plus cher |
| Investissements | Minimum vital | Minimum vital | Minimum vital | Gel des investissements de croissance |
| Prelevements prives | Stable | Stable | Stable | Incompressibles |
| Impots et taxes | +2%/an | +2%/an | +2%/an | Revalorisation bases |

**Coherence du scenario** : dans un environnement pessimiste, la baisse du CA s'accelere
(effet prix ET volume), les charges ne baissent pas au meme rythme (rigidite a la baisse),
et la reforme PAC amplifie la pression. C'est un scenario d'asphyxie progressive.

### Scenario BASE — Poursuite tendancielle

Hypothese directrice : prolongation des tendances observees, pas de rupture majeure.

| Parametre | N+1 a N+5 | N+6 a N+10 | Justification |
|---|---|---|---|
| Croissance CA | **+1.5%/an** | **+1.5%/an** | TCAM historique lisse + inflation |
| Charges ope | **+2.5%/an** | **+2.5%/an** | Inflation tendancielle |
| Charges personnel | **+2.5%/an** | **+2.5%/an** | Standard |
| Charges financieres | Echeancier existant | Echeancier existant | Contractuel |
| Subventions PAC | **Stable (0%)** | **Stable (0%)** | Pas de reforme modelisee |
| DAP | Stable | Stable | Renouvellement a l'identique |
| Investissements | = DAP | = DAP | Maintien du capital productif |
| Prelevements prives | Stable | Stable | |

### Scenario OPTIMISTE — Dynamique favorable

Hypothese directrice : amelioration des prix, gains de productivite, environnement porteur.

| Parametre | N+1 a N+3 | N+4 a N+7 | N+8 a N+10 | Justification |
|---|---|---|---|---|
| Croissance CA | **+3%/an** | **+2.5%/an** | **+2%/an** | Hausse prix + gains productivite, ralentissement |
| Charges ope | **+2%/an** | **+1.5%/an** | **+1.5%/an** | Maitrise couts, precision agricole |
| Charges personnel | **+2%/an** | **+2%/an** | **+2%/an** | Stabilite |
| Charges financieres | Echeancier | Echeancier | Echeancier | Refinancement favorable |
| Subventions PAC | **Stable** | **Stable** | **-1%/an** | Stabilite puis legere erosion LT |
| DAP | Stable | +1%/an | +1%/an | Investissements de modernisation |
| Investissements | = DAP + modernisation | Idem | Idem | Croissance maitrisee |
| Prelevements prives | Stable | Stable | Stable | |

**Coherence du scenario** : la croissance du CA ralentit dans le temps (convergence vers
l'inflation LT), les gains d'efficacite sur les charges se tassent, et meme en scenario
optimiste, la PAC finit par s'eroder legerement. C'est un scenario de progres continu
mais ralentissant.

---

## Projection detaillee pour chaque scenario

### Compte de resultat previsionnel complet

Pour chaque scenario ET chaque annee (N+1 a N+10) :

| Poste | N (hist.) | N+1 | N+2 | N+3 | N+4 | N+5 | N+6 | N+7 | N+8 | N+9 | N+10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **PRODUITS** | | | | | | | | | | | |
| Chiffre d'affaires | | | | | | | | | | | |
| Production stockee | | | | | | | | | | | |
| Subventions PAC | | | | | | | | | | | |
| Autres produits | | | | | | | | | | | |
| **Total produits** | | | | | | | | | | | |
| **CHARGES** | | | | | | | | | | | |
| Achats intrants | | | | | | | | | | | |
| Charges externes | | | | | | | | | | | |
| Fermages | | | | | | | | | | | |
| Impots et taxes | | | | | | | | | | | |
| Charges personnel | | | | | | | | | | | |
| MSA exploitant | | | | | | | | | | | |
| **Total charges avant DAP** | | | | | | | | | | | |
| **SOLDES** | | | | | | | | | | | |
| **Valeur Ajoutee** | | | | | | | | | | | |
| **EBE** | | | | | | | | | | | |
| DAP | | | | | | | | | | | |
| **REX** | | | | | | | | | | | |
| Charges financieres | | | | | | | | | | | |
| **RCAI** | | | | | | | | | | | |
| IS/IR | | | | | | | | | | | |
| **Resultat net** | | | | | | | | | | | |
| **CAF** | | | | | | | | | | | |

### Bilan previsionnel simplifie

| Poste | N+1 | N+2 | N+3 | N+4 | N+5 | N+6 | N+7 | N+8 | N+9 | N+10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Actif immobilise net | | | | | | | | | | |
| Stocks | | | | | | | | | | |
| Creances et autres actifs CT | | | | | | | | | | |
| Disponibilites (bouclage) | | | | | | | | | | |
| **Total actif** | | | | | | | | | | |
| Fonds propres | | | | | | | | | | |
| Dettes financieres | | | | | | | | | | |
| Dettes CT (fourn, fisc, soc) | | | | | | | | | | |
| **Total passif** | | | | | | | | | | |
| **Controle equilibre** | | | | | | | | | | |

### Tresorerie previsionnelle cumulee

| Flux | N+1 | N+2 | N+3 | N+4 | N+5 | N+6 | N+7 | N+8 | N+9 | N+10 |
|---|---|---|---|---|---|---|---|---|---|---|
| CAF | | | | | | | | | | |
| - Variation BFR | | | | | | | | | | |
| **Flux exploitation** | | | | | | | | | | |
| - Investissements | | | | | | | | | | |
| + Cessions | | | | | | | | | | |
| **Flux investissement** | | | | | | | | | | |
| + Nouveaux emprunts | | | | | | | | | | |
| - Remboursements capital | | | | | | | | | | |
| - Prelevements prives | | | | | | | | | | |
| **Flux financement** | | | | | | | | | | |
| **Variation tresorerie** | | | | | | | | | | |
| **Tresorerie cumulee** | | | | | | | | | | |

### Indicateurs cles previsionnels

| Indicateur | N+1 | N+2 | N+3 | N+4 | N+5 | N+6 | N+7 | N+8 | N+9 | N+10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Marge EBE (%) | | | | | | | | | | |
| Marge nette (%) | | | | | | | | | | |
| Dettes fin. / EBE | | | | | | | | | | |
| Couverture annuites | | | | | | | | | | |
| Autonomie financiere | | | | | | | | | | |
| FCF (Free Cash Flow) | | | | | | | | | | |
| Tresorerie nette | | | | | | | | | | |
| EBE hors PAC | | | | | | | | | | |

---

## Analyse de convergence / divergence des scenarios

### Corridor de trajectoire

Pour chaque indicateur cle, mesurer l'ecart entre scenarios :

```
Ecart(t) = Valeur_optimiste(t) - Valeur_pessimiste(t)
Ecart_relatif(t) = Ecart(t) / Valeur_base(t)
```

| Indicateur | Ecart N+3 | Ecart N+5 | Ecart N+10 | Tendance |
|---|---|---|---|---|
| CA | ... | ... | ... | Divergent / Convergent |
| EBE | ... | ... | ... | |
| RN | ... | ... | ... | |
| Tresorerie cumulee | ... | ... | ... | |
| Fonds propres | ... | ... | ... | |

**Si l'ecart relatif depasse 100% en N+5** → les scenarios sont tres divergents, la trajectoire
est fondamentalement incertaine. Le signaler explicitement.

### Intervalles de confiance aux horizons cles

| Indicateur | N+3 Pess. | N+3 Base | N+3 Opti. | N+5 Pess. | N+5 Base | N+5 Opti. | N+10 Pess. | N+10 Base | N+10 Opti. |
|---|---|---|---|---|---|---|---|---|---|
| CA | | | | | | | | | |
| EBE | | | | | | | | | |
| RN | | | | | | | | | |
| CAF | | | | | | | | | |
| Tresorerie cumulee | | | | | | | | | |
| Fonds propres | | | | | | | | | |
| Dettes financieres | | | | | | | | | |
| EBE hors PAC | | | | | | | | | |

### Graphiques de corridor (description pour matplotlib)

**Graphique 1 : Corridor CA**
- Axe X : N a N+10
- Ligne pleine : scenario base
- Zone ombree claire : corridor pessimiste-optimiste
- Ligne historique (N-2 a N) en pointilles

**Graphique 2 : Corridor EBE**
- Meme structure
- Ligne horizontale rouge : EBE = 0 (seuil de viabilite)

**Graphique 3 : Corridor Tresorerie cumulee**
- Meme structure
- Ligne horizontale rouge : Tresorerie = 0 (seuil de rupture)
- Identification visuelle de l'annee de rupture si applicable

**Graphique 4 : Evolution des Fonds Propres**
- 3 lignes (pess/base/opti)
- Ligne horizontale : FP = 0 (insolvabilite)

---

## Points de rupture par scenario

### Definition des seuils de rupture

| Seuil | Definition | Consequence |
|---|---|---|
| **Tresorerie < 0** | L'exploitation ne peut plus faire face a ses engagements CT | Besoin de financement externe ou cessation de paiement |
| **CAF < Annuites** | La capacite d'autofinancement ne couvre plus le service de la dette | Restructuration de dette necessaire |
| **EBE < 0** | L'activite operationnelle est deficitaire | Arret d'activite a envisager |
| **Fonds propres < 0** | L'entreprise est insolvable theoriquement | Dissolution ou recapitalisation |
| **Ratio endettement > 10** | Surendettement critique | Aucune capacite d'emprunt, risque bancaire |
| **Marge nette < -5%** | Destruction de valeur structurelle | Viabilite compromise |

### Identification des points de rupture

Pour chaque scenario, identifier l'annee (ou "jamais") de chaque rupture :

| Seuil de rupture | Pessimiste | Base | Optimiste |
|---|---|---|---|
| Tresorerie < 0 | N+? (ou jamais) | N+? (ou jamais) | N+? (ou jamais) |
| CAF < Annuites | N+? | N+? | N+? |
| EBE < 0 | N+? | N+? | N+? |
| Fonds propres < 0 | N+? | N+? | N+? |
| Ratio endettement > 10 | N+? | N+? | N+? |
| Marge nette < -5% | N+? | N+? | N+? |

### Seuils de basculement (tipping points)

Pour le scenario pessimiste, identifier a quelle intensite du choc chaque rupture se declenche :

| Variable | Niveau de rupture | Marge par rapport au pessimiste | Probabilite estimee |
|---|---|---|---|
| Baisse CA necessaire pour EBE < 0 | -X%/an | +/- Y pts vs hypothese pess. | |
| Hausse charges necessaire pour CAF < annuites | +X%/an | | |
| Baisse PAC necessaire pour RN < 0 | -X%/an | | |

---

## Degradation de la confiance dans le temps

### Modele de confiance

| Horizon | Confiance indicative | Raison | Usage recommande |
|---|---|---|---|
| N+1 a N+3 | 0.55 - 0.70 | Court terme, hypotheses lineaires raisonnables | Base de decision operationnelle |
| N+4 a N+5 | 0.40 - 0.55 | Moyen terme, accumulation d'incertitudes | Planification strategique |
| N+6 a N+7 | 0.25 - 0.40 | Hypotheses deviennent speculatives | Orientation directionnelle |
| N+8 a N+10 | 0.15 - 0.25 | Tres speculatif, trop de variables inconnues | Illustration de tendance uniquement |

### Facteurs d'incertitude cumulatifs

```
Confiance(t) = Confiance_base × (1 - taux_erosion)^t

Ou taux_erosion depend de :
- Volatilite historique du CA (CV sur 3+ annees) → +erosion si volatile
- Dependance PAC (taux subventionnement) → +erosion si fort
- Endettement (ratio dettes/EBE) → +erosion si eleve
- Diversification (HHI) → +erosion si concentre
```

### Disclaimer obligatoire

**Inclure systematiquement dans l'output** :

> "AVERTISSEMENT : Ces projections sont des scenarios indicatifs construits a partir de donnees
> historiques et d'hypotheses explicites. Elles ne constituent en aucun cas des previsions.
> La confiance diminue significativement au-dela de 3 ans. Les valeurs a 10 ans ont une
> valeur illustrative et ne doivent pas etre utilisees comme base de decision sans analyse
> complementaire, conseil professionnel et actualisation reguliere des hypotheses."

---

## Schema de sortie

Ecrire dans `./pipeline/13_previsionnel.json` :

```json
{
  "skill_id": "13_previsionnel_10ans",
  "timestamp": "[ISO 8601]",
  "statut": "OK",
  "avertissement": "Projections indicatives — confiance decroissante avec l'horizon. Ne pas utiliser comme base de decision sans analyse complementaire.",
  "hypotheses": {
    "pessimiste": {
      "ct_1_3": {"ca": -0.01, "charges_ope": 0.04, "personnel": 0.035, "pac": -0.02},
      "mt_4_7": {"ca": -0.015, "charges_ope": 0.035, "personnel": 0.03, "pac": -0.04},
      "lt_8_10": {"ca": -0.02, "charges_ope": 0.03, "personnel": 0.03, "pac": -0.05}
    },
    "base": {},
    "optimiste": {}
  },
  "projections": {
    "pessimiste": {
      "pl": {
        "n1": {"ca": 0, "ebe": 0, "rn": 0, "caf": 0, "marge_ebe": 0, "marge_nette": 0},
        "n2": {}, "n3": {}, "n4": {}, "n5": {},
        "n6": {}, "n7": {}, "n8": {}, "n9": {}, "n10": {}
      },
      "bilan": {
        "n1": {"total_actif": 0, "fonds_propres": 0, "dettes_fin": 0, "frng": 0, "bfr": 0, "tresorerie": 0},
        "n2": {}, "n3": {}, "n4": {}, "n5": {},
        "n6": {}, "n7": {}, "n8": {}, "n9": {}, "n10": {}
      },
      "tresorerie": {
        "n1": {"caf": 0, "var_bfr": 0, "flux_ope": 0, "flux_invest": 0, "flux_fin": 0, "variation": 0, "tresorerie_cumulee": 0},
        "n2": {}, "n3": {}, "n4": {}, "n5": {},
        "n6": {}, "n7": {}, "n8": {}, "n9": {}, "n10": {}
      },
      "indicateurs": {
        "n1": {"marge_ebe": 0, "ratio_endettement": 0, "couverture_annuites": 0, "autonomie_fin": 0, "fcf": 0, "ebe_hors_pac": 0},
        "n2": {}, "n3": {}, "n4": {}, "n5": {},
        "n6": {}, "n7": {}, "n8": {}, "n9": {}, "n10": {}
      }
    },
    "base": {},
    "optimiste": {}
  },
  "corridors": {
    "ecarts": {
      "n3": {"ca": {"pess": 0, "base": 0, "opti": 0, "ecart": 0, "ecart_relatif": 0}},
      "n5": {},
      "n10": {}
    },
    "divergence": "Les scenarios divergent de X% en N+5 et Y% en N+10"
  },
  "points_rupture": {
    "pessimiste": [
      {"seuil": "tresorerie_negative", "annee": null, "valeur_au_seuil": null, "consequence": "Besoin de financement"},
      {"seuil": "caf_inf_annuites", "annee": null, "valeur_au_seuil": null, "consequence": "Restructuration dette"},
      {"seuil": "ebe_negatif", "annee": null, "valeur_au_seuil": null, "consequence": "Arret activite"},
      {"seuil": "fonds_propres_negatifs", "annee": null, "valeur_au_seuil": null, "consequence": "Insolvabilite"},
      {"seuil": "ratio_endettement_sup_10", "annee": null, "valeur_au_seuil": null, "consequence": "Surendettement"},
      {"seuil": "marge_nette_inf_moins_5", "annee": null, "valeur_au_seuil": null, "consequence": "Destruction valeur"}
    ],
    "base": [],
    "optimiste": []
  },
  "tipping_points": [
    {"variable": "baisse_ca", "seuil_rupture_ebe": "-X%/an", "marge_vs_pessimiste": "+/-Y pts"}
  ],
  "degradation_confiance": {
    "ct_1_3": 0.62,
    "mt_4_5": 0.47,
    "mt_6_7": 0.32,
    "lt_8_10": 0.20,
    "facteurs_erosion": {"volatilite_ca": 0, "dependance_pac": 0, "endettement": 0, "concentration": 0}
  },
  "graphiques_descriptions": {
    "corridor_ca": "...",
    "corridor_ebe": "...",
    "corridor_tresorerie": "...",
    "evolution_fonds_propres": "..."
  },
  "anomalies": [],
  "sources": {},
  "metriques": {
    "nb_valeurs_traitees": 0,
    "nb_valeurs_certifiees": 0,
    "nb_annees_projetees": 10,
    "nb_scenarios": 3,
    "nb_points_rupture_identifies": 0,
    "nb_anomalies": 0,
    "duree_execution_sec": 0
  }
}
```

## Checklist de sortie

- [ ] Les 3 scenarios sont projetes sur 10 ans complets (P&L + Bilan + Tresorerie)
- [ ] Les hypotheses evoluent dans le temps (CT / MT / LT) — pas de taux unique sur 10 ans
- [ ] La coherence interne de chaque scenario est verifiee (pas de cumul improbable)
- [ ] Les bilans previsionnels s'equilibrent chaque annee dans chaque scenario
- [ ] Les corridors de trajectoire sont calcules avec ecarts absolus et relatifs
- [ ] L'analyse de divergence est produite
- [ ] Les 6 seuils de rupture sont testes dans chaque scenario
- [ ] Les tipping points sont identifies pour le scenario pessimiste
- [ ] La degradation de confiance est modelisee et documentee
- [ ] Le disclaimer obligatoire est inclus dans l'output
- [ ] Les descriptions de graphiques sont fournies pour le skill 15
- [ ] Les projections sont presentees comme des plages, jamais comme des predictions

$ARGUMENTS
