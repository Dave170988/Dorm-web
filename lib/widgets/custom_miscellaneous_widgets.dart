import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/utils/go_router_util.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/dorms_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import 'custom_button_widgets.dart';
import 'custom_padding_widgets.dart';
import 'custom_text_field_widget.dart';

Widget stackedLoadingContainer(
    BuildContext context, bool isLoading, Widget child) {
  return Stack(children: [
    child,
    if (isLoading)
      Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.black.withOpacity(0.5),
          child: const Center(child: CircularProgressIndicator()))
  ]);
}

Widget switchedLoadingContainer(bool isLoading, Widget child) {
  return isLoading ? const Center(child: CircularProgressIndicator()) : child;
}

Widget loginFieldsContainer(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController,
    required TextEditingController passwordController}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          color: CustomColors.pearlWhite.withOpacity(0.8),
          border: Border.all(width: 3)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          vertical20Pix(child: blackInterBold('LOG-IN', fontSize: 40)),
          Divider(color: CustomColors.midnightBlue),
          emailAddressTextField(emailController: emailController),
          all10Pix(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              blackInterBold('Password', fontSize: 18),
              CustomTextField(
                  text: 'Password',
                  controller: passwordController,
                  textInputType: TextInputType.visiblePassword,
                  onSearchPress: () => logInUser(context, ref,
                      emailController: emailController,
                      passwordController: passwordController),
                  displayPrefixIcon: const Icon(Icons.lock)),
            ],
          )),
          Divider(color: CustomColors.midnightBlue),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () =>
                      GoRouter.of(context).goNamed(GoRoutes.forgotPassword),
                  child: blackInterRegular('Forgot Password?',
                      fontSize: 12, textDecoration: TextDecoration.underline))
            ],
          ),
          loginButton(
              onPress: () => logInUser(context, ref,
                  emailController: emailController,
                  passwordController: passwordController)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            blackInterRegular('Don\'t have an account?', fontSize: 12),
            TextButton(
                onPressed: () =>
                    GoRouter.of(context).goNamed(GoRoutes.register),
                child: blackInterRegular('Create an account',
                    fontSize: 12, textDecoration: TextDecoration.underline))
          ])
        ],
      ));
}

Widget registerFieldsContainer(BuildContext context, WidgetRef ref,
    {required String userType,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          color: CustomColors.murkyGreen.withOpacity(0.8),
          border: Border.all(width: 3)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          blackHelveticaBold('REGISTRATION', fontSize: 40),
          Divider(color: CustomColors.midnightBlue),
          emailAddressTextField(emailController: emailController),
          passwordTextField(
              label: 'Password', passwordController: passwordController),
          passwordTextField(
              label: 'Confirm Password',
              passwordController: confirmPasswordController),
          Divider(color: CustomColors.midnightBlue),
          regularTextField(
              label: 'First Name', textController: firstNameController),
          regularTextField(
              label: 'Last Name', textController: lastNameController),
          Divider(color: CustomColors.midnightBlue),
          registerButton(
              onPress: () => registerNewUser(context, ref,
                  userType: userType,
                  emailController: emailController,
                  passwordController: passwordController,
                  confirmPasswordController: confirmPasswordController,
                  firstNameController: firstNameController,
                  lastNameController: lastNameController)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            blackHelveticaRegular('Already have an account?', fontSize: 12),
            TextButton(
                onPressed: () => GoRouter.of(context).goNamed(GoRoutes.home),
                child: blackHelveticaRegular('Log-in to your account',
                    fontSize: 12, textDecoration: TextDecoration.underline))
          ])
        ],
      ));
}

Widget emailAddressTextField({required TextEditingController emailController}) {
  return all10Pix(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        blackHelveticaBold('Email Address', fontSize: 18),
        CustomTextField(
            text: 'Email Address',
            controller: emailController,
            textInputType: TextInputType.emailAddress,
            displayPrefixIcon: const Icon(Icons.email)),
      ],
    ),
  );
}

Widget passwordTextField(
    {required String label,
    required TextEditingController passwordController}) {
  return all10Pix(
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      blackHelveticaBold(label, fontSize: 18),
      CustomTextField(
          text: label,
          controller: passwordController,
          textInputType: TextInputType.visiblePassword,
          displayPrefixIcon: const Icon(Icons.lock)),
    ],
  ));
}

Widget regularTextField(
    {required String label, required TextEditingController textController}) {
  return all10Pix(
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      blackHelveticaBold(label, fontSize: 18),
      CustomTextField(
          text: label,
          controller: textController,
          textInputType: TextInputType.name,
          displayPrefixIcon: null),
    ],
  ));
}

Widget numberTextField(
    {required String label, required TextEditingController textController}) {
  return all10Pix(
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      blackHelveticaBold(label, fontSize: 18),
      CustomTextField(
          text: label,
          controller: textController,
          textInputType: TextInputType.number,
          displayPrefixIcon: null),
    ],
  ));
}

