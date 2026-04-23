import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

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
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.rRadius(24))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + context.rSpacing(24),
        top: context.rSpacing(12),
        left: context.rSpacing(24),
        right: context.rSpacing(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: context.rSpacing(40),
              height: context.rSpacing(4),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(context.rRadius(2)),
              ),
            ),
          ),
          SizedBox(height: context.rSpacing(20)),
          Text(
            'Бараа материал сонгох',
            style: TextStyle(
              fontSize: context.rFontSize(18),
              fontWeight: FontWeight.bold,
              color: c.primary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: context.rSpacing(20)),
          
          Theme(
            data: Theme.of(context).copyWith(
              hoverColor: c.brandGreen.withOpacity(0.05),
              focusColor: c.brandGreen.withOpacity(0.05),
            ),
            child: DropdownButtonFormField<Baraa>(
              dropdownColor: c.cardBackground,
              borderRadius: BorderRadius.circular(context.rRadius(16)),
              decoration: InputDecoration(
                labelText: 'Материал',
                labelStyle: TextStyle(color: c.mutedForeground, fontSize: context.rFontSize(14)),
                filled: true,
                fillColor: c.secondary.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.rRadius(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.rRadius(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(context.rRadius(12)),
                  borderSide: BorderSide(color: c.brandGreen.withOpacity(0.5), width: 1.5),
                ),
                prefixIcon: Icon(Icons.inventory_2_rounded, color: c.brandGreen, size: context.rIconSize(20)),
              ),
              isExpanded: true,
              value: _selectedBaraa,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.mutedForeground),
              items: _baraas.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text(
                    '${b.ner} (Үлдэгдэл: ${b.uldegdel.toStringAsFixed(b.uldegdel.truncateToDouble() == b.uldegdel ? 0 : 2)} ${b.negjLabel})',
                    style: TextStyle(
                      fontSize: context.rFontSize(14),
                      color: c.primary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBaraa = val;
                  _validateInput();
                });
              },
            ),
          ),
          SizedBox(height: context.rSpacing(16)),
          TextField(
            controller: _tooController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: c.primary, fontSize: context.rFontSize(14)),
            decoration: InputDecoration(
              labelText: 'Тоо хэмжээ',
              labelStyle: TextStyle(color: c.mutedForeground, fontSize: context.rFontSize(14)),
              filled: true,
              fillColor: c.secondary.withOpacity(0.3),
              errorText: _validationError,
              errorStyle: TextStyle(fontSize: context.rFontSize(12)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.rRadius(12)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.rRadius(12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(context.rRadius(12)),
                borderSide: BorderSide(color: c.brandGreen.withOpacity(0.5), width: 1.5),
              ),
              prefixIcon: Icon(Icons.calculate_rounded, color: c.brandGreen, size: context.rIconSize(20)),
            ),
          ),
          SizedBox(height: context.rSpacing(24)),
          SizedBox(
            width: double.infinity,
            height: context.rSpacing(50),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.brandGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.rRadius(12))),
                disabledBackgroundColor: c.brandGreen.withOpacity(0.3),
              ),
              onPressed: _selectedBaraa == null || _tooController.text.isEmpty || _validationError != null ? null : _save,
              child: Text(
                'Сонгох',
                style: TextStyle(
                  fontSize: context.rFontSize(16),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
