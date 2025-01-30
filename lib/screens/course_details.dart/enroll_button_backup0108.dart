import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lms_app/configs/app_assets.dart';
import 'package:lms_app/constants/app_constants.dart';
import 'package:lms_app/mixins/course_mixin.dart';
import 'package:lms_app/mixins/user_mixin.dart';
import 'package:lms_app/models/course.dart';
import 'package:lms_app/utils/loading_widget.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../providers/user_data_provider.dart';

final _isLoadingEnrollmentProvider = StateProvider.autoDispose((ref) => false);

class EnrollButton extends ConsumerWidget with UserMixin {
  EnrollButton({super.key, required this.course});

  final Course course;

  Razorpay _razorpay = Razorpay();
  var _user; // Instance variable to store user reference
  BuildContext? _contextRef; // Instance variable to store context reference
  WidgetRef? _widgetRef; // Instance variable to store ref reference

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _user = ref.watch(userDataProvider); // Assigning user to instance variable
    _contextRef = context; // Assigning context to instance variable
    _widgetRef = ref; // Assigning ref to instance variable

    final bool isLoading = ref.watch(_isLoadingEnrollmentProvider);
    final String text = CourseMixin.enrollButtonText(course, _user!);
    final bool isPremium = course.priceStatus == priceStatus.keys.first ? false : true;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    return BottomAppBar(
      padding: const EdgeInsets.all(0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Visibility(
              visible: !hasEnrolled(_user!, course),
              child: Flexible(
                fit: FlexFit.loose,
                flex: isPremium ? 1 : 2,
                child: isPremium ? _PremiumTag() : _FreeTag(),
              ),
            ),
            Flexible(
              fit: FlexFit.tight,
              flex: 5,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const LoadingIndicatorWidget(color: Colors.white)
                      : Text(
                    text,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ).tr(),
                  onPressed: () async {
                    print("###########################################");
                    print(course.courseMeta.price);
                    ref.read(_isLoadingEnrollmentProvider.notifier).state = true;
                    var options = {
                      'key': 'rzp_test_tK0PIKK9xRybJS',
                      'amount': int.parse(course.courseMeta.price.toString())*100,
                      'name': 'Baalgeet',
                      'description': 'Baalgeet - season 1',
                      'prefill': {
                        'contact': '8888888888',
                        'email': 'test@razorpay.com'
                      }
    // 'key': 'rzp_test_tK0PIKK9xRybJS',
    // 'amount': int.parse(course.courseMeta.price.toString())*100,
    // 'name': course.name,
    // 'description': course.courseMeta.description,
    // 'prefill': {
    // 'contact': 0000000000,
    // 'email': 'test@razorpay.com'
                    };
                    _razorpay.open(options);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Do something when payment succeeds
    if (_user != null && _contextRef != null && _widgetRef != null) {
      await handleEnrollment(_contextRef!, user: _user!, course: course, ref: _widgetRef!);
      _widgetRef!.read(_isLoadingEnrollmentProvider.notifier).state = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Do something when payment fails
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Do something when an external wallet was selected
  }
}

class _FreeTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(30)),
      child: Text(
        // priceStatus.values.first.toUpperCase(),
        "₹99999",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PremiumTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
      ),
      child: Image.asset(premiumImage, fit: BoxFit.contain),
    );
  }
}