Widget multiLineTextField(
    {required String label, required TextEditingController textController}) {
  return all10Pix(
      child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      blackHelveticaBold(label, fontSize: 18),
      CustomTextField(
          text: label,
          controller: textController,
          textInputType: TextInputType.multiline,
          displayPrefixIcon: null),
    ],
  ));
}

Container viewContentContainer(BuildContext context, {required Widget child}) {
  return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        color: CustomColors.dirtyWhite,
        border: Border.all(color: CustomColors.pearlWhite),
      ),
      child: child);
}

Widget viewContentLabelRow(BuildContext context,
    {required List<Widget> children}) {
  return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Row(children: children));
}

Widget viewContentEntryRow(BuildContext context,
    {required List<Widget> children}) {
  return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: 50,
      child: Row(children: children));
}

Widget viewFlexTextCell(String text,
    {required int flex,
    backgroundColor = CustomColors.dirtyWhite,
    Color textColor = Colors.black,
    Border customBorder = const Border.symmetric(
        horizontal: BorderSide(color: CustomColors.pearlWhite)),
    BorderRadius? customBorderRadius}) {
  return Flexible(
    flex: flex,
    child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: backgroundColor,
            border: customBorder,
            borderRadius: customBorderRadius),
        child: ClipRRect(
          child: Center(
              child: SelectableText(text,
                  style: GoogleFonts.arimo(
                    textStyle: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))),
        )),
  );
}

Widget viewFlexLabelTextCell(String text, int flex) {
  return viewFlexTextCell(text,
      flex: flex,
      backgroundColor: CustomColors.dirtyWhite,
      textColor: Colors.black);
}

Widget viewFlexActionsCell(List<Widget> children,
    {required int flex,
    backgroundColor = CustomColors.dirtyWhite,
    Color textColor = Colors.black,
    Border customBorder = const Border.symmetric(
        horizontal: BorderSide(color: CustomColors.pearlWhite)),
    BorderRadius? customBorderRadius}) {
  return Flexible(
      flex: flex,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            border: customBorder,
            borderRadius: customBorderRadius,
            color: backgroundColor),
        child: Center(
            child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.spaceEvenly,
                spacing: 10,
                runSpacing: 10,
                children: children)),
      ));
}

Widget viewContentUnavailable(BuildContext context, {required String text}) {
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.65,
    child: Center(
        child: blackHelveticaBold(text,
            fontSize: 44, fontStyle: FontStyle.italic)),
  );
}

Widget analyticReportWidget(BuildContext context,
    {required String count,
    required String demographic,
    required Widget displayIcon,
    required Function? onPress}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Container(
        width: MediaQuery.of(context).size.width * 0.14,
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), color: Colors.white),
        padding: const EdgeInsets.all(4),
        child: Row(children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.08,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                blackInterBold(count, fontSize: 40),
                SizedBox(
                  height: 45,
                  child: ElevatedButton(
                    onPressed: onPress != null ? () => onPress() : null,
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    )),
                    child: Center(
                      child: blackInterBold(demographic, fontSize: 12),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.05,
              child: Transform.scale(scale: 2, child: displayIcon))
        ])),
  );
}

Widget buildProfileImage(
    {required String profileImageURL, double radius = 70}) {
  return profileImageURL.isNotEmpty
      ? Container(
          decoration:
              BoxDecoration(shape: BoxShape.circle, border: Border.all()),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: CustomColors.dirtyWhite,
            backgroundImage: NetworkImage(profileImageURL),
          ),
        )
      : Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(width: 3)),
          child: CircleAvatar(
              radius: radius,
              backgroundColor: CustomColors.dirtyWhite,
              child: Icon(Icons.person, color: Colors.black, size: 60)),
        );
}

Widget selectedMemoryImageDisplay(
    Uint8List? imageStream, Function deleteImage) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 40),
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SizedBox(
                width: 150, height: 150, child: Image.memory(imageStream!)),
            const SizedBox(height: 5),
            SizedBox(
              width: 90,
              child: ElevatedButton(
                  onPressed: () => deleteImage(),
                  child: const Icon(Icons.delete, color: Colors.white)),
            )
          ],
        ),
      ),
    ),
  );
}

Widget dormImageUploadWidget(BuildContext context, WidgetRef ref,
    {String dormID = ''}) {
  List<Widget> existingNetworkImages = ref
      .read(dormsProvider)
      .existingDormImages
      .map((image) =>
          selectedNetworkImage(context, ref, image: image, dormID: dormID))
      .toList();
  List<Widget> selectedFileImages = ref
      .read(dormsProvider)
      .dormImages
      .map((image) => selectedFileImage(context, ref, image: image))
      .toList();
  return Column(
    children: [
      Row(children: [blackInterBold('Dorm Images', fontSize: 18)]),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [...existingNetworkImages, ...selectedFileImages],
        ),
      ),
      ElevatedButton(
          onPressed: () async => ref.read(dormsProvider).setDormImages(),
          child: whiteInterBold('SELECT IMAGES OF DORM', fontSize: 12))
    ],
  );
}

