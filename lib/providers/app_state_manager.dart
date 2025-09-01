import 'package:flutter/material.dart';
import '../models/task.dart';

class AppStateManager extends ChangeNotifier {
  int _selectedIndex = 0;
  Task? _dailyTask;
  int _stockRefreshCounter = 0;

  int get selectedIndex => _selectedIndex;
  Task? get dailyTask => _dailyTask;
  int get stockRefreshCounter => _stockRefreshCounter;

  void goToTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setDailyTask(Task task) {
    _dailyTask = task;
    notifyListeners();
  }

  void clearDailyTask() {
    _dailyTask = null;
    notifyListeners();
  }

  void requestStockRefresh() {
    _stockRefreshCounter++;
    notifyListeners();
  }
}
