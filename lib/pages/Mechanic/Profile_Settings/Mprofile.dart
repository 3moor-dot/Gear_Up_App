import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_header.dart';
import 'package:gear_up_app/components/Mechanic/mechanic_sidebar.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/additional_tab.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/personal_tab.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/security_tab.dart';
import 'package:gear_up_app/pages/Mechanic/Profile_Settings/Taps/services_tab.dart';

class MProfilePage extends StatefulWidget {
  const MProfilePage({super.key});

  @override
  State<MProfilePage> createState() => _MProfilePageState();
}

class _MProfilePageState extends State<MProfilePage> {
  String activeTab = TabType.personal;

  final List<_TabItem> tabs = const [
    _TabItem(id: TabType.personal, label: "البيانات الشخصية"),
    _TabItem(id: TabType.additional, label: "بيانات إضافية"),
    _TabItem(id: TabType.services, label: "الخدمات"),
    _TabItem(id: TabType.security, label: "الأمان"),
  ];

  static const Color primaryColor = Color(0xFF137FEC);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FC),

      endDrawer: const MachineDrawer(
        currentRoute: '/mechanics/machineprofile',
      ),

      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const MachineHeader(),

              // ================= TITLE =================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: const [
                    Text(
                      "ملفك الشخصي",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ================= TABS (React style pills) =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabs(isDark),
              ),

              const SizedBox(height: 12),

              // ================= CONTENT =================
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(activeTab),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildTabContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MODERN PILLS TAB BAR (React-like) =================
  Widget _buildTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final isActive = activeTab == tab.id;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(left: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() => activeTab = tab.id);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),

                  // ===== React-like active style =====
                  color: isActive
                      ? primaryColor
                      : (isDark
                          ? const Color(0xFF121C2E)
                          : Colors.white),

                  border: Border.all(
                    color: isActive
                        ? primaryColor
                        : (isDark
                            ? Colors.white10
                            : Colors.grey.shade300),
                  ),

                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : (isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= TAB SWITCH =================
  Widget _buildTabContent() {
    switch (activeTab) {
      case TabType.personal:
        return const PersonalTab(
          key: PageStorageKey(TabType.personal),
        );

      case TabType.additional:
        return const AdditionalTab(
          key: PageStorageKey(TabType.additional),
        );

      case TabType.services:
        return const ServicesTab(
          key: PageStorageKey(TabType.services),
          title: "الخدمات",
        );

      case TabType.security:
        return const SecurityTab(
          key: PageStorageKey(TabType.security),
        );

      default:
        return const SizedBox();
    }
  }
}

// ================= TYPES =================
class TabType {
  static const personal = "personal";
  static const additional = "additional";
  static const services = "services";
  static const security = "security";
}

class _TabItem {
  final String id;
  final String label;

  const _TabItem({
    required this.id,
    required this.label,
  });
}