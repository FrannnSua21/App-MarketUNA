import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'models/profile_models.dart';
import 'widgets/profile_widgets.dart';

/// -----------------------------------------------------------------------
/// IDIOMA
/// -----------------------------------------------------------------------
class ProfileLanguagePage extends StatefulWidget {
  const ProfileLanguagePage({super.key});

  @override
  State<ProfileLanguagePage> createState() => _ProfileLanguagePageState();
}

class _ProfileLanguagePageState extends State<ProfileLanguagePage> {
  late String _selectedCode = MockProfileRepository.selectedLanguageCode;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final languages = MockProfileRepository.availableLanguages
        .where((l) => l.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final hasChanges =
        _selectedCode != MockProfileRepository.selectedLanguageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientSubHeader(title: 'Idioma', onBack: () => context.pop()),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                AppSpacing.md,
                responsive.horizontalPadding,
                AppSpacing.sm,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar idioma…',
                  hintStyle: const TextStyle(fontSize: 13.5),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final selected = lang.code == _selectedCode;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () => setState(() => _selectedCode = lang.code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang.flag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                lang.name,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              )
                            else
                              const Icon(
                                Icons.circle_outlined,
                                color: AppColors.border,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                0,
                responsive.horizontalPadding,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: hasChanges ? _apply : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _apply() {
    MockProfileRepository.selectedLanguageCode = _selectedCode;
    // TODO: aplica el cambio de idioma real (ej. con easy_localization o intl)
    // y persiste la preferencia en el backend/local storage.
    context.pop();
  }
}
