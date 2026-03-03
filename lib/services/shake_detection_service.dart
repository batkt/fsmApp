import 'dart:math';
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Service to detect device shake gestures
class ShakeDetectionService {
  static StreamSubscription<AccelerometerEvent>? _subscription;
  static VoidCallback? _onShake;
  static bool _isListening = false;

  // Shake detection parameters - tuned so typical strong shakes (17–25 magnitude)
  // will reliably trigger the help modal.
  static const double _shakeThreshold =
      17.0; // Acceleration threshold (slightly sensitive)
  static const int _shakeWindowMs =
      1200; // Time window for counting shakes (ms)
  static const int _minShakeCount =
      2; // Require at least 2 strong shakes within the window
  static const int _debounceMs = 4000; // Minimum time between triggers (ms)

  static DateTime? _lastShakeTime;
  static int _shakeCount = 0;
  static DateTime? _windowStart;

  /// Start listening for shake gestures
  static void startListening(VoidCallback onShake) {
    if (_isListening) {
      debugPrint('[ShakeDetection] Already listening, stopping first');
      stopListening();
    }

    debugPrint('[ShakeDetection] Starting shake detection');
    _onShake = onShake;
    _isListening = true;
    _lastShakeTime = null;
    _shakeCount = 0;
    _windowStart = null;

    try {
      _subscription = accelerometerEventStream().listen(
        (event) {
          _handleAccelerometerEvent(event);
        },
        onError: (error) {
          debugPrint('[ShakeDetection] Stream error: $error');
          debugPrint(
            '[ShakeDetection] ⚠️ If you see MissingPluginException, please do a full rebuild (not hot restart)',
          );
          _isListening = false;
        },
        cancelOnError: false,
      );
      debugPrint(
        '[ShakeDetection] ✅ Accelerometer stream started successfully',
      );
    } catch (e) {
      debugPrint('[ShakeDetection] ❌ Failed to start: $e');
      debugPrint(
        '[ShakeDetection] ⚠️ Please do a full rebuild: flutter run (not hot restart)',
      );
      _isListening = false;
    }
  }

  /// Stop listening for shake gestures
  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _onShake = null;
    _lastShakeTime = null;
    _shakeCount = 0;
    _windowStart = null;
  }

  static void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Calculate acceleration magnitude
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final now = DateTime.now();

    // Debug: log acceleration only when significant (reduce log spam)
    // Removed frequent logging to reduce console noise

    // Check if acceleration exceeds threshold
    if (magnitude > _shakeThreshold) {
      debugPrint(
        '[ShakeDetection] Threshold exceeded! Magnitude: ${magnitude.toStringAsFixed(2)}',
      );
      if (_windowStart == null) {
        // Start new shake window
        _windowStart = now;
        _shakeCount = 1;
        debugPrint('[ShakeDetection] Starting new shake window');
      } else {
        // Check if still within window
        final elapsed = now.difference(_windowStart!).inMilliseconds;
        if (elapsed < _shakeWindowMs) {
          _shakeCount++;
          debugPrint(
            '[ShakeDetection] Shake count increased to $_shakeCount (elapsed: ${elapsed}ms)',
          );
        } else {
          // Window expired, start new one
          _windowStart = now;
          _shakeCount = 1;
          debugPrint('[ShakeDetection] Window expired, starting new window');
        }
      }

      // Check if we have enough shakes
      if (_shakeCount >= _minShakeCount) {
        final timeSinceLastShake = _lastShakeTime != null
            ? now.difference(_lastShakeTime!).inMilliseconds
            : double.infinity;

        debugPrint(
          '[ShakeDetection] Enough shakes detected! Count: $_shakeCount, time since last: ${timeSinceLastShake}ms',
        );

        // Prevent multiple rapid triggers (debounce)
        if (timeSinceLastShake > _debounceMs) {
          debugPrint('[ShakeDetection] ✅ Shake detected! Triggering callback');
          _lastShakeTime = now;
          _shakeCount = 0;
          _windowStart = null;
          if (_onShake != null) {
            debugPrint('[ShakeDetection] Calling callback...');
            _onShake!();
            debugPrint('[ShakeDetection] Cooldown active for ${_debounceMs}ms');
          } else {
            debugPrint('[ShakeDetection] ⚠️ Callback is null!');
          }
        } else {
          debugPrint(
            '[ShakeDetection] Shake detected but debounced (${timeSinceLastShake}ms since last, need ${_debounceMs}ms)',
          );
        }
      }
    } else {
      // Reset if no significant acceleration
      final elapsed = _windowStart != null
          ? now.difference(_windowStart!).inMilliseconds
          : 0;

      if (elapsed > _shakeWindowMs) {
        _windowStart = null;
        _shakeCount = 0;
      }
    }
  }
}
