import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mentorship_client/auth/auth_bloc.dart';
import 'package:mentorship_client/auth/bloc.dart';
import 'package:mentorship_client/extensions/context.dart';
import 'package:mentorship_client/failure.dart';
import 'package:mentorship_client/remote/repositories/user_repository.dart';
import 'package:mentorship_client/remote/requests/change_password.dart';
import 'package:mentorship_client/remote/responses/custom_response.dart';
import 'package:mentorship_client/screens/settings/about.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Builder(
        builder: (context) => ListView(
          children: [
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text("Info"),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AboutPage())),
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text("Feedback"),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text("Log out"),
              onTap: () => _showConfirmLogoutDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text("Change password"),
              onTap: () => _showChangePasswordDialog(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text(
                "Delete account",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmLogoutDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Log Out'),
            content: Text('Are you sure you want to logout?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              FlatButton(
                child: Text('Confirm'),
                onPressed: () {
                  BlocProvider.of<AuthBloc>(context).add(JustLoggedOut());

                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final _currentPassController = TextEditingController();
    final _newPassController = TextEditingController();
    final _newPassConfirmController = TextEditingController();
    bool _passwordVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void _togglePassVisibility() {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          }

          return AlertDialog(
            title: Text("Change password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPassController,
                  decoration: InputDecoration(labelText: "Current password"),
                ),
                TextFormField(
                  controller: _newPassController,
                  decoration: InputDecoration(
                    labelText: "New password",
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: _togglePassVisibility,
                    ),
                  ),
                  obscureText: !_passwordVisible,
                ),
                TextFormField(
                  controller: _newPassConfirmController,
                  decoration: InputDecoration(
                    labelText: "Confirm password",
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: _togglePassVisibility,
                    ),
                  ),
                  obscureText: !_passwordVisible
                  ,
                )
              ],
            ),
            actions: [
              FlatButton(
                child: Text("Submit"),
                onPressed: () async {
                  if (_newPassConfirmController.text != _newPassController.text) {
                    _newPassController.clear();
                    _newPassConfirmController.clear();
                  } else {
                    ChangePassword changePassword = ChangePassword(
                      currentPassword: _currentPassController.text,
                      newPassword: _newPassController.text,
                    );
                    try {
                      CustomResponse response =
                          await UserRepository.instance.changePassword(changePassword);
                      context.showSnackBar(response.message);
                    } on Failure catch (failure) {
                      context.showSnackBar(failure.message);
                    }

                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
