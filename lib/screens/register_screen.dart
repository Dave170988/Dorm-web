import 'package:dorm_bnb_web/providers/loading_provider.dart';
import 'package:dorm_bnb_web/utils/string_util.dart';
import 'package:dorm_bnb_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/color_util.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    image: AssetImage(ImagePaths.loginBG), fit: BoxFit.fill)),
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
            right: 0,
            child: registerFieldsContainer(context, ref,
                userType: UserTypes.owner,
                emailController: emailController,
                passwordController: passwordController,
                confirmPasswordController: confirmPasswordController,
                firstNameController: firstNameController,
                lastNameController: lastNameController),
          )
        ],
      ),
    ));
  }
}
