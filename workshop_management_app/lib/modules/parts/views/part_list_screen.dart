import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import '../controllers/part_controller.dart';
import '../models/part.dart';
import 'part_edit_screen.dart';
import '../widgets/part_card.dart';

class PartListScreen extends StatefulWidget {
  const PartListScreen({Key? key}) : super(key: key);

  @override
  State<PartListScreen> createState() => _PartListScreenState();
}

class _PartListScreenState extends State<PartListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartController>(context, listen: false).fetchParts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget screenBody = Consumer<PartController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.parts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.errorMessage != null && controller.parts.isEmpty) {
            return Center(child: Text('Error: ${controller.errorMessage}'));
          }
          if (controller.parts.isEmpty) {
            return const Center(child: Text('No parts found. Add one!'));
          }

          return ListView.builder(
            itemCount: controller.parts.length,
            itemBuilder: (context, index) {
              final part = controller.parts[index];
              return PartCard(
                part: part,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PartEditScreen(part: part)),
                  ).then((_) => Provider.of<PartController>(context, listen: false).fetchParts());
                },
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: Text('Are you sure you want to delete "${part.name}"? This may fail if the part is in use (e.g., in other assemblies, products, or has inventory).'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await controller.deletePart(part.id!);
                    if (controller.errorMessage != null && mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${controller.errorMessage}')),
                          );
                      }
                  }
                }
              );
            },
          );
        },
      );

    return MainLayoutScaffold(
      title: 'Parts & Assemblies',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Add Part/Assembly',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PartEditScreen()),
            ).then((_) => Provider.of<PartController>(context, listen: false).fetchParts());
          },
        ),
        // TODO: Consider adding buttons to navigate to ProductListScreen and AssemblyOrderListScreen from here
        // or keep them accessible only via AppDrawer for less clutter.
        // For now, keeping AppBar clean.
      ],
      body: screenBody,
    );
  }
}
