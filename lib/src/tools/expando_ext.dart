extension ExpandoGetOrPutExt<T extends Object> on Expando<T> {
  T getOrPut(Object? key, T Function() defaultValue) {
    if (key == null) return defaultValue();
    T? result = this[key];
    if (result == null) {
      result = defaultValue();
      this[key] = result;
    }
    return result;
  }
}
