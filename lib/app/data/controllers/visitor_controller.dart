import 'package:get/get.dart';

import '../models/visitor_model.dart';
import '../repositories/visitor_repository.dart';

class VisitorController extends GetxController {
  VisitorController(this._repository);

  final VisitorRepository _repository;

  final RxList<Visitor> visitors = <Visitor>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasLoaded = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString query = ''.obs;
  final Rxn<VisitorStatus> statusFilter = Rxn<VisitorStatus>();
  Future<void>? _pendingLoad;

  List<Visitor> get visitorsList => visitors.toList();

  bool get hasFilters => query.value.isNotEmpty || statusFilter.value != null;

  int get totalVisitorsToday => visitors
      .where((visitor) => _isToday(visitor.createdAt))
      .length;

  int get currentlyCheckedIn => visitors
      .where((visitor) => visitor.status == VisitorStatus.checkedIn)
      .length;

  int get registeredToday => visitors
      .where(
        (visitor) =>
            visitor.status == VisitorStatus.registered &&
            _isToday(visitor.createdAt),
      )
      .length;

  int get checkedOutToday => visitors
      .where(
        (visitor) =>
            visitor.status == VisitorStatus.checkedOut &&
            visitor.checkOutTime != null &&
            _isToday(visitor.checkOutTime!),
      )
      .length;

  List<Visitor> get recentVisitors {
    final sorted = List<Visitor>.of(visitors)
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return sorted.take(4).toList();
  }

  List<Visitor> get visibleVisitors {
    final search = query.value.trim().toLowerCase();
    final filter = statusFilter.value;

    final items = visitors.where((visitor) {
      if (filter != null && visitor.status != filter) return false;
      if (search.isEmpty) return true;

      final haystack = <String>[
        visitor.name,
        visitor.mobile,
        visitor.email ?? '',
        visitor.visitorType.label,
        visitor.project,
        visitor.purpose,
        visitor.status.label,
      ].join(' ').toLowerCase();

      return haystack.contains(search);
    }).toList();

    items.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return items;
  }

  Future<void> load({bool force = false}) {
    if (!force && hasLoaded.value) return Future<void>.value();
    if (_pendingLoad != null) return _pendingLoad!;

    final future = _load();
    _pendingLoad = future;
    return future.whenComplete(() => _pendingLoad = null);
  }

  @override
  Future<void> refresh() => load(force: true);

  Future<void> _load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      visitors.assignAll(await _repository.fetchAll());
      hasLoaded.value = true;
    } on Exception catch (exception) {
      errorMessage.value = exception.toString().replaceAll('Exception: ', '');
    } catch (_) {
      errorMessage.value = 'Unable to load visitors right now. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Visitor? findById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final visitor in visitors) {
      if (visitor.id == id) return visitor;
    }
    return null;
  }

  Future<Visitor> fetchById(String id) async {
    final cached = findById(id);
    if (cached != null) return cached;

    final visitor = await _repository.fetchById(id);
    _upsert(visitor);
    return visitor;
  }

  Future<Visitor> create(Visitor visitor) async {
    final created = await _repository.create(visitor);
    _upsert(created);
    return created;
  }

  Future<Visitor> updateVisitor(Visitor visitor) async {
    final updated = await _repository.update(visitor);
    _upsert(updated);
    return updated;
  }

  Future<Visitor> updateVisitorModel(Visitor visitor) =>
      updateVisitor(visitor);

  Future<Visitor> checkIn(Visitor visitor) async {
    final current = findById(visitor.id) ?? visitor;
    if (!current.canCheckIn) {
      throw Exception('Only registered visitors can be checked in.');
    }

    return updateVisitor(
      current.copyWith(
        status: VisitorStatus.checkedIn,
        checkInTime: current.checkInTime ?? DateTime.now(),
      ),
    );
  }

  Future<Visitor> checkOut(Visitor visitor) async {
    final current = findById(visitor.id) ?? visitor;
    if (!current.canCheckOut) {
      throw Exception('Only checked-in visitors can be checked out.');
    }

    return updateVisitor(
      current.copyWith(
        status: VisitorStatus.checkedOut,
        checkOutTime: current.checkOutTime ?? DateTime.now(),
      ),
    );
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    visitors.removeWhere((visitor) => visitor.id == id);
  }

  void updateQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (query.value == normalized) return;
    query.value = normalized;
  }

  void setStatusFilter(VisitorStatus? status) {
    if (statusFilter.value == status) return;
    statusFilter.value = status;
  }

  void clearFilters() {
    if (!hasFilters) return;
    query.value = '';
    statusFilter.value = null;
  }

  void _upsert(Visitor visitor) {
    final index = visitors.indexWhere((item) => item.id == visitor.id);
    if (index == -1) {
      visitors.insert(0, visitor);
    } else {
      visitors[index] = visitor;
    }

    visitors.sort((first, second) => second.createdAt.compareTo(first.createdAt));
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}
