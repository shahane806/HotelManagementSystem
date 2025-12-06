import 'package:frontend/models/user_model.dart';

class UserRepository {
  static late UserModel user;
  static void setUserData(final data){
    user = UserModel.fromJson(data);
  }
  static UserModel getUserData(){
    return UserRepository.user;
  }
}