import 'package:flutter/foundation.dart';

const _text = 'anlifecycle';
const _src = 'src';
const _reasons = 'from anlifecycle';

class AnLifecycleStackFilter extends StackFilter {
  @override
  void filter(List<StackFrame> stackFrames, List<String?> reasons) {
    for (var i = 0; i < stackFrames.length; i++) {
      var frame = stackFrames[i];
      if (frame.package == _text && frame.packagePath.startsWith(_src)) {
        reasons[i] = _reasons;
      }
    }
  }
}
