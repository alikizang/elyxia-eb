import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/exam.dart';
import '../models/school_class.dart';
import '../models/student_result.dart';
import '../services/calculation_service.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  final AppSettings? settings;
  final Exam? exam;
  final SchoolClass? schoolClass;
  final List<StudentResult> results;
  final VoidCallback onGoToMarks;
  final VoidCallback onGoToResults;
  final VoidCallback onGoToPrintA5;
  final VoidCallback onGoToPrintPv;

  const DashboardScreen({
    super.key,
    required this.settings,
    required this.exam,
    required this.schoolClass,
    required this.results,
    required this.onGoToMarks,
    required this.onGoToResults,
    required this.onGoToPrintA5,
    required this.onGoToPrintPv,
  });

  @override
  Widget build(BuildContext context) {
    final stats = CalculationService.computeStatistics(results);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de bienvenue
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          "SESSION OFFICIELLE — ${exam?.title.toUpperCase() ?? 'EXAMEN BLANC'}",
                          style: const TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        settings?.schoolName ?? "COMPLEXE SCOLAIRE LES VICTORIEUX",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Classe active : ${schoolClass?.name ?? '-'} (${schoolClass?.examType ?? '-'}) • Session : ${exam?.sessionDate ?? '-'} • Année : ${settings?.academicYear ?? '-'}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onGoToPrintA5,
                  icon: const Icon(Icons.print_rounded, size: 20),
                  label: const Text("Imprimer Relevés A5"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4 Cartes de Statistiques Rapides
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Effectif Candidats",
                  value: "${stats.totalStudents}",
                  subtitle: "Inscrits dans la classe",
                  icon: Icons.groups_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: "Taux de Réussite",
                  value: "${stats.successRate} %",
                  subtitle: "${stats.admittedCount} Admis • ${stats.failedCount} Ajournés",
                  icon: Icons.check_circle_outline_rounded,
                  color: stats.successRate >= 50 ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: "Moyenne Générale",
                  value: "${stats.classAverage.toStringAsFixed(2)} /20",
                  subtitle: "Moyenne de la promotion",
                  icon: Icons.analytics_outlined,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: "Extrêmes (Max / Min)",
                  value: stats.highestAverage.toStringAsFixed(2),
                  subtitle: "Min: ${stats.lowestAverage.toStringAsFixed(2)} /20",
                  icon: Icons.swap_vert_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Raccourcis d'actions
          const Text(
            "Actions Rapides",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: "Saisie Rapide des Notes",
                  description: "Grille de saisie ergonomique par matière ou par candidat avec validation clavier.",
                  icon: Icons.edit_note_rounded,
                  color: AppColors.primary,
                  onTap: onGoToMarks,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: "Relevés de Notes (Format A5)",
                  description: "Visualisez individuellement ou par lot toute la classe et imprimez en 1 clic.",
                  icon: Icons.description_outlined,
                  color: AppColors.accent,
                  onTap: onGoToPrintA5,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: "Procès-Verbal (PV A4)",
                  description: "Fiche récapitulative officielle de délibération grand format paysage pour affichage.",
                  icon: Icons.table_chart_outlined,
                  color: AppColors.info,
                  onTap: onGoToPrintPv,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Podium des Majors de la Classe
          if (results.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tableau d'Honneur (Tête de Promotion)",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: onGoToResults,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text("Voir tout le classement"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length > 5 ? 5 : results.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final r = results[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                            : index == 1
                                ? const Color(0xFFC0C0C0).withValues(alpha: 0.2)
                                : index == 2
                                    ? const Color(0xFFCD7F32).withValues(alpha: 0.2)
                                    : AppColors.surfaceSubtle,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == 0
                              ? const Color(0xFFFFD700)
                              : index == 1
                                  ? const Color(0xFFC0C0C0)
                                  : index == 2
                                      ? const Color(0xFFCD7F32)
                                      : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        r.rankFormatted,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: index == 0
                              ? const Color(0xFFB8860B)
                              : index == 1
                                  ? const Color(0xFF708090)
                                  : index == 2
                                      ? const Color(0xFF8B4513)
                                      : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      r.student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      "N° Table: ${r.student.tableNumber} • Total points: ${r.totalPointsFormatted} pts",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: r.isAdmitted ? AppColors.successBg : AppColors.errorBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: r.isAdmitted ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            "${r.averageFormatted} /20",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: r.isAdmitted ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.mention,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
