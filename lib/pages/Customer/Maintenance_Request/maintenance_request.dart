import 'package:flutter/material.dart';
import 'package:gear_up_app/components/Customer/customer_header.dart';
import 'package:gear_up_app/components/Customer/customer_sidebar.dart';

// استيراد المكونات التي سننشئها بالأسفل
import 'package:gear_up_app/pages/Customer/Maintenance_Request/step_progress.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Request/step_one_details.dart';
import 'package:gear_up_app/pages/Customer/Maintenance_Request/step_two_mechanics.dart';

class MaintenanceRequestPage extends StatefulWidget {
  const MaintenanceRequestPage({super.key});

  @override
  State<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends State<MaintenanceRequestPage> {
  int _currentStep = 1; // إدارة الخطوة الحالية

  void _nextStep() => setState(() => _currentStep = 2);
  void _prevStep() => setState(() => _currentStep = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomDrawer(currentRoute: '/request'),
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // المكون العلوي (البروجرس)
                    StepProgressWidget(
                      currentStep: _currentStep,
                      onStepChange: (step) => setState(() => _currentStep = step),
                    ),

                    const SizedBox(height: 30),

                    // عرض المحتوى بناءً على الخطوة
                    _currentStep == 1 
                        ? StepOneDetails(onNext: _nextStep) 
                        : StepTwoMechanics(onBack: _prevStep),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}