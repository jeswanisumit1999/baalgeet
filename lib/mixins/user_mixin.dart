import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_app/ads/ad_manager.dart';
import 'package:lms_app/iAP/iap_config.dart';
import 'package:lms_app/models/app_settings_model.dart';
import 'package:lms_app/models/course.dart';
import 'package:lms_app/models/user_model.dart';
import 'package:lms_app/providers/app_settings_provider.dart';
import 'package:lms_app/screens/curricullam_screen.dart';
import 'package:lms_app/screens/home/home_bottom_bar.dart';
import 'package:lms_app/screens/home/home_view.dart';
import 'package:lms_app/screens/intro.dart';
import 'package:lms_app/screens/auth/login.dart';
import 'package:lms_app/services/auth_service.dart';
import 'package:lms_app/services/firebase_service.dart';
import 'package:lms_app/utils/next_screen.dart';
import 'package:lms_app/utils/snackbars.dart';
import '../iAP/iap_screen.dart';
import '../providers/user_data_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

mixin UserMixin {

  Razorpay _razorpay = Razorpay();

  void handleLogout(context, {required WidgetRef ref}) async {
    await AuthService().userLogOut().onError((error, stackTrace) => debugPrint('error: $error'));
    await AuthService().googleLogout().onError((error, stackTrace) => debugPrint('error1: $error'));
    ref.invalidate(userDataProvider);
    ref.invalidate(homeTabControllerProvider);
    ref.invalidate(navBarIndexProvider);
    NextScreen.closeOthersAnimation(context, const IntroScreen());
  }

  bool hasEnrolled(UserModel? user, Course course) {
    if (user != null && user.enrolledCourses != null && user.enrolledCourses!.contains(course.id)) {
      return true;
    } else {
      return false;
    }
  }

  static bool isExpired(UserModel user) {
    final DateTime expireDate = user.subscription!.expireAt;
    final DateTime now = DateTime.now().toUtc();
    final difference = expireDate.difference(now).inDays;
    if (difference >= 0) {
      return false;
    } else {
      return true;
    }
  }

  static bool isUserPremium(UserModel? user) {
    return user != null && user.subscription != null && isExpired(user) == false ? true : false;
  }

  int remainingDays(UserModel user) {
    final DateTime expireDate = user.subscription!.expireAt;
    final DateTime now = DateTime.now().toUtc();
    final difference = expireDate.difference(now).inDays;
    return difference;
  }

  Future handleEnrollment(
    BuildContext context, {
    required UserModel? user,
    required Course course,
    required WidgetRef ref,
  }) async {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
    // Do something when payment succeeds
    if (user != null) {
      await _comfirmEnrollment(context, user, course, ref);
    }
  });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    if (user != null) {
      if (course.priceStatus == 'free') {
        // Free Course
        if (hasEnrolled(user, course)) {
          NextScreen.popup(context, CurriculamScreen(course: course));
        } else {
          // AdManager.initInterstitailAds(ref);
          String? price;
          if (course.courseMeta.price == null){
            price="0";
          }
          else{
            price = course.courseMeta.price;
          }
          var options = {
            'key': 'rzp_test_tK0PIKK9xRybJS',
            //'amount': int.parse(course.courseMeta.price.toString())*100,
            'amount': int.parse(price!)*100,
            'name': 'Baalgeet',
            'description': 'Baalgeet - season 1',
            'prefill': {
              //'contact': '8888888888',
              //'email': 'test@razorpay.com'
            }
          };
          _razorpay.open(options);
          // await _comfirmEnrollment(context, user, course, ref);
        }
      } else {
        //  Premium Course
        if (user.subscription != null && !isExpired(user)) {
          if (hasEnrolled(user, course)) {
            NextScreen.popup(context, CurriculamScreen(course: course));
          } else {
            await _comfirmEnrollment(context, user, course, ref);
          }
        } else {
          // Checking license before opening iAP
          final settings = ref.read(appSettingsProvider);
          if (IAPConfig.iAPEnabled && settings?.license == LicenseType.extended) {
            NextScreen.openBottomSheet(context, const IAPScreen(), isDismissable: false);
          } else {
            openSnackbarFailure(context, 'Extended license required!');
          }
        }
      }
    } else {
      NextScreen.openBottomSheet(context, const LoginScreen(popUpScreen: true));
    }
  }

Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Do something when payment succeeds
    
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Do something when payment fails
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Do something when an external wallet was selected
  }


  Future _comfirmEnrollment(BuildContext context, UserModel user, Course course, WidgetRef ref) async {
    await FirebaseService().updateEnrollment(user, course);
    await FirebaseService().updateStudentCountsOnCourse(true, course.id);
    await FirebaseService().updateStudentCountsOnAuthor(true, course.author.id);
    await ref.read(userDataProvider.notifier).getData();
    if (!context.mounted) return;
    openSnackbar(context, 'Enrolled Succesfully');
  }

  Future handleOpenCourse(
    BuildContext context, {
    required UserModel user,
    required Course course,
  }) async {
    if (course.priceStatus == 'free') {
      NextScreen.popup(context, CurriculamScreen(course: course));
    } else {
      if (!isExpired(user)) {
        NextScreen.popup(context, CurriculamScreen(course: course));
      } else {
        NextScreen.openBottomSheet(context, const IAPScreen());
      }
    }
  }
}
