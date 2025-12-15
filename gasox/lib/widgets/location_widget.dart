import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationWidget extends StatefulWidget {
  final bool showTitle;
  final bool compact;

  const LocationWidget({
    super.key,
    this.showTitle = true,
    this.compact = false,
  });

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    await _locationService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoading = true);
    await _locationService.updateLocation();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _locationService.isLocationEnabled
                ? Icons.location_on
                : Icons.location_off,
            color:
                _locationService.isLocationEnabled ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _isLoading
                  ? 'Obteniendo...'
                  : _locationService.getLocationString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Manrope',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Card(
      color: Colors.black.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: _locationService.isLocationEnabled
                        ? Colors.orange
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ubicación Actual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado:',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                Text(
                  _locationService.isLocationEnabled
                      ? 'Habilitado'
                      : 'Deshabilitado',
                  style: TextStyle(
                    color: _locationService.isLocationEnabled
                        ? const Color(0xFF74FF77)
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Coordenadas:',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Manrope',
                  ),
                ),
                Flexible(
                  child: Text(
                    _isLoading
                        ? 'Obteniendo...'
                        : _locationService.getLocationString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Manrope',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Actualizar Ubicación',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
