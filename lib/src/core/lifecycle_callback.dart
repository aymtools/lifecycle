part of 'lifecycle.dart';

final Map<Lifecycle, Set<LifecycleAttachCallback>> _attachCallbacks = {};
final Map<Lifecycle, Set<LifecycleDetachCallback>> _detachCallback = {};

extension LifecycleCallback on Lifecycle {
  void onAttach(LifecycleObserverRegistry registry) {
    if (_attachCallbacks.containsKey(this)) {
      final callbacks =
          Set<LifecycleAttachCallback>.of(_attachCallbacks[this]!);
      for (var c in callbacks) {
        c.onRegistryAttach(this, registry);
        if (registry is LifecycleOwner) {
          c.onOwnerAttach(this, registry as LifecycleOwner);
        }
      }
    }
  }

  void onDetach(LifecycleObserverRegistry registry) {
    if (_detachCallback.containsKey(this)) {
      final callbacks = Set<LifecycleDetachCallback>.of(_detachCallback[this]!);
      for (var c in callbacks) {
        c.onRegistryDetach(this, registry);
        if (registry is LifecycleOwner) {
          c.onOwnerDetach(this, registry as LifecycleOwner);
        }
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

  void onRegistryAttach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry);
}

abstract class LifecycleDetachCallback {
  void onOwnerDetach(Lifecycle parent, LifecycleOwner childOwner);

  void onRegistryDetach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry);
}
