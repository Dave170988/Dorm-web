import 'package:dorm_bnb_web/screens/add_faq_screen.dart';
import 'package:dorm_bnb_web/screens/edit_faq_screen.dart';
import 'package:dorm_bnb_web/screens/forgot_password_screen.dart';
import 'package:dorm_bnb_web/screens/owner_add_dorm_screen.dart';
import 'package:dorm_bnb_web/screens/register_screen.dart';
import 'package:dorm_bnb_web/screens/view_dorms_screen.dart';
import 'package:dorm_bnb_web/screens/view_faqs_screen.dart';
import 'package:dorm_bnb_web/screens/view_owners_screen.dart';
import 'package:dorm_bnb_web/screens/view_payments_screen.dart';
import 'package:dorm_bnb_web/screens/view_rentals_screen.dart';
import 'package:dorm_bnb_web/screens/view_renters_screen.dart';
import 'package:dorm_bnb_web/screens/view_selected_dorm_screen.dart';
import 'package:dorm_bnb_web/screens/view_selected_owner_screen.dart';
import 'package:dorm_bnb_web/screens/view_selected_renter_screen.dart';
import 'package:dorm_bnb_web/utils/string_util.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';

class GoRoutes {
  static const home = '/';
  static const register = 'register';
  static const forgotPassword = 'forgotPassword';
  static const owners = 'owners';
  static const selectedOwner = 'selectedOwner';
  static const renters = 'renters';
  static const selectedRenter = 'selectedRenter';
  static const dorms = 'dorms';
  static const selectedDorm = 'selectedDorm';
  static const addDorm = 'addDorm';
  static const faqs = 'faqs';
  static const addFAQ = 'addFAQ';
  static const editFAQ = 'editFAQ';
  static const rentals = 'rentals';
  static const payments = 'payments';
}

final GoRouter goRoutes = GoRouter(initialLocation: GoRoutes.home, routes: [
  GoRoute(
      name: GoRoutes.home,
      path: GoRoutes.home,
      pageBuilder: (context, state) =>
          customTransition(context, state, const HomeScreen()),
      routes: [
        GoRoute(
            name: GoRoutes.register,
            path: GoRoutes.register,
            pageBuilder: (context, state) =>
                customTransition(context, state, const RegisterScreen())),
        GoRoute(
            name: GoRoutes.forgotPassword,
            path: GoRoutes.forgotPassword,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ForgotPasswordScreen())),
        GoRoute(
            name: GoRoutes.owners,
            path: GoRoutes.owners,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewOwnersScreen())),
        GoRoute(
            name: GoRoutes.selectedOwner,
            path: '${GoRoutes.owners}/:${PathParameters.userID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedOwnerScreen(
                    userID: state.pathParameters[PathParameters.userID]!))),
        GoRoute(
            name: GoRoutes.renters,
            path: GoRoutes.renters,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewRentersScreen())),
        GoRoute(
            name: GoRoutes.selectedRenter,
            path: '${GoRoutes.renters}/:${PathParameters.userID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedRenterScreen(
                    userID: state.pathParameters[PathParameters.userID]!))),
        GoRoute(
            name: GoRoutes.dorms,
            path: GoRoutes.dorms,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewDormsScreen())),
        GoRoute(
            name: GoRoutes.addDorm,
            path: GoRoutes.addDorm,
            pageBuilder: (context, state) =>
                customTransition(context, state, const OwnerAddDormScreen())),
        GoRoute(
            name: GoRoutes.selectedDorm,
            path: '${GoRoutes.dorms}/:${PathParameters.dormID}',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                ViewSelectedDormScreen(
                    dormID: state.pathParameters[PathParameters.dormID]!))),
        GoRoute(
            name: GoRoutes.faqs,
            path: GoRoutes.faqs,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewFAQsScreen())),
        GoRoute(
            name: GoRoutes.addFAQ,
            path: '${GoRoutes.faqs}/add',
            pageBuilder: (context, state) =>
                customTransition(context, state, const AddFAQScreen())),
        GoRoute(
            name: GoRoutes.editFAQ,
            path: '${GoRoutes.faqs}/:${PathParameters.faqID}/edit',
            pageBuilder: (context, state) => customTransition(
                context,
                state,
                EditFAQScreen(
                    faqID: state.pathParameters[PathParameters.faqID]!))),
        GoRoute(
            name: GoRoutes.rentals,
            path: GoRoutes.rentals,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewRentalsScreen())),
        GoRoute(
            name: GoRoutes.payments,
            path: GoRoutes.payments,
            pageBuilder: (context, state) =>
                customTransition(context, state, const ViewPaymentsScreen())),
      ])
]);

CustomTransitionPage customTransition(
    BuildContext context, GoRouterState state, Widget widget) {
  return CustomTransitionPage(
      fullscreenDialog: true,
      key: state.pageKey,
      child: widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return easeInOutCircTransition(animation, child);
      });
}

FadeTransition easeInOutCircTransition(
    Animation<double> animation, Widget child) {
  return FadeTransition(
      opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
      child: child);
}
