part of 'lifecycle.dart';

abstract class LifecycleAttachCallback {
  void onOwnerAttach(Lifecycle? parent, LifecycleOwner childOwner);

  void onRegistryAttach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry);
}

abstract class LifecycleDetachCallback {
  void onOwnerDetach(Lifecycle? parent, LifecycleOwner childOwner);

  void onRegistryDetach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry);
}

abstract class LifecycleCallback
    implements LifecycleAttachCallback, LifecycleDetachCallback {}

///全局的lifecycle互相绑定回调处理
class LifecycleCallbacks {
  LifecycleCallbacks._();

  final Set<LifecycleCallback> _callbacks = {};

  static final LifecycleCallbacks _instance = LifecycleCallbacks._();

  static LifecycleCallbacks get instance => _instance;

  void addCallback(LifecycleCallback callback) => _callbacks.add(callback);

  void _onAttachRegistry(Lifecycle parent, LifecycleObserverRegistry registry) {
    final callbacks = Set<LifecycleCallback>.of(_callbacks);
    for (var c in callbacks) {
      c.onRegistryAttach(parent, registry);
      if (registry is LifecycleOwner) {
        c.onOwnerAttach(parent, registry as LifecycleOwner);
      }
    }
  }

  void _onAttachOwner(Lifecycle? parent, LifecycleOwner owner) {
    final callbacks = Set<LifecycleCallback>.of(_callbacks);
    for (var c in callbacks) {
      c.onOwnerAttach(parent, owner);
      if (owner is LifecycleObserverRegistry && parent != null) {
        c.onRegistryAttach(parent, owner as LifecycleObserverRegistry);
      }
    }
  }

  void _onDetachRegistry(Lifecycle parent, LifecycleObserverRegistry registry) {
    final callbacks = Set<LifecycleCallback>.of(_callbacks);
    for (var c in callbacks) {
      c.onRegistryDetach(parent, registry);
      if (registry is LifecycleOwner) {
        c.onOwnerDetach(parent, registry as LifecycleOwner);
      }
    }
  }

  void _onDetachOwner(Lifecycle? parent, LifecycleOwner owner) {
    final callbacks = Set<LifecycleCallback>.of(_callbacks);
    for (var c in callbacks) {
      c.onOwnerDetach(parent, owner);
      if (owner is LifecycleObserverRegistry && parent != null) {
        c.onRegistryDetach(parent, owner as LifecycleObserverRegistry);
      }
    }
  }
}

class _TargetLifecycleCallback implements LifecycleCallback {
  final Set<LifecycleAttachCallback> _attachCallbacks = {};
  final Set<LifecycleDetachCallback> _detachCallback = {};
  final LifecycleOwner owner;

  _TargetLifecycleCallback({required this.owner}) {
    LifecycleCallbacks.instance.addCallback(this);
    owner.lifecycle.addObserver(LifecycleObserver.onEventDestroy(
        (owner) => _targetCallback.remove(owner)));
  }

  @override
  void onOwnerAttach(Lifecycle? parent, LifecycleOwner childOwner) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_attachCallbacks);
    for (var callback in callbacks) {
      callback.onOwnerAttach(parent, childOwner);
    }
  }

  @override
  void onOwnerDetach(Lifecycle? parent, LifecycleOwner childOwner) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_detachCallback);
    for (var callback in callbacks) {
      callback.onOwnerDetach(parent, childOwner);
    }
  }

  @override
  void onRegistryAttach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_attachCallbacks);
    for (var callback in callbacks) {
      callback.onRegistryAttach(parent, childRegistry);
    }
  }

  @override
  void onRegistryDetach(
      Lifecycle parent, LifecycleObserverRegistry childRegistry) {
    if (parent != owner.lifecycle) return;
    final callbacks = Set.of(_detachCallback);
    for (var callback in callbacks) {
      callback.onRegistryDetach(parent, childRegistry);
    }
  }
}

final Map<LifecycleOwner, _TargetLifecycleCallback> _targetCallback = {};

extension LifecycleCallbackManager on LifecycleOwner {
  void addLifecycleAttachCallbacks(LifecycleAttachCallback callback) {
    assert(lifecycle.currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');

    var callbacks = _targetCallback.putIfAbsent(
        this, () => _TargetLifecycleCallback(owner: this));
    callbacks._attachCallbacks.add(callback);
  }

  void addLifecycleDetachCallbacks(LifecycleDetachCallback callback) {
    assert(lifecycle.currentState > LifecycleState.destroyed,
        'Must add after the LifecycleState.initialized.');

    var callbacks = _targetCallback.putIfAbsent(
        this, () => _TargetLifecycleCallback(owner: this));
    callbacks._detachCallback.add(callback);
  }
}
