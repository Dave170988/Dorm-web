import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/providers/users_provider.dart';
import 'package:dorm_bnb_web/utils/url_util.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';

class ViewRentersScreen extends ConsumerStatefulWidget {
  const ViewRentersScreen({super.key});

  @override
  ConsumerState<ViewRentersScreen> createState() => _ViewRentersScreenState();
}

class _ViewRentersScreenState extends ConsumerState<ViewRentersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        String userType = await getCurrentUserType();
        if (userType == UserTypes.owner) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(usersProvider).setUserDocs(await getAllRenterDocs());
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all renters: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: switchedLoadingContainer(
        ref.read(loadingProvider).isLoading,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminLeftNavigator(context, path: GoRoutes.renters),
            Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                  color: CustomColors.pearlWhite,
                  borderRadius: BorderRadius.circular(50)),
              child: SingleChildScrollView(
                child: horizontal5Percent(context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        vertical20Pix(
                            child: Row(children: [
                          blackHelveticaBold('REGISTERED STUDENTS',
                              fontSize: 40, fontStyle: FontStyle.italic)
                        ])),
                        viewContentContainer(context,
                            child: Column(
                              children: [
                                _rentersLabelRow(),
                                ref.read(usersProvider).userDocs.isNotEmpty
                                    ? _rentersEntries()
                                    : viewContentUnavailable(context,
                                        text: 'NO AVAILABLE RENTERS'),
                              ],
                            )),
                      ],
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _rentersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Profile Picture', 1),
      viewFlexLabelTextCell('Name', 3),
      viewFlexLabelTextCell('Student ID', 2),
      viewFlexLabelTextCell('Enrollment', 2),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _rentersEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ref.read(usersProvider).userDocs.length,
            itemBuilder: (context, index) {
              return _userEntry(ref.read(usersProvider).userDocs[index], index);
            }));
  }

  Widget _userEntry(DocumentSnapshot userDoc, int index) {
    final userData = userDoc.data() as Map<dynamic, dynamic>;
    String formattedName =
        '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
    String studentID = userData[UserFields.studentID];
    String proofOfEnrollment = userData[UserFields.proofOfEnrollment];
    bool isVerified = userData[UserFields.isVerified];
    String profileImageURL = userData[UserFields.profileImageURL];

    return viewContentEntryRow(context, children: [
      viewFlexActionsCell([
        profileImageURL.isNotEmpty
            ? Image.network(profileImageURL, width: 30, height: 30)
            : Container(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, border: Border.all()),
                child: Icon(Icons.person_2_sharp))
      ], flex: 1),
      viewFlexTextCell(formattedName, flex: 3),
      viewFlexActionsCell([
        ElevatedButton(
            onPressed: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(),
                      content: SingleChildScrollView(
                        child: Image.network(
                          studentID,
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: MediaQuery.of(context).size.width * 0.3,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )),
            child: whiteInterBold('VIEW STUDENT ID'))
      ], flex: 2),
      viewFlexActionsCell([
        TextButton(
            onPressed: () => launchThisURL(proofOfEnrollment),
            child: blackInterBold(getFileName(proofOfEnrollment),
                textDecoration: TextDecoration.underline))
      ], flex: 2),
      viewFlexActionsCell([
        if (isVerified)
          viewEntryButton(context,
              onPress: () => GoRouter.of(context).goNamed(
                  GoRoutes.selectedRenter,
                  pathParameters: {PathParameters.userID: userDoc.id}))
        else ...[
          ElevatedButton(
              onPressed: () =>
                  approveThisRenter(context, ref, userID: userDoc.id),
              child: const Icon(Icons.check, color: Colors.white)),
          ElevatedButton(
              onPressed: () => displayDeleteEntryDialog(context,
                  message:
                      'Are you sure you want to deny this student\'s ID and proof of enrollment? This account will be deleted.',
                  deleteWord: 'Deny',
                  deleteEntry: () =>
                      denyThisRenter(context, ref, userID: userDoc.id)),
              child: const Icon(Icons.block, color: Colors.white))
        ]
      ], flex: 2)
    ]);
  }
}
