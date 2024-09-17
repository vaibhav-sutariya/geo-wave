import 'package:attendence_tracker/utils/routes/routes_name.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Authentication
    final User? user = FirebaseAuth.instance.currentUser;

    // Fetch user details (name, email, photo URL)
    final String displayName = user?.displayName ?? 'Unknown User';
    final String email = user?.email ?? 'No Email';
    final String? photoURL = user?.photoURL;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: photoURL != null
                  ? NetworkImage(photoURL) // Use the photo from Firebase
                  : const AssetImage('assets/images/default_profile.png')
                      as ImageProvider, // Fallback image if no photoURL
            ),
            otherAccountsPictures: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    // Navigate to profile edit
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  text: 'Home',
                  onTap: () {
                    Navigator.pushNamed(context, RoutesName.home);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  text: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.admin_panel_settings,
                  text: 'Admin',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, RoutesName.admin);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  text: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: user == null ? Icons.login : Icons.logout,
                  text: user == null ? 'Sign In' : 'Logout',
                  onTap: () async {
                    if (user == null) {
                      // Navigate to Sign In screen if user is not logged in
                      Navigator.pushNamed(context, RoutesName.signIn);
                    } else {
                      // Sign out from Firebase
                      await FirebaseAuth.instance.signOut();
                      // Navigate to Sign In screen after signing out
                      Navigator.pushReplacementNamed(
                          context, RoutesName.signIn);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build ListTile items
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blueAccent,
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
