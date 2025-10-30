import 'package:ecommerce_app/controllers/auth_service.dart';
import 'package:ecommerce_app/controllers/db_service.dart';
import 'package:ecommerce_app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  final formKey = GlobalKey<FormState>();

  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();

  bool _changeEmail = false;

  @override
  void initState() {
    final user = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = user.name;
    _emailController.text = user.email;
    _addressController.text = user.address;
    _phoneController.text = user.phone;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profile"),
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                      labelText: "Name",
                      hintText: "Name",
                      border: OutlineInputBorder()),
                  validator: (value) =>
                  value!.isEmpty ? "Name cannot be empty." : null,
                ),
                SizedBox(height: 10),

                // Email
                TextFormField(
                  controller: _emailController,
                  readOnly: !_changeEmail,
                  decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "Email",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _changeEmail ? Icons.lock_open : Icons.lock,
                        ),
                        onPressed: () {
                          setState(() {
                            _changeEmail = !_changeEmail;
                          });
                        },
                      )),
                  validator: (value) =>
                  value!.isEmpty ? "Email cannot be empty." : null,
                ),
                SizedBox(height: 10),

                // Current password (only if changing email)
                if (_changeEmail)
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: "Current Password",
                        hintText: "Current Password",
                        border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty
                        ? "Enter your current password to update email"
                        : null,
                  ),
                if (_changeEmail) SizedBox(height: 10),

                // Address
                TextFormField(
                  maxLines: 3,
                  controller: _addressController,
                  decoration: InputDecoration(
                      labelText: "Address",
                      hintText: "Address",
                      border: OutlineInputBorder()),
                  validator: (value) =>
                  value!.isEmpty ? "Address cannot be empty." : null,
                ),
                SizedBox(height: 10),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                      labelText: "Phone",
                      hintText: "Phone",
                      border: OutlineInputBorder()),
                  validator: (value) =>
                  value!.isEmpty ? "Phone cannot be empty." : null,
                ),
                SizedBox(height: 10),

                // Update button
                SizedBox(
                  height: 60,
                  width: MediaQuery.of(context).size.width * .9,
                  child: ElevatedButton(
                           onPressed: () async{
                             if (formKey.currentState!.validate()) {
                               // Update email if changed
                               if (_changeEmail &&
                                   _emailController.text.trim() !=
                                       Provider.of<UserProvider>(context, listen: false).email) {
                                 String res = await AuthService().updateEmail(
                                     newEmail: _emailController.text.trim(),
                                     currentPassword: _currentPasswordController.text.trim());

                                 ScaffoldMessenger.of(context)
                                     .showSnackBar(SnackBar(content: Text(res)));

                                 if (res.contains("Error")) return; // Stop if email fails
                               }

                               // Always update name, address, phone in Firestore
                               var data = {
                                 "name": _nameController.text.trim(),
                                 "address": _addressController.text.trim(),
                                 "phone": _phoneController.text.trim(),
                               };

                               await DbService().updateUserData(extraData: data);

                               Navigator.pop(context);
                               ScaffoldMessenger.of(context)
                                   .showSnackBar(SnackBar(content: Text("Profile Updated")));
                             }

                           },


                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white),
                    child: Text(
                      "Update Profile",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
