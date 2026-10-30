import 'package:flutter/material.dart';
import '../models/report_data.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  BusinessReportData? _reportData;
  bool _isLoading = false;
  String? _errorMessage;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  BusinessReportData? get reportData => _reportData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setDateRange(DateTime start, DateTime end, String ownerId) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
    fetchReport(ownerId);
  }

  void setThisMonth(String ownerId) {
    final now = DateTime.now();
    setDateRange(DateTime(now.year, now.month, 1), now, ownerId);
  }

  void setLastMonth(String ownerId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0, 23, 59, 59);
    setDateRange(start, end, ownerId);
  }

  Future<void> fetchReport(String ownerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reportData = await _service.generateReport(
        ownerId: ownerId,
        startDate: _startDate,
        endDate: _endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

