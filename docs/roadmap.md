# Feuille de route de développement

## Phase 0 – Préparation (2 semaines)

* Recrutement de l'équipe (iOS, ergonomes, QA).
* Atelier avec les experts pour valider les besoins et définir les scénarios
  d'utilisation.
* Constitution du référentiel de normes ISO et des seuils personnalisables.
* Choix définitif du moteur de pose (Vision vs Core ML personnalisé).

## Phase 1 – Prototype fonctionnel (6 semaines)

1. **Sprint 1** :
   * Configuration du projet Xcode (SwiftUI, Combine, CoreData).
   * Mise en place de la capture vidéo en temps réel.
   * Stockage local des sessions.
2. **Sprint 2** :
   * Intégration de l'estimation de pose (Vision).
   * Visualisation overlay des articulations en temps réel.
   * Calcul basique des angles (épaule, coude, tronc).
3. **Sprint 3** :
   * Calcul des répétitions et segmentation temporelle.
   * Tableau de bord interactif (angles vs temps).
   * Export CSV des données brutes.

## Phase 2 – Moteur ergonomique avancé (8 semaines)

* Implémentation du moteur de règles ISO.
* Personnalisation des seuils par profil utilisateur.
* Génération de rapports PDF avec recommandations.
* Intégration des normes ISO 11226/11228/12295 et fiches explicatives.
* Tests d'acceptation internes avec ergonomes (3 cas d'usage).

## Phase 3 – Qualité et conformité (4 semaines)

* Optimisation des performances (traitement temps réel ≤ 50 ms/frame).
* Ajout d'un mode hors-ligne et synchronisation CloudKit optionnelle.
* Audit de sécurité, chiffrement des données, gestion des consentements.
* Tests utilisateurs terrain, collecte de feedback.
* Préparation de la documentation (manuel utilisateur, procédures RGPD).

## Phase 4 – Lancement pilote (4 semaines)

* Déploiement via TestFlight à un groupe d'ergonomes partenaires.
* Suivi des indicateurs (temps d'analyse, satisfaction, bugs).
* Ajustements finaux et préparation de la version App Store.

## Indicateurs de réussite

* Précision des angles ≤ 5° d'erreur par rapport au goniomètre.
* Temps de traitement en direct ≥ 25 fps.
* Rapport conforme aux normes ISO avec traçabilité des seuils.
* Satisfaction utilisateur > 85 % lors des tests pilotes.

