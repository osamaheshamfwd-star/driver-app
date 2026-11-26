import 'package:stackfood_multivendor_driver/common/widgets/custom_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_card.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/controllers/my_account_controller.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/wallet_payment_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/domain/models/withdraw_list_model.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/widgets/payment_method_bottom_sheet_widget.dart';
import 'package:stackfood_multivendor_driver/feature/my_account/widgets/wallet_attention_alert_widget.dart';
import 'package:stackfood_multivendor_driver/feature/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_driver/feature/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_driver/helper/date_converter_helper.dart';
import 'package:stackfood_multivendor_driver/helper/price_converter_helper.dart';
import 'package:stackfood_multivendor_driver/util/dimensions.dart';
import 'package:stackfood_multivendor_driver/util/styles.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor_driver/common/widgets/custom_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MyAccountScreen — Delivery-man wallet
//
// Fully wired to three backend endpoints:
//   • GET wallet-summary      → banner + 2 stat cards + action buttons
//   • GET wallet-payment-list → Tab 0 "الفلوس اللي دفعتها" with date filter
//   • GET get-withdraw-list   → Tab 1 "طلبات السحب" with date filter + status
//
// Data-source precedence (banner & cards):
//   WalletSummaryModel (wallet-summary) → fallback to ProfileModel fields
//   Controlled via MyAccountController convenience getters.
//
// Wallet logic:
//   • Card 1 "الفلوس اللي ليك"  = free_delivery_due (app owes the driver)
//   • Card 2 "الفلوس اللي عليك" = admin_payable     (driver owes the app)
//   • Banner / Pay Now          = netDue = admin_payable - free_delivery_due
// ─────────────────────────────────────────────────────────────────────────────

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Get.find<ProfileController>().getProfile();
    Get.find<MyAccountController>().initWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Date-picker — scoped to the currently active tab ─────────────────────

  Future<void> _openDatePicker(BuildContext context, MyAccountController ctrl) async {
    final int activeTab = _tabController.index;
    final DateTime? existingFrom = activeTab == 0 ? ctrl.tab1From : ctrl.tab2From;
    final DateTime? existingTo   = activeTab == 0 ? ctrl.tab1To   : ctrl.tab2To;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (existingFrom != null && existingTo != null)
          ? DateTimeRange(start: existingFrom, end: existingTo)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (activeTab == 0) {
        ctrl.setTab1DateRange(picked.start, picked.end);
      } else {
        ctrl.setTab2DateRange(picked.start, picked.end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(
        title: 'my_account'.tr,
        isBackButtonExist: false,
      ),

      body: GetBuilder<MyAccountController>(builder: (ctrl) {
        return GetBuilder<ProfileController>(builder: (profileController) {

          // ── Top section: banner, buttons, stat cards ─────────────────────
          // Profile must be loaded first (needed for Pay Now logic regardless
          // of whether wallet-summary has returned yet).
          final profile = profileController.profileModel;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool hasDateFilter = (_tabController.index == 0)
              ? (ctrl.tab1From != null)
              : (ctrl.tab2From != null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Top cards section ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeLarge,
                  0,
                ),
                child: Column(children: [

                  // 1. Orange banner
                  _BannerCard(ctrl: ctrl),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // 2. Pay Now / Adjust buttons
                  _ActionButtons(
                    ctrl: ctrl,
                    profileController: profileController,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  // 3. Two stat cards
                  Row(children: [
                    Expanded(
                      child: _StatCard(
                        label: 'money_owed_to_you'.tr,
                        value: ctrl.freeDeliveryDue,
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: _StatCard(
                        label: 'money_you_owe'.tr,
                        value: ctrl.adminPayable,
                      ),
                    ),
                  ]),
                  const SizedBox(height: Dimensions.paddingSizeSmall),

                ]),
              ),

              // ── Tab bar ─────────────────────────────────────────────────
              _WalletTabBar(tabController: _tabController),

              // ── Filter row ──────────────────────────────────────────────
              _FilterRow(
                hasDateFilter: hasDateFilter,
                onTap: () => _openDatePicker(context, ctrl),
                onClear: () {
                  if (_tabController.index == 0) {
                    ctrl.clearTab1DateFilter();
                  } else {
                    ctrl.clearTab2DateFilter();
                  }
                },
              ),

              // ── Tab content ─────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [

                    // Tab 0 — wallet-payment-list
                    _PaymentListTab(ctrl: ctrl),

                    // Tab 1 — withdraw-list
                    _WithdrawListTab(ctrl: ctrl),

                  ],
                ),
              ),

              // ── Bottom overflow warning ─────────────────────────────────
              if (ctrl.overFlowWarning || ctrl.overFlowBlockWarning)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeLarge,
                    0,
                    Dimensions.paddingSizeLarge,
                    Dimensions.paddingSizeLarge,
                  ),
                  child: WalletAttentionAlertWidget(
                    isOverFlowBlockWarning: ctrl.overFlowBlockWarning,
                  ),
                ),

            ],
          );
        });
      }),
    );
  }
}

