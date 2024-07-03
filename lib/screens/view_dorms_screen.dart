import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/providers/dorms_provider.dart';
import 'package:dorm_bnb_web/providers/user_type_provider.dart';
import 'package:dorm_bnb_web/utils/string_util.dart';
import 'package:dorm_bnb_web/utils/url_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_widgets.dart';
import '../widgets/left_navigator_widget.dart';

class ViewDormsScreen extends ConsumerStatefulWidget {
  const ViewDormsScreen({super.key});

  @override
  ConsumerState<ViewDormsScreen> createState() => _ViewDormsScreenState();
}

class _ViewDormsScreenState extends ConsumerState<ViewDormsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(userTypeProvider).setUserType(await getCurrentUserType());
        ref.read(dormsProvider).setDormDocs(
            ref.read(userTypeProvider).userType == UserTypes.admin
                ? await getAllDormDocs()
                : await getAllUserDormDocs());

        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting all associated dorms: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(dormsProvider);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ref.read(userTypeProvider).userType == UserTypes.admin
              ? adminLeftNavigator(context, path: GoRoutes.dorms)
              : ownerLeftNavigator(context, path: GoRoutes.dorms),
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
                color: CustomColors.pearlWhite,
                borderRadius: BorderRadius.circular(50)),
            child: switchedLoadingContainer(
                ref.read(loadingProvider).isLoading,
                SingleChildScrollView(
                  child: horizontal5Percent(context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _dormsHeader(),
                          viewContentContainer(context,
                              child: Column(
                                children: [
                                  _dormsLabelRow(),
                                  ref.read(dormsProvider).dormDocs.isNotEmpty
                                      ? _vehicleEntries()
                                      : viewContentUnavailable(context,
                                          text: 'NO AVAILABLE DORMS'),
                                ],
                              )),
                        ],
                      )),
                )),
          )
        ],
      ),
    );
  }

  Widget _dormsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        vertical20Pix(
            child: blackHelveticaBold('DORMS',
                fontSize: 40, fontStyle: FontStyle.italic)),
        if (ref.read(userTypeProvider).userType == UserTypes.owner)
          ElevatedButton(
              onPressed: () {
                ref.read(dormsProvider).resetDorm();
                GoRouter.of(context).goNamed(GoRoutes.addDorm);
              },
              child: whiteInterBold('ADD DORM'))
      ],
    );
  }

  Widget _dormsLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Name', 2),
      if (ref.read(userTypeProvider).userType == UserTypes.admin)
        viewFlexLabelTextCell('Owner', 2),
      viewFlexLabelTextCell('Proof of Ownership', 2),
      viewFlexLabelTextCell('Accreditation', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _vehicleEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: ref.read(dormsProvider).dormDocs.length,
            itemBuilder: (context, index) {
              return _dormEntry(ref.read(dormsProvider).dormDocs[index], index);
            }));
  }

  Widget _dormEntry(DocumentSnapshot dormDoc, int index) {
    final dormData = dormDoc.data() as Map<dynamic, dynamic>;
    String name = dormData[DormFields.name];
    String ownerID = dormData[DormFields.ownerID];
    bool isVerified = dormData[DormFields.isVerified];
    String proofOfOwnership = dormData[DormFields.proofOfOwnership];
    String accrediation = dormData[DormFields.accreditation];
    return viewContentEntryRow(context, children: [
      viewFlexTextCell(name, flex: 2),
      if (ref.read(userTypeProvider).userType == UserTypes.admin)
        viewFlexActionsCell([
          FutureBuilder(
              future: getThisUserDoc(ownerID),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.hasError) return snapshotHandler(snapshot);
                final ownerData =
                    snapshot.data!.data() as Map<dynamic, dynamic>;
                String formattedName =
                    '${ownerData[UserFields.firstName]} ${ownerData[UserFields.lastName]}';
                return blackInterBold(formattedName, fontSize: 16);
              })
        ], flex: 2),
      viewFlexActionsCell([
        TextButton(
            onPressed: () => launchThisURL(proofOfOwnership),
            child: blackInterBold(getFileName(proofOfOwnership),
                textDecoration: TextDecoration.underline))
      ], flex: 2),
      viewFlexActionsCell([
        TextButton(
            onPressed: () => launchThisURL(accrediation),
            child: blackInterBold(getFileName(accrediation),
                textDecoration: TextDecoration.underline))
      ], flex: 2),
      viewFlexActionsCell([
        if (isVerified ||
            ref.read(userTypeProvider).userType == UserTypes.owner)
          viewEntryButton(context,
              onPress: () => GoRouter.of(context).goNamed(GoRoutes.selectedDorm,
                  pathParameters: {PathParameters.dormID: dormDoc.id})),
        if (!isVerified &&
            ref.read(userTypeProvider).userType == UserTypes.admin) ...[
          ElevatedButton(
              onPressed: () =>
                  approveThisDormOwnership(context, ref, dormID: dormDoc.id),
              child: const Icon(Icons.check, color: Colors.white)),
          ElevatedButton(
              onPressed: () => displayDeleteEntryDialog(context,
                  message:
                      'Are you sure you want to deny this owner\'s dorm ownership and accreditation?',
                  deleteWord: 'Deny',
                  deleteEntry: () =>
                      denyThisDormOwnership(context, ref, dormID: dormDoc.id)),
              child: const Icon(Icons.block, color: Colors.white))
        ]
      ], flex: 2)
    ]);
  }
}
