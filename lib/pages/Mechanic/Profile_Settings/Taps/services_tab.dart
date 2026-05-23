import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ================= MODELS =================

class SubSpecialization {
  final String id;
  final String name;

  SubSpecialization({required this.id, required this.name});

  factory SubSpecialization.fromJson(Map<String, dynamic> json) {
    return SubSpecialization(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
    );
  }
}

class ServiceData {
  String? id;
  String subSpecializationId;
  String subSpecializationName;
  TextEditingController priceController;
  bool isNew;

  ServiceData({
    this.id,
    required this.subSpecializationId,
    required this.subSpecializationName,
    required String price,
    this.isNew = false,
  }) : priceController = TextEditingController(text: price);
}

/// ================= API =================

class Api {
  final base = "https://gearupapp.runasp.net/api";

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userToken");
  }

  Future<List> get(String endpoint) async {
    final t = await token();
    final res = await http.get(
      Uri.parse("$base/$endpoint"),
      headers: {"Authorization": "Bearer $t"},
    );

    final data = jsonDecode(res.body);
    return data is List ? data : (data["data"] ?? []);
  }

  Future post(String e, Map b) async {
    final t = await token();
    await http.post(Uri.parse("$base/$e"),
        headers: {
          "Authorization": "Bearer $t",
          "Content-Type": "application/json"
        },
        body: jsonEncode(b));
  }

  Future put(String e, Map b) async {
    final t = await token();
    await http.put(Uri.parse("$base/$e"),
        headers: {
          "Authorization": "Bearer $t",
          "Content-Type": "application/json"
        },
        body: jsonEncode(b));
  }

  Future delete(String e) async {
    final t = await token();
    await http.delete(
      Uri.parse("$base/$e"),
      headers: {"Authorization": "Bearer $t"},
    );
  }
}

/// ================= MAIN =================

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key, required String title});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final api = Api();

  bool loading = true;
  bool editing = false;
  bool saving = false;

  String? error;
  String? success;

  List<ServiceData> services = [];
  List<SubSpecialization> options = [];

  String? deletingId;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    await Future.wait([loadOptions(), loadServices()]);

    setState(() => loading = false);
  }

  Future<void> loadOptions() async {
    final data = await api.get("specializations/sub-specializations");

    final map = <String, SubSpecialization>{};
    for (var e in data) {
      final item = SubSpecialization.fromJson(e);
      map[item.id] = item;
    }

    options = map.values.toList();
  }

  Future<void> loadServices() async {
    final data = await api.get("mechanics/my/services");

    services = data
        .map<ServiceData>((e) => ServiceData(
              id: e["id"]?.toString(),
              subSpecializationId: e["subSpecializationId"] ?? "",
              subSpecializationName: e["subSpecializationName"] ?? "",
              price: e["price"]?.toString() ?? "",
            ))
        .toList();
  }

  void add() {
    setState(() {
      services.insert(
        0,
        ServiceData(
          subSpecializationId: "",
          subSpecializationName: "",
          price: "",
          isNew: true,
        ),
      );
      editing = true;
    });
  }

  void update(int i, {String? id, String? name}) {
    if (id != null) services[i].subSpecializationId = id;
    if (name != null) services[i].subSpecializationName = name;
    setState(() {});
  }

  Future<void> delete(int i) async {
    final s = services[i];

    if (s.isNew || s.id == null) {
      setState(() => services.removeAt(i));
      return;
    }

    setState(() => deletingId = s.id);

    await api.delete("mechanics/my/services/${s.id}");

    services.removeAt(i);

    setState(() => deletingId = null);
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
      success = null;
    });

    try {
      final valid = services.where((s) =>
          s.subSpecializationId.isNotEmpty &&
          s.priceController.text.isNotEmpty);

      for (final s in valid) {
        final body = {
          "subSpecializationId": s.subSpecializationId,
          "price": double.tryParse(s.priceController.text) ?? 0,
        };

        if (s.isNew || s.id == null) {
          await api.post("mechanics/my/services", body);
        } else {
          await api.put("mechanics/my/services/${s.id}", body);
        }
      }

      await loadServices();

      success = "Saved successfully";
      editing = false;
    } catch (e) {
      error = "Save failed";
    }

    setState(() => saving = false);
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// HEADER (React-like)
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Services & Pricing",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              if (!editing)
                _btn("Edit", Icons.edit, () {
                  setState(() => editing = true);
                })
              else ...[
                _iconBtn(Icons.add, Colors.green, add),
                _iconBtn(
                  saving ? Icons.hourglass_bottom : Icons.save,
                  Colors.blue,
                  saving ? null : save,
                ),
                _iconBtn(Icons.close, Colors.red, () {
                  setState(() => editing = false);
                }),
              ]
            ],
          ),

          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
          if (success != null)
            Text(success!, style: const TextStyle(color: Colors.green)),

          const SizedBox(height: 10),

          /// LIST
          Expanded(
            child: ListView.separated(
              itemCount: services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = services[i];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF131C2F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.05),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      /// CUSTOM DROPDOWN (React Style)
                      _Dropdown(
                        options: options,
                        value: s.subSpecializationId,
                        dark: dark,
                        onChange: (id, name) => update(i, id: id, name: name),
                      ),

                      const SizedBox(height: 10),

                      /// PRICE
                      TextField(
                        controller: s.priceController,
                        enabled: editing,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Price",
                          prefixText: "EGP ",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      if (editing)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => delete(i),
                            child: Text(
                              deletingId == s.id ? "Deleting..." : "Delete",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(text),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color),
    );
  }
}

/// ================= CUSTOM DROPDOWN (React Clone) =================

class _Dropdown extends StatefulWidget {
  final List<SubSpecialization> options;
  final String value;
  final bool dark;
  final Function(String id, String name) onChange;

  const _Dropdown({
    required this.options,
    required this.value,
    required this.onChange,
    required this.dark,
  });

  @override
  State<_Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<_Dropdown> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.options.where((e) => e.id == widget.value).toList();

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => open = !open),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue),
              color: widget.dark ? const Color(0xFF1A253A) : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected.isEmpty ? "Select Service" : selected.first.name,
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),

        if (open)
          Container(
            height: 200,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey),
            ),
            child: ListView(
              children: widget.options.map((e) {
                return ListTile(
                  title: Text(e.name),
                  onTap: () {
                    widget.onChange(e.id, e.name);
                    setState(() => open = false);
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}