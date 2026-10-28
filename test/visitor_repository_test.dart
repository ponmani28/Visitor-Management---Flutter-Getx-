import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/app/data/models/visitor_model.dart';
import 'package:visitor_management/app/data/repositories/visitor_repository.dart';

import 'test_helpers.dart';

void main() {
  test('fetchAll sorts visitors by newest registration first', () async {
    final older = buildVisitor(
      id: 'older',
      createdAt: DateTime.utc(2026, 10, 25),
    );
    final newest = buildVisitor(
      id: 'newest',
      createdAt: DateTime.utc(2026, 10, 27),
    );
    final middle = buildVisitor(
      id: 'middle',
      createdAt: DateTime.utc(2026, 10, 26),
    );
    final api = FakeVisitorApi(<Visitor>[older, newest, middle]);
    final repository = VisitorRepository(api);

    final result = await repository.fetchAll();

    expect(result.map((item) => item.id), <String>[
      'newest',
      'middle',
      'older',
    ]);
  });

  test('delegates single-record operations to the API', () async {
    final visitor = buildVisitor();
    final api = FakeVisitorApi(<Visitor>[visitor]);
    final repository = VisitorRepository(api);

    expect((await repository.fetchById('visitor-1')).id, 'visitor-1');
    expect((await repository.create(buildVisitor(id: null))).id, 'visitor-1');
    expect(
      (await repository.update(visitor.copyWith(purpose: 'Updated'))).purpose,
      'Updated',
    );

    await repository.delete('visitor-1');

    expect(api.fetchByIdCalls, 1);
    expect(api.createCalls, 1);
    expect(api.updateCalls, 1);
    expect(api.deleteCalls, 1);
    expect(api.visitors, isEmpty);
  });
}
