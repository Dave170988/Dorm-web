// ignore_for_file: unnecessary_cast

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_bnb_web/providers/user_type_provider.dart';
import 'package:dorm_bnb_web/providers/users_provider.dart';
import 'package:dorm_bnb_web/utils/date_util.dart';
import 'package:dorm_bnb_web/utils/go_router_util.dart';
import 'package:dorm_bnb_web/utils/string_util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dorms_provider.dart';
import '../providers/loading_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/rentals_provider.dart';

//==============================================================================
//USERS=========================================================================
//==============================================================================
bool hasLoggedInUser() {
  return FirebaseAuth.instance.currentUser != null;
}

Future logInUser(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController,
    required TextEditingController passwordController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);
    final userDoc = await getCurrentUserDoc();
    final userData = userDoc.data() as Map<dynamic, dynamic>;

    if (userData[UserFields.userType] == UserTypes.renter) {
      await FirebaseAuth.instance.signOut();
      scaffoldMessenger.showSnackBar(const SnackBar(
          content:
              Text('Only admins and owners may log-in to the web platform.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }

    //  reset the password in firebase in case client reset it using an email link.
    if (userData[UserFields.password] != passwordController.text) {
      await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({UserFields.password: passwordController.text});
    }
    ref.read(userTypeProvider).setUserType(userData[UserFields.userType]);
    ref.read(loadingProvider.notifier).toggleLoading(false);
    goRouter.goNamed(GoRoutes.home);
    goRouter.pushReplacementNamed(GoRoutes.home);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error logging in: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future registerNewUser(BuildContext context, WidgetRef ref,
    {required String userType,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required TextEditingController confirmPasswordController,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please fill up all given fields.')));
      return;
    }
    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.com')) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please input a valid email address')));
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('The passwords do not match')));
      return;
    }
    if (passwordController.text.length < 6) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('The password must be at least six characters long')));
      return;
    }
    //  Create user with Firebase Auth
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(), password: passwordController.text);

    //  Create new document is Firestore database
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      UserFields.email: emailController.text.trim(),
      UserFields.password: passwordController.text,
      UserFields.firstName: firstNameController.text.trim(),
      UserFields.lastName: lastNameController.text.trim(),
      UserFields.userType: userType,
      UserFields.profileImageURL: '',
      UserFields.isVerified: true
    });
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully registered new user')));
    await FirebaseAuth.instance.signOut();
    ref.read(loadingProvider).toggleLoading(false);

    goRouter.goNamed(GoRoutes.home);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error registering new user: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future sendResetPasswordEmail(BuildContext context, WidgetRef ref,
    {required TextEditingController emailController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (!emailController.text.contains('@') ||
      !emailController.text.contains('.com')) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please input a valid email address.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    final filteredUsers = await FirebaseFirestore.instance
        .collection(Collections.users)
        .where(UserFields.email, isEqualTo: emailController.text.trim())
        .get();

    if (filteredUsers.docs.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('There is no user with that email address.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }
    if (filteredUsers.docs.first.data()[UserFields.userType] ==
        UserTypes.admin) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('This feature is for users and collectors only.')));
      ref.read(loadingProvider.notifier).toggleLoading(false);
      return;
    }
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text.trim());
    ref.read(loadingProvider.notifier).toggleLoading(false);
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Successfully sent password reset email!')));
    goRouter.goNamed(GoRoutes.home);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error sending password reset email: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future<DocumentSnapshot> getCurrentUserDoc() async {
  return await getThisUserDoc(FirebaseAuth.instance.currentUser!.uid);
}

Future<DocumentSnapshot> getThisUserDoc(String userID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.users)
      .doc(userID)
      .get();
}

Future<String> getCurrentUserType() async {
  final userDoc = await getCurrentUserDoc();
  final userData = userDoc.data() as Map<dynamic, dynamic>;
  return userData[UserFields.userType];
}

