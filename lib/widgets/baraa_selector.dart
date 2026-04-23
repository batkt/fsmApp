import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class BaraaSelector extends StatefulWidget {
  final Baraa placeholder;
  final String baiguullagiinId;
  final String barilgiinId;
  final Function(Baraa) onSelected;

  const BaraaSelector({
    super.key,
    required this.placeholder,
    required this.baiguullagiinId,
    required this.barilgiinId,
    required this.onSelected,
  });

  @override
  State<BaraaSelector> createState() => _BaraaSelectorState();
}

class _BaraaSelectorState extends State<BaraaSelector> {
  bool _loading = true;
  List<Baraa> _baraas = [];
  String? _error;
  Baraa? _selectedBaraa;
  final _tooController = TextEditingController();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _fetchBaraas();
    _tooController.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      if (_selectedBaraa == null || _tooController.text.isEmpty) {
        _validationError = null;
        return;
      }
      final too = double.tryParse(_tooController.text) ?? 0;
      if (too <= 0) {
        _validationError = 'Тоо хэмжээ буруу байна';
      } else if (too > _selectedBaraa!.uldegdel) {
        _validationError = 'Үлдэгдэл хүрэлцэхгүй байна';
      } else {
        _validationError = null;
      }
    });
  }

  Future<void> _fetchBaraas() async {
    try {
      final res = await ApiService.get('/baraas', query: {
        'baiguullagiinId': widget.baiguullagiinId,
        'barilgiinId': widget.barilgiinId,
      });

      if (!res.success) {
        setState(() {
          _error = res.message ?? 'Алдаа гарлаа';
          _loading = false;
        });
        return;
      }

      final list = res.data is Map ? (res.data['data'] ?? res.data['result'] ?? []) : res.data;
      final allBaraas = (list as List).map((j) => Baraa.fromJson(j)).toList();

      // Filter by type
      final type = widget.placeholder.type;
      final baraaTypeMap = {
        'tseverlegch': 'Цэвэрлэгээ',
        'ugaalgiin': 'Угаалгын',
        'ariutgagch': 'Ариутгагч',
        'bagaj': 'Багаж',
        'busad': 'Бусад'
      };
      
      final filtered = allBaraas.where((b) {
        if (type == null || type == 'all') return true;
        if (type == 'tseverlegch') return ['tseverlegch', 'Цэвэрлэгч', 'Цэвэрлэгээ'].contains(b.type);
        if (type == 'busad') {
          final keys = ['tseverlegch', 'Цэвэрлэгч', 'Цэвэрлэгээ', 'ugaalgiin', 'Угаалгын', 'ariutgagch', 'Ариутгагч', 'bagaj', 'Багаж'];
          return !keys.contains(b.type);
        }
        return b.type == type || b.type == baraaTypeMap[type];
      }).toList();

      setState(() {
        _baraas = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _save() {
    if (_selectedBaraa == null) return;
    final too = double.tryParse(_tooController.text) ?? 0;
    if (too <= 0 || too > _selectedBaraa!.uldegdel) return;

    final updated = Baraa(
      baraaId: _selectedBaraa!.baraaId,
      ner: _selectedBaraa!.ner,
      negj: _selectedBaraa!.negj,
      too: too.toInt(),
      une: _selectedBaraa!.une,
      niitUne: _selectedBaraa!.une * too,
      type: widget.placeholder.type,
    );

    widget.onSelected(updated);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(_error!, style: TextStyle(color: c.destructive))),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Бараа материал сонгох',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Baraa>(
            decoration: InputDecoration(
              labelText: 'Материал',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            isExpanded: true,
            value: _selectedBaraa,
            items: _baraas.map((b) {
              return DropdownMenuItem(
                value: b,
                child: Text('${b.ner} (Үлдэгдэл: ${b.uldegdel.toStringAsFixed(b.uldegdel.truncateToDouble() == b.uldegdel ? 0 : 2)} ${b.negjLabel})'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBaraa = val;
                _validateInput();
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tooController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Тоо хэмжээ',
              errorText: _validationError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.brandGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedBaraa == null || _tooController.text.isEmpty || _validationError != null ? null : _save,
              child: const Text('Сонгох', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
