import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_app/components/splash_logo.dart';
import 'package:lms_app/configs/features_config.dart';
import 'package:lms_app/models/app_settings_model.dart';
import 'package:lms_app/screens/auth/no_user.dart';
import 'package:lms_app/services/auth_service.dart';
import 'package:lms_app/services/sp_service.dart';
import 'package:simple_animations/simple_animations.dart';
import '../core/home.dart';
import '../providers/app_settings_provider.dart';
import '../providers/user_data_provider.dart';
import '../utils/next_screen.dart';
import '../utils/no_license.dart';
import 'intro.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  // Getting required settings data
  var deviceId;
  bool showSplashIcon = true;

  _getRequiredData() async {
    final user = FirebaseAuth.instance.currentUser;
    var storedDeviceId;
    deviceId = await _getId();
    print(deviceId.toString());
    // print("In _getRequiredData User Id : " + user!.uid.toString());
    if (user != null) {
      // Fetch device ID from Firestore user document
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      try {
        storedDeviceId = userDoc['deviceId'];
      }
      catch(e){
        print(e.toString());
        storedDeviceId = null;
      }
      // if storedDeviceId == deviceId
      // Ok logged in
      // else logout
      // while login/create_account update device id in user data
    }

    if (user != null && storedDeviceId == deviceId && deviceId != null) {
      // Signed In
      await ref.read(userDataProvider.notifier).getData();
      final userData = ref.read(userDataProvider);
      if (userData != null) {
        if (ref.read(appSettingsProvider) == null) {
          await ref.read(appSettingsProvider.notifier).getData();
        }
        if (!mounted) return;

        // Checking license
        if (ref.read(appSettingsProvider)?.license != LicenseType.none) {
          NextScreen.replaceAnimation(context, const Home());
        } else {
          NextScreen.openBottomSheet(context, const NoLicenseFound());
        }
      } else {
        // if user not fould
        await AuthService().userLogOut();
        await AuthService().googleLogout();
        if (!mounted) return;
        NextScreen.replace(context, const NoUserFound());
      }
    } else {
      // Signed Out
      await ref.read(appSettingsProvider.notifier).getData();
      final settings = ref.read(appSettingsProvider);
      final bool isGuestUser = await SPService().isGuestUser();

      // Checking license
      if (settings?.license != LicenseType.none) {
        if (isGuestUser || settings?.onBoarding == false) {
          if (!mounted) return;
          NextScreen.replaceAnimation(context, const Home());
        } else {
          if (!mounted) return;
          NextScreen.replaceAnimation(context, const IntroScreen());
        }
      } else {
        if (!mounted) return;
        NextScreen.openBottomSheet(context, const NoLicenseFound());
      }
    }
  }

  Future<String?> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) { // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor.toString(); // unique ID on iOS
    } else if(Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id.toString(); // unique ID on Android
    }
  }

  @override
  void initState() {
    super.initState();
    _getRequiredData();
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        showSplashIcon = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: showSplashIcon
          ? const Center(child: SplashLogo())
          : MirrorAnimationBuilder<double>(
              curve: Curves.easeInOut,
              tween: Tween(begin: 100.0, end: 200),
              duration: const Duration(seconds: 10),
              builder: (context, value, _) {
                return const SplashLogo();
              },
            ),
    );
  }
}