Future<List<DocumentSnapshot>> getAllRenterDocs() async {
  final users = await FirebaseFirestore.instance
      .collection(Collections.users)
      .where(UserFields.userType, isEqualTo: UserTypes.renter)
      .get();
  return users.docs.map((user) => user as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllOwnerDocs() async {
  final users = await FirebaseFirestore.instance
      .collection(Collections.users)
      .where(UserFields.userType, isEqualTo: UserTypes.owner)
      .get();
  return users.docs.map((user) => user as DocumentSnapshot).toList();
}

Future approveThisRenter(BuildContext context, WidgetRef ref,
    {required String userID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(userID)
        .update({UserFields.isVerified: true});
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Successfully approved this renter\'s ID and proof of enrollment.')));
    ref.read(usersProvider).setUserDocs(await getAllRenterDocs());
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error approving this renter\'s ID and proof of enrollment: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

Future denyThisRenter(BuildContext context, WidgetRef ref,
    {required String userID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);

    //  Store admin's current data locally then sign out
    final currentUser = await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final currentUserData = currentUser.data() as Map<dynamic, dynamic>;
    String userEmail = currentUserData[UserFields.email];
    String userPassword = currentUserData[UserFields.password];
    await FirebaseAuth.instance.signOut();

    //  Log-in to the collector account to be deleted
    final collector = await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(userID)
        .get();
    final collectorData = collector.data() as Map<dynamic, dynamic>;
    String collectorEmail = collectorData[UserFields.email];
    String collectorPassword = collectorData[UserFields.password];
    final collectorToDelete = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
            email: collectorEmail, password: collectorPassword);
    await collectorToDelete.user!.delete();

    //  Log-back in to admin account
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: userEmail, password: userPassword);

    //  Delete student ID from Firebase Storage
    await FirebaseStorage.instance
        .ref()
        .child(StorageFields.studentIDs)
        .child('$userID.png')
        .delete();

//  Delete proof of enrollment from Firebase Storage
    final proofs = await FirebaseStorage.instance
        .ref()
        .child(StorageFields.proofOfEnrollments)
        .child(userID)
        .listAll();
    for (var proof in proofs.items) {
      await proof.delete();
    }

    //  Delete collector document from users Firestore collection
    await FirebaseFirestore.instance
        .collection(Collections.users)
        .doc(userID)
        .delete();
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Successfully denied this user\'s ID and proof of enrollment.')));
    ref.read(usersProvider).setUserDocs(await getAllRenterDocs());
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error denying this user\'s ID and proof of enrollment: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

//==============================================================================
//DORMS=========================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllDormDocs() async {
  final dorms =
      await FirebaseFirestore.instance.collection(Collections.dorms).get();
  return dorms.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<DocumentSnapshot> getThisDormDoc(String dormID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.dorms)
      .doc(dormID)
      .get();
}

