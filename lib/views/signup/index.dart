import 'dart:async';

import 'package:Tether/global/strings.dart';
import 'package:Tether/store/auth/state.dart';
import 'package:Tether/store/auth/actions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/state.dart';

// Styling Widgets
import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/behaviors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import './step-username.dart';
import './step-password.dart';
import './step-homeserver.dart';

class SignupView extends StatefulWidget {
  const SignupView({Key key}) : super(key: key);

  SignupViewState createState() => SignupViewState();
}

class SignupViewState extends State<SignupView> {
  final String title = StringStore.viewTitleSignup;

  final sections = [
    HomeserverStep(),
    UsernameStep(),
    PasswordStep(),
  ];

  int currentStep = 0;
  bool onboarding = false;
  bool validStep = false;
  bool naving = false;
  StreamSubscription subscription;
  PageController pageController;

  SignupViewState({Key key});

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: 0,
      keepPage: false,
      viewportFraction: 1.5,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @protected
  void onMounted() {
    final store = StoreProvider.of<AppState>(context);

    // Init change listener
    subscription = store.onChange.listen((state) {
      // toggle button to a creating user state
      if (state.authStore.creating && this.currentStep != 3) {
        setState(() {
          currentStep = 3;
        });
        // otherwise let them retry
      } else if (!state.authStore.creating && this.currentStep == 3) {
        setState(() {
          currentStep = 2;
        });
      }

      if (state.authStore.user.accessToken != null) {
        final String currentRoute = ModalRoute.of(context).settings.name;
        print('Subscription is working $currentRoute');
        if (currentRoute != '/home' && !naving) {
          setState(() {
            naving = true;
          });
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      }
    });
  }

  @override
  void deactivate() {
    subscription.cancel();
    super.deactivate();
  }

  @protected
  void onBackStep(BuildContext context) {
    if (this.currentStep < 1) {
      Navigator.pop(context, false);
    } else {
      this.setState(() {
        currentStep = this.currentStep - 1;
      });
      pageController.animateToPage(
        this.currentStep,
        duration: Duration(milliseconds: 275),
        curve: Curves.easeInOut,
      );
    }
  }

  @protected
  Function onCheckStepValidity(_Props props) {
    switch (this.currentStep) {
      case 0:
        return props.isHomeserverValid
            ? () {
                pageController.nextPage(
                  duration: Duration(milliseconds: 350),
                  curve: Curves.ease,
                );
              }
            : null;
      case 1:
        return props.isUsernameValid && props.isUsernameAvailable
            ? () {
                pageController.nextPage(
                  duration: Duration(milliseconds: 350),
                  curve: Curves.ease,
                );
              }
            : null;
      case 2:
        return !props.isPasswordValid
            ? null
            : () {
                props.onCreateUser();
              };
      default:
        return null;
    }
  }

  Widget buildButtonText() {
    switch (currentStep) {
      case 2:
        return const Text('Finish',
            style: TextStyle(fontSize: 20, color: Colors.white));
      default:
        return const Text('Continue',
            style: TextStyle(fontSize: 20, color: Colors.white));
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              brightness: Brightness.light,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  onBackStep(context);
                },
              ),
            ),
            body: ScrollConfiguration(
              behavior: DefaultScrollBehavior(),
              child: SingleChildScrollView(
                child: Container(
                  width:
                      width, // set actual height and width for flex constraints
                  height:
                      height, // set actual height and width for flex constraints
                  child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        flex: 8,
                        fit: FlexFit.tight,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          direction: Axis.horizontal,
                          children: <Widget>[
                            Container(
                              width: width,
                              padding: EdgeInsets.only(bottom: height * 0.05),
                              constraints: BoxConstraints(
                                minHeight: Dimensions.pageViewerHeightMin,
                                maxHeight: Dimensions.pageViewerHeightMax,
                              ),
                              child: PageView(
                                pageSnapping: true,
                                allowImplicitScrolling: false,
                                controller: pageController,
                                physics: NeverScrollableScrollPhysics(),
                                children: sections,
                                onPageChanged: (index) {
                                  setState(() {
                                    currentStep = index;
                                    onboarding = index != 0 &&
                                        index != sections.length - 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Flex(
                          mainAxisAlignment: MainAxisAlignment.end,
                          direction: Axis.vertical,
                          children: <Widget>[
                            Container(
                              // EXAMPLE OF WIDGET PROPORTIONAL SCALING
                              width: width * 0.725,
                              height: Dimensions.inputHeight,
                              constraints: BoxConstraints(
                                minWidth: Dimensions.buttonWidthMin,
                                maxWidth: Dimensions.buttonWidthMax,
                              ),
                              child: FlatButton(
                                disabledColor: Colors.grey,
                                disabledTextColor: Colors.grey[300],
                                onPressed: onCheckStepValidity(props),
                                color: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                child: !props.creating
                                    ? buildButtonText()
                                    : CircularProgressIndicator(
                                        backgroundColor: Colors.white,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        constraints: BoxConstraints(
                          minHeight: 45,
                        ),
                        child: Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SmoothPageIndicator(
                              controller: pageController, // PageController
                              count: sections.length,
                              effect: WormEffect(
                                spacing: 16,
                                dotHeight: 12,
                                dotWidth: 12,
                                activeDotColor: Theme.of(context).primaryColor,
                              ), // your preferred effect
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final String username;
  final bool isUsernameValid;
  final bool isUsernameAvailable;

  final String password;
  final bool isPasswordValid;

  final String homeserver;
  final bool isHomeserverValid;

  final bool creating;

  final Function onCreateUser;

  _Props({
    @required this.username,
    @required this.isUsernameValid,
    @required this.isUsernameAvailable,
    @required this.password,
    @required this.isPasswordValid,
    @required this.homeserver,
    @required this.isHomeserverValid,
    @required this.creating,
    @required this.onCreateUser,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        username: store.state.authStore.username,
        isUsernameValid: store.state.authStore.isUsernameValid,
        isUsernameAvailable: store.state.authStore.isUsernameAvailable,
        password: store.state.authStore.password,
        isPasswordValid: store.state.authStore.isPasswordValid,
        homeserver: store.state.authStore.homeserver,
        isHomeserverValid: store.state.authStore.isHomeserverValid,
        creating: store.state.authStore.creating,
        onCreateUser: () {
          store.dispatch(createUser());
        },
      );

  @override
  List<Object> get props => [
        username,
        isUsernameValid,
        isUsernameAvailable,
        password,
        isPasswordValid,
        homeserver,
        isHomeserverValid,
        creating,
      ];
}
