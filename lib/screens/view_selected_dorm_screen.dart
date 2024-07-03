import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/loading_provider.dart';
import '../providers/user_type_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';

class ViewSelectedDormScreen extends ConsumerStatefulWidget {
  final String dormID;
  const ViewSelectedDormScreen({super.key, required this.dormID});

  @override
  ConsumerState<ViewSelectedDormScreen> createState() =>
      _ViewSelectedDormScreenState();
}

class _ViewSelectedDormScreenState
    extends ConsumerState<ViewSelectedDormScreen> {
  String name = '';
  String address = '';
  String description = '';
  bool isVerified = false;
  num monthlyRent = 0;
  List<dynamic> imageURLs = [];
  String proofOfOwnership = '';
  List<DocumentSnapshot> rentalDocs = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        final dorm = await getThisDormDoc(widget.dormID);
        final dormData = dorm.data() as Map<dynamic, dynamic>;
        name = dormData[DormFields.name];
        address = dormData[DormFields.address];
        description = dormData[DormFields.description];
        imageURLs = dormData[DormFields.dormImageURLs];
        isVerified = dormData[DormFields.isVerified];
        proofOfOwnership = dormData[DormFields.proofOfOwnership];
        monthlyRent = dormData[DormFields.monthlyRent];
        rentalDocs = await getAllDormRentals(widget.dormID);
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error getting selected dorm detials: $error')));
        ref.read(loadingProvider).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      children: [_backButton(), dormDetails(), rentalHistory()],
                    )),
              )),
        )
      ]),
    );
  }

  Widget _backButton() {
    return Row(children: [
      vertical20Pix(
        child: backButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.dorms)),
      )
    ]);
  }

  Widget dormDetails() {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: 400,
          decoration: BoxDecoration(
              border: Border.all(),
              image: imageURLs.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageURLs.first),
                      fit: BoxFit.fitWidth)
                  : null),
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7 - 2,
            height: 150,
            color: CustomColors.pearlWhite.withOpacity(0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                blackHelveticaBold(name, fontSize: 30),
                blackHelveticaRegular('Address: $address'),
                const Gap(20),
                blackHelveticaRegular('Description'),
                blackHelveticaRegular(description),
              ],
            ),
          ),
        )
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
                    itemBuilder: (context, index) => rentalEntry(
                        rentalDocs[index],
                        showOwner: ref.read(userTypeProvider).userType ==
                            UserTypes.admin),
                  )
                : blackHelveticaRegular('No Available Rental History')
          ],
        ),
      ),
    );
  }

  Widget rentalEntry(DocumentSnapshot rentalDoc, {bool showOwner = true}) {
    final rentalData = rentalDoc.data() as Map<dynamic, dynamic>;
    String renterID = rentalData[RentalFields.renterID];
    String ownerID = rentalData[RentalFields.ownerID];
    String status = rentalData[RentalFields.status];
    DateTime dateStart =
        (rentalData[RentalFields.dateStart] as Timestamp).toDate();
    DateTime dateEnd = (rentalData[RentalFields.dateEnd] as Timestamp).toDate();
    num monthsRequested = rentalData[RentalFields.monthsRequested];
    return FutureBuilder(
      future: getThisUserDoc(renterID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.hasError) return snapshotHandler(snapshot);
        final userData = snapshot.data!.data() as Map<dynamic, dynamic>;
        String profileImageURL = userData[UserFields.profileImageURL];
        final formattedName =
            '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
        return Container(
          decoration: BoxDecoration(
              color: CustomColors.pearlWhite, border: Border.all()),
          padding: EdgeInsets.all(20),
          child: Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildProfileImage(profileImageURL: profileImageURL),
              Gap(20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showOwner)
                    FutureBuilder(
                      future: getThisUserDoc(ownerID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            !snapshot.hasData ||
                            snapshot.hasError) return snapshotHandler(snapshot);
                        final userData =
                            snapshot.data!.data() as Map<dynamic, dynamic>;
                        final formattedName =
                            '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
                        return blackInterBold('Owner: $formattedName',
                            fontSize: 18);
                      },
                    ),
                  blackInterBold('Tenant: $formattedName', fontSize: 18),
                  Gap(20),
                  blackInterBold(
                      'Monthly Rent: PHP ${formatPrice(monthlyRent.toDouble())}',
                      fontSize: 16),
                  blackInterRegular('Rental Period: $monthsRequested months',
                      fontSize: 16),
                  blackInterRegular(
                      '${DateFormat('MMM dd, yyyy').format(dateStart)} - ${DateFormat('MMM dd, yyyy').format(dateEnd)}',
                      fontSize: 16),
                  Gap(10),
                  blackInterBold('Status: $status')
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
