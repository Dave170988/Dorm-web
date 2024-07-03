import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/providers/rentals_provider.dart';
import 'package:dorm_bnb_web/utils/delete_entry_dialog_util.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:dorm_bnb_web/widgets/left_navigator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewRentalsScreen extends ConsumerStatefulWidget {
  const ViewRentalsScreen({super.key});

  @override
  ConsumerState<ViewRentalsScreen> createState() => _ViewRentalsScreenState();
}

class _ViewRentalsScreenState extends ConsumerState<ViewRentalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.admin) {
          goRouter.goNamed(GoRoutes.home);
          ref.read(loadingProvider).toggleLoading(false);
          return;
        }
        ref.read(rentalsProvider).setRentalDocs(await getAllRentalsDocs());
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting rental docs: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(rentalsProvider);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ownerLeftNavigator(context, path: GoRoutes.rentals),
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
                color: CustomColors.pearlWhite,
                borderRadius: BorderRadius.circular(50)),
            child: switchedLoadingContainer(
              ref.read(loadingProvider).isLoading,
              SingleChildScrollView(
                child: horizontal5Percent(context, child: _rentalsContainer()),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _rentalsContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        vertical20Pix(child: blackInterBold('RENTALS', fontSize: 40)),
        viewContentContainer(
          context,
          child: Column(
            children: [
              _rentalLabelRow(),
              ref.read(rentalsProvider).rentalDocs.isNotEmpty
                  ? _rentalEntries()
                  : viewContentUnavailable(context,
                      text: 'NO AVAILABLE RENTALS'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rentalLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Date Requested', 1),
      viewFlexLabelTextCell('Renter', 1),
      viewFlexLabelTextCell('Owner', 1),
      viewFlexLabelTextCell('Dorm', 1),
      viewFlexLabelTextCell('Status', 1),
      viewFlexLabelTextCell('Duration', 2),
    ]);
  }

  Widget _rentalEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(rentalsProvider).rentalDocs.length,
            itemBuilder: (context, index) {
              return _rentalEntry(
                  ref.read(rentalsProvider).rentalDocs[index], index);
            }));
  }

  Widget _rentalEntry(DocumentSnapshot rentalDoc, int index) {
    final rentalData = rentalDoc.data() as Map<dynamic, dynamic>;
    String renterID = rentalData[RentalFields.renterID];
    String ownerID = rentalData[RentalFields.ownerID];
    String dormID = rentalData[RentalFields.dormID];
    String status = rentalData[RentalFields.status];
    DateTime startDate =
        (rentalData[RentalFields.dateStart] as Timestamp).toDate();
    DateTime endDate = (rentalData[RentalFields.dateEnd] as Timestamp).toDate();
    DateTime dateRequested =
        (rentalData[RentalFields.dateRequested] as Timestamp).toDate();
    return viewContentEntryRow(context, children: [
      viewFlexTextCell('${DateFormat('MMM dd, yyyy').format(dateRequested)}',
          flex: 1),
      viewFlexActionsCell([
        FutureBuilder(
          future: getThisUserDoc(renterID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData ||
                snapshot.hasError) return Container();
            final userData = snapshot.data!.data() as Map<dynamic, dynamic>;
            String formattedName =
                '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
            return blackInterBold(formattedName);
          },
        )
      ], flex: 1),
      viewFlexActionsCell([
        FutureBuilder(
          future: getThisUserDoc(ownerID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData ||
                snapshot.hasError) return Container();
            final userData = snapshot.data!.data() as Map<dynamic, dynamic>;
            String formattedName =
                '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
            return blackInterBold(formattedName);
          },
        )
      ], flex: 1),
      viewFlexActionsCell([
        FutureBuilder(
          future: getThisDormDoc(dormID),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData ||
                snapshot.hasError) return Container();
            final dormData = snapshot.data!.data() as Map<dynamic, dynamic>;
            String name = dormData[DormFields.name];
            return blackInterBold(name);
          },
        )
      ], flex: 1),
      viewFlexActionsCell([
        if (status == RentalStatus.pending)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                  onPressed: () =>
                      acceptRentalRequest(context, ref, rentalID: rentalDoc.id),
                  child: blackInterBold('APPROVE', fontSize: 10)),
              ElevatedButton(
                  onPressed: () => displayDeleteEntryDialog(context,
                      message:
                          'Are you sure you wush to deny this rental request? ',
                      deleteWord: 'Deny',
                      deleteEntry: () => denyRentalRequest(context, ref,
                          rentalID: rentalDoc.id)),
                  child: blackInterBold('DENY', fontSize: 10))
            ],
          )
        else
          blackInterBold(status)
      ], flex: 1),
      viewFlexTextCell(
          '${DateFormat('MMM dd, yyyy').format(startDate)} - ${DateFormat('MMM dd, yyyy').format(endDate)}',
          flex: 2)
    ]);
  }
}
