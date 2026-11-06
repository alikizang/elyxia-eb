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

    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo & School Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
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
                            value: selectedYear,
                            isDense: true,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            items: academicYears.map((yr) {
                              return DropdownMenuItem<AcademicYear>(
                                value: yr,
                                child: Text(
                                  "${yr.name}${yr.isClosed ? ' 🔒 (Clôturée)' : ''}",
                                  style: TextStyle(
                                    color: yr.isClosed ? Colors.redAccent : Colors.white,
                                    fontSize: 11,
                                  ),
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
            color: Colors.black.withValues(alpha: 0.2),
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
                      value: selectedExam,
                      isExpanded: true,
                      isDense: true,
                      dropdownColor: const Color(0xFF1E293B),
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
                      value: selectedClass,
                      isExpanded: true,
                      isDense: true,
                      dropdownColor: const Color(0xFF1E293B),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
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

          // Profil Utilisateur Connecté & Bouton Déconnexion
          Container(
            padding: const EdgeInsets.all(14),
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
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, Color primaryColor, Color accentColor) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.8) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: accentColor.withValues(alpha: 0.6), width: 1)
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
