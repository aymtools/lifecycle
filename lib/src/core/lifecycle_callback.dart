part of 'lifecycle.dart';

final Map<Lifecycle, Set<LifecycleAttachCallback>> _attachCallbacks = {};
final Map<Lifecycle, Set<LifecycleDetachCallback>> _detachCallback = {};

extension LifecycleCallback on Lifecycle {
  void onAttach(LifecycleOwner owner) {
    if (_attachCallbacks.containsKey(this)) {
      final callbacks =
          Set<LifecycleAttachCallback>.of(_attachCallbacks[this]!);
      for (var c in callbacks) {
        c.onOwnerAttach(this, owner);
      }
    }
  }

  void onDetach(LifecycleOwner owner) {
    if (_detachCallback.containsKey(this)) {
      final callbacks = Set<LifecycleDetachCallback>.of(_detachCallback[this]!);
      for (var c in callbacks) {
        c.onOwnerDetach(this, owner);
      }
    }
  }

  void addLifecycleAttachCallbacks(LifecycleAttachCallback callback) {
    assert(currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');

    var callbacks = _attachCallbacks[this];
    if (callbacks == null) {
      callbacks = {};
      _attachCallbacks[this] = callbacks;
      addObserver(LifecycleObserver.onEventDestroy(
          (owner) => _attachCallbacks.remove(owner.lifecycle)));
    }
    callbacks.add(callback);
  }

  void addLifecycleDetachCallbacks(LifecycleDetachCallback callback) {
    assert(currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');
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

abstract class LifecycleAttachCallback {
  void onOwnerAttach(Lifecycle parent, LifecycleOwner childOwner);

  void onRegistryAttach(Lifecycle parent, LifecycleObserverRegistry childOwner);
}

abstract class LifecycleDetachCallback {
  void onOwnerDetach(Lifecycle parent, LifecycleOwner childOwner);

  void onRegistryDetach(Lifecycle parent, LifecycleOwner childOwner);
}
