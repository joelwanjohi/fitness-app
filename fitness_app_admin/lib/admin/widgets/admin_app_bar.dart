import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onRefresh;

  const AdminAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Color(0xFF2E7D32),
      elevation: 4,
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: onRefresh,
          ),
        ...(actions ?? []),
        IconButton(
          icon: Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}