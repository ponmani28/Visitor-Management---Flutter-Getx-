enum VisitorStatus {
  registered('Registered'),
  checkedIn('Checked In'),
  checkedOut('Checked Out');

  const VisitorStatus(this.label);

  final String label;

  bool get canCheckIn => this == VisitorStatus.registered;

  bool get canCheckOut => this == VisitorStatus.checkedIn;

  bool get isCompleted => this == VisitorStatus.checkedOut;

  static VisitorStatus fromJson(Object? value) {
    final normalized = (value ?? '').toString().toLowerCase().replaceAll(
      RegExp('[^a-z]'),
      '',
    );

    return switch (normalized) {
      'checkedin' || 'onsite' || 'arrived' => VisitorStatus.checkedIn,
      'checkedout' || 'departed' || 'completed' => VisitorStatus.checkedOut,
      _ => VisitorStatus.registered,
    };
  }
}

enum VisitorType {
  customer('Customer'),
  vendor('Vendor'),
  other('Other');

  const VisitorType(this.label);

  final String label;

  static VisitorType fromJson(Object? value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    return switch (normalized) {
      'customer' => VisitorType.customer,
      'vendor' => VisitorType.vendor,
      _ => VisitorType.other,
    };
  }
}

abstract final class VisitorProjects {
  static const List<String> values = <String>[
    'Project A',
    'Project B',
    'Project C',
  ];
}

class Visitor {
  const Visitor({
    this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    this.status = VisitorStatus.registered,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  static const Object _unset = Object();

  final String? id;
  final String name;
  final String mobile;
  final String? email;
  final VisitorType visitorType;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  bool get canCheckIn => status.canCheckIn;

  bool get canCheckOut => status.canCheckOut;

  String get qrPayload => id ?? '';

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get displayEmail =>
      (email == null || email!.trim().isEmpty) ? 'Not provided' : email!.trim();

  Visitor copyWith({
    String? id,
    String? name,
    String? mobile,
    Object? email = _unset,
    VisitorType? visitorType,
    String? project,
    String? purpose,
    VisitorStatus? status,
    DateTime? createdAt,
    Object? checkInTime = _unset,
    Object? checkOutTime = _unset,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: identical(email, _unset) ? this.email : email as String?,
      visitorType: visitorType ?? this.visitorType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: identical(checkInTime, _unset)
          ? this.checkInTime
          : checkInTime as DateTime?,
      checkOutTime: identical(checkOutTime, _unset)
          ? this.checkOutTime
          : checkOutTime as DateTime?,
    );
  }

  factory Visitor.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    return Visitor(
      id: rawId?.toString(),
      name: _readString(json['name'] ?? json['fullName']),
      mobile: _readString(
        json['mobile'] ?? json['phone'] ?? json['phoneNumber'],
      ),
      email: _readNullableString(json['email']),
      visitorType: VisitorType.fromJson(
        json['visitor_type'] ?? json['visitorType'],
      ),
      project: _readString(json['project']).isEmpty
          ? VisitorProjects.values.first
          : _readString(json['project']),
      purpose: _readString(json['purpose']),
      status: VisitorStatus.fromJson(json['status']),
      createdAt:
          _parseDate(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      checkInTime: _parseDate(
        json['check_in_time'] ??
            json['checkInTime'] ??
            json['checkInAt'] ??
            json['checkedInAt'],
      ),
      checkOutTime: _parseDate(
        json['check_out_time'] ??
            json['checkOutTime'] ??
            json['checkOutAt'] ??
            json['checkedOutAt'],
      ),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    return <String, dynamic>{
      if (includeId && id != null) 'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'visitor_type': visitorType.label,
      'project': project,
      'purpose': purpose,
      'status': status.label,
      'created_at': createdAt.toUtc().toIso8601String(),
      'check_in_time': checkInTime?.toUtc().toIso8601String(),
      'check_out_time': checkOutTime?.toUtc().toIso8601String(),
    };
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parsed =
        DateTime.tryParse(text) ??
        DateTime.tryParse(text.replaceFirst(' ', 'T'));
    return parsed?.toLocal();
  }
}
