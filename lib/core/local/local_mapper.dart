abstract class LocalMapper<T> {
  Future<int> add(T type);

  Future<int> addList(List<T> types);

  // Future<T?> get(String id);

  Future<List<T>> getAll();

  // Future<List<T>> search(String character);

  Future<int> delete(String id);

  Future<int> edit(T type);
}