Future<List<DocumentSnapshot>> getAllOwnerDormDocs(
    {required String ownerID}) async {
  final dorms = await FirebaseFirestore.instance
      .collection(Collections.dorms)
      .where(DormFields.ownerID, isEqualTo: ownerID)
      .get();
  return dorms.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllUserDormDocs() async {
  return await getAllOwnerDormDocs(
      ownerID: FirebaseAuth.instance.currentUser!.uid);
}

Future addNewDorm(BuildContext context, WidgetRef ref,
    {required TextEditingController nameController,
    required TextEditingController addressController,
    required TextEditingController descriptionController,
    required TextEditingController rentController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please indicate a dorm name.')));
    return;
  }
  if (addressController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please indicate the dorm address.')));
    return;
  }
  if (descriptionController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please indicate the dorm description.')));
    return;
  }
  if (rentController.text.isEmpty ||
      double.tryParse(rentController.text) == null ||
      double.parse(rentController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Please input a valid rent amount higher than PHP 0.00')));
    return;
  }
  if (ref.read(dormsProvider).dormImages.isEmpty) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please upload at least one dorm image.')));
    return;
  }
  if (ref.read(dormsProvider).ownershipSelectedFileBytes == null) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please select a proof of ownership document.')));
    return;
  }
  if (ref.read(dormsProvider).accreditationSelectedFileBytes == null) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text('Please select an accreditation document.')));
    return;
  }
  try {
    ref.read(loadingProvider).toggleLoading(true);

    final dormReference =
        await FirebaseFirestore.instance.collection(Collections.dorms).add({
      DormFields.ownerID: FirebaseAuth.instance.currentUser!.uid,
      DormFields.isAvailable: false,
      DormFields.isVerified: false,
      DormFields.name: nameController.text.trim(),
      DormFields.description: descriptionController.text.trim(),
      DormFields.address: addressController.text.trim(),
      DormFields.monthlyRent: double.parse(rentController.text.trim())
    });

    //  Upload vehicle image
    List<String> dormImages = [];
    for (Uint8List dormImage in ref.read(dormsProvider).dormImages) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.dormImages)
          .child(dormReference.id)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef.putData(dormImage);
      final taskSnapshot = await uploadTask;
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();
      dormImages.add(downloadURL);
    }

    //  Upload dorm ownership
    final storageRef2 = FirebaseStorage.instance
        .ref()
        .child(StorageFields.proofOfOwnerships)
        .child(dormReference.id)
        .child(ref.read(dormsProvider).ownershipFileName);
    final uploadTask2 = storageRef2
        .putData(ref.read(dormsProvider).ownershipSelectedFileBytes!);
    final taskSnapshot2 = await uploadTask2;
    final String proofOfOwnership = await taskSnapshot2.ref.getDownloadURL();

    //  Upload dorm accreditation
    final storageRef3 = FirebaseStorage.instance
        .ref()
        .child(StorageFields.accreditations)
        .child(dormReference.id)
        .child(ref.read(dormsProvider).accreditationFileName);
    final uploadTask3 = storageRef3
        .putData(ref.read(dormsProvider).ownershipSelectedFileBytes!);
    final taskSnapshot3 = await uploadTask3;
    final String accreditation = await taskSnapshot3.ref.getDownloadURL();

    //  Set vehicle image and ownership URLs in Firestore
    await FirebaseFirestore.instance
        .collection(Collections.dorms)
        .doc(dormReference.id)
        .update({
      DormFields.proofOfOwnership: proofOfOwnership,
      DormFields.accreditation: accreditation,
      DormFields.dormImageURLs: dormImages
    });

    //  Vehicle has been added and we will now return to the vehicles list.
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new dorm!')));
    ref.read(loadingProvider).toggleLoading(false);
    ref.read(dormsProvider).resetDorm();
    goRouter.goNamed(GoRoutes.dorms);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error adding new dorm: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

Future editThisDorm(BuildContext context, WidgetRef ref,
    {required String dormID,
    required TextEditingController nameController,
    required TextEditingController addressController,
    required TextEditingController descriptionController,
    required TextEditingController rentController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (nameController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please indicate a dorm name.')));
    return;
  }
  if (addressController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please indicate the dorm address.')));
    return;
  }
  if (descriptionController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please indicate the dorm description.')));
    return;
  }
  if (rentController.text.isEmpty ||
      double.tryParse(rentController.text) == null ||
      double.parse(rentController.text) <= 0) {
    scaffoldMessenger.showSnackBar(const SnackBar(
        content:
            Text('Please input a valid rent amount higher than PHP 0.00')));
    return;
  }
  try {
    ref.read(loadingProvider).toggleLoading(true);

    await FirebaseFirestore.instance
        .collection(Collections.dorms)
        .doc(dormID)
        .update({
      DormFields.name: nameController.text.trim(),
      DormFields.description: descriptionController.text.trim(),
      DormFields.address: addressController.text.trim(),
      DormFields.monthlyRent: double.parse(rentController.text.trim())
    });

    //  Upload vehicle image
    List<String> dormImages = [];
    for (Uint8List dormImage in ref.read(dormsProvider).dormImages) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child(StorageFields.dormImages)
          .child(dormID)
          .child('${generateRandomHexString(6)}.png');
      final uploadTask = storageRef.putData(dormImage);
      final taskSnapshot = await uploadTask;
      final String downloadURL = await taskSnapshot.ref.getDownloadURL();
      dormImages.add(downloadURL);
    }

    //  Set vehicle image and ownership URLs in Firestore
    await FirebaseFirestore.instance
        .collection(Collections.dorms)
        .doc(dormID)
        .update({DormFields.dormImageURLs: FieldValue.arrayUnion(dormImages)});

    //  Vehicle has been added and we will now return to the vehicles list.
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this dorm!')));
    ref.read(loadingProvider).toggleLoading(false);
    ref.read(dormsProvider).resetDorm();
    goRouter.goNamed(GoRoutes.dorms);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error adding new dorm: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

Future deleteDormImage(BuildContext context, WidgetRef ref,
    {required String dormID, required String imageURL}) async {
  try {
    await FirebaseFirestore.instance
        .collection(Collections.dorms)
        .doc(dormID)
        .update({
      DormFields.dormImageURLs: FieldValue.arrayRemove([imageURL])
    });
    final dorm = await getThisDormDoc(dormID);
    final dormData = dorm.data() as Map<dynamic, dynamic>;

    ref
        .read(dormsProvider)
        .setDormNetworkImages(dormData[DormFields.dormImageURLs]);
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting dorm image: $error')));
  }
}

Future approveThisDormOwnership(BuildContext context, WidgetRef ref,
    {required String dormID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.dorms)
        .doc(dormID)
        .update({DormFields.isVerified: true});
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Successfully approved this user\'s dorm ownership and accreditation.')));
    ref.read(dormsProvider).setDormDocs(await getAllDormDocs());
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error approving this user\'s dorm ownership and accreditation: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

