import 'package:dorm_bnb_web/utils/go_router_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_button_widgets.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    return Scaffold(
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(ImagePaths.loginBG),
                        fit: BoxFit.fill)),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: CustomColors.midnightBlue.withOpacity(0.7),
                child: Row(
                  children: [
                    SizedBox(
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [Image.asset(ImagePaths.logo)],
                        )),
                  ],
                ),
              ),
              Positioned(
                  child: all20Pix(
                      child: Row(children: [
                backButton(context,
                    onPress: () => GoRouter.of(context).goNamed(GoRoutes.home))
              ]))),
              Positioned(
                right: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                      color: CustomColors.murkyGreen,
                      border: Border.all(width: 3)),
                  child: all20Pix(
                      child: Column(
                    children: [
                      blackInterBold('RESET PASSWORD', fontSize: 35),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              emailAddressTextField(
                                  emailController: emailController),
                              sendPasswordResetEmailButton(
                                  onPress: () => sendResetPasswordEmail(
                                      context, ref,
                                      emailController: emailController)),
                            ],
                          ))
                    ],
                  )),
                ),
              ),
            ],
          )),
    );
  }
}
