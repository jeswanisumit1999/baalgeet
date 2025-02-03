import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

InAppPurchase _inAppPurchase = InAppPurchase.instance;
late StreamSubscription<dynamic> _streamSubscription;
List<ProductDetails> _products = [];
const _variant = {"Season1"};

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;

    _streamSubscription = purchaseUpdated.listen((purchaseList) {
      _listenToPurchase(purchaseList, context);
    }, onDone: (){
      _streamSubscription.cancel();
    }, onError: (error){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error")));
    });
    initStore();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("In-app Purchase"),),
        body: Center(
          child: TextButton(
            onPressed: (){
              _buy();
            },
            child: const Text("Pay"),
          ),
        ),
      ),
    );
  }

  initStore() async{
    ProductDetailsResponse productDetailsResponse =
    await _inAppPurchase.queryProductDetails(_variant);

    if(productDetailsResponse.error==null){
      setState(() {
        _products = productDetailsResponse.productDetails;
      });
    }

  }
}

_listenToPurchase(List<PurchaseDetails> purchaseDetailsList, BuildContext context) {
  purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pending")));
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error")));
    } else if (purchaseDetails.status == PurchaseStatus.purchased) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchased")));
    }
      });

}

_buy(){
  final PurchaseParam param = PurchaseParam(productDetails: _products[0]);
  _inAppPurchase.buyConsumable(purchaseParam: param);
}