Future denyThisDormOwnership(BuildContext context, WidgetRef ref,
    {required String dormID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    ref.read(loadingProvider).toggleLoading(true);
    final images = await FirebaseStorage.instance
        .ref()
        .child(StorageFields.dormImages)
        .child(dormID)
        .listAll();
    for (var image in images.items) {
      await image.delete();
    }

    final ownershipDocs = await FirebaseStorage.instance
        .ref()
        .child(StorageFields.proofOfOwnerships)
        .child(dormID)
        .listAll();
    for (var doc in ownershipDocs.items) {
      await doc.delete();
    }
    final accreditationDocs = await FirebaseStorage.instance
        .ref()
        .child(StorageFields.accreditations)
        .child(dormID)
        .listAll();
    for (var doc in accreditationDocs.items) {
      await doc.delete();
    }
    await FirebaseFirestore.instance
        .collection(Collections.dorms)
        .doc(dormID)
        .delete();
    scaffoldMessenger.showSnackBar(const SnackBar(
        content: Text(
            'Successfully denied this user\'s dorm ownership and accreditation.')));
    ref.read(dormsProvider).setDormDocs(await getAllDormDocs());
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            'Error denying this user\'s dorm ownership accreditation: $error')));
    ref.read(loadingProvider).toggleLoading(false);
  }
}

//==============================================================================
//RENTALS=======================================================================
//==============================================================================
Future<DocumentSnapshot> getThisRentalDoc(String rentalID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.rentals)
      .doc(rentalID)
      .get();
}

