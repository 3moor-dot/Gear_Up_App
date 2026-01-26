import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  // استخدام const هنا يقلل من إعادة بناء الودجت غير الضرورية
  const ThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // تحديد الألوان بناءً على الحالة لسهولة القراءة
    final Color trackColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final Color knobColor = isDark ? const Color(0xFF0A84FF) : Colors.amber;

    return MouseRegion(
      cursor: SystemMouseCursors.click, // للمتصفح والديسكتوب
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutBack, // حركة "ارتدادية" بسيطة تعطي لمسة احترافية
          width: 64, // عرض أكبر قليلاً لراحة العين
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(20),
            // إضافة ظل داخلي خفيف لإعطاء عمق (اختياري)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // أيقونات ثابتة في الخلفية تعطي إيحاءً بالثيمين
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(FontAwesomeIcons.sun, size: 10, color: Colors.grey),
                      Icon(FontAwesomeIcons.moon, size: 10, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              // الزر المتحرك (Knob)
              AnimatedAlign(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutBack,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: knobColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: knobColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    // لإضافة حركة تلاشي (Fade) عند تغيير الأيقونة
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isDark ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
                      key: ValueKey<bool>(isDark), // ضروري لـ AnimatedSwitcher
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}