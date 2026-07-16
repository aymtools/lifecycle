import 'package:anlifecycle/src/core/lifecycle.dart';
import 'package:anlifecycle/src/tools/run_in_post_frame.dart';
import 'package:flutter/widgets.dart';

class _LifecycleNativeAppStateObserver with WidgetsBindingObserver {
  final LifecycleAppOwnerState _appOwnerState;

  _LifecycleNativeAppStateObserver(this._appOwnerState);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appOwnerState._didChangeAppLifecycleState(state);
  }
}

mixin LifecycleAppOwnerState<T extends LifecycleOwnerWidget>
    on LifecycleOwnerStateMixin<T> {
  late final _LifecycleNativeAppStateObserver _nativeAppLifecycleStateObserver =
      _LifecycleNativeAppStateObserver(this);

  AppLifecycleState? _currAppState;
  bool _isInactivate = false;

  @override
  bool get customDispatchEvent => true;

  void _didChangeAppLifecycleState(AppLifecycleState state) {
    _currAppState = state;
    _changeState();
  }

  void _changeState() {
    if (currentLifecycleState < LifecycleState.created) return;
    final currState = _currAppState;

    if (currState == AppLifecycleState.resumed || currState == null) {
      if (_isInactivate) {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.resume);
      } else {
        lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
      }
    } else if (currState == AppLifecycleState.inactive) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.pause);
    } else if (currState == AppLifecycleState.paused) {
      lifecycleRegistry.handleLifecycleEvent(LifecycleEvent.stop);
    }
  }

  @override
  void initState() {
    _currAppState = WidgetsBinding.instance.lifecycleState;
    super.initState();
    WidgetsBinding.instance.addObserver(_nativeAppLifecycleStateObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_nativeAppLifecycleStateObserver);
    super.dispose();
  }

  @override
  void deactivate() {
    _isInactivate = false;
    _changeState();
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isInactivate = true;
    // 这里必须使用下一帧进行检测 不可使用检测当前帧的空闲状态直接执行
    // final binds=WidgetsBinding.instance;
    //  print('LifecycleAppOwnerState ${binds.lifecycleState} hasScheduledFrame:${binds.hasScheduledFrame}  schedulerPhase:${binds.schedulerPhase}');
    // LifecycleAppOwnerState AppLifecycleState.resumed hasScheduledFrame:false  schedulerPhase:SchedulerPhase.idle
    // 首次进入时竟然是空闲的flutter bug？
    // WidgetsBinding.instance.addPostFrameCallback((_) => _changeState());
    // 为啥不行？
    // 已经解决了
    runInPostFrameCallbackOrNext(_changeState);
  }

  @override
  void activate() {
    super.activate();
    _isInactivate = true;
    if (lifecycleRegistry.currentLifecycleState < LifecycleState.resumed) {
      // WidgetsBinding.instance.addPostFrameCallback((_) => _changeState());
      runInPostFrameCallbackOrNext(_changeState);
    }
  }
}

class LifecycleAppOwner extends LifecycleOwnerWidget {
  const LifecycleAppOwner({super.key, required super.child});

  @override
  LifecycleAppOwnerState<LifecycleAppOwner> createState() =>
      _LifecycleAppState();
}

abstract class LifecycleAppOwnerBaseState<LOW extends LifecycleAppOwner>
    extends State<LOW> with LifecycleOwnerStateMixin, LifecycleAppOwnerState {}

class _LifecycleAppState
    extends LifecycleAppOwnerBaseState<LifecycleAppOwner> {}

typedef LifecycleApp = LifecycleAppOwner;
typedef LifecycleAppState<T extends LifecycleOwnerWidget>
    = LifecycleAppOwnerState<T>;
typedef LifecycleAppBaseState<LOW extends LifecycleAppOwner>
    = LifecycleAppOwnerBaseState<LOW>;
