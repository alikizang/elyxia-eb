# 🎓 Elyxia EB — Édition Examen Blanc (Hors Ligne / Desktop)

> **Application autonome pour PC Windows & Mac**, spécialement conçue pour les examens blancs des classes de **Premières (BAC 1)** et **Terminales (BAC 2)** du **Complexe Scolaire Les Victorieux**.

---

## 🌟 Présentation

**Elyxia EB** est une déclinaison allégée, ultra-rapide et **100% hors ligne** de l'écosystème Elyxia.  
Elle permet aux enseignants et à l'administration scolaire de gérer l'intégralité d'une session d'examen blanc : de la saisie au kilomètre des notes jusqu'à la sortie des **relevés de notes imprimables au format A5** et du **Procès-Verbal (PV) de délibération au format A4**.

---

## 💻 Tech Stack & Architecture

- **Framework UI** : **Flutter Desktop (macOS & Windows)**
- **Base de Données** : **SQL Natif (SQLite)** via FFI (`sqflite_common_ffi` + `sqlite3_flutter_libs`)
  - Stockage local dans un fichier standard SQLite : `~/Documents/ElyxiaEB/elyxia_eb.db`
  - Aucun serveur web, Apache ou MySQL externe requis.
  - Sauvegarde et restauration immédiates par simple copie du fichier `.db`.
- **Génération & Impression Documentaire** : `pdf` + `printing`
  - Format officiel **A5 Portrait (148 × 210 mm)** pour les relevés de notes élèves.
  - Format officiel **A4 Paysage (297 × 210 mm)** pour le PV de délibération.
  - Prévisualisation interactive native avec zoom, pagination et impression directe vers toute imprimante connectée.
- **Import / Export** : `csv` + `file_picker` (Importation et exportation des listes élèves et des résultats complets).

---

## 📋 Curriculum & Spécificités Togo Intégrées

L'application intègre par défaut la configuration complète des filières du Togo :
- **Classes configurées** :
  - **1ère A4** (Bac 1 - Série Littéraire)
  - **1ère D** (Bac 1 - Série Scientifique Biologie)
  - **1ère C** (Bac 1 - Série Scientifique Mathématiques / Physique)
  - **Terminale A4** (Bac 2 - Littéraire & Philosophie)
  - **Terminale D** (Bac 2 - Sciences Expérimentales)
  - **Terminale C** (Bac 2 - Sciences Exactes & Mathématiques)
- **Coefficients officiels** : Préconfigurés (ex: SVT coef 5, SP coef 4, Maths coef 4 en Tle D ; Math coef 6, SP coef 5 en Tle C ; Philo coef 5, Français coef 4 en Tle A4).
- Les matières et coefficients restent **100% modifiables et personnalisables** dans l'onglet *Paramètres*.

---

## 🚀 Fonctionnalités Clés

### 1. ✍️ Saisie des Notes au Kilomètre
- Saisie matière par matière avec affichage instantané de la note sur 20 et des points ($Note \times Coef$).
- **Navigation ultra-rapide au clavier** : la touche `[Entrée]` passe automatiquement au candidat suivant.
- Gestion instantanée des absences (`ABS`).
- Statistiques en direct : moyenne de l'épreuve, note la plus forte, note la plus faible.

### 2. 🏆 Calculs & Délibérations Automatiques
- Calcul de la somme des points et de la somme des coefficients.
- Calcul de la moyenne générale pondérée sur 20.
- **Attribution des Rangs** automatique avec prise en compte des ex-æquo (ex: *1er, 2ème, 2ème ex, 4ème...*).
- **Décision du Jury** automatique :
  - `Moyenne ≥ 10.00` $\rightarrow$ **ADMIS(E)**
  - `Moyenne < 10.00` $\rightarrow$ **AJOURNÉ(E)**
- **Mentions officielles** : *Très Bien (≥ 16)*, *Bien (≥ 14)*, *Assez Bien (≥ 12)*, *Passable (≥ 10)*, *Insuffisant (< 10)*.