// ─── Orange Banner Card ───────────────────────────────────────────────────────
//
// Amount sourced from MyAccountController.netDue
// (= admin_payable - free_delivery_due).
// Positive: the delivery man owes the app. Negative: the app owes the driver.

class _BannerCard extends StatelessWidget {
  final MyAccountController ctrl;
  const _BannerCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'payable_amount'.tr,
                  style: robotoRegular.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                ctrl.summaryLoading
                    ? const SizedBox(
                        height: 24, width: 80,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        PriceConverter.convertPrice(ctrl.netDue),
                        textDirection: TextDirection.ltr,
                        style: robotoBlack.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeOverLarge,
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Buttons Row ───────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final MyAccountController ctrl;
  final ProfileController profileController;
  const _ActionButtons({required this.ctrl, required this.profileController});

  @override
  Widget build(BuildContext context) {
    return Row(children: [

      // Optional "Adjust Payments" outlined button
      if (ctrl.adjustable) ...[
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return GetBuilder<MyAccountController>(
                    builder: (c) {
                      return AlertDialog(
                        title: Center(child: Text('cash_adjustment'.tr)),
                        content: Text(
                          'cash_adjustment_description'.tr,
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(children: [
                              Expanded(
                                child: CustomButtonWidget(
                                  onPressed: () => Get.back(),
                                  backgroundColor: Theme.of(context)
                                      .hintColor
                                      .withValues(alpha: 0.5),
                                  buttonText: 'cancel'.tr,
                                ),
                              ),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraLarge),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    c.makeWalletAdjustment();
                                  },
                                  child: Container(
                                    height: 45,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.radiusSmall),
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    child: !c.isLoading
                                        ? Text(
                                            'ok'.tr,
                                            style: robotoBold.copyWith(
                                              color: Theme.of(context).cardColor,
                                              fontSize: Dimensions.fontSizeLarge,
                                            ),
                                          )
                                        : const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusDefault),
              ),
              padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeSmall),
            ),
            child: Text(
              'adjust_payments'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
      ],

      // "Pay Now" button — enabled whenever the net amount owed to the app > 0
      Expanded(
        child: ElevatedButton(
          onPressed: ctrl.netDue > 0
              ? () {
                  final splash = Get.find<SplashController>();
                  if (splash.configModel!.activePaymentMethodList!.isEmpty ||
                      !splash.configModel!.digitalPayment!) {
                    showCustomSnackBar(
                      'currently_there_are_no_payment_options_available_please_contact_admin_regarding_any_payment_process_or_queries'
                          .tr,
                    );
                  } else if (splash.configModel!.minAmountToPayDm! >
                      ctrl.netDue) {
                    showCustomSnackBar(
                      '${'you_do_not_have_sufficient_balance_to_pay_the_minimum_payable_balance_is'.tr} '
                      '${PriceConverter.convertPrice(splash.configModel!.minAmountToPayDm)}',
                    );
                  } else {
                    showCustomBottomSheet(
                        child: const PaymentMethodBottomSheetWidget());
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ctrl.netDue > 0
                ? Theme.of(context).primaryColor
                : Theme.of(context).hintColor.withValues(alpha: 0.8),
            foregroundColor: Theme.of(context).cardColor,
            disabledBackgroundColor:
                Theme.of(context).hintColor.withValues(alpha: 0.8),
            disabledForegroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeSmall),
            elevation: 0,
          ),
          child: Text(
            'pay_now'.tr,
            style: robotoMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).cardColor,
            ),
          ),
        ),
      ),

    ]);
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final double? value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      isBorder: false,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value != null ? PriceConverter.convertPrice(value) : '---',
            textDirection: TextDirection.ltr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            label,
            textAlign: TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: robotoRegular.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────
//
// Tab 0: "الفلوس اللي دفعتها"  (cash_handed_over) → wallet-payment-list
// Tab 1: "طلبات السحب"          (withdraw_requests) → get-withdraw-list

class _WalletTabBar extends StatelessWidget {
  final TabController tabController;
  const _WalletTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      labelStyle: robotoMedium,
      unselectedLabelStyle: robotoRegular,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Theme.of(context).hintColor,
      indicatorColor: Theme.of(context).primaryColor,
      indicatorWeight: 2.5,
      indicatorSize: TabBarIndicatorSize.tab,
      tabs: [
        Tab(text: 'cash_handed_over'.tr),   // index 0
        Tab(text: 'withdraw_requests'.tr),  // index 1
      ],
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────
//
// Calendar icon opens a DateRangePicker scoped to the active tab.
// When a filter is active the icon gains the primary colour and a clear ×.

class _FilterRow extends StatelessWidget {
  final bool hasDateFilter;
  final VoidCallback onTap;
  final VoidCallback onClear;
  const _FilterRow({
    required this.hasDateFilter,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Row(children: [
        // Calendar button
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: hasDateFilter
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.12)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              border: Border.all(
                color: hasDateFilter
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).hintColor.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            child: Icon(
              Icons.calendar_today_outlined,
              color: hasDateFilter
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
              size: 20,
            ),
          ),
        ),

        // Clear filter button (only shown when filter is active)
        if (hasDateFilter) ...[
          const SizedBox(width: Dimensions.paddingSizeSmall),
          GestureDetector(
            onTap: onClear,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Icon(
                Icons.close,
                color: Theme.of(context).hintColor,
                size: 18,
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── Tab 0: Payment List ──────────────────────────────────────────────────────

class _PaymentListTab extends StatefulWidget {
  final MyAccountController ctrl;
  const _PaymentListTab({required this.ctrl});

  @override
  State<_PaymentListTab> createState() => _PaymentListTabState();
}

class _PaymentListTabState extends State<_PaymentListTab> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      widget.ctrl.loadMorePayments();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    if (ctrl.paymentListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ctrl.paymentListError) {
      return _ErrorRetry(onRetry: () => ctrl.fetchPaymentList(reset: true));
    }

    final items = ctrl.paymentList;
    if (items.isEmpty) {
      return _EmptyState(message: 'no_transaction_found'.tr);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeSmall,
      ),
      itemCount: items.length + (ctrl.paymentListLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final tx = items[index];
        final bool isLast = index == items.length - 1 && !ctrl.paymentListLoadingMore;
        return _PaymentRow(tx: tx, isLast: isLast);
      },
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final Transactions tx;
  final bool isLast;
  const _PaymentRow({required this.tx, required this.isLast});

  @override
  Widget build(BuildContext context) {
    // Format date: prefer paymentTime, fallback to createdAt
    String dateStr = '';
    final raw = tx.paymentTime ?? tx.createdAt;
    if (raw != null && raw.isNotEmpty) {
      try {
        dateStr = DateConverter.dateTimeStringForDisbursement(raw);
      } catch (_) {
        dateStr = raw;
      }
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeLarge),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PriceConverter.convertPrice(tx.amount),
                  style: robotoBold,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                if (tx.ref != null && tx.ref!.isNotEmpty)
                  Text(
                    tx.ref!,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  )
                else if (tx.method != null)
                  Text(
                    '${'paid_via'.tr} ${tx.method?.replaceAll('_', ' ').capitalize ?? ''}',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            dateStr,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ]),
      ),
      if (!isLast) const Divider(height: 1),
    ]);
  }
}

// ─── Tab 1: Withdraw List ─────────────────────────────────────────────────────

class _WithdrawListTab extends StatefulWidget {
  final MyAccountController ctrl;
  const _WithdrawListTab({required this.ctrl});

  @override
  State<_WithdrawListTab> createState() => _WithdrawListTabState();
}

class _WithdrawListTabState extends State<_WithdrawListTab> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      widget.ctrl.loadMoreWithdraws();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    if (ctrl.withdrawListLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ctrl.withdrawListError) {
      return _ErrorRetry(onRetry: () => ctrl.fetchWithdrawList(reset: true));
    }

    final items = ctrl.withdrawList;
    if (items.isEmpty) {
      return _EmptyState(message: 'no_transaction_found'.tr);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeSmall,
      ),
      itemCount: items.length + (ctrl.withdrawListLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final req = items[index];
        final bool isLast = index == items.length - 1 && !ctrl.withdrawListLoadingMore;
        return _WithdrawRow(req: req, isLast: isLast);
      },
    );
  }
}

