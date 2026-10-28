import 'package:flutter_test/flutter_test.dart';
import 'package:visitor_management/app/core/utils/app_validators.dart';
import 'package:visitor_management/app/core/utils/qr_payload_parser.dart';

void main() {
  group('AppValidators', () {
    test('name is required and must contain at least two characters', () {
      expect(AppValidators.name(null), 'Name is required');
      expect(AppValidators.name('   '), 'Name is required');
      expect(AppValidators.name('A'), 'Enter a valid visitor name');
      expect(AppValidators.name('Asha'), isNull);
    });

    test('mobile is required and must be exactly ten digits', () {
      expect(AppValidators.mobile(null), 'Mobile number is required');
      expect(AppValidators.mobile(''), 'Mobile number is required');
      expect(AppValidators.mobile('98765'), 'Enter exactly 10 digits');
      expect(AppValidators.mobile('98765432101'), 'Enter exactly 10 digits');
      expect(AppValidators.mobile('98765abcde'), 'Enter exactly 10 digits');
      expect(AppValidators.mobile('98765 43210'), 'Enter exactly 10 digits');
      expect(AppValidators.mobile('9876543210'), isNull);
    });

    test('email is optional but validated when supplied', () {
      expect(AppValidators.optionalEmail(null), isNull);
      expect(AppValidators.optionalEmail('  '), isNull);
      expect(AppValidators.optionalEmail('not-an-email'), isNotNull);
      expect(AppValidators.optionalEmail('visitor@example.com'), isNull);
    });

    test('purpose and project are required', () {
      expect(AppValidators.purpose(null), 'Purpose is required');
      expect(AppValidators.purpose('  '), 'Purpose is required');
      expect(AppValidators.purpose('Meeting'), isNull);
      expect(AppValidators.project(null), 'Project is required');
      expect(AppValidators.project(''), 'Project is required');
      expect(AppValidators.project('Project A'), isNull);
    });
  });

  group('extractVisitorId', () {
    test('returns a plain visitor id', () {
      expect(extractVisitorId('local-abc-123'), 'local-abc-123');
      expect(extractVisitorId('  local-abc-123  '), 'local-abc-123');
    });

    test('reads JSON payloads', () {
      expect(
        extractVisitorId('{"id":"local-json-1","name":"Test"}'),
        'local-json-1',
      );
      expect(extractVisitorId('{"visitor_id":"local-json-2"}'), 'local-json-2');
      expect(extractVisitorId('{"visitorId":"local-json-3"}'), 'local-json-3');
    });

    test('reads scheme and URL payloads', () {
      expect(extractVisitorId('vms:local-scheme-1'), 'local-scheme-1');
      expect(extractVisitorId('visitor:local-scheme-2'), 'local-scheme-2');
      expect(
        extractVisitorId('https://vms.example.com/visitors/local-url-1'),
        'local-url-1',
      );
      expect(
        extractVisitorId('https://vms.example.com/scan?id=local-query-1'),
        'local-query-1',
      );
      expect(extractVisitorId('id=local-query-2&source=qr'), 'local-query-2');
    });

    test('decodes quoted and percent-encoded ids', () {
      expect(extractVisitorId('"local-quoted-1"'), 'local-quoted-1');
      expect(extractVisitorId("'local-quoted-2'"), 'local-quoted-2');
      expect(extractVisitorId('local%2Dencoded'), 'local-encoded');
    });

    test('returns an empty string for malformed or empty input', () {
      expect(extractVisitorId('   '), '');
      expect(
        extractVisitorId('{"name":"missing id"}'),
        '{"name":"missing id"}',
      );
    });
  });
}
