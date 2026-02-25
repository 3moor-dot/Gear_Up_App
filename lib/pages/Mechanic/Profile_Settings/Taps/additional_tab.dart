import 'package:flutter/material.dart';

class AdditionalTab extends StatefulWidget {
  const AdditionalTab({super.key});

  @override
  State<AdditionalTab> createState() => _AdditionalTabState();
}

class _AdditionalTabState extends State<AdditionalTab> {
  String? selectedCity;
  List<String> selectedSpecs = [];
  bool fieldVisit = false;
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

  final List<String> specialties = ["ميكانيكا عامة", "كهرباء", "ضبط زوايا", "تروس"];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildCard(
          isDark,
          title: "التخصص والموقع",
          child: Column(
            children: [
              _buildDropdown("الموقع / المدينة", ["القاهرة", "الجيزة", "الإسكندرية"], selectedCity, (val) => setState(() => selectedCity = val)),
              const SizedBox(height: 20),
              _buildSpecialtyChips(isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          isDark,
          title: "ساعات العمل",
          child: Row(
            children: [
              Expanded(child: _buildTimePicker("من", startTime, (t) => setState(() => startTime = t))),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker("إلى", endTime, (t) => setState(() => endTime = t))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool isDark, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1629) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSpecialtyChips(bool isDark) {
    return Wrap(
      spacing: 8,
      children: specialties.map((spec) {
        bool isSelected = selectedSpecs.contains(spec);
        return FilterChip(
          label: Text(spec),
          selected: isSelected,
          onSelected: (val) {
            setState(() => isSelected ? selectedSpecs.remove(spec) : selectedSpecs.add(spec));
          },
          selectedColor: Colors.blue.withOpacity(0.2),
          checkmarkColor: Colors.blue,
        );
      }).toList(),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(label),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(time.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}