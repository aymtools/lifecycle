part of 'lifecycle_registry.dart';

typedef LifecycleOwnerAttachCallback = void Function(
    Lifecycle? parent, LifecycleOwner childOwner);
typedef LifecycleOwnerDetachCallback = void Function(
    Lifecycle parent, LifecycleOwner childOwner);
typedef LifecycleRegistryAttachCallback = void Function(
    Lifecycle parent, LifecycleObserverRegistry childOwner);
typedef LifecycleRegistryDetachCallback = void Function(
    Lifecycle parent, LifecycleObserverRegistry childOwner);

///全局的lifecycle互相绑定回调处理
class LifecycleCallbacks {
  LifecycleCallbacks._();

  final Set<LifecycleOwnerAttachCallback> _ownerAttachCallbacks = {};
  final Set<LifecycleOwnerDetachCallback> _ownerDetachCallbacks = {};
  final Set<LifecycleRegistryAttachCallback> _registryAttachCallbacks = {};
  final Set<LifecycleRegistryDetachCallback> _registryDetachCallbacks = {};

  static final LifecycleCallbacks _instance = LifecycleCallbacks._();

  static LifecycleCallbacks get instance => _instance;

  void addOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    _ownerAttachCallbacks.add(callback);
  }

  void addOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    _ownerDetachCallbacks.add(callback);
  }

  void addRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    _registryAttachCallbacks.add(callback);
  }

  void addRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    _registryDetachCallbacks.add(callback);
  }

  void _onAttach(Lifecycle? parent, Object child) {
    if (child is LifecycleOwner && _ownerAttachCallbacks.isNotEmpty) {
      final callbacks =
          Set<LifecycleOwnerAttachCallback>.of(_ownerAttachCallbacks);
      for (var c in callbacks) {
        c(parent, child);
      }
    }
    if (parent != null &&
        child is LifecycleObserverRegistry &&
        _registryAttachCallbacks.isNotEmpty) {
      final callbacks =
          Set<LifecycleRegistryAttachCallback>.of(_registryAttachCallbacks);
      for (var c in callbacks) {
        c(parent, child);
      }
    }
  }

  void _onDetach(Lifecycle parent, Object child) {
    if (child is LifecycleOwner && _ownerDetachCallbacks.isNotEmpty) {
      final callbacks =
          Set<LifecycleOwnerDetachCallback>.of(_ownerDetachCallbacks);
      for (var c in callbacks) {
        c(parent, child);
      }
    }
    if (child is LifecycleObserverRegistry &&
        _registryDetachCallbacks.isNotEmpty) {
      final callbacks =
          Set<LifecycleRegistryDetachCallback>.of(_registryDetachCallbacks);
      for (var c in callbacks) {
        c(parent, child);
      }
    }
  }
}

class _TargetLifecycleCallback {
  final Set<LifecycleOwnerAttachCallback> _ownerAttachCallbacks = {};
  final Set<LifecycleOwnerDetachCallback> _ownerDetachCallbacks = {};
  final Set<LifecycleRegistryAttachCallback> _registryAttachCallbacks = {};
  final Set<LifecycleRegistryDetachCallback> _registryDetachCallbacks = {};
  final LifecycleOwner owner;

  _TargetLifecycleCallback({required this.owner}) {
    LifecycleCallbacks.instance.addOwnerAttachCallback(onOwnerAttach);
    LifecycleCallbacks.instance.addOwnerDetachCallback(onOwnerDetach);
    LifecycleCallbacks.instance.addRegistryAttachCallback(onRegistryAttach);
    LifecycleCallbacks.instance.addRegistryDetachCallback(onRegistryDetach);

    owner.lifecycle.addObserver(LifecycleObserver.onEventDestroy((owner) {
      _targetCallback.remove(owner);
      LifecycleCallbacks.instance._ownerAttachCallbacks.remove(onOwnerAttach);
      LifecycleCallbacks.instance._ownerDetachCallbacks.remove(onOwnerDetach);
      LifecycleCallbacks.instance._registryAttachCallbacks
          .remove(onRegistryAttach);
      LifecycleCallbacks.instance._registryDetachCallbacks
          .remove(onRegistryDetach);
    }));
  }

  void onOwnerAttach(Lifecycle? parent, LifecycleOwner childOwner) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_ownerAttachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childOwner);
    }
  }

  void onOwnerDetach(Lifecycle parent, LifecycleOwner childOwner) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_ownerDetachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childOwner);
    }
  }

  void onRegistryAttach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_registryAttachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childRegistry);
    }
  }

  void onRegistryDetach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_registryDetachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childRegistry);
    }
  }
}

final Map<LifecycleOwner, _TargetLifecycleCallback> _targetCallback = {};

extension LifecycleCallbackManager on LifecycleOwner {
  void addOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    assert(lifecycle.currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');
    _targetCallback
        .putIfAbsent(this, () => _TargetLifecycleCallback(owner: this))
        ._ownerAttachCallbacks
        .add(callback);
  }

  void addOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    assert(lifecycle.currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');
    _targetCallback
        .putIfAbsent(this, () => _TargetLifecycleCallback(owner: this))
        ._ownerDetachCallbacks
        .add(callback);
  }

  void addRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    assert(lifecycle.currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');
    _targetCallback
        .putIfAbsent(this, () => _TargetLifecycleCallback(owner: this))
        ._registryAttachCallbacks
        .add(callback);
  }

  void addRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    assert(lifecycle.currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');
    _targetCallback
        .putIfAbsent(this, () => _TargetLifecycleCallback(owner: this))
        ._registryDetachCallbacks
        .add(callback);
  }
}
