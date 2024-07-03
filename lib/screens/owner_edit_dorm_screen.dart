import 'package:dorm_bnb_web/utils/go_router_util.dart';
import 'package:dorm_bnb_web/widgets/custom_button_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/dorms_provider.dart';
import '../providers/loading_provider.dart';
import '../utils/color_util.dart';
import '../utils/firebase_util.dart';
import '../utils/string_util.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/custom_miscellaneous_widgets.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/custom_text_widgets.dart';

class OwnerEditDormScreen extends ConsumerStatefulWidget {
  final String dormID;
  const OwnerEditDormScreen({super.key, required this.dormID});

  @override
  ConsumerState<OwnerEditDormScreen> createState() =>
      _OwnerEditDormScreenState();
}

class _OwnerEditDormScreenState extends ConsumerState<OwnerEditDormScreen> {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final rentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);

          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        if (userData[UserFields.userType] == UserTypes.admin) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(dormsProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: appBarWidget(),
        body: stackedLoadingContainer(
            context,
            ref.read(loadingProvider).isLoading,
            SingleChildScrollView(
                child: horizontal5Percent(
              context,
              child: Column(
                children: [
                  _backButton(),
                  blackInterBold('EDIT DORM', fontSize: 36),
                  _dormFields(),
                  _submitButton()
                ],
              ),
            ))),
      ),
    );
  }

  Widget _backButton() {
    return vertical20Pix(
      child: Row(children: [
        backButton(context,
            onPress: () => GoRouter.of(context).goNamed(GoRoutes.dorms))
      ]),
    );
  }

  Widget _dormFields() {
    return Container(
        decoration: BoxDecoration(
            color: CustomColors.murkyGreen,
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            regularTextField(label: 'Name', textController: nameController),
            regularTextField(
                label: 'Address', textController: addressController),
            multiLineTextField(
                label: 'Description', textController: descriptionController),
            numberTextField(
                label: 'Monthly Rent', textController: rentController),
            const Divider(color: CustomColors.midnightBlue),
            vertical20Pix(child: dormImageUploadWidget(context, ref)),
            const Divider(color: CustomColors.midnightBlue),
          ],
        ));
  }

  Widget _submitButton() {
    return vertical20Pix(
        child: ElevatedButton(
            onPressed: () => addNewDorm(context, ref,
                nameController: nameController,
                addressController: addressController,
                descriptionController: descriptionController,
                rentController: rentController),
            child: whiteInterBold('SAVE CHANGES')));
  }
}
