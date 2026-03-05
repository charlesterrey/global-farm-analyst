# Global Farm Analyst — Regles Globales du Systeme

Ce projet est un **systeme de pipeline sequentiel a 16 skills** pour l'analyse financiere et agronomique d'exploitations agricoles a partir de documents comptables PDF.

## Architecture du pipeline

```
LAYER 1 — Extraction & Audit     : 01 → 02 → 03 → 04
LAYER 2 — Database                :           05 → 06
LAYER 3 — Analyses (parallelisables) : 07 + 08 + 09 + 10 + 11 + 12 + 13
LAYER 4 — Validation              :           14
LAYER 5 — Rendus finaux           :       15 + 16
```

Les skills 07 a 13 lisent le dataset verrouille (skill 06) en LECTURE SEULE.
Les skills 15 et 16 sont conditionnes au GO du skill 14.

## Regle 1 — Anti-hallucination absolue

C'est la regle fondatrice de tout le systeme. Aucune exception.

Chaque valeur chiffree produite DOIT etre accompagnee de :
- `source_doc` : nom exact du fichier PDF source
- `source_page` : numero de page dans le PDF
- `verbatim` : extrait textuel exact tel qu'il apparait dans le document
- `confiance` : score entre 0.0 et 1.0

Si une valeur ne peut pas etre tracee a une source :
- Ecrire `null` + champ `raison` expliquant pourquoi
- JAMAIS inventer, estimer sans le declarer, ni arrondir silencieusement

Une valeur supprimee par l'audit legal (skill 04) ne reapparait JAMAIS dans le pipeline.

## Regle 2 — Format des outputs inter-skills

Chaque skill ecrit son output dans `./pipeline/[NN]_[nom].json`.

Structure JSON obligatoire :
```json
{
  "skill_id": "NN_nom_du_skill",
  "timestamp": "ISO 8601",
  "statut": "OK | BLOQUANT | AVERTISSEMENT",
  "donnees": {},
  "anomalies": [
    {
      "code": "ANO_XXX",
      "severite": "ROUGE | ORANGE | VERT",
      "description": "...",
      "localisation": "doc/page ou champ concerne",
      "action_requise": "..."
    }
  ],
  "sources": {
    "nom_du_champ": {
      "source_doc": "fichier.pdf",
      "source_page": 3,
      "verbatim": "texte exact",
      "confiance": 0.97
    }
  },
  "metriques": {
    "nb_valeurs_traitees": 0,
    "nb_valeurs_certifiees": 0,
    "nb_anomalies": 0,
    "duree_execution_sec": 0
  }
}
```

## Regle 3 — Blocage pipeline

Si `statut` = `"BLOQUANT"` dans un output :
1. Le skill suivant NE PEUT PAS s'executer
2. Claude Code affiche clairement : le skill bloquant, la liste des anomalies ROUGE, et l'action corrective attendue
3. Le pipeline attend une correction humaine avant de reprendre

Un statut `"AVERTISSEMENT"` permet de continuer mais les anomalies ORANGE sont reportees dans tous les skills suivants.

## Regle 4 — Aucune inference non declaree

Si Claude doit interpoler, estimer ou deduire une valeur manquante :
- Le declarer explicitement avec `confiance` < 0.7
- Ajouter le flag `"ESTIME"` dans les metadonnees de la valeur
- Mentionner `"ESTIME — non source directement, methode : [description]"`
- Ne jamais presenter une estimation comme un fait

## Regle 5 — Integrite du dataset

A partir du skill 06, le dataset Excel est VERROUILLE :
- Les skills 07 a 16 accedent aux donnees en LECTURE SEULE
- Aucun skill d'analyse ne peut modifier les donnees sources
- Toute nouvelle valeur calculee est stockee dans l'output du skill, pas dans le dataset

## Regle 6 — Normes comptables de reference

Le systeme applique les normes comptables agricoles francaises :
- **PCG** (Plan Comptable General) pour les principes fondamentaux
- **ANC** (Autorite des Normes Comptables) pour les reglements specifiques
- **Liasses fiscales** 2050 a 2059 pour la structure des etats financiers
- **RICA** (Reseau d'Information Comptable Agricole) pour les benchmarks sectoriels
- **OTEX** (Orientation Technico-Economique des eXploitations) pour la classification

## Regle 7 — Confidentialite

Les donnees traitees sont strictement confidentielles :
- Le repertoire `./inputs/` contient des documents comptables originaux
- Le repertoire `./outputs/` contient des analyses nominatives
- Ces repertoires ne sont JAMAIS commites dans git (cf. `.gitignore`)

## Librairies Python autorisees

```
pdfplumber, PyMuPDF, camelot-py  — extraction PDF
openpyxl                          — generation Excel
python-docx                       — generation Word
matplotlib                        — graphiques
pandas, numpy                     — traitement donnees
pydantic                          — validation schemas
```

## Convention de nommage

- Skills : `NN-nom-du-skill` (kebab-case, prefixe numerique)
- Fichiers pipeline : `NN_nom_du_fichier.json` (snake_case, prefixe numerique)
- Champs JSON : `snake_case`
- Pas d'accents dans les noms de fichiers et cles JSON
