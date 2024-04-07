part of 'lifecycle.dart';

final Map<Lifecycle, Set<LifecycleAttachCallback>> _attachCallbacks = {};
final Map<Lifecycle, Set<LifecycleDetachCallback>> _detachCallback = {};

extension LifecycleCallback on Lifecycle {
  void onAttach(LifecycleOwner owner) {
    if (_attachCallbacks.containsKey(this)) {
      final callbacks =
          Set<LifecycleAttachCallback>.of(_attachCallbacks[this]!);
      for (var c in callbacks) {
        c.onAttach(this, owner);
      }
    }
  }

  void onDetach(LifecycleOwner owner) {
    if (_detachCallback.containsKey(this)) {
      final callbacks = Set<LifecycleDetachCallback>.of(_detachCallback[this]!);
      for (var c in callbacks) {
        c.onDetach(this, owner);
      }
    }
  }

  void registerLifecycleAttachCallbacks(LifecycleAttachCallback callback) {
    assert(currentState > LifecycleState.destroyed,
        'Must register after the LifecycleState.initialized.');

    var callbacks = _attachCallbacks[this];
    if (callbacks == null) {
      callbacks = {};
      _attachCallbacks[this] = callbacks;
      addObserver(LifecycleObserver.onEventDestroy(
          (owner) => _attachCallbacks.remove(owner.lifecycle)));
    }
    callbacks.add(callback);
  }

  void registerLifecycleDetachCallbacks(LifecycleDetachCallback callback) {
    assert(currentState > LifecycleState.destroyed,
        'Must register after the LifecycleState.initialized.');
    var callbacks = _detachCallback[this];
    if (callbacks == null) {
      callbacks = {};
      _detachCallback[this] = callbacks;
      addObserver(LifecycleObserver.onEventDestroy(
          (owner) => _detachCallback.remove(owner.lifecycle)));
    }
    callbacks.add(callback);
  }
}

abstract interface class LifecycleAttachCallback {
  void onAttach(Lifecycle parent, LifecycleOwner childOwner);
}

abstract interface class LifecycleDetachCallback {
  void onDetach(Lifecycle parent, LifecycleOwner childOwner);
}
