
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:vector_math/vector_math_64.dart';


/// The possible states of a [MultiScaleGestureRecognizer].
enum _MultiScaleState {
  /// The recognizer is ready to start recognizing a gesture.
  ready,

  /// The sequence of pointer events seen thus far is consistent with a scale
  /// gesture but the gesture has not been accepted definitively.
  possible,

  /// The sequence of pointer events seen thus far has been accepted
  /// definitively as a scale gesture.
  accepted,

  /// The sequence of pointer events seen thus far has been accepted
  /// definitively as a scale gesture and the pointers established a focal point
  /// and initial scale.
  started,
}

// /// Details for [GestureMultiScaleStartCallback].
// class MultiScaleStartDetails {
//   /// Creates details for [GestureMultiScaleStartCallback].
//   ///
//   /// The [focalPoint] argument must not be null.
//   MultiScaleStartDetails({ this.focalPoint = Offset.zero, Offset? localFocalPoint, this.pointerCount = 0 })
//       : localFocalPoint = localFocalPoint ?? focalPoint;
//
//   /// The initial focal point of the pointers in contact with the screen.
//   ///
//   /// Reported in global coordinates.
//   ///
//   /// See also:
//   ///
//   ///  * [localFocalPoint], which is the same value reported in local
//   ///    coordinates.
//   final Offset focalPoint;
//
//   /// The initial focal point of the pointers in contact with the screen.
//   ///
//   /// Reported in local coordinates. Defaults to [focalPoint] if not set in the
//   /// constructor.
//   ///
//   /// See also:
//   ///
//   ///  * [focalPoint], which is the same value reported in global
//   ///    coordinates.
//   final Offset localFocalPoint;
//
//   /// The number of pointers being tracked by the gesture recognizer.
//   ///
//   /// Typically this is the number of fingers being used to pan the widget using the gesture
//   /// recognizer.
//   final int pointerCount;
//
//   @override
//   String toString() => 'MultiScaleStartDetails(focalPoint: $focalPoint, localFocalPoint: $localFocalPoint, pointersCount: $pointerCount)';
// }

/// Details for [GestureMultiScaleUpdateCallback].
class MultiScaleUpdateDetails {
  /// Creates details for [GestureMultiScaleUpdateCallback].
  ///
  /// The [scale], [rotation] arguments must not be null.
  /// The [scale] argument must be greater than or equal to zero.
  MultiScaleUpdateDetails({
    this.scale = 1.0,
    this.rotation = 0.0,
  }) : assert(scale >= 0.0);

  /// The scale implied by the average distance between the pointers in contact
  /// with the screen.
  ///
  /// This value must be greater than or equal to zero.
  final double scale;

  /// The angle implied by the first two pointers to enter in contact with
  /// the screen.
  ///
  /// Expressed in radians.
  final double rotation;

  @override
  String toString() => 'MultiScaleUpdateDetails('
      'scale: $scale,'
      ' rotation: $rotation';
}

/// Details for [GestureMultiScaleEndCallback].
class MultiScaleEndDetails {
  /// Creates details for [GestureMultiScaleEndCallback].
  ///
  /// The [velocity] argument must not be null.
  MultiScaleEndDetails({ this.velocity = Velocity.zero});

  /// The velocity of the last pointer to be lifted off of the screen.
  final Velocity velocity;

  @override
  String toString() => 'MultiScaleEndDetails(velocity: $velocity';
}

/// Signature for when the pointers in contact with the screen have established
/// a focal point and initial scale of 1.0.
typedef GestureMultiScaleStartCallback = void Function();

/// Signature for when the pointers in contact with the screen have indicated a
/// new focal point and/or scale.
typedef GestureMultiScaleUpdateCallback = void Function(MultiScaleUpdateDetails details);

/// Signature for when the pointers are no longer in contact with the screen.
typedef GestureMultiScaleEndCallback = void Function(MultiScaleEndDetails details);

bool _isFlingGesture(Velocity velocity) {
  final double speedSquared = velocity.pixelsPerSecond.distanceSquared;
  return speedSquared > kMinFlingVelocity * kMinFlingVelocity;
}


/// Defines a line between two pointers on screen.
///
/// [_LineBetweenPointers] is an abstraction of a line between two pointers in
/// contact with the screen. Used to track the rotation of a scale gesture.
class _LineBetweenPointers {

  /// Creates a [_LineBetweenPointers]. None of the [pointerStartLocation], [pointerStartId]
  /// [pointerEndLocation] and [pointerEndId] must be null. [pointerStartId] and [pointerEndId]
  /// should be different.
  _LineBetweenPointers({
    this.pointerStartLocation = Offset.zero,
    this.pointerStartId = 0,
    this.pointerEndLocation = Offset.zero,
    this.pointerEndId = 1,
  }) : assert(pointerStartId != pointerEndId);

