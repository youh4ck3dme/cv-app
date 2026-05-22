import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cv_app/screens/paywall_screen.dart';
import 'package:flutter_cv_app/providers/permissions_provider.dart';

class TestPermissionsNotifier extends PermissionsNotifier {
  bool shouldSucceedRefresh = true;

  TestPermissionsNotifier({bool initialCanExportPDF = false})
      : super(autoInit: false) {
    state = PermissionsState(
      canGenerateCV: true,
      canExportPDF: initialCanExportPDF,
      isPremium: initialCanExportPDF,
      isLoading: false,
    );
  }

  @override
  Future<void> init() async {
    // Bypass async storage operations
  }

  @override
  Future<void> refreshPermissions() async {
    if (shouldSucceedRefresh) {
      state = state.copyWith(
        canExportPDF: true,
        isPremium: true,
      );
    } else {
      state = state.copyWith(
        canExportPDF: false,
        isPremium: false,
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel purchasesChannel = MethodChannel('purchases_flutter');

  // Mock JSON payloads for RevenueCat
  final mockCustomerInfoJson = {
    'entitlements': {
      'all': {
        'premium': {
          'identifier': 'premium',
          'isActive': true,
          'willRenew': true,
          'latestPurchaseDate': '2026-05-22T00:00:00Z',
          'originalPurchaseDate': '2026-05-22T00:00:00Z',
          'productIdentifier': 'premium_weekly',
          'isSandbox': true,
          'ownershipType': 'PURCHASED',
          'store': 'PLAY_STORE',
          'periodType': 'NORMAL',
          'expirationDate': '2026-05-29T00:00:00Z',
          'unsubscribeDetectedAt': null,
          'billingIssueDetectedAt': null,
          'productPlanIdentifier': null,
          'verification': 'NOT_REQUESTED'
        }
      },
      'active': {
        'premium': {
          'identifier': 'premium',
          'isActive': true,
          'willRenew': true,
          'latestPurchaseDate': '2026-05-22T00:00:00Z',
          'originalPurchaseDate': '2026-05-22T00:00:00Z',
          'productIdentifier': 'premium_weekly',
          'isSandbox': true,
          'ownershipType': 'PURCHASED',
          'store': 'PLAY_STORE',
          'periodType': 'NORMAL',
          'expirationDate': '2026-05-29T00:00:00Z',
          'unsubscribeDetectedAt': null,
          'billingIssueDetectedAt': null,
          'productPlanIdentifier': null,
          'verification': 'NOT_REQUESTED'
        }
      },
      'verification': 'NOT_REQUESTED'
    },
    'allPurchaseDates': {'premium_weekly': '2026-05-22T00:00:00Z'},
    'activeSubscriptions': ['premium_weekly'],
    'allPurchasedProductIdentifiers': ['premium_weekly'],
    'nonSubscriptionTransactions': [],
    'firstSeen': '2026-05-22T00:00:00Z',
    'originalAppUserId': 'test_user_id',
    'allExpirationDates': {'premium_weekly': '2026-05-29T00:00:00Z'},
    'requestDate': '2026-05-22T00:00:00Z',
    'latestExpirationDate': '2026-05-29T00:00:00Z',
    'originalPurchaseDate': '2026-05-22T00:00:00Z',
    'originalApplicationVersion': '1.0.0',
    'managementURL': 'https://play.google.com/store/account/subscriptions'
  };

  final mockOfferingsJson = {
    'all': {
      'default': {
        'identifier': 'default',
        'serverDescription': 'Default Offering',
        'metadata': {},
        'availablePackages': [
          {
            'identifier': '\$rc_weekly',
            'packageType': 'WEEKLY',
            'product': {
              'identifier': 'premium_weekly',
              'description': 'Weekly Premium Access',
              'title': 'Premium Weekly',
              'price': 9.99,
              'priceString': '9.99€',
              'currencyCode': 'EUR',
              'introPrice': null,
              'discounts': null,
              'productCategory': 'SUBSCRIPTION',
              'defaultOption': null,
              'subscriptionOptions': null,
              'presentedOfferingContext': {
                'offeringIdentifier': 'default',
                'placementIdentifier': null,
                'targetingContext': null
              },
              'subscriptionPeriod': 'P1W',
              'pricePerWeek': 9.99,
              'pricePerMonth': 39.96,
              'pricePerYear': 519.48,
              'pricePerWeekString': '9.99€',
              'pricePerMonthString': '39.96€',
              'pricePerYearString': '519.48€'
            },
            'presentedOfferingContext': {
              'offeringIdentifier': 'default',
              'placementIdentifier': null,
              'targetingContext': null
            },
            'webCheckoutUrl': null
          }
        ],
        'lifetime': null,
        'annual': null,
        'sixMonth': null,
        'threeMonth': null,
        'twoMonth': null,
        'monthly': null,
        'weekly': {
          'identifier': '\$rc_weekly',
          'packageType': 'WEEKLY',
          'product': {
            'identifier': 'premium_weekly',
            'description': 'Weekly Premium Access',
            'title': 'Premium Weekly',
            'price': 9.99,
            'priceString': '9.99€',
            'currencyCode': 'EUR',
            'introPrice': null,
            'discounts': null,
            'productCategory': 'SUBSCRIPTION',
            'defaultOption': null,
            'subscriptionOptions': null,
            'presentedOfferingContext': {
              'offeringIdentifier': 'default',
              'placementIdentifier': null,
              'targetingContext': null
            },
            'subscriptionPeriod': 'P1W',
            'pricePerWeek': 9.99,
            'pricePerMonth': 39.96,
            'pricePerYear': 519.48,
            'pricePerWeekString': '9.99€',
            'pricePerMonthString': '39.96€',
            'pricePerYearString': '519.48€'
          },
          'presentedOfferingContext': {
            'offeringIdentifier': 'default',
            'placementIdentifier': null,
            'targetingContext': null
          },
          'webCheckoutUrl': null
        },
        'webCheckoutUrl': null
      }
    },
    'current': {
      'identifier': 'default',
      'serverDescription': 'Default Offering',
      'metadata': {},
      'availablePackages': [
        {
          'identifier': '\$rc_weekly',
          'packageType': 'WEEKLY',
          'product': {
            'identifier': 'premium_weekly',
            'description': 'Weekly Premium Access',
            'title': 'Premium Weekly',
            'price': 9.99,
            'priceString': '9.99€',
            'currencyCode': 'EUR',
            'introPrice': null,
            'discounts': null,
            'productCategory': 'SUBSCRIPTION',
            'defaultOption': null,
            'subscriptionOptions': null,
            'presentedOfferingContext': {
              'offeringIdentifier': 'default',
              'placementIdentifier': null,
              'targetingContext': null
            },
            'subscriptionPeriod': 'P1W',
            'pricePerWeek': 9.99,
            'pricePerMonth': 39.96,
            'pricePerYear': 519.48,
            'pricePerWeekString': '9.99€',
            'pricePerMonthString': '39.96€',
            'pricePerYearString': '519.48€'
          },
          'presentedOfferingContext': {
            'offeringIdentifier': 'default',
            'placementIdentifier': null,
            'targetingContext': null
          },
          'webCheckoutUrl': null
        }
      ],
      'lifetime': null,
      'annual': null,
      'sixMonth': null,
      'threeMonth': null,
      'twoMonth': null,
      'monthly': null,
      'weekly': {
        'identifier': '\$rc_weekly',
        'packageType': 'WEEKLY',
        'product': {
          'identifier': 'premium_weekly',
          'description': 'Weekly Premium Access',
          'title': 'Premium Weekly',
          'price': 9.99,
          'priceString': '9.99€',
          'currencyCode': 'EUR',
          'introPrice': null,
          'discounts': null,
          'productCategory': 'SUBSCRIPTION',
          'defaultOption': null,
          'subscriptionOptions': null,
          'presentedOfferingContext': {
            'offeringIdentifier': 'default',
            'placementIdentifier': null,
            'targetingContext': null
          },
          'subscriptionPeriod': 'P1W',
          'pricePerWeek': 9.99,
          'pricePerMonth': 39.96,
          'pricePerYear': 519.48,
          'pricePerWeekString': '9.99€',
          'pricePerMonthString': '39.96€',
          'pricePerYearString': '519.48€'
        },
        'presentedOfferingContext': {
          'offeringIdentifier': 'default',
          'placementIdentifier': null,
          'targetingContext': null
        },
        'webCheckoutUrl': null
      },
      'webCheckoutUrl': null
    }
  };

  late Map<String, dynamic> mockPurchaseResultJson;
  bool shouldFailGetOfferings = false;
  bool shouldFailPurchase = false;
  bool shouldFailRestore = false;
  bool delayPurchase = false;
  PlatformException? purchasePlatformException;
  late TestPermissionsNotifier mockPermissionsNotifier;

  setUp(() {
    mockPermissionsNotifier =
        TestPermissionsNotifier(initialCanExportPDF: false);
    mockPurchaseResultJson = {
      'customerInfo': mockCustomerInfoJson,
      'transaction': {
        'transactionIdentifier': 'mock_transaction_id',
        'productIdentifier': 'premium_weekly',
        'purchaseDate': '2026-05-22T00:00:00Z'
      }
    };

    shouldFailGetOfferings = false;
    shouldFailPurchase = false;
    shouldFailRestore = false;
    delayPurchase = false;
    purchasePlatformException = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(purchasesChannel,
            (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'setupPurchases':
        case 'setLogLevel':
          return null;
        case 'getOfferings':
          if (delayPurchase) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
          if (shouldFailGetOfferings) {
            throw PlatformException(
              code: '0',
              message: 'Mock getOfferings error',
            );
          }
          return mockOfferingsJson;
        case 'purchasePackage':
          if (shouldFailPurchase) {
            if (purchasePlatformException != null) {
              throw purchasePlatformException!;
            }
            throw PlatformException(
              code: '0',
              message: 'Mock purchase error',
            );
          }
          return mockPurchaseResultJson;
        case 'restorePurchases':
          if (shouldFailRestore) {
            throw PlatformException(
              code: '0',
              message: 'Mock restore error',
            );
          }
          return mockCustomerInfoJson;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(purchasesChannel, null);
  });

  Future<void> pumpPaywall(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          permissionsProvider.overrideWith((ref) => mockPermissionsNotifier),
        ],
        child: const MaterialApp(
          home: TickerMode(
            enabled: false,
            child: PaywallScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('PaywallScreen layout and mounting verification',
      (WidgetTester tester) async {
    await pumpPaywall(tester);

    // Verify critical elements are present
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.text("Your resume is ready!"), findsOneWidget);
    expect(find.text("Unlock and download PDF\n(3 days free)"), findsOneWidget);
    expect(find.text("Then only 9.99€/week. Cancel anytime."), findsOneWidget);

    // Verify Apple compliance links are present in the footer
    expect(find.text("Restore Purchases"), findsOneWidget);
    expect(find.text("Terms of Service"), findsOneWidget);
    expect(find.text("Privacy Policy"), findsOneWidget);
  });

  testWidgets('Successful purchase flow and navigation to preview screen',
      (WidgetTester tester) async {
    delayPurchase = true;
    await pumpPaywall(tester);

    // Click on the unlock/purchase button
    await tester.tap(find.text("Unlock and download PDF\n(3 days free)"));

    // Pump frames to handle initState/animations and futures
    await tester.pump();

    // Verify that the button text changed to show it is processing
    expect(find.text("Processing..."), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    // Complete the future and allow navigation
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Verify that it successfully navigated to PreviewScreen (which returns 'No active resume' because CV provider is empty)
    expect(find.text("No active resume"), findsOneWidget);
  });

  testWidgets('Double-tap prevention disabled state during purchase',
      (WidgetTester tester) async {
    delayPurchase = true;
    await pumpPaywall(tester);

    // First tap triggers the purchase flow
    await tester.tap(find.text("Unlock and download PDF\n(3 days free)"));
    await tester
        .pump(); // Start execution, widget rebuilds with processing state

    // Try tapping again during processing
    await tester.tap(find.text("Processing..."));
    await tester.pump();

    // Let the mock future complete
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    // Verify we navigated, proving it executed without throwing a double invocation error
    expect(find.text("No active resume"), findsOneWidget);
  });

  testWidgets(
      'Purchase failure with generic exception displays correct SnackBar',
      (WidgetTester tester) async {
    shouldFailPurchase = true;

    await pumpPaywall(tester);

    await tester.tap(find.text("Unlock and download PDF\n(3 days free)"));
    await tester.pump(); // Starts processing
    await tester.pumpAndSettle(); // Completes with error

    // Verify that the error SnackBar is displayed
    expect(find.text("Purchase failed: Mock purchase error"), findsOneWidget);
  });

  testWidgets(
      'Purchase cancellation is ignored silently without showing SnackBar',
      (WidgetTester tester) async {
    shouldFailPurchase = true;
    // Code 1 is purchaseCancelledError according to PurchasesErrorCode
    purchasePlatformException = PlatformException(
      code: '1',
      message: 'User cancelled the purchase sheet.',
    );

    await pumpPaywall(tester);

    await tester.tap(find.text("Unlock and download PDF\n(3 days free)"));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify that no error SnackBar is shown (since cancellation is ignored silently)
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Pending payment shows specific pending SnackBar message',
      (WidgetTester tester) async {
    shouldFailPurchase = true;
    // Code 20 is paymentPendingError (index of PurchasesErrorCode.paymentPendingError)
    purchasePlatformException = PlatformException(
      code: '20',
      message: 'Payment is pending verification.',
    );

    await pumpPaywall(tester);

    await tester.tap(find.text("Unlock and download PDF\n(3 days free)"));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify pending payment message
    expect(
        find.text(
            "Payment is pending. Your premium status will update once completed."),
        findsOneWidget);
  });

  testWidgets('Restore purchases successfully displays success SnackBar',
      (WidgetTester tester) async {
    await pumpPaywall(tester);

    await tester.tap(find.text("Restore Purchases"));
    await tester.pump(); // Rebuild for restore state
    await tester.pumpAndSettle(); // Navigate/success SnackBar

    // Verify navigation or success message
    // Note: Since restoredInfo entitlements are active, it pushes replacement route PreviewScreen
    expect(find.text("No active resume"), findsOneWidget);
  });

  testWidgets('Restore purchases failure displays error SnackBar',
      (WidgetTester tester) async {
    shouldFailRestore = true;

    await pumpPaywall(tester);

    await tester.tap(find.text("Restore Purchases"));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify restore error snackbar
    expect(find.text("Restore failed: Mock restore error"), findsOneWidget);
  });
}
