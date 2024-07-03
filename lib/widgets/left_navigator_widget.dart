import 'package:dorm_bnb_web/utils/string_util.dart';
import 'package:dorm_bnb_web/widgets/custom_padding_widgets.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/color_util.dart';
import '../utils/go_router_util.dart';

Widget adminLeftNavigator(BuildContext context, {required String path}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.15,
    height: MediaQuery.of(context).size.height,
    decoration: BoxDecoration(color: CustomColors.dirtyWhite),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        all10Pix(
          child: Image.asset(ImagePaths.logo,
              width: MediaQuery.of(context).size.width * 0.1, height: 150),
        ),
        Gap(20),
        Flexible(
            child: ListView(
          padding: EdgeInsets.zero,
          children: [
            listTile(context,
                label: 'Dashboard', thisPath: GoRoutes.home, currentPath: path),
            listTile(context,
                label: 'Owners', thisPath: GoRoutes.owners, currentPath: path),
            listTile(context,
                label: 'Students',
                thisPath: GoRoutes.renters,
                currentPath: path),
            listTile(context,
                label: 'Dorms', thisPath: GoRoutes.dorms, currentPath: path),
            listTile(context,
                label: 'Payments',
                thisPath: GoRoutes.payments,
                currentPath: path),
            listTile(context,
                label: 'FAQs', thisPath: GoRoutes.faqs, currentPath: path),
          ],
        )),
        all10Pix(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: CustomColors.pearlWhite, width: 3)),
            child: ListTile(
                title: blackHelveticaBold('Log Out', textAlign: TextAlign.left),
                onTap: () {
                  FirebaseAuth.instance.signOut().then((value) {
                    GoRouter.of(context).goNamed(GoRoutes.home);
                    GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
                  });
                }),
          ),
        )
      ],
    ),
  );
}

Widget ownerLeftNavigator(BuildContext context, {required String path}) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.15,
    height: MediaQuery.of(context).size.height,
    decoration: BoxDecoration(color: CustomColors.dirtyWhite),
    child: Column(
      children: [
        Flexible(
            child: ListView(
          padding: EdgeInsets.zero,
          children: [
            all10Pix(
              child: Image.asset(ImagePaths.logo,
                  width: MediaQuery.of(context).size.width * 0.1, height: 150),
            ),
            Gap(20),
            listTile(context,
                label: 'Dashboard', thisPath: GoRoutes.home, currentPath: path),
            listTile(context,
                label: 'Dorms', thisPath: GoRoutes.dorms, currentPath: path),
            listTile(context,
                label: 'Rentals',
                thisPath: GoRoutes.rentals,
                currentPath: path),
          ],
        )),
        all10Pix(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: CustomColors.pearlWhite)),
            child: ListTile(
                title: const Text('Log Out',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                onTap: () {
                  FirebaseAuth.instance.signOut().then((value) {
                    GoRouter.of(context).goNamed(GoRoutes.home);
                    GoRouter.of(context).pushReplacementNamed(GoRoutes.home);
                  });
                }),
          ),
        )
      ],
    ),
  );
}

Widget listTile(BuildContext context,
    {required String label,
    required String thisPath,
    required String currentPath,
    double fontSize = 12,
    bool isBold = true}) {
  return Container(
      decoration: BoxDecoration(
          color: thisPath == currentPath ? CustomColors.pearlWhite : null),
      child: ListTile(
          title: Text(label,
              style: GoogleFonts.arimo(
                  textStyle: TextStyle(
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                      color: Colors.black,
                      fontWeight:
                          isBold ? FontWeight.bold : FontWeight.normal))),
          onTap: () {
            if (thisPath.isEmpty || thisPath == currentPath) {
              return;
            }
            GoRouter.of(context).goNamed(thisPath);
            if (thisPath == GoRoutes.home) {
              GoRouter.of(context).pushReplacementNamed(thisPath);
            }
          }));
}