class _WithdrawRow extends StatelessWidget {
  final WithdrawRequest req;
  final bool isLast;
  const _WithdrawRow({required this.req, required this.isLast});

  @override
  Widget build(BuildContext context) {
    // Date
    String dateStr = '';
    final raw = req.createdAt;
    if (raw != null && raw.isNotEmpty) {
      try {
        dateStr = DateConverter.dateTimeStringForDisbursement(raw);
      } catch (_) {
        dateStr = raw;
      }
    }

    // Status badge colour
    final String status = req.status ?? 'pending';
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'approved':
        badgeColor = Colors.green;
        break;
      case 'denied':
        badgeColor = Colors.red;
        break;
      default: // pending
        badgeColor = Colors.orange;
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeLarge),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PriceConverter.convertPrice(req.amount),
                  style: robotoBold,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                if (req.ref != null && req.ref!.isNotEmpty)
                  Text(
                    req.ref!,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                  vertical: Dimensions.paddingSizeExtraSmall,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  color: badgeColor.withValues(alpha: 0.12),
                ),
                child: Text(
                  status.tr,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

        ]),
      ),
      if (!isLast) const Divider(height: 1),
    ]);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Text(
          message,
          style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_outlined,
              size: 48, color: Theme.of(context).hintColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            'something_went_wrong'.tr,
            style: robotoMedium.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('try_again'.tr,
                style: robotoMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
