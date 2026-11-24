import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:geolocator/geolocator.dart';

import '../screens/zuvshuurul_screen.dart';
import '../services/irts_service.dart';

const _emerald = Color(0xFF059669);
const _ulaanbaatar = LatLng(47.9185, 106.9176);

/// Ирцийн газрын зураг (OpenStreetMap): миний байршил, оффисын бүс,
/// оффис хүртэлх зай. Түлхүүр шаардахгүй.
class IrtsGazriinZurag extends StatefulWidget {
  const IrtsGazriinZurag({super.key, this.doodZai = 0});
  /// Доорх товч/самбарт дарагдахгүй байхаар баруун талын товчнуудыг дээшлүүлэх зай
  final double doodZai;
  @override
  State<IrtsGazriinZurag> createState() => _IrtsGazriinZuragState();
}

class _IrtsGazriinZuragState extends State<IrtsGazriinZurag> {
  final _map = MapController();
  LatLng? _bi;
  LatLng? _office;
  double _radius = 150;
  bool _belen = false;

  @override
  void initState() {
    super.initState();
    _achaallaya();
  }

  Future<void> _achaallaya() async {
    try {
      final o = await IrtsService.officeBairshil();
      if (o != null && o['latitude'] is num && o['longitude'] is num && o['idevkhitei'] != false) {
        _office = LatLng((o['latitude'] as num).toDouble(), (o['longitude'] as num).toDouble());
        _radius = (o['radiusMetr'] as num?)?.toDouble() ?? 150;
      }
    } catch (_) {}
    final p = await IrtsService.minnyBairshil();
    if (p != null) _bi = LatLng(p.latitude, p.longitude);
    if (!mounted) return;
    setState(() {});
    if (_belen) _map.move(_bi ?? _office ?? _ulaanbaatar, 16);
  }

  double? get _zai => _bi != null && _office != null ? const Distance().as(LengthUnit.Meter, _bi!, _office!) : null;

  @override
  Widget build(BuildContext context) {
    final zai = _zai;
    final dotor = zai != null && zai <= _radius;
    return Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _bi ?? _office ?? _ulaanbaatar,
          initialZoom: 16,
          onMapReady: () => _belen = true,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.batkt.workease',
          ),
          if (_office != null)
            CircleLayer(circles: [
              CircleMarker(
                point: _office!,
                radius: _radius,
                useRadiusInMeter: true,
                color: _emerald.withValues(alpha: 0.12),
                borderColor: _emerald.withValues(alpha: 0.7),
                borderStrokeWidth: 2,
              ),
            ]),
          MarkerLayer(markers: [
            if (_office != null)
              Marker(
                point: _office!,
                width: 36,
                height: 36,
                child: const Icon(Icons.apartment_rounded, color: _emerald, size: 30),
              ),
            if (_bi != null)
              Marker(
                point: _bi!,
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.4), blurRadius: 10)],
                  ),
                ),
              ),
          ]),
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomLeft,
            attributions: [TextSourceAttribution('© OpenStreetMap')],
          ),
        ],
      ),
      // Оффис хүртэлх зай
      if (zai != null)
        Positioned(
          // Статус мөр + дээд мөрийн (барилга, хонх) доор
          top: MediaQuery.paddingOf(context).top + 62,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(dotor ? Icons.check_circle_rounded : Icons.info_rounded,
                    size: 16, color: dotor ? _emerald : const Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  dotor ? 'Оффисын бүсэд байна' : 'Бүсээс гадуур, оффисоос ${_zaiTekst(zai)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                ),
              ]),
            ),
          ),
        ),
      // Баруун талын товчнууд
      Positioned(
        right: 12,
        bottom: widget.doodZai + 12,
        child: Column(children: [
          _DuguiTovch(
            icon: Icons.my_location_rounded,
            tailbar: 'Миний байршил',
            onTap: () async {
              // Утасны тохиргоог дагана: асуух / Тохиргоо нээх / байршил асаах
              final t = await bairshliinTuluv();
              if (t == ZTuluv.tokhirgoond) return Geolocator.openAppSettings().then((_) {});
              if (t == ZTuluv.unraasan) return Geolocator.openLocationSettings().then((_) {});
              if (t == ZTuluv.asuuj_bolno) await Geolocator.requestPermission();
              final p = await IrtsService.minnyBairshil();
              if (p != null) {
                setState(() => _bi = LatLng(p.latitude, p.longitude));
                _map.move(_bi!, 17);
              }
            },
          ),
          if (_office != null) ...[
            const SizedBox(height: 10),
            _DuguiTovch(icon: Icons.apartment_rounded, tailbar: 'Оффис', onTap: () => _map.move(_office!, 17)),
          ],
        ]),
      ),
    ]);
  }

  static String _zaiTekst(double m) {
    if (m >= 100000) return '${(m / 1000).round()} км';
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} км';
    return '${m.round()} м';
  }
}

class _DuguiTovch extends StatelessWidget {
  const _DuguiTovch({required this.icon, required this.tailbar, required this.onTap});
  final IconData icon;
  final String tailbar;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tailbar,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        fixedSize: const Size(48, 48),
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      icon: Icon(icon, color: _emerald, size: 22),
    );
  }
}
