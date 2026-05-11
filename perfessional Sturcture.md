## Professional Flutter Folder Structure

This structure is good for:

scalable apps
clean code
team projects

Recommended Structure
lib/
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── network/
│   ├── services/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── datasource/
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   ├── widgets/
│   │   │   └── controllers/
│   │   │
│   │   └── domain/
│   │
│   ├── home/
│   ├── profile/
│   └── product/
│
├── routes/
│
├── shared/
│
├── main.dart
└── app.dart
Explanation
## core/
   Global things used everywhere.

## constants/
  Store:
   API URLs
   colors
   strings

Example:

class ApiConstants {
  static const baseUrl = "http://localhost:3000";
}
network/

API setup.

Example:

Dio configuration
interceptors
token handling

Files:

dio_client.dart
api_service.dart
services/

Things like:

local storage
notifications
secure storage

Example:
   storage_service.dart
   widgets/

   Reusable widgets.

   Example:

    custom_button.dart
    custom_textfield.dart
    loading_widget.dart
    features/

Main business modules.

Example:

auth
products
orders
users

Each feature is separated.

Example: auth feature
auth/
│
├── data/
│   ├── datasource/
│   ├── models/
│   └── repositories/
│
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── controllers/
│
└── domain/
data/

Handles:

API calls
database
JSON models
models/

Example:

class UserModel {
  final String id;
  final String email;

  UserModel({
    required this.id,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      email: json['email'],
    );
  }
}
datasource/

Direct API communication.

Example:

auth_remote_datasource.dart
repositories/

Connect UI with data layer.

Example:

auth_repository.dart
presentation/

UI layer.

Contains:

pages
screens
widgets
state management
pages/

Example:

login_page.dart
register_page.dart
controllers/

I'm using state management:

Riverpod

Example:

auth_controller.dart
routes/

App navigation.

Example:

class AppRoutes {
  static const login = "/login";
  static const home = "/home";
}
shared/

Things shared across features.

Example:

shared models
shared widgets

Professional Stack

Frontend:

Flutter
Riverpod
Dio
GoRouter

Backend:

NestJS
MongoDB
JWT Auth
Recommended Naming Style
snake_case.dart

Examples:

login_page.dart
auth_controller.dart
product_model.dart
Professional Tips
1. Separate features

Do NOT put everything in one folder.

2. Reusable widgets

Create shared components.

3. Environment configs

Use:

.env

Package:

flutter_dotenv:
4. Use secure storage for tokens

Package:

flutter_secure_storage:
5. Use Dio Interceptors

Automatic:

JWT token
refresh token
error handling
