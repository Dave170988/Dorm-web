import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class UserTypeProvider extends ChangeNotifier {
  String userType = UserTypes.admin;

  void setUserType(String user) {
    userType = user;
    notifyListeners();
  }
}

final userTypeProvider = ChangeNotifierProvider((ref) => UserTypeProvider());
