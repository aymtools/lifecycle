part of 'lifecycle.dart';

typedef LifecycleOwnerAttachCallback = void Function(
    Lifecycle? parent, LifecycleOwner childOwner);
typedef LifecycleOwnerDetachCallback = void Function(
    Lifecycle parent, LifecycleOwner childOwner);
typedef LifecycleRegistryAttachCallback = void Function(
    Lifecycle parent, ILifecycleRegistry childOwner);
typedef LifecycleRegistryDetachCallback = void Function(
    Lifecycle parent, ILifecycleRegistry childOwner);

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

  void removeOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    _ownerAttachCallbacks.remove(callback);
  }

  void addOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    _ownerDetachCallbacks.add(callback);
  }

  void removeOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    _ownerDetachCallbacks.remove(callback);
  }

  void addRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    _registryAttachCallbacks.add(callback);
  }

  void removeRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    _registryAttachCallbacks.remove(callback);
  }

  void addRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    _registryDetachCallbacks.add(callback);
  }

  void removeRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    _registryDetachCallbacks.remove(callback);
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
        child is ILifecycleRegistry &&
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
    if (child is ILifecycleRegistry && _registryDetachCallbacks.isNotEmpty) {
      final callbacks =
          Set<LifecycleRegistryDetachCallback>.of(_registryDetachCallbacks);
      for (var c in callbacks) {
        c(parent, child);
      }
    }
  }
}

class _LifecycleToTargetCallbacks {
  final Set<LifecycleOwnerAttachCallback> _ownerAttachCallbacks = {};
  final Set<LifecycleOwnerDetachCallback> _ownerDetachCallbacks = {};
  final Set<LifecycleRegistryAttachCallback> _registryAttachCallbacks = {};
  final Set<LifecycleRegistryDetachCallback> _registryDetachCallbacks = {};
  final LifecycleOwner owner;
  bool _isDisposed = false;

  _LifecycleToTargetCallbacks({required this.owner}) {
    LifecycleCallbacks.instance.addOwnerAttachCallback(onOwnerAttach);
    LifecycleCallbacks.instance.addOwnerDetachCallback(onOwnerDetach);
    LifecycleCallbacks.instance.addRegistryAttachCallback(onRegistryAttach);
    LifecycleCallbacks.instance.addRegistryDetachCallback(onRegistryDetach);

    owner.addLifecycleObserver(LifecycleObserver.eventDestroy(_dispose));
  }

  void _dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _targetCallback.remove(owner);
    LifecycleCallbacks.instance._ownerAttachCallbacks.remove(onOwnerAttach);
    LifecycleCallbacks.instance._ownerDetachCallbacks.remove(onOwnerDetach);
    LifecycleCallbacks.instance._registryAttachCallbacks
        .remove(onRegistryAttach);
    LifecycleCallbacks.instance._registryDetachCallbacks
        .remove(onRegistryDetach);
  }

  void onOwnerAttach(Lifecycle? parent, LifecycleOwner childOwner) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_ownerAttachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childOwner);
    }
  }

  void onOwnerDetach(Lifecycle parent, LifecycleOwner childOwner) {
    // if (childOwner == owner) {
    //   // 如果发生了切换 也会触发onOwnerDetach
    //   _dispose();
    //   return;
    // }
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_ownerDetachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childOwner);
    }
  }

  void onRegistryAttach(Lifecycle parent, ILifecycleRegistry childRegistry) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_registryAttachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childRegistry);
    }
  }

  void onRegistryDetach(Lifecycle parent, ILifecycleRegistry childRegistry) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_registryDetachCallbacks);
    for (var callback in callbacks) {
      callback(parent, childRegistry);
    }
  }

  factory _LifecycleToTargetCallbacks.of(LifecycleOwner owner) {
    return _targetCallback.putIfAbsent(
        owner, () => _LifecycleToTargetCallbacks(owner: owner));
  }

  static _LifecycleToTargetCallbacks? maybeOf(LifecycleOwner owner) {
    return _targetCallback[owner];
  }

  void addOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    _ownerAttachCallbacks.add(callback);
  }

  void removeOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    _ownerAttachCallbacks.remove(callback);
  }

  void addOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    _ownerDetachCallbacks.add(callback);
  }

  void removeOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    _ownerDetachCallbacks.remove(callback);
  }

  void addRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    _registryAttachCallbacks.add(callback);
  }

  void removeRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    _registryAttachCallbacks.remove(callback);
  }

  void addRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    _registryDetachCallbacks.add(callback);
  }

  void removeRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    _registryDetachCallbacks.remove(callback);
  }
}

//已经基于了lifecycle的自动移除不用担心内存泄露
final Map<LifecycleOwner, _LifecycleToTargetCallbacks> _targetCallback = {};

extension LifecycleCallbackManager on LifecycleOwner {
  void addOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    assert(currentLifecycleState > LifecycleState.destroyed,
        'Must add after the LifecycleState.destroyed.');
    _LifecycleToTargetCallbacks.of(this).addOwnerAttachCallback(callback);
  }

  void removeOwnerAttachCallback(LifecycleOwnerAttachCallback callback) {
    _LifecycleToTargetCallbacks.maybeOf(this)
        ?.removeOwnerAttachCallback(callback);
  }

  void addOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    assert(currentLifecycleState > LifecycleState.destroyed,
        'Must add after the LifecycleState.destroyed.');
    _LifecycleToTargetCallbacks.of(this).addOwnerDetachCallback(callback);
  }

  void removeOwnerDetachCallback(LifecycleOwnerDetachCallback callback) {
    _LifecycleToTargetCallbacks.maybeOf(this)
        ?.removeOwnerDetachCallback(callback);
  }

  void addRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    assert(currentLifecycleState > LifecycleState.destroyed,
        'Must add after the LifecycleState.destroyed.');
    _LifecycleToTargetCallbacks.of(this).addRegistryAttachCallback(callback);
  }

  void removeRegistryAttachCallback(LifecycleRegistryAttachCallback callback) {
    _LifecycleToTargetCallbacks.maybeOf(this)
        ?.removeRegistryAttachCallback(callback);
  }

  void addRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    assert(currentLifecycleState > LifecycleState.destroyed,
        'Must add after the LifecycleState.destroyed.');
    _LifecycleToTargetCallbacks.of(this).addRegistryDetachCallback(callback);
  }

  void removeRegistryDetachCallback(LifecycleRegistryDetachCallback callback) {
    _LifecycleToTargetCallbacks.maybeOf(this)
        ?.removeRegistryDetachCallback(callback);
  }
}
