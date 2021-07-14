

import 'package:demo3/network/services/Impl/answer_service.dart';
import 'package:demo3/network/services/Impl/auth_service.dart';
import 'package:demo3/network/services/Impl/category_service.dart';
import 'package:demo3/network/services/Impl/quiz_service.dart';
import 'package:demo3/network/services/Impl/user_service.dart';
import 'package:demo3/network/services/repositories/category_repository.dart';

class ServiceProvider{

  AnswerService getAnswerService(){
    return AnswerService();
  }
  AuthService getAuthService(){
    return AuthService();
  }
  CategoryService getCategoryService(){
    return CategoryService();
  }
  CategoryRepository getCategoryRepository(){
    return CategoryRepository();
  }

  QuizService getQuizService() {
    return QuizService();
  }

  UserService getUserService() {
    return UserService();
  }
}