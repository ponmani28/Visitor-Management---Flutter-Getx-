import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/app/data/models/visitor_model.dart';

import 'test_helpers.dart';

void main() {
  group('VisitorStatus', () {
    test('exposes the required labels and workflow guards', () {
      expect(VisitorStatus.registered.label, 'Registered');
      expect(VisitorStatus.checkedIn.label, 'Checked In');
      expect(VisitorStatus.checkedOut.label, 'Checked Out');

      expect(VisitorStatus.registered.canCheckIn, isTrue);
      expect(VisitorStatus.checkedIn.canCheckIn, isFalse);
      expect(VisitorStatus.checkedOut.canCheckIn, isFalse);

      expect(VisitorStatus.checkedIn.canCheckOut, isTrue);
      expect(VisitorStatus.registered.canCheckOut, isFalse);
      expect(VisitorStatus.checkedOut.canCheckOut, isFalse);
      expect(VisitorStatus.checkedOut.isCompleted, isTrue);
    });

    test('parses known statuses and falls back to registered', () {
      expect(VisitorStatus.fromJson('Checked In'), VisitorStatus.checkedIn);
      expect(VisitorStatus.fromJson('checked-in'), VisitorStatus.checkedIn);
      expect(VisitorStatus.fromJson('Checked Out'), VisitorStatus.checkedOut);
      expect(VisitorStatus.fromJson('completed'), VisitorStatus.checkedOut);
      expect(VisitorStatus.fromJson('Registered'), VisitorStatus.registered);
      expect(VisitorStatus.fromJson('unknown'), VisitorStatus.registered);
      expect(VisitorStatus.fromJson(null), VisitorStatus.registered);
    });
  });

  group('VisitorType', () {
    test('parses known types and falls back to other', () {
      expect(VisitorType.fromJson('Customer'), VisitorType.customer);
      expect(VisitorType.fromJson('vendor'), VisitorType.vendor);
      expect(VisitorType.fromJson('Other'), VisitorType.other);
      expect(VisitorType.fromJson('contractor'), VisitorType.other);
      expect(VisitorType.fromJson(null), VisitorType.other);
    });
  });

  group('Visitor.fromJson', () {
    test('reads the assignment schema', () {
      final visitor = Visitor.fromJson(<String, dynamic>{
        'id': 'local-123',
        'name': 'Meera Nair',
        'mobile': '9123456780',
        'email': 'meera@example.com',
        'visitor_type': 'Vendor',
        'project': 'Project B',
        'purpose': 'Equipment delivery',
        'status': 'Checked In',
        'created_at': '2026-10-27T08:15:00.000Z',
        'check_in_time': '2026-10-27T08:30:00.000Z',
        'check_out_time': null,
      });

      expect(visitor.id, 'local-123');
      expect(visitor.name, 'Meera Nair');
      expect(visitor.mobile, '9123456780');
      expect(visitor.email, 'meera@example.com');
      expect(visitor.visitorType, VisitorType.vendor);
      expect(visitor.project, 'Project B');
      expect(visitor.purpose, 'Equipment delivery');
      expect(visitor.status, VisitorStatus.checkedIn);
      expect(visitor.createdAt.toUtc(), DateTime.utc(2026, 10, 27, 8, 15));
      expect(visitor.checkInTime?.toUtc(), DateTime.utc(2026, 10, 27, 8, 30));
      expect(visitor.checkOutTime, isNull);
    });

    test('supports legacy field aliases and safe defaults', () {
      final visitor = Visitor.fromJson(<String, dynamic>{
        'id': 42,
        'fullName': 'Legacy Visitor',
        'phone': '9000000000',
        'visitorType': 'customer',
        'status': 'checkedOut',
        'checkInAt': '2026-10-27 09:00:00',
        'checkOutAt': '2026-10-27T10:00:00Z',
      });

      expect(visitor.id, '42');
      expect(visitor.name, 'Legacy Visitor');
      expect(visitor.mobile, '9000000000');
      expect(visitor.project, VisitorProjects.values.first);
      expect(visitor.visitorType, VisitorType.customer);
      expect(visitor.status, VisitorStatus.checkedOut);
      expect(visitor.createdAt, isA<DateTime>());
      expect(visitor.checkInTime, isNotNull);
      expect(visitor.checkOutTime?.toUtc(), DateTime.utc(2026, 10, 27, 10));
    });
  });

  group('Visitor serialization', () {
    test('writes the API field names and timestamps in UTC', () {
      final visitor = buildVisitor(
        email: 'test@example.com',
        visitorType: VisitorType.vendor,
        status: VisitorStatus.checkedIn,
        createdAt: DateTime.utc(2026, 10, 27, 8),
        checkInTime: DateTime.utc(2026, 10, 27, 9),
      );

      final json = visitor.toJson();

      expect(json['id'], isNull);
      expect(json['name'], 'Aarav Sharma');
      expect(json['mobile'], '9876543210');
      expect(json['email'], 'test@example.com');
      expect(json['visitor_type'], 'Vendor');
      expect(json['project'], 'Project A');
      expect(json['purpose'], 'Client meeting');
      expect(json['status'], 'Checked In');
      expect(json['created_at'], '2026-10-27T08:00:00.000Z');
      expect(json['check_in_time'], '2026-10-27T09:00:00.000Z');
      expect(json['check_out_time'], isNull);
    });

    test('optionally includes the visitor id', () {
      expect(
        buildVisitor(id: 'local-9').toJson(includeId: true)['id'],
        'local-9',
      );
    });
  });

  group('Visitor helpers', () {
    test('copyWith updates workflow fields and can clear optional fields', () {
      final visitor = buildVisitor(
        email: 'visitor@example.com',
        checkInTime: DateTime.utc(2026, 10, 27, 9),
      );

      final updated = visitor.copyWith(
        status: VisitorStatus.checkedOut,
        email: null,
        checkInTime: null,
        checkOutTime: DateTime.utc(2026, 10, 27, 11),
      );

      expect(updated.status, VisitorStatus.checkedOut);
      expect(updated.email, isNull);
      expect(updated.checkInTime, isNull);
      expect(updated.checkOutTime, DateTime.utc(2026, 10, 27, 11));
      expect(updated.name, visitor.name);
    });

    test('derives initials, qr payload, and display email', () {
      expect(buildVisitor(name: 'Aarav Sharma').initials, 'AS');
      expect(buildVisitor(name: 'Meera').initials, 'M');
      expect(buildVisitor(name: '  ').initials, '?');
      expect(buildVisitor(id: null).qrPayload, '');
      expect(buildVisitor(id: 'local-1').qrPayload, 'local-1');
      expect(buildVisitor().displayEmail, 'Not provided');
      expect(buildVisitor(email: ' a@b.com ').displayEmail, 'a@b.com');
    });
  });
}
