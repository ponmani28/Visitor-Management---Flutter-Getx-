import 'package:visitor_management/app/core/errors/api_exception.dart';
import 'package:visitor_management/app/data/models/visitor_model.dart';
import 'package:visitor_management/app/data/providers/api_provider.dart';

Visitor buildVisitor({
  String? id = 'visitor-1',
  String name = 'Aarav Sharma',
  String mobile = '9876543210',
  String? email,
  VisitorType visitorType = VisitorType.customer,
  String project = 'Project A',
  String purpose = 'Client meeting',
  VisitorStatus status = VisitorStatus.registered,
  DateTime? createdAt,
  DateTime? checkInTime,
  DateTime? checkOutTime,
}) {
  return Visitor(
    id: id,
    name: name,
    mobile: mobile,
    email: email,
    visitorType: visitorType,
    project: project,
    purpose: purpose,
    status: status,
    createdAt: createdAt ?? DateTime.now(),
    checkInTime: checkInTime,
    checkOutTime: checkOutTime,
  );
}

class FakeVisitorApi implements VisitorApi {
  FakeVisitorApi([Iterable<Visitor> seed = const <Visitor>[]])
    : visitors = List<Visitor>.of(seed);

  final List<Visitor> visitors;
  Object? fetchError;
  int fetchAllCalls = 0;
  int fetchByIdCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int _nextId = 1;

  @override
  Future<List<Visitor>> fetchAll() async {
    fetchAllCalls += 1;
    if (fetchError != null) throw fetchError!;
    return List<Visitor>.of(visitors);
  }

  @override
  Future<Visitor> fetchById(String id) async {
    fetchByIdCalls += 1;
    for (final visitor in visitors) {
      if (visitor.id == id) return visitor;
    }
    throw const ApiException(
      'The requested record could not be found.',
      statusCode: 404,
    );
  }

  @override
  Future<Visitor> create(Visitor visitor) async {
    createCalls += 1;
    final created = visitor.copyWith(id: 'visitor-${_nextId++}');
    visitors.add(created);
    return created;
  }

  @override
  Future<Visitor> update(Visitor visitor) async {
    updateCalls += 1;
    final index = visitors.indexWhere((item) => item.id == visitor.id);
    if (index == -1) {
      throw const ApiException(
        'The requested record could not be found.',
        statusCode: 404,
      );
    }
    visitors[index] = visitor;
    return visitor;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls += 1;
    visitors.removeWhere((item) => item.id == id);
  }
}
