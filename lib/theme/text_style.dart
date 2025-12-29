import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle messageUser = TextStyle(
    fontSize: 16,
    color: Colors.black87,
    fontFamily: 'OpenSans',
  );

  static const TextStyle messageAi = TextStyle(
    fontSize: 16,
    color: Colors.black87,
    fontFamily: 'OpenSans',
  );
}
