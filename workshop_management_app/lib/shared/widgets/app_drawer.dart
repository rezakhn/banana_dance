import 'package:flutter/material.dart';

// Import all the list/dashboard screens for navigation
import '../../modules/employees/views/employee_list_screen.dart';
import '../../modules/orders/views/customer_list_screen.dart';
import '../../modules/orders/views/sales_order_list_screen.dart';
import '../../modules/purchases/views/supplier_list_screen.dart';
import '../../modules/purchases/views/purchase_invoice_list_screen.dart';
import '../../modules/inventory/views/inventory_list_screen.dart';
import '../../modules/parts/views/part_list_screen.dart';
import '../../modules/reports/views/report_dashboard_screen.dart';
import '../../modules/backup/views/backup_settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  // Helper class for navigation items
  static final List<_NavigationItem> _navItems = [
    _NavigationItem(icon: Icons.people_alt_outlined, title: 'Employees', routeWidget: const EmployeeListScreen()), // Current home
    _NavigationItem(icon: Icons.person_pin_circle_outlined, title: 'Customers', routeWidget: const CustomerListScreen()),
    _NavigationItem(icon: Icons.shopping_cart_checkout_outlined, title: 'Sales Orders', routeWidget: const SalesOrderListScreen()),
    const _NavigationItem(isDivider: true),
    _NavigationItem(icon: Icons.storefront_outlined, title: 'Suppliers', routeWidget: const SupplierListScreen()),
    _NavigationItem(icon: Icons.receipt_long_outlined, title: 'Purchase Invoices', routeWidget: const PurchaseInvoiceListScreen()),
    const _NavigationItem(isDivider: true),
    _NavigationItem(icon: Icons.inventory_2_outlined, title: 'Inventory', routeWidget: const InventoryListScreen()),
    _NavigationItem(icon: Icons.build_circle_outlined, title: 'Parts & Assemblies', routeWidget: const PartListScreen()),
    const _NavigationItem(isDivider: true),
    _NavigationItem(icon: Icons.assessment_outlined, title: 'Reports', routeWidget: const ReportDashboardScreen()),
    _NavigationItem(icon: Icons.settings_backup_restore_outlined, title: 'Backup & Restore', routeWidget: const BackupSettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Text(
              'Workshop Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ..._navItems.map((item) {
            if (item.isDivider) {
              return const Divider();
            }
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.title!),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Navigate to the new screen, replacing the current one if it's already a top-level view.
                // This prevents a large back stack from drawer navigations.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => item.routeWidget!),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Helper class to define navigation items
class _NavigationItem {
  final IconData? icon;
  final String? title;
  final Widget? routeWidget; // The widget for the screen to navigate to
  final bool isDivider;

  const _NavigationItem({
    this.icon,
    this.title,
    this.routeWidget,
    this.isDivider = false,
  });
}
