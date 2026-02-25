import 'package:flutter/material.dart';

class ServiceModel {
  String name;
  double minPrice;
  double maxPrice;
  ServiceModel({this.name = "", this.minPrice = 0, this.maxPrice = 0});
}

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  List<ServiceModel> services = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...services.asMap().entries.map((entry) => _buildServiceItem(entry.key, entry.value)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => setState(() => services.add(ServiceModel())),
          icon: const Icon(Icons.add),
          label: const Text("إضافة خدمة جديدة"),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }

  Widget _buildServiceItem(int index, ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextField(
                decoration: const InputDecoration(hintText: "اسم الخدمة (مثلاً: فحص محرك)"),
                onChanged: (val) => service.name = val,
              )),
              IconButton(onPressed: () => setState(() => services.removeAt(index)), icon: const Icon(Icons.delete, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _priceField("السعر الأدنى", (val) => service.minPrice = double.tryParse(val) ?? 0)),
              const SizedBox(width: 12),
              Expanded(child: _priceField("السعر الأعلى", (val) => service.maxPrice = double.tryParse(val) ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceField(String label, Function(String) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: "EGP",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: onChanged,
    );
  }
}