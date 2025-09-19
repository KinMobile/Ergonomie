# Analyse ergonomique et normes ISO

Ce document détaille les métriques calculées par l'application et leur
alignement avec les normes internationales en ergonomie du travail.

## 1. Données capturées

Pour chaque session de capture :

* Coordonnées spatiales des articulations (Vision/Core ML).
* Vitesses et accélérations angulaires.
* Durée de maintien des postures (statique vs dynamique).
* Nombre de répétitions par articulation (épaule, coude, poignet, cou, tronc,
  hanche, genou).
* Métadonnées : tâche observée, durée totale, opérateur, notes.

## 2. Calcul des angles articulaires

Les angles sont calculés à partir des vecteurs formés par les articulations
adjacentes.

```
θ = arccos( (u · v) / (||u|| · ||v||) )
```

Où `u` et `v` sont les vecteurs 2D/3D des segments articulaires. Un filtre de
lissage est appliqué pour réduire le bruit (exponentiel α = 0,2 par défaut).

### Tolérances et seuils

| Articulation | Plage recommandée (ISO 11226 / ISO 11228) | Déclencheurs d'alerte |
| --- | --- | --- |
| Cou | Flexion ≤ 25° prolongée, extension ≤ 15° | > 25° > 4 s ou répétition > 30/min |
| Épaule | Élévation ≤ 60° pour tâches répétitives | > 60° maintenu > 2 s ou > 80° répétitif |
| Coude | Flexion recommandée 60–100° | < 45° ou > 120° répétitif |
| Poignet | Déviation ≤ 15° | > 15° répétitif > 10 cycles/min |
| Tronc | Flexion ≤ 20° statique | > 20° > 4 s ou > 45° répétitif |
| Hanche | Flexion ≤ 60° | > 60° répétitif |
| Genou | Flexion ≤ 90° statique | > 90° > 4 s |

Les seuils sont configurables dans un fichier JSON embarqué (`isoThresholds.json`).

## 3. Détection des répétitions

1. Calculer la série temporelle de l'angle pour l'articulation cible.
2. Filtrer le signal (passe-bas Butterworth 4ᵉ ordre, fc = 6 Hz).
3. Normaliser autour de la moyenne mobile.
4. Détecter les pics (algorithme `findPeaks`) avec un intervalle minimal défini
   par la durée moyenne du cycle.
5. Compter les cycles et calculer la fréquence (cycles/minute).

## 4. Durée des postures

* Segmentation du signal en états : neutre, modéré, critique selon les seuils.
* Agrégation du temps passé dans chaque état.
* Calcul d'un indice d'exposition :

```
ExposureIndex = Σ (temps_etat × poids_ISO)
```

Les poids sont définis par l'équipe ergonomique pour refléter la sévérité.

## 5. Cartographie avec les normes ISO

| Norme | Application dans l'app |
| --- | --- |
| ISO 11226 | Postures statiques du tronc, du cou et des membres supérieurs. Les
  temps de maintien sont comparés aux seuils recommandés et catégorisés en
  acceptables / à surveiller / action immédiate. |
| ISO 11228-3 | Tâches répétitives des membres supérieurs : calcul de l'indice de
  répétitivité, comparaison avec charges admissibles. |
| ISO/TR 12295 | Guides pour interpréter ISO 11228, utilisés pour paramétrer les
  seuils selon la durée de tâche et le sexe/âge. |
| ISO 14738 | Dimensions anthropométriques : permet de personnaliser les seuils
  selon la stature renseignée dans le profil utilisateur. |

## 6. Rapport d'évaluation

Le moteur `ReportService` génère :

* Tableau récapitulatif des scores par articulation (vert/jaune/rouge).
* Chronologie des événements (pics, positions critiques).
* Images clés annotées (capturées automatiquement aux pics d'angle).
* Recommandations générées à partir d'une base de règles (ex. suggérer pauses,
  ajustements de poste, outils).
* Export PDF avec métadonnées et signature numérique.

## 7. Validation et assurance qualité

* Tests de régression sur des vidéos annotées manuellement (ground truth).
* Comparaison des mesures d'angle avec un goniomètre externe (erreur cible < 5°).
* Session pilote avec ergonomes pour valider l'interprétation des scores ISO.
* Journalisation des versions de seuils et du moteur d'analyse pour audit.

