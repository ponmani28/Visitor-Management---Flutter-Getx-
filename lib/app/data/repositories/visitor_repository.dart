import '../models/visitor_model.dart';
import '../providers/api_provider.dart';

class VisitorRepository {
  const VisitorRepository(this._api);

  final VisitorApi _api;

  Future<List<Visitor>> fetchAll() async {
    final visitors = await _api.fetchAll();
    visitors.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );
    return visitors;
  }

  Future<Visitor> fetchById(String id) => _api.fetchById(id);

  Future<Visitor> create(Visitor visitor) => _api.create(visitor);

  Future<Visitor> update(Visitor visitor) => _api.update(visitor);

  Future<void> delete(String id) => _api.delete(id);
}
