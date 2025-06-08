import 'package:flutter/material.dart';
import 'app_drawer.dart'; // Import the AppDrawer

class MainLayoutScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final Key? scaffoldKey; // Optional key for the Scaffold itself

  const MainLayoutScaffold({
    Key? key,
    this.scaffoldKey,
    required this.title,
    required this.body,
    this.appBarActions,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(title),
        actions: appBarActions,
      ),
      drawer: const AppDrawer(), // Include the AppDrawer
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
