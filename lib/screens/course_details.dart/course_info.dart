import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_app/models/course.dart';
import 'package:lms_app/models/user_model.dart';
import 'package:lms_app/screens/author_profie/author_profile.dart';
import 'package:lms_app/services/app_service.dart';
import 'package:lms_app/services/firebase_service.dart';
import 'package:lms_app/utils/next_screen.dart';
import 'package:lms_app/utils/snackbars.dart';

import '../../providers/user_data_provider.dart';

class CourseInfo extends ConsumerWidget {
  const CourseInfo({super.key, required this.course});
  final Course course;

  bool hasEnrolled(UserModel? user, Course course) {
    if (user != null && user.enrolledCourses != null && user.enrolledCourses!.contains(course.id)) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userDataProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'created-by'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              children: [
                const TextSpan(text: ' '),
                TextSpan(
                  text: course.author.name,
                  recognizer: TapGestureRecognizer()..onTap = () => _onTapAuthor(context),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(FeatherIcons.calendar, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 5),
              Text('last-updated-', style: Theme.of(context).textTheme.bodyLarge).tr(
                args: [AppService.getDate(course.updatedAt ?? course.createdAt)],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(FeatherIcons.globe, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 5),
              Text('language-', style: Theme.of(context).textTheme.bodyLarge).tr(args: [course.courseMeta.language.toString()]),
            ],
          ),
          const SizedBox(height: 8),
          !hasEnrolled(user, course) ? Row(
            children: [
              const Icon(FeatherIcons.clock, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 5),
              Text('Validity - ${course.courseMeta.duration.toString()} Days', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ) : Row(
            children: [
              const Icon(FeatherIcons.clock, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  user != null && user!.enrolled_status != null && course.id != null
                      ? 'Valid till- ${DateFormat("yyyy-MM-dd").format(
                      DateTime.fromMillisecondsSinceEpoch(
                          (user!.enrolled_status![course.id]["course_expiry_date"] as Timestamp).seconds * 1000
                      )
                  )}'
                      : 'No expiration date available',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )// Text(' Days', style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(FeatherIcons.book, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 5),
              Text('count-lesson', style: Theme.of(context).textTheme.bodyLarge).tr(args: [course.lessonsCount.toString()]),
            ],
          ),
        ],
      ),
    );
  }

  void _onTapAuthor(BuildContext context) async {
    final UserModel? author = await FirebaseService().getAuthorData(course.author.id);
    if (!context.mounted) return;
    if (author != null) {
      NextScreen.popup(context, AuthorProfile(user: author));
    } else {
      openSnackbar(context, 'Error on getting author profile');
    }
  }
}