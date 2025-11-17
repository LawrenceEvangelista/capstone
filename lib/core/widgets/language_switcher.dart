import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:testapp/providers/localization_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  final Color primaryColor;
  final Color accentColor;
  
  const LanguageSwitcher({
    super.key,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, localizationProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizationProvider.translate('language'),
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LanguageButton(
                            label: localizationProvider.translate('english'),
                            isSelected: localizationProvider.currentLanguage == 'en',
                            onTap: () => localizationProvider.changeLanguage('en'),
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LanguageButton(
                            label: localizationProvider.translate('tagalog'),
                            isSelected: localizationProvider.currentLanguage == 'fil',
                            onTap: () => localizationProvider.changeLanguage('fil'),
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LanguageButton extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color primaryColor;

  const _LanguageButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  State<_LanguageButton> createState() => _LanguageButtonState();
}

class _LanguageButtonState extends State<_LanguageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _setupColorAnimation();
  }

  void _setupColorAnimation() {
    _colorAnimation = ColorTween(
      begin: widget.isSelected ? widget.primaryColor : Colors.transparent,
      end: widget.isSelected ? widget.primaryColor : Colors.transparent,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_LanguageButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _setupColorAnimation();
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSelected ? widget.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: !widget.isSelected
                  ? Border.all(color: Colors.grey.shade300, width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    color: widget.isSelected ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
