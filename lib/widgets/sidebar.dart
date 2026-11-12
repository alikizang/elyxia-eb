import 'dart:convert' show base64Decode;
import 'package:flutter/material.dart';

import '../models/academic_year.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../theme/app_colors.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final AppSettings? settings;
  final List<AcademicYear> academicYears;
  final AcademicYear? selectedYear;
  final Function(AcademicYear) onYearChanged;
  final List<Exam> exams;
  final Exam? selectedExam;
  final Function(Exam) onExamChanged;
  final List<SchoolClass> classes;
  final SchoolClass? selectedClass;
  final Function(SchoolClass) onClassChanged;
  final AppUser? currentUser;
  final VoidCallback onLogout;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.settings,
    required this.academicYears,
    required this.selectedYear,
    required this.onYearChanged,
    required this.exams,
    required this.selectedExam,
    required this.onExamChanged,
    required this.classes,
    required this.selectedClass,
    required this.onClassChanged,
    required this.currentUser,
    required this.onLogout,
    this.isCollapsed = false,
    required this.onToggleCollapse,
  });

  Widget _buildSchoolLogo() {
    if (settings?.logoBase64 != null && settings!.logoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(settings!.logoBase64!);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {}
    }
    return Image.asset('assets/images/school_logo_default.jpg', fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.fromHex(settings?.primaryColorHex);
    final accentColor = AppColors.fromHex(settings?.accentColorHex);
    final isYearClosed = selectedYear?.isClosed ?? false;
    final dropdownBg = Color.lerp(primaryColor, const Color(0xFF1E293B), 0.75)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 72 : 270,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(primaryColor, const Color(0xFF060B13), 0.78)!,
            Color.lerp(primaryColor, const Color(0xFF0B1120), 0.88)!,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 14,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: isCollapsed
          ? _buildCollapsedSidebar(context, primaryColor, accentColor, isYearClosed)
          : _buildExpandedSidebar(context, primaryColor, accentColor, isYearClosed, dropdownBg),
    );
  }

  /// Vue compacte (Icônes uniquement)
  Widget _buildCollapsedSidebar(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
    bool isYearClosed,
  ) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Bouton toggle expand
        Tooltip(
          message: "Développer le menu",
          child: InkWell(
            onTap: onToggleCollapse,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Logo établissement compact
        Tooltip(
          message: "${settings?.schoolName ?? 'Établissement'}\n${settings?.schoolSlogan ?? ''}",
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipOval(child: _buildSchoolLogo()),
          ),
        ),

        const SizedBox(height: 14),
        const Divider(color: Colors.white12, height: 1, indent: 12, endIndent: 12),
        const SizedBox(height: 10),

        // Badges d'état compacts avec Tooltips
        Tooltip(
          message: "Année : ${selectedYear?.name ?? '-'} ${isYearClosed ? '(Clôturée)' : ''}",
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isYearClosed ? Colors.red.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isYearClosed ? Colors.redAccent.withValues(alpha: 0.6) : Colors.white12,
              ),
            ),
            child: Icon(
              isYearClosed ? Icons.lock : Icons.calendar_today_outlined,
              size: 15,
              color: isYearClosed ? Colors.redAccent : accentColor,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Tooltip(
          message: "Session : ${selectedExam?.title ?? '-'}",
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.assignment_outlined, size: 15, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 8),

        Tooltip(
          message: "Classe : ${selectedClass?.name ?? '-'}",
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.school_outlined, size: 15, color: Colors.white70),
          ),
        ),

        const SizedBox(height: 10),
        const Divider(color: Colors.white12, height: 1, indent: 12, endIndent: 12),

        // Navigation items compacts
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildCompactNavItem(0, "Tableau de Bord", Icons.dashboard_outlined, primaryColor, accentColor),
              _buildCompactNavItem(1, "Saisie des Notes", Icons.edit_note_outlined, primaryColor, accentColor),
              _buildCompactNavItem(2, "Résultats & Délibération", Icons.leaderboard_outlined, primaryColor, accentColor),
              _buildCompactNavItem(3, "Relevés de Notes (A5)", Icons.picture_as_pdf_outlined, primaryColor, accentColor),
              _buildCompactNavItem(4, "Procès-Verbal (A4)", Icons.assignment_outlined, primaryColor, accentColor),
              _buildCompactNavItem(5, "Gestion des Élèves", Icons.people_outline, primaryColor, accentColor),
              _buildCompactNavItem(6, "Paramètres & Portabilité", Icons.settings_outlined, primaryColor, accentColor),
            ],
          ),
        ),

        // Profil compact & Logout
        Tooltip(
          message: "${currentUser?.fullName ?? 'Utilisateur'}\n${currentUser?.roleLabel ?? ''}",
          child: CircleAvatar(
            radius: 15,
            backgroundColor: primaryColor,
            child: Text(
              (currentUser?.fullName.isNotEmpty ?? false) ? currentUser!.fullName[0].toUpperCase() : "A",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 6),
        IconButton(
          icon: const Icon(Icons.logout, size: 18, color: Colors.white60),
          tooltip: "Déconnexion",
          onPressed: onLogout,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCompactNavItem(
    int index,
    String label,
    IconData icon,
    Color primaryColor,
    Color accentColor,
  ) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withValues(alpha: 0.85) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: accentColor.withValues(alpha: 0.6), width: 1) : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected ? accentColor : Colors.white70,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Vue étendue (Standard)
  Widget _buildExpandedSidebar(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
    bool isYearClosed,
    Color dropdownBg,
  ) {
    AcademicYear? effectiveYear;
    if (selectedYear != null && academicYears.isNotEmpty) {
      effectiveYear = academicYears.cast<AcademicYear?>().firstWhere(
            (y) => y != null && (y.id == selectedYear!.id || y.name == selectedYear!.name),
            orElse: () => null,
          );
    }

    Exam? effectiveExam;
    if (selectedExam != null && exams.isNotEmpty) {
      effectiveExam = exams.cast<Exam?>().firstWhere(
            (e) => e != null && e.id == selectedExam!.id,
            orElse: () => null,
          );
    }

    SchoolClass? effectiveClass;
    if (selectedClass != null && classes.isNotEmpty) {
      effectiveClass = classes.cast<SchoolClass?>().firstWhere(
            (c) => c != null && c.id == selectedClass!.id,
            orElse: () => null,
          );
    }

    return Column(
      children: [
        // Header de Marque Elyxia EB avec bouton de réduction
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.45),
                Colors.white.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "ELYXIA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            "EB",
                            style: TextStyle(
                              color: accentColor.computeLuminance() > 0.65 ? Colors.black87 : Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "Suite Examen Blanc",
                      style: TextStyle(color: Colors.white54, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              // Bouton Réduire Sidebar
              IconButton(
                icon: const Icon(Icons.menu_open_rounded, color: Colors.white70, size: 18),
                tooltip: "Réduire le menu (Icônes seules)",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onToggleCollapse,
              ),
            ],
          ),
        ),

        // Logo & School Branding Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(child: _buildSchoolLogo()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings?.schoolName ?? "CS LES VICTORIEUX",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          settings?.schoolSlogan ?? "Discipline - Travail - Succès",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // SÉLECTEUR RAPIDE D'ANNÉE ACADÉMIQUE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isYearClosed ? Colors.red.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isYearClosed ? Colors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isYearClosed ? Icons.lock_outline : Icons.calendar_today_outlined,
                      size: 14,
                      color: isYearClosed ? Colors.redAccent : accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AcademicYear>(
                          value: effectiveYear,
                          hint: const Text("Aucune année", style: TextStyle(color: Colors.white54, fontSize: 11)),
                          isDense: true,
                          dropdownColor: dropdownBg,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          items: academicYears.map((yr) {
                            return DropdownMenuItem<AcademicYear>(
                              value: yr,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    yr.name,
                                    style: TextStyle(
                                      color: yr.isClosed ? Colors.white70 : Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: yr.name == effectiveYear?.name ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if (yr.isClosed) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.lock_rounded, size: 12, color: Colors.redAccent),
                                    const SizedBox(width: 3),
                                    const Text(
                                      "(Clôturée)",
                                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newYr) {
                            if (newYr != null) onYearChanged(newYr);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sélecteurs rapides : Examen & Classe
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black.withValues(alpha: 0.22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur d'examen
              const Text(
                "SESSION D'EXAMEN",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Exam>(
                    value: effectiveExam,
                    hint: const Text("Aucune session", style: TextStyle(color: Colors.white54, fontSize: 11)),
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: dropdownBg,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    items: exams.map((e) {
                      return DropdownMenuItem<Exam>(
                        value: e,
                        child: Text(
                          e.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 11.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (newExam) {
                      if (newExam != null) onExamChanged(newExam);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Sélecteur de classe
              const Text(
                "CLASSE CONCERNÉE",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SchoolClass>(
                    value: effectiveClass,
                    hint: const Text("Aucune classe", style: TextStyle(color: Colors.white54, fontSize: 11)),
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: dropdownBg,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    items: classes.map((c) {
                      return DropdownMenuItem<SchoolClass>(
                        value: c,
                        child: Text(
                          "${c.name} (${c.series})",
                          style: const TextStyle(color: Colors.white, fontSize: 11.5),
                        ),
                      );
                    }).toList(),
                    onChanged: (newClass) {
                      if (newClass != null) onClassChanged(newClass);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Menu de navigation principal
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildNavItem(0, "Tableau de Bord", Icons.dashboard_outlined, primaryColor, accentColor),
              _buildNavItem(1, "Saisie des Notes", Icons.edit_note_outlined, primaryColor, accentColor),
              _buildNavItem(2, "Résultats & Délibération", Icons.leaderboard_outlined, primaryColor, accentColor),
              _buildNavItem(3, "Relevés de Notes (A5)", Icons.picture_as_pdf_outlined, primaryColor, accentColor),
              _buildNavItem(4, "Procès-Verbal (A4)", Icons.assignment_outlined, primaryColor, accentColor),
              _buildNavItem(5, "Gestion des Élèves", Icons.people_outline, primaryColor, accentColor),
              _buildNavItem(6, "Paramètres & Portabilité", Icons.settings_outlined, primaryColor, accentColor),
            ],
          ),
        ),

        // Mention légale et version Elyxia EB
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, size: 11, color: accentColor.withValues(alpha: 0.8)),
              const SizedBox(width: 5),
              const Text(
                "Elyxia EB v1.2 • Édition Locale",
                style: TextStyle(color: Colors.white38, fontSize: 9.5, letterSpacing: 0.2),
              ),
            ],
          ),
        ),

        // Profil Utilisateur Connecté & Bouton Déconnexion
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primaryColor,
                child: Text(
                  (currentUser?.fullName.isNotEmpty ?? false) ? currentUser!.fullName[0].toUpperCase() : "A",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentUser?.fullName ?? "Admin Principal",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      currentUser?.roleLabel ?? "Administrateur",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 18, color: Colors.white60),
                tooltip: "Déconnexion",
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, Color primaryColor, Color accentColor) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.85) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: accentColor.withValues(alpha: 0.6), width: 1)
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        leading: Icon(
          icon,
          color: isSelected ? accentColor : Colors.white70,
          size: 19,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12.5,
          ),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }
}
