import 'package:in_app_purchase/in_app_purchase.dart';

class InAppPurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final Set<String> _productIds = {'product_id_1', 'product_id_2'}; // Replace with your product IDs

  Future<bool> initialize() async {
    final bool available = await _inAppPurchase.isAvailable();
    return available;
  }

  Future<List<ProductDetails>> fetchProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Failed to fetch products: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  Future<void> purchaseProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }
}
