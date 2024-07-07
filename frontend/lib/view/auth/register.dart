import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_icons/flutter_icons.dart';
import 'package:example/components/password_text_field.dart';
import 'package:example/components/text_form_builder.dart';
import 'package:example/utils/validations.dart';
import 'package:example/view/auth/login.dart';
import 'package:example/view_model/auth/register_view_model.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'MultiSelectAutocomplete.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  @override
  Widget build(BuildContext context) {
    //RegisterViewModel viewModel = Provider.of<RegisterViewModel>(context);

    return ModalProgressHUD(
      inAsyncCall: context.watch<RegisterViewModel>().loading,
      progressIndicator: CircularProgressIndicator(),
      child: Scaffold(
        key: context.watch<RegisterViewModel>().scaffoldMessengerKey,
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          children: [
            SizedBox(height: 10.0),
            Center(
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(height: 30.0),
            buildForm(context.watch<RegisterViewModel>(), context),
            SizedBox(height: 30.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account  ',
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .push(CupertinoPageRoute(builder: (_) => Login()));
                  },
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Form buildForm(RegisterViewModel viewModel, BuildContext context) {
    return Form(
      key: viewModel.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          TextFormBuilder(
            enabled: !viewModel.loading,
            prefix: Icons.person,
            hintText: "Username",
            textInputAction: TextInputAction.next,
            validateFunction: (String? val) {
              return Validations.validateName(val!);
            },
            onSaved: (String val) {
              viewModel.setName(val);
            },
            focusNode: viewModel.usernameFN,
            nextFocusNode: viewModel.emailFN,
          ),
          SizedBox(height: 20.0),
          TextFormBuilder(
            enabled: !viewModel.loading,
            prefix: Icons.mail,
            hintText: "Email",
            textInputAction: TextInputAction.next,
            validateFunction: (String? val) {
              return Validations.validateEmail(val!, false);
            },
            onSaved: (String val) {
              viewModel.setEmail(val);
            },
            focusNode: viewModel.emailFN,
            nextFocusNode: viewModel.countryFN,
          ),
          SizedBox(height: 20.0),
          TextFormBuilder(
            enabled: !viewModel.loading,
            prefix: Icons.map,
            hintText: "Country",
            textInputAction: TextInputAction.next,
            // validateFunction: (String? val) {
            //   return Validations.(val!, false);
            // },
            onSaved: (String val) {
              viewModel.setCountry(val);
            },
            focusNode: viewModel.countryFN,
            nextFocusNode: viewModel.passFN,
          ),
          SizedBox(height: 20.0),
          // AutocompleteBasicExample(
          //   viewModel: viewModel,
          // ),
          // SizedBox(height: 20.0),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return viewModel.languageCodes.keys.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              viewModel.setPreferredLanguage(selection);
            },
            fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              return TextFormBuilder(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                enabled: !viewModel.loading,
                prefix: Icons.language,
                hintText: "Preferred Language",
                textInputAction: TextInputAction.next,
                onSaved: (String val) {
                  viewModel.setPreferredLanguage(val);
                },
              );
            },
          ),
          SizedBox(height: 20.0),

          MultiSelectAutocomplete(
            options: viewModel.languageCodes,
            selectedOptions: viewModel.knownLanguages,
            onSelectionChanged: (selectedOptions) {
              viewModel.setKnownLanguages(selectedOptions);
            },
          ),

          SizedBox(height: 20.0),
          PasswordFormBuilder(
            enabled: !viewModel.loading,
            prefix: Icons.lock,
            suffix: Icons.lock_open,
            hintText: "Password",
            textInputAction: TextInputAction.next,
            validateFunction: (String? val) {
              return Validations.validatePassword(val!);
            },
            obscureText: true,
            onSaved: (String val) {
              viewModel.setPassword(val);
            },
            focusNode: viewModel.passFN,
            nextFocusNode: viewModel.cPassFN,
          ),
          SizedBox(height: 20.0),
          PasswordFormBuilder(
            enabled: !viewModel.loading,
            prefix: Icons.lock,
            hintText: "Confirm Password",
            textInputAction: TextInputAction.done,
            validateFunction: (String? val) {
              return Validations.validatePassword(val!);
            },
            submitAction: () => viewModel.register(context),
            obscureText: true,
            onSaved: (String val) {
              viewModel.setConfirmPass(val);
            },
            focusNode: viewModel.cPassFN,
          ),
          SizedBox(height: 25.0),
          Container(
            height: 45.0,
            width: 180.0,
            child: MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              color: Theme.of(context).colorScheme.primary,
              child: Text(
                'sign up'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => viewModel.register(context),
            ),
          ),
        ],
      ),
    );
  }
}
