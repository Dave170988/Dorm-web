import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:dorm_bnb_web/widgets/left_navigator_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';

class ViewSelectedRenterScreen extends ConsumerStatefulWidget {
  final String userID;
  const ViewSelectedRenterScreen({super.key, required this.userID});

  @override
  ConsumerState<ViewSelectedRenterScreen> createState() =>
      _ViewSelectedRenterScreenState();
}

class _ViewSelectedRenterScreenState
    extends ConsumerState<ViewSelectedRenterScreen> {
  String formattedName = '';
  String profileImageURL = '';
  List<DocumentSnapshot> rentalDocs = [];

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

        final selectedUser = await getThisUserDoc(widget.userID);
        final selectedUserData = selectedUser.data() as Map<dynamic, dynamic>;
        formattedName =
            '${selectedUserData[UserFields.firstName]} ${selectedUserData[UserFields.lastName]}';
        profileImageURL = selectedUserData[UserFields.profileImageURL];
        rentalDocs = await getAllRenterRentals(widget.userID);
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting selected user data: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminLeftNavigator(context, path: GoRoutes.renters),
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
                color: CustomColors.pearlWhite,
                borderRadius: BorderRadius.circular(50)),
            child: switchedLoadingContainer(
                ref.read(loadingProvider).isLoading,
                SingleChildScrollView(
                  child: horizontal5Percent(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _backButton(),
                        _userDetails(),
                        rentalHistory()
                      ],
                    ),
                  ),
                )),
          )
        ],
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: backButton(context,
          onPress: () => GoRouter.of(context).goNamed(GoRoutes.renters)),
    );
  }

  Widget _userDetails() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 70),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 180,
            decoration: BoxDecoration(
                image: DecorationImage(
                    colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.2), BlendMode.dstATop),
                    image: AssetImage(ImagePaths.loginBG),
                    fit: BoxFit.cover),
                //color: CustomColors.pearlWhite,
                border: Border.all(width: 4)),
            padding: const EdgeInsets.all(20),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Gap(12),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [blackHelveticaBold(formattedName, fontSize: 40)],
              ),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: buildProfileImage(profileImageURL: profileImageURL),
        ),
      ],
    );
  }

  Widget rentalHistory() {
    return vertical20Pix(
      child: Container(
        width: double.infinity,
        decoration:
            BoxDecoration(color: CustomColors.dirtyWhite, border: Border.all()),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(children: [blackHelveticaBold('RENTAL HISTORY', fontSize: 36)]),
            rentalDocs.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: rentalDocs.length,
                    itemBuilder: (context, index) =>
                        rentalHistoryEntry(rentalDocs[index]),
                  )
                : blackHelveticaRegular('No Available Rental History')
          ],
        ),
      ),
    );
  }
}
