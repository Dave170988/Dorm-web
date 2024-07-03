import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/utils/color_util.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';

class ViewOwnersScreen extends ConsumerStatefulWidget {
  const ViewOwnersScreen({super.key});

  @override
  ConsumerState<ViewOwnersScreen> createState() => _ViewOwnersScreenState();
}

class _ViewOwnersScreenState extends ConsumerState<ViewOwnersScreen> {
  List<DocumentSnapshot> ownerDocs = [];
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
        ownerDocs = await getAllOwnerDocs();
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting all supervisors: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      //appBar: appBarWidget(),
      body: switchedLoadingContainer(
        ref.read(loadingProvider).isLoading,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            adminLeftNavigator(context, path: GoRoutes.owners),
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
                          blackHelveticaBold('REGISTERED DORM OWNERS',
                              fontSize: 40, fontStyle: FontStyle.italic)
                        ])),
                        viewContentContainer(context,
                            child: Column(
                              children: [
                                _ownersLabelRow(),
                                ownerDocs.isNotEmpty
                                    ? _ownerEntries()
                                    : viewContentUnavailable(context,
                                        text: 'NO AVAILABLE OWNERS'),
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

  Widget _ownersLabelRow() {
    return viewContentLabelRow(context, children: [
      viewFlexLabelTextCell('Profile Picture', 1),
      viewFlexLabelTextCell('Name', 4),
      viewFlexLabelTextCell('Actions', 2)
    ]);
  }

  Widget _ownerEntries() {
    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ownerDocs.length,
            itemBuilder: (context, index) {
              return _userEntry(ownerDocs[index], index);
            }));
  }

  Widget _userEntry(DocumentSnapshot userDoc, int index) {
    final userData = userDoc.data() as Map<dynamic, dynamic>;
    String formattedName =
        '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
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
      viewFlexTextCell(formattedName, flex: 4),
      viewFlexActionsCell([
        viewEntryButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.selectedOwner,
                pathParameters: {PathParameters.userID: userDoc.id}))
      ], flex: 2)
    ]);
  }
}
