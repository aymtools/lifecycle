## 2.0.3

* 移除了LifecycleObserverRegistry中的findLifecycleObserver,改为使用扩展兼容模式
* 修正了LifecycleRouteOwner在LifecycleNavigatorObserver.didReplace时路由记录错误的bug
* 对Rouge的resume事件推迟处理，与其他的LifecycleOwnerWidget的行为保持一直(在widget.build之后触发)
* LifecycleCallbacks增加removeCallback

## 2.0.2

* 修复首次的start事件，触发在build之后(version 2.0.0,2.0.1),修复后start事件必读在build之前

## 2.0.1

* addOnDidUpdateWidget会产生性能问题将在下一个版本移除
* 提供LifecycleObserverRegistryDelegate，以便可以自定义LifecycleObserverRegistryMixin

## 2.0.1

* addOnDidUpdateWidget会产生性能问题将在下一个版本移除
* 提供LifecycleObserverRegistryDelegate，以便可以自定义LifecycleObserverRegistryMixin
* 增加LifecycleObserverRegistryElementMixin以便将registry混入到自定义element

## 2.0.0

* lifecycle的提供者使用InheritedWidget来保证变更的及时通知
* 增加LifecycleCallback关联时的处理
* 优化调整工程结构(会带来一些兼容问题)

## 1.0.5

* 修正dispose与!mounted的状态不一致的bug，引起的page的state异常

## 1.0.4

* 修正pageviewItem的存在缩放时的判断
* 修正routepage的透明判断

## 1.0.3

* 修正EventStream和StateStream为同步调用的stream
* 修正Register无法添加后立即移除的异常

## 1.0.2

* 首次owner发布start时一定在build之前

## 1.0.1

* 优化RoutePage的onStop onPause的判定

## 1.0.0

* 首个版本发布.
