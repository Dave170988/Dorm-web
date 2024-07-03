import 'package:dorm_bnb_web/providers/loading_provider.dart';
import 'package:dorm_bnb_web/utils/firebase_util.dart';
import 'package:dorm_bnb_web/widgets/custom_miscellaneous_widgets.dart';
import 'package:dorm_bnb_web/widgets/custom_text_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_type_provider.dart';
import '../utils/color_util.dart';
import '../utils/go_router_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/left_navigator_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  //  LOG-IN
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        ref.read(loadingProvider.notifier).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider.notifier).toggleLoading(false);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        ref.read(userTypeProvider).setUserType(userData[UserFields.userType]);
        ref.read(loadingProvider.notifier).toggleLoading(false);
      } catch (error) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error initializing home: $error')));
        ref.read(loadingProvider.notifier).toggleLoading(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userTypeProvider);
    return Scaffold(
      body: stackedLoadingContainer(
        context,
        ref.read(loadingProvider).isLoading,
        Center(child: hasLoggedInUser() ? properDashboard() : _logInContainer()),
      ),
    );
  }

  Widget properDashboard() {
    if (ref.read(userTypeProvider).userType == UserTypes.admin) {
      return adminDashboard();
    } else {
      return ownerDashboard();
    }
  }

  //==========================================================================
  //ADMIN=====================================================================
  //==========================================================================
  Widget adminDashboard() {
    return DefaultTabController(
      length: 5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          adminLeftNavigator(context, path: GoRoutes.home),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  title: Text('ADMIN DASHBOARD', style: TextStyle(fontSize: 30, fontStyle: FontStyle.italic)),
                  floating: true,
                  pinned: true,
                  bottom: TabBar(
                    tabs: [
                      Tab(text: 'Total Renters'),
                      Tab(text: 'Total Owners'),
                      Tab(text: 'Total Dorms'),
                      Tab(text: 'Total Transaction'),
                      Tab(text: 'Withdrawal Interface'),
                    ],
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _TotalRenters(),
                  _TotalOwners(),
                  _TotalDorms(),
                  _TotalTransaction(),
                  _WithdrawalInterface(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _TotalRenters() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Renter ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Status')),
      ],
      rows: const [
        DataRow(cells: [
          DataCell(Text('1')),
          DataCell(Text('Alice')),
          DataCell(Text('Active')),
        ]),
        DataRow(cells: [
          DataCell(Text('2')),
          DataCell(Text('Bob')),
          DataCell(Text('Inactive')),
        ]),
      ],
    );
  }

  Widget _TotalOwners() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Owner ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Properties Owned')),
      ],
      rows: const [
        DataRow(cells: [
          DataCell(Text('1')),
          DataCell(Text('Charlie')),
          DataCell(Text('3')),
        ]),
        DataRow(cells: [
          DataCell(Text('2')),
          DataCell(Text('David')),
          DataCell(Text('5')),
        ]),
      ],
    );
  }

  Widget _TotalDorms() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Dorm ID')),
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Capacity')),
      ],
      rows: const [
        DataRow(cells: [
          DataCell(Text('1')),
          DataCell(Text('Dorm A')),
          DataCell(Text('100')),
        ]),
        DataRow(cells: [
          DataCell(Text('2')),
          DataCell(Text('Dorm B')),
          DataCell(Text('150')),
        ]),
      ],
    );
  }

  Widget _TotalTransaction() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Transaction ID')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Date')),
      ],
      rows: const [
        DataRow(cells: [
          DataCell(Text('T001')),
          DataCell(Text('\$500')),
          DataCell(Text('2023-01-01')),
        ]),
        DataRow(cells: [
          DataCell(Text('T002')),
          DataCell(Text('\$300')),
          DataCell(Text('2023-01-02')),
        ]),
      ],
    );
  }

  Widget _WithdrawalInterface() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Withdrawal ID')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Date')),
      ],
      rows: const [
        DataRow(cells: [
          DataCell(Text('W001')),
          DataCell(Text('\$200')),
          DataCell(Text('2023-01-03')),
        ]),
        DataRow(cells: [
          DataCell(Text('W002')),
          DataCell(Text('\$400')),
          DataCell(Text('2023-01-04')),
        ]),
      ],
    );
  }

  //==========================================================================
  //OWNER=====================================================================
  //==========================================================================
  Widget ownerDashboard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ownerLeftNavigator(context, path: GoRoutes.home),
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: CustomColors.pearlWhite,
            borderRadius: BorderRadius.circular(50),
          ),
          child: SingleChildScrollView(
            child: horizontal5Percent(
              context,
              child: Center(
                child: blackHelveticaBold(
                  'OWNER DASHBOARD',
                  fontSize: 60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //==========================================================================
  //LOG-IN====================================================================
  //==========================================================================
  Widget _logInContainer() {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(ImagePaths.loginBG),
              fit: BoxFit.fill,
            ),
          ),
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
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          child: loginFieldsContainer(
            context,
            ref,
            emailController: emailController,
            passwordController: passwordController,
          ),
        ),
      ],
    );
  }
}