  // The location and the id of the pointer that marks the start of the line.
  final Offset pointerStartLocation;
  final int pointerStartId;

  // The location and the id of the pointer that marks the end of the line.
  final Offset pointerEndLocation;
  final int pointerEndId;

}


/// Recognizes a scale gesture.
///
/// [MultiScaleGestureRecognizer] tracks the pointers in contact with the screen and
/// calculates their focal point, indicated scale, and rotation. When a focal
/// pointer is established, the recognizer calls [onStart]. As the focal point,
/// scale, rotation change, the recognizer calls [onUpdate]. When the pointers
/// are no longer in contact with the screen, the recognizer calls [onEnd].
class MultiScaleGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Create a gesture recognizer for interactions intended for scaling content.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  MultiScaleGestureRecognizer({
    Object? debugOwner,
    Set<PointerDeviceKind>? supportedDevices,
    this.dragStartBehavior = DragStartBehavior.down,
  }) : super(
        debugOwner: debugOwner,
        supportedDevices: supportedDevices,
      );

  /// Determines what point is used as the starting point in all calculations
  /// involving this gesture.
  ///
  /// When set to [DragStartBehavior.down], the scale is calculated starting
  /// from the position where the pointer first contacted the screen.
  ///
  /// When set to [DragStartBehavior.start], the scale is calculated starting
  /// from the position where the scale gesture began. The scale gesture may
  /// begin after the time that the pointer first contacted the screen if there
  /// are multiple listeners competing for the gesture. In that case, the
  /// gesture arena waits to determine whether or not the gesture is a scale
  /// gesture before giving the gesture to this GestureRecognizer. This happens
  /// in the case of nested GestureDetectors, for example.
  ///
  /// Defaults to [DragStartBehavior.down].
  ///
  /// See also:
  ///
  /// * https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation,
  ///   which provides more information about the gesture arena.
  DragStartBehavior dragStartBehavior;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  ///
  /// This won't be called until the gesture arena has determined that this
  /// GestureRecognizer has won the gesture.
  ///
  /// See also:
  ///
  /// * https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation,
  ///   which provides more information about the gesture arena.
  GestureMultiScaleStartCallback? onStart;

  /// The pointers in contact with the screen have indicated a new focal point
  /// and/or scale.
  GestureMultiScaleUpdateCallback? onUpdate;

  /// The pointers are no longer in contact with the screen.
  GestureMultiScaleEndCallback? onEnd;

  _MultiScaleState _state = _MultiScaleState.ready;

  _LineBetweenPointers? _initialLine;
  _LineBetweenPointers? _currentLine;
  late Map<int, Offset> _initialPointerLocations;
  late Map<int, Offset> _pointerLocations;
  late List<int> _pointerQueue; // A queue to sort pointers in order of entrance
  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  double get _scaleFactor {
    final _initialSpan = (_initialPointerLocations[_pointerQueue[0]]!
        - _initialPointerLocations[_pointerQueue[1]]!).distance;
    final _currentSpan = (_pointerLocations[_pointerQueue[0]]! - _pointerLocations[_pointerQueue[1]]!).distance;
    return _initialSpan > 0.0 ? _currentSpan / _initialSpan : 1.0;
  }

  double _computeRotationFactor() {
    if (_initialLine == null || _currentLine == null) {
      return 0.0;
    }
    final double fx = _initialLine!.pointerStartLocation.dx;
    final double fy = _initialLine!.pointerStartLocation.dy;
    final double sx = _initialLine!.pointerEndLocation.dx;
    final double sy = _initialLine!.pointerEndLocation.dy;

    final double nfx = _currentLine!.pointerStartLocation.dx;
    final double nfy = _currentLine!.pointerStartLocation.dy;
    final double nsx = _currentLine!.pointerEndLocation.dx;
    final double nsy = _currentLine!.pointerEndLocation.dy;

    final double angle1 = math.atan2(fy - sy, fx - sx);
    final double angle2 = math.atan2(nfy - nsy, nfx - nsx);

    return angle2 - angle1;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _velocityTrackers[event.pointer] = VelocityTracker.withKind(event.kind);
    if (_state == _MultiScaleState.ready) {
      _state = _MultiScaleState.possible;
      _pointerLocations = <int, Offset>{};
      _initialPointerLocations = <int, Offset>{};
      _pointerQueue = <int>[];
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _MultiScaleState.ready);
    bool didChangeConfiguration = false;
    bool shouldStartIfAccepted = false;
    if (event is PointerMoveEvent) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer]!;
      if (!event.synthesized)
        tracker.addPosition(event.timeStamp, event.position);
      _pointerLocations[event.pointer] = event.position;
      shouldStartIfAccepted = true;
    } else if (event is PointerDownEvent) {
      _initialPointerLocations[event.pointer] = event.position;
      _pointerLocations[event.pointer] = event.position;
      _pointerQueue.add(event.pointer);
      didChangeConfiguration = true;
      shouldStartIfAccepted = true;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointerLocations.remove(event.pointer);
      _initialPointerLocations.remove(event.pointer);
      _pointerQueue.remove(event.pointer);
      didChangeConfiguration = true;
    }

    if (_pointerQueue.length == 2) {
      _updateLines();
    }

    if ((!didChangeConfiguration || _reconfigure(event.pointer)) && _pointerQueue.length == 2) {
      _advanceStateMachine(shouldStartIfAccepted, event.kind);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  /// Updates [_initialLine] and [_currentLine] accordingly to the situation of
  /// the registered pointers.
  void _updateLines() {
    /// In case of just one pointer registered, reconfigure [_initialLine]
    if (_initialLine != null &&
        _initialLine!.pointerStartId == _pointerQueue[0] &&
        _initialLine!.pointerEndId == _pointerQueue[1]) {
      /// Rotation updated, set the [_currentLine]
      _currentLine = _LineBetweenPointers(
        pointerStartId: _pointerQueue[0],
        pointerStartLocation: _pointerLocations[_pointerQueue[0]]!,
        pointerEndId: _pointerQueue[1],
        pointerEndLocation: _pointerLocations[_pointerQueue[1]]!,
      );
    } else {
      /// A new rotation process is on the way, set the [_initialLine]
      _initialLine = _LineBetweenPointers(
        pointerStartId: _pointerQueue[0],
        pointerStartLocation: _pointerLocations[_pointerQueue[0]]!,
        pointerEndId: _pointerQueue[1],
        pointerEndLocation: _pointerLocations[_pointerQueue[1]]!,
      );
      _currentLine = _initialLine;
    }
  }

  bool _reconfigure(int pointer) {
    if (_state == _MultiScaleState.started) {
      if (onEnd != null) {
        final VelocityTracker tracker = _velocityTrackers[pointer]!;

        Velocity velocity = tracker.getVelocity();
        if (_isFlingGesture(velocity)) {
          final Offset pixelsPerSecond = velocity.pixelsPerSecond;
          if (pixelsPerSecond.distanceSquared > kMaxFlingVelocity * kMaxFlingVelocity) {
            velocity = Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * kMaxFlingVelocity);
          }
          invokeCallback<void>('onEnd', () => onEnd!(MultiScaleEndDetails(velocity: velocity)));
        } else {
          invokeCallback<void>('onEnd', () => onEnd!(MultiScaleEndDetails()));
        }
      }
      _state = _MultiScaleState.accepted;
      return false;
    }
    return true;
  }

  void _advanceStateMachine(bool shouldStartIfAccepted, PointerDeviceKind pointerDeviceKind) {
    if (_state == _MultiScaleState.ready) {
      _state = _MultiScaleState.possible;
    }

    if (_state == _MultiScaleState.possible) {
      final firstPointDelta = _pointerLocations[_pointerQueue[0]]! - _initialPointerLocations[_pointerQueue[0]]!;
      final secondPointDelta = _pointerLocations[_pointerQueue[1]]! - _initialPointerLocations[_pointerQueue[1]]!;

      if ((firstPointDelta.dx.sign != secondPointDelta.dx.sign
          && (firstPointDelta.dx.abs() + secondPointDelta.dx.abs()) > computeScaleSlop(pointerDeviceKind))
          || (firstPointDelta.dy.sign != secondPointDelta.dy.sign
              && (firstPointDelta.dy.abs() + secondPointDelta.dy.abs()) > computeScaleSlop(pointerDeviceKind))) {
        resolve(GestureDisposition.accepted);
        _state = _MultiScaleState.accepted;
      }
    }

    if (_state == _MultiScaleState.accepted && shouldStartIfAccepted) {
      _state = _MultiScaleState.started;
      _dispatchOnStartCallbackIfNeeded();
    }

    if (_state == _MultiScaleState.started && onUpdate != null) {
      invokeCallback<void>('onUpdate', () {
        onUpdate!(MultiScaleUpdateDetails(
          scale: _scaleFactor,
          rotation: _computeRotationFactor(),
        ));
      });
    }
  }

  void _dispatchOnStartCallbackIfNeeded() {
    assert(_state == _MultiScaleState.started);
    if (onStart != null) {
      invokeCallback<void>('onStart', () {
        onStart!();
      });
    }
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch (_state) {
      case _MultiScaleState.possible:
        resolve(GestureDisposition.rejected);
        break;
      case _MultiScaleState.ready:
        assert(false); // We should have not seen a pointer yet
        break;
      case _MultiScaleState.accepted:
        break;
      case _MultiScaleState.started:
        assert(false); // We should be in the accepted state when user is done
        break;
    }
    _state = _MultiScaleState.ready;
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }

  @override
  String get debugDescription => 'scale';
}