Future<List<DocumentSnapshot>> getAllRentalsDocs() async {
  final rentals =
      await FirebaseFirestore.instance.collection(Collections.rentals).get();
  return rentals.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllRenterRentals(String renterID) async {
  final rentals = await FirebaseFirestore.instance
      .collection(Collections.rentals)
      .where(RentalFields.renterID, isEqualTo: renterID)
      .get();
  return rentals.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllOwnerRentals(String owner) async {
  final rentals = await FirebaseFirestore.instance
      .collection(Collections.rentals)
      .where(RentalFields.ownerID, isEqualTo: owner)
      .get();
  return rentals.docs.map((e) => e as DocumentSnapshot).toList();
}

Future<List<DocumentSnapshot>> getAllDormRentals(String dormID) async {
  final rentals = await FirebaseFirestore.instance
      .collection(Collections.rentals)
      .where(RentalFields.dormID, isEqualTo: dormID)
      .get();
  return rentals.docs.map((e) => e as DocumentSnapshot).toList();
}

Future acceptRentalRequest(BuildContext context, WidgetRef ref,
    {required String rentalID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    await FirebaseFirestore.instance
        .collection(Collections.rentals)
        .doc(rentalID)
        .update({
      RentalFields.status: RentalStatus.pendingPayment,
      RentalFields.dateProcessed: DateTime.now()
    });
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Rental Request Accepted')));
    ref.read(rentalsProvider).setRentalDocs(await getAllRentalsDocs());
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error accepting rental request: $error')));
  }
}

Future denyRentalRequest(BuildContext context, WidgetRef ref,
    {required String rentalID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    await FirebaseFirestore.instance
        .collection(Collections.rentals)
        .doc(rentalID)
        .update({
      RentalFields.status: RentalStatus.denied,
      RentalFields.dateProcessed: DateTime.now()
    });
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Rental Request Denied')));
    ref.read(rentalsProvider).setRentalDocs(await getAllRentalsDocs());
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error denying rental request: $error')));
  }
}

//==============================================================================
//==PAYMENTS====================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllPaymentDocs() async {
  final payments =
      await FirebaseFirestore.instance.collection(Collections.payments).get();
  return payments.docs.map((e) => e as DocumentSnapshot).toList();
}

Future approveThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID, required String rentalID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentID)
        .update({
      PaymentFields.isVerified: true,
      PaymentFields.paymentStatus: PaymentStatuses.approved,
      PaymentFields.dateProcessed: DateTime.now()
    });
    final rentalDoc = await getThisRentalDoc(rentalID);
    final rentalData = rentalDoc.data() as Map<dynamic, dynamic>;
    DateTime nextPaymentDeadline =
        (rentalData[RentalFields.nextPaymentDeadline] as Timestamp).toDate();
    await FirebaseFirestore.instance
        .collection(Collections.rentals)
        .doc(rentalID)
        .update({
      RentalFields.status: RentalStatus.inUse,
      RentalFields.nextPaymentDeadline: (addMonths(nextPaymentDeadline, 1))
    });
    ref.read(paymentsProvider).setPaymentDocs(await getAllPaymentDocs());
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully approved this payment')));
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error approving this payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future denyThisPayment(BuildContext context, WidgetRef ref,
    {required String paymentID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  try {
    await FirebaseFirestore.instance
        .collection(Collections.payments)
        .doc(paymentID)
        .update({
      PaymentFields.isVerified: true,
      PaymentFields.paymentStatus: PaymentStatuses.denied,
      PaymentFields.dateProcessed: DateTime.now()
    });

    await FirebaseFirestore.instance
        .collection(Collections.rentals)
        .doc(paymentID)
        .update({RentalFields.status: RentalStatus.pendingPayment});
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully denied this payment')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error denying this payment: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

//==============================================================================
//==FAQS========================================================================
//==============================================================================
Future<List<DocumentSnapshot>> getAllFAQs() async {
  final faqs =
      await FirebaseFirestore.instance.collection(Collections.faqs).get();
  return faqs.docs;
}

Future<DocumentSnapshot> getThisFAQDoc(String faqID) async {
  return await FirebaseFirestore.instance
      .collection(Collections.faqs)
      .doc(faqID)
      .get();
}

Future addFAQEntry(BuildContext context, WidgetRef ref,
    {required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (questionController.text.isEmpty || answerController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    String faqID = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .set({
      FAQFields.question: questionController.text.trim(),
      FAQFields.answer: answerController.text.trim()
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully added new FAQ.')));
    goRouter.goNamed(GoRoutes.faqs);
  } catch (error) {
    scaffoldMessenger
        .showSnackBar(SnackBar(content: Text('Error adding FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future editFAQEntry(BuildContext context, WidgetRef ref,
    {required String faqID,
    required TextEditingController questionController,
    required TextEditingController answerController}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  if (questionController.text.isEmpty || answerController.text.isEmpty) {
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill up all fields.')));
    return;
  }
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .update({
      FAQFields.question: questionController.text.trim(),
      FAQFields.answer: answerController.text.trim()
    });
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully edited this FAQ.')));
    goRouter.goNamed(GoRoutes.faqs);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error editing this FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}

Future deleteFAQEntry(BuildContext context, WidgetRef ref,
    {required String faqID}) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final goRouter = GoRouter.of(context);
  try {
    ref.read(loadingProvider.notifier).toggleLoading(true);
    await FirebaseFirestore.instance
        .collection(Collections.faqs)
        .doc(faqID)
        .delete();
    ref.read(loadingProvider.notifier).toggleLoading(false);

    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Successfully deleted this FAQ.')));
    goRouter.pushReplacementNamed(GoRoutes.faqs);
  } catch (error) {
    scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting this FAQ: $error')));
    ref.read(loadingProvider.notifier).toggleLoading(false);
  }
}