Widget proofOfOwnershipUploadWidget(BuildContext context, WidgetRef ref) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [blackInterBold('Proof of Ownership', fontSize: 18)]),
        if (ref.read(dormsProvider).ownershipSelectedFileBytes != null)
          Container(
            decoration: BoxDecoration(border: Border.all()),
            child: blackInterRegular(ref.read(dormsProvider).ownershipFileName,
                textDecoration: TextDecoration.underline),
          ),
        ElevatedButton(
            onPressed: () => ref.read(dormsProvider).setProofOfOwnership(),
            child: whiteInterBold('SELECT PROOF OF OWNERSHIP', fontSize: 12))
      ],
    ),
  );
}

Widget proofOfAccreditationUploadWidget(BuildContext context, WidgetRef ref) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.3,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [blackInterBold('Proof of Accreditation', fontSize: 18)]),
        if (ref.read(dormsProvider).accreditationSelectedFileBytes != null)
          Container(
            decoration: BoxDecoration(border: Border.all()),
            child: blackInterRegular(
                ref.read(dormsProvider).accreditationFileName,
                textDecoration: TextDecoration.underline),
          ),
        ElevatedButton(
            onPressed: () => ref.read(dormsProvider).setAccreditation(),
            child:
                whiteInterBold('SELECT PROOF OF ACCREDITATION', fontSize: 12))
      ],
    ),
  );
}

Widget selectedNetworkImage(BuildContext context, WidgetRef ref,
    {required String dormID, required String image}) {
  return all10Pix(
    child: Column(
      children: [
        whiteInterRegular('SAVED ONLINE'),
        Image.network(image, width: 150, height: 150, fit: BoxFit.cover),
        ElevatedButton(
            onPressed: () {
              if (ref.read(dormsProvider).existingDormImages.length <= 1) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Dorm must have at least one saved image online')));
                return;
              } else {
                displayDeleteEntryDialog(context,
                    message:
                        'Are you sure you wish to remove this image from this dorm?',
                    deleteEntry: () => deleteDormImage(context, ref,
                        dormID: dormID, imageURL: image));
              }
            },
            child: const Icon(Icons.delete, color: Colors.white))
      ],
    ),
  );
}

Widget selectedFileImage(BuildContext context, WidgetRef ref,
    {required Uint8List image}) {
  return all10Pix(
    child: Column(
      children: [
        Image.memory(image, width: 150, height: 150, fit: BoxFit.cover),
        ElevatedButton(
            onPressed: () => ref.read(dormsProvider).removeDormFileImage(image),
            child: const Icon(Icons.delete, color: Colors.white))
      ],
    ),
  );
}

Widget snapshotHandler(AsyncSnapshot snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: const CircularProgressIndicator());
  } else if (!snapshot.hasData) {
    return const Text('No data found');
  } else if (snapshot.hasError) {
    return Text('Error gettin data: ${snapshot.error.toString()}');
  }
  return Container();
}

Widget rentalHistoryEntry(DocumentSnapshot rentalDoc,
    {bool showTenant = false}) {
  final rentalData = rentalDoc.data() as Map<dynamic, dynamic>;
  String dormID = rentalData[RentalFields.dormID];
  String renterID = rentalData[RentalFields.renterID];
  String status = rentalData[RentalFields.status];
  DateTime dateStart =
      (rentalData[RentalFields.dateStart] as Timestamp).toDate();
  DateTime dateEnd = (rentalData[RentalFields.dateEnd] as Timestamp).toDate();
  num monthsRequested = rentalData[RentalFields.monthsRequested];
  return FutureBuilder(
    future: getThisDormDoc(dormID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting ||
          !snapshot.hasData ||
          snapshot.hasError) return snapshotHandler(snapshot);
      final dormData = snapshot.data!.data() as Map<dynamic, dynamic>;
      List<dynamic> dormImageURLs = dormData[DormFields.dormImageURLs];
      String name = dormData[DormFields.name];
      String address = dormData[DormFields.address];
      num monthlyRent = dormData[DormFields.monthlyRent];
      return Container(
        decoration:
            BoxDecoration(color: CustomColors.pearlWhite, border: Border.all()),
        padding: EdgeInsets.all(20),
        child: Row(
          //crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(border: Border.all()),
              child: Image.network(
                dormImageURLs.first,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTenant)
                  FutureBuilder(
                    future: getThisUserDoc(renterID),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData ||
                          snapshot.hasError) return snapshotHandler(snapshot);
                      final userData =
                          snapshot.data!.data() as Map<dynamic, dynamic>;
                      final formattedName =
                          '${userData[UserFields.firstName]} ${userData[UserFields.lastName]}';
                      return Column(
                        children: [
                          blackInterBold('Tenant: $formattedName'),
                          Gap(8)
                        ],
                      );
                    },
                  ),
                blackInterBold(name, fontSize: 20),
                blackInterRegular(address,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 20),
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
