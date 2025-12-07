import 'dart:convert';

import 'package:frontend/app/constants.dart';
import 'package:frontend/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRepository {
  static  UserModel? user;
  
  static void setUserData(final data){
    user = UserModel.fromJson(data);
    AppConstants.pref?.setString('user', jsonEncode(data));
  }
  static UserModel? getUserData(){
    final storedData = AppConstants.pref?.getString('user');
    if(storedData != null){
      user = UserModel.fromJson(jsonDecode(storedData.toString()));
    }
    
    return UserRepository.user;
  }

  static void logout(){
    AppConstants.pref?.clear();
  }
}