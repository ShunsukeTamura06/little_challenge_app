import 'package:flutter/material.dart';
import '../models/task.dart';

class AppStateManager extends ChangeNotifier {
  int _selectedIndex = 0;
  Task? _dailyTask;

  int get selectedIndex => _selectedIndex;
  Task? get dailyTask => _dailyTask;

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
}
