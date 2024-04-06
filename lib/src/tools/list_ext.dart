extension ListFind<E> on List<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  T? firstWhereTypeOrNull<T>() {
    for (E element in this) {
      if (element is T) return element;
    }
    return null;
  }
}
