import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/widgets/custom_button_widgets.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:dorm_bnb_web/widgets/left_navigator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../providers/payments_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewPaymentsScreen extends ConsumerStatefulWidget {
  const ViewPaymentsScreen({super.key});

  @override
  ConsumerState<ViewPaymentsScreen> createState() => _ViewPaymentsScreenState();
}

class _ViewPaymentsScreenState extends ConsumerState<ViewPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(loadingProvider.notifier).toggleLoading(true);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.owner) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);
          return;
        }

        ref.read(paymentsProvider).setPaymentDocs(await getAllPaymentDocs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all payments: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(paymentsProvider);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminLeftNavigator(context, path: GoRoutes.payments),
          Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: CustomColors.pearlWhite,
                  borderRadius: BorderRadius.circular(50)),
              child: switchedLoadingContainer(
                  ref.read(loadingProvider).isLoading,
                  SingleChildScrollView(
                    child:
                        horizontal5Percent(context, child: _ordersContainer()),
                  )))
        ],
      ),
    );
  }

  Widget _ordersContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vertical20Pix(
            child: blackHelveticaBold('PAYMENTS HISTORY',
                fontSize: 40, fontStyle: FontStyle.italic)),
        viewContentContainer(
          context,
          child: Column(
            children: [
              _transactionsLabelRow(),
              ref.read(paymentsProvider).paymentDocs.isNotEmpty
                  ? _transactionEntries()
                  : viewContentUnavailable(context,
                      text: 'NO AVAILABLE PAYMENTS'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _transactionsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Date Settled', 2),
      viewFlexLabelTextCell('Renter', 3),
      viewFlexLabelTextCell('Amount Paid', 2),
      viewFlexLabelTextCell('Payment', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _transactionEntries() {
    return SizedBox(
      height: 500,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: ref.read(paymentsProvider).paymentDocs.length,
          itemBuilder: (context, index) {
            final paymentData = ref
                .read(paymentsProvider)
                .paymentDocs[index]
                .data() as Map<dynamic, dynamic>;
            String clientID = paymentData[PaymentFields.userID];
            String rentalID = paymentData[PaymentFields.rentalID];
            num totalAmount = paymentData[PaymentFields.amount];
            String paymentMethod = paymentData[PaymentFields.paymentMethod];
            String proofOfPayment =
                paymentData[PaymentFields.proofOfPaymentURL];
            DateTime dateSettled =
                (paymentData[PaymentFields.dateSettled] as Timestamp).toDate();
            DateTime dateProcessed =
                (paymentData[PaymentFields.dateProcessed] as Timestamp)
                    .toDate();
            return FutureBuilder(
                future: getThisUserDoc(clientID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting ||
                      !snapshot.hasData ||
                      snapshot.hasError) return snapshotHandler(snapshot);

                  final clientData =
                      snapshot.data!.data() as Map<dynamic, dynamic>;
                  String formattedName =
                      '${clientData[UserFields.firstName]} ${clientData[UserFields.lastName]}';

                  return viewContentEntryRow(
                    context,
                    children: [
                      viewFlexTextCell(
                          DateFormat('MMM dd, yyyy').format(dateSettled),
                          flex: 2),
                      viewFlexTextCell(formattedName, flex: 3),
                      viewFlexTextCell('PHP ${totalAmount.toStringAsFixed(2)}',
                          flex: 2),
                      viewFlexActionsCell([
                        viewEntryButton(context,
                            onPress: () => showProofOfPaymentDialog(
                                paymentMethod: paymentMethod,
                                proofOfPayment: proofOfPayment)),
                      ], flex: 2),
                      viewFlexActionsCell([
                        if (paymentData[PaymentFields.isVerified])
                          blackInterBold(
                              'Verified on ${DateFormat('MMM dd, yyyy').format(dateProcessed)}')
                        else ...[
                          ElevatedButton(
                              onPressed: () => approveThisPayment(context, ref,
                                  paymentID: ref
                                      .read(paymentsProvider)
                                      .paymentDocs[index]
                                      .id,
                                  rentalID: rentalID),
                              child: const Icon(Icons.check,
                                  color: CustomColors.midnightBlue)),
                          ElevatedButton(
                              onPressed: () => displayDeleteEntryDialog(context,
                                  message:
                                      'Are you sure you want to deny this payment?',
                                  deleteWord: 'Deny',
                                  deleteEntry: () => denyThisPayment(
                                      context, ref,
                                      paymentID: ref
                                          .read(paymentsProvider)
                                          .paymentDocs[index]
                                          .id)),
                              child: const Icon(Icons.block,
                                  color: CustomColors.midnightBlue))
                        ]
                      ], flex: 2)
                    ],
                  );
                });
          }),
    );
  }

  void showProofOfPaymentDialog(
      {required String paymentMethod, required String proofOfPayment}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(),
              content: SizedBox(
                //width: MediaQuery.of(context).size.width * 0.45,
                //height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    blackInterBold('Payment Method: $paymentMethod',
                        fontSize: 30),
                    const Gap(10),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.height * 0.5,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          image: DecorationImage(
                              image: NetworkImage(proofOfPayment))),
                    ),
                    const Gap(30),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.1,
                      height: 30,
                      child: ElevatedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: whiteInterBold('CLOSE')),
                    )
                  ],
                ),
              ),
            ));
  }
}