### 3. 🖨️ Relevés de Notes Officiels au Format A5
- **Prévisualisation Unique** : Visualisez et imprimez le relevé d'un élève en particulier.
- **Prévisualisation d'Ensemble (Par lot)** : Visualisez l'ensemble du carnet de la classe (1 page A5 par élève) et lancez l'impression de toute la classe en **un seul clic** !
- Présentation conforme aux normes de l'enseignement secondaire togolais :
  - En-tête : République Togolaise + Complexe Scolaire Les Victorieux
  - Informations candidat : N° de table, matricule, classe, série, sexe, date de naissance
  - Tableau détaillé des matières, notes, coefficients, points, rangs par matière et appréciations
  - Cartouche de délibération : Moyenne, Rang, Décision, Mention, Profil statistique de la classe
  - Cadres pour visas du Président du Jury et signature/cachet du Chef d'Établissement.

### 4. 📄 Procès-Verbal (PV) de Délibération A4
- Grand tableau de synthèse de toute la promotion.
- Toutes les notes affichées colonne par colonne avec totaux, moyennes, décisions et taux de réussite.
- Prêt à imprimer en A4 Paysage pour archivage ou affichage officiel.

### 5. 👥 Gestion des Candidats & Import CSV
- Importation en un clic de la liste des élèves depuis un fichier CSV ou Excel.
- Téléchargement d'un modèle CSV type depuis l'application.

---

## 🛠️ Instructions de Lancement & Compilation

### Lancement en mode développement (sur Mac) :
```bash
cd elyxia_eb
flutter run -d macos
```

### Génération de l'application installable Mac (.app) :
```bash
cd elyxia_eb
flutter build macos --release
```
L'application compilée se trouvera dans : `build/macos/Build/Products/Release/elyxia_eb.app`.

### Génération de l'application installable Windows (.exe) :
Sur une machine Windows avec Flutter installé :
```bash
cd elyxia_eb
flutter build windows --release
```
L'exécutable autonome et ses DLLs se trouveront dans : `build/windows/x64/runner/Release/`.

---

## 📁 Structure du Projet

```text
elyxia_eb/
├── lib/
│   ├── data/
│   │   └── database_helper.dart      # Moteur SQLite local & schéma SQL
│   ├── models/
│   │   ├── app_settings.dart         # Configuration établissement
│   │   ├── exam.dart                 # Sessions d'examen blanc
│   │   ├── school_class.dart         # Classes (1ère & Tle, Séries)
│   │   ├── subject.dart              # Matières & coefficients Togo
│   │   ├── student.dart              # Candidats
│   │   ├── mark.dart                 # Notes & absences
│   │   └── student_result.dart       # Moyennes, rangs et décisions calculés
│   ├── services/
│   │   ├── calculation_service.dart  # Moteur de calcul, rangs et statistiques
│   │   ├── pdf_service.dart          # Générateur des relevés A5 et PV A4
│   │   └── csv_service.dart          # Import/Export CSV
│   ├── theme/
│   │   ├── app_colors.dart           # Palette officielle Elyxia
│   │   └── app_theme.dart            # Thème Material 3 épuré
│   ├── widgets/
│   │   └── sidebar.dart              # Barre latérale avec sélecteur classe/session
│   ├── screens/
│   │   ├── main_layout_screen.dart   # Écran principal et navigation
│   │   ├── dashboard_screen.dart     # Tableau de bord et stats
│   │   ├── marks_entry_screen.dart   # Saisie rapide au clavier des notes
│   │   ├── results_screen.dart       # Résultats, tableau des rangs & filtres
│   │   ├── print_report_card_screen.dart # Impression Relevés A5 (Unique & Lot)
│   │   ├── print_pv_screen.dart      # Impression PV A4 Paysage
│   │   ├── students_screen.dart      # Gestion élèves & import CSV
│   │   └── settings_screen.dart      # Paramètres école & coefficients
│   └── main.dart                     # Point d'entrée de l'application
├── assets/images/                    # Logos et identité visuelle Elyxia
└── pubspec.yaml
```
