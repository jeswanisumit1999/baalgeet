import 'dart:io';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:lms_app/configs/app_config.dart';
import 'package:lms_app/models/course.dart';
import 'package:share_plus/share_plus.dart';

class CourseShareButton extends StatelessWidget {
  const CourseShareButton({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () async {
          // Android
          final String shareTextAndroid =
              "${course.name}\nExplore this Season on ${AppConfig.appName} App: https://play.google.com/store/apps/details?id=${AppConfig.androidPackageName}";

          // iOS
          final String shareTextiOS =
              "${course.name}\nExplore this Season on ${AppConfig.appName} App: https://play.google.com/store/apps/details?id=${AppConfig.iosAppID}";

          final String shareText = Platform.isAndroid ? shareTextAndroid : shareTextiOS;

          Share.share(shareText);
        },
        icon: const Icon(LineIcons.share));
  }
}
