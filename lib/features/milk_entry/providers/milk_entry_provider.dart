import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/milk_entry_model.dart';
import '../repositories/milk_entry_repository.dart';
import '../../customers/models/customer_model.dart';

class MilkEntryProvider extends ChangeNotifier {
  final MilkEntryRepository _repository = MilkEntryRepository();
  StreamSubscription? _dateSub;

  DateTime _selectedDate = DateTime.now();
  List<MilkEntryModel> _dailyEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime get selectedDate => _selectedDate;
  List<MilkEntryModel> get dailyEntries => _dailyEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get todayMorningTotal => _dailyEntries.fold(0.0, (s, e) => s + e.morningQty);
  double get todayEveningTotal => _dailyEntries.fold(0.0, (s, e) => s + e.eveningQty);
  double get todayGrandTotalLitres => todayMorningTotal + todayEveningTotal;
  double get todayGrandTotalAmount => _dailyEntries.fold(0.0, (s, e) => s + e.totalAmount);

  void setDate(DateTime date, String ownerId) {
    _selectedDate = date;
    notifyListeners();
    listenToDailyEntries(ownerId);
  }

  void listenToDailyEntries(String ownerId) {
    _dateSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _dateSub = _repository.getEntriesForDate(ownerId, _selectedDate).listen(
      (entries) {
        _dailyEntries = entries;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Save single manual milk entry with duplicate check
  Future<bool> saveEntry({
    required String ownerId,
    required CustomerModel customer,
    required DateTime date,
    required double morningQty,
    required double eveningQty,
    required double rate,
    bool isZeroMilk = false,
    String notes = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check existing entry
      final existing = await _repository.getExistingEntry(
        ownerId: ownerId,
        customerId: customer.id,
        date: date,
      );

      final entryId = existing?.id ?? const Uuid().v4();
      final newEntry = MilkEntryModel.create(
        id: entryId,
        ownerId: ownerId,
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        customerUserId: customer.userId,
        date: date,
        morningQty: morningQty,
        eveningQty: eveningQty,
        ratePerLitre: rate,
        isZeroMilk: isZeroMilk,
        notes: notes,
      );

      await _repository.saveMilkEntry(newEntry);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete milk entry
  Future<bool> deleteEntry(MilkEntryModel entry) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteMilkEntry(entry);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _dateSub?.cancel();
    super.dispose();
  }
}

