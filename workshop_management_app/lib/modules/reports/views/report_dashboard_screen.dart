import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:workshop_management_app/shared/widgets/main_layout_scaffold.dart';
import '../controllers/report_controller.dart';
import '../models/income_report_data.dart';
import '../models/employee_performance_data.dart';
import '../../employees/models/employee.dart';
import '../../employees/controllers/employee_controller.dart';

enum ReportType { none, income, employeePerformance }

class ReportDashboardScreen extends StatefulWidget {
  const ReportDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen> {
  ReportType _selectedReportType = ReportType.none;
  Employee? _selectedEmployeeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeController>(context, listen: false).fetchEmployees();
      // ReportController's default date range is set in its constructor.
      // Initial data generation will happen upon user interaction.
    });
  }

  Future<void> _pickDateRange(BuildContext context, ReportController controller) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(
        start: controller.reportStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: controller.reportEndDate ?? DateTime.now(),
      ),
    );
    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildDateRangePicker(ReportController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(controller.reportStartDate != null
                  ? DateFormat.yMMMd().format(controller.reportStartDate!)
                  : 'Select Start Date'),
              onPressed: () => _pickDateRange(context, controller),
            ),
          ),
          const Text("to"),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(controller.reportEndDate != null
                  ? DateFormat.yMMMd().format(controller.reportEndDate!)
                  : 'Select End Date'),
              onPressed: () => _pickDateRange(context, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeFilterDropdown(ReportController controller) {
    return Consumer<EmployeeController>(
      builder: (context, empCtrl, child) {
        if (empCtrl.isLoading && empCtrl.employees.isEmpty) return CircularProgressIndicator();
        return DropdownButtonFormField<Employee?>(
          decoration: InputDecoration(labelText: "Filter by Employee (Optional)"),
          hint: const Text("All Employees"),
          value: _selectedEmployeeFilter,
          isExpanded: true,
          items: [
            const DropdownMenuItem<Employee?>(
              value: null,
              child: Text("All Employees"),
            ),
            ...empCtrl.employees.map((Employee emp) {
              return DropdownMenuItem<Employee?>(
                value: emp,
                child: Text(emp.name),
              );
            }).toList(),
          ],
          onChanged: (Employee? newValue) {
            setState(() {
              _selectedEmployeeFilter = newValue;
            });
          },
        );
      }
    );
  }

  Widget _buildReportContent(ReportController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null) {
      return Center(child: Text('Error: ${controller.errorMessage}', style: const TextStyle(color: Colors.red)));
    }

    switch (_selectedReportType) {
      case ReportType.income:
        final data = controller.incomeReportData;
        if (data == null) return const Center(child: Text("Press 'Generate Report' to see income data."));
        return _buildIncomeReportView(data);
      case ReportType.employeePerformance:
        final data = controller.employeePerformanceList;
        // Show message if report generated but list is empty (e.g. no worklogs for employee in period)
        if (data.isEmpty && !controller.isLoading && controller.errorMessage == null && _selectedReportType == ReportType.employeePerformance) {
          return const Center(child: Text("No performance data for the selected criteria."));
        }
        if (data.isEmpty && !controller.isLoading) return const Center(child: Text("Press 'Generate Report' to see employee performance."));
        return _buildEmployeePerformanceReportView(data);
      default:
        return const Center(child: Text("Select a report type and generate."));
    }
  }

  Widget _buildIncomeReportView(IncomeReportData data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Income Report (${DateFormat.yMMMd().format(data.startDate)} - ${DateFormat.yMMMd().format(data.endDate)})", style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          _buildReportRow("Total Revenue (Completed Sales):", "\$${data.totalRevenue.toStringAsFixed(2)}"),
          _buildReportRow("Total Expenses (Purchases):", "\$${data.totalExpenses.toStringAsFixed(2)}"),
          const Divider(),
          _buildReportRow("Net Profit:", "\$${data.netProfit.toStringAsFixed(2)}", isBold: true),
          const SizedBox(height: 20),
          ElevatedButton.icon(icon: Icon(Icons.picture_as_pdf), label: Text("Export PDF (Placeholder)"), onPressed: (){}),
        ],
      ),
    );
  }

  Widget _buildEmployeePerformanceReportView(List<EmployeePerformanceData> data) {
    return Expanded(
      child: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          final empData = data[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empData.employeeName, style: Theme.of(context).textTheme.titleLarge),
                  _buildReportRow("Work Log Entries:", "${empData.workLogEntryCount}"),
                  if (empData.totalDaysWorked > 0) _buildReportRow("Total Days Worked:", "${empData.totalDaysWorked}"),
                  if (empData.totalHoursWorked > 0) _buildReportRow("Total Regular Hours:", "${empData.totalHoursWorked.toStringAsFixed(2)}"),
                  _buildReportRow("Total Overtime Hours:", "${empData.totalOvertimeHours.toStringAsFixed(2)}"),
                  _buildReportRow("Total Salary Paid (Period):", "\$${empData.totalSalaryPaid.toStringAsFixed(2)}", isBold: true),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportController = Provider.of<ReportController>(context);

    final Widget screenBody = Column(
        children: [
          _buildDateRangePicker(reportController),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<ReportType>(
              segments: const <ButtonSegment<ReportType>>[
                ButtonSegment<ReportType>(value: ReportType.income, label: Text('Income'), icon: Icon(Icons.attach_money)),
                ButtonSegment<ReportType>(value: ReportType.employeePerformance, label: Text('Employee'), icon: Icon(Icons.person_search)),
              ],
              selected: <ReportType>{_selectedReportType},
              onSelectionChanged: (Set<ReportType> newSelection) {
                setState(() {
                  _selectedReportType = newSelection.first;
                });
              },
            ),
          ),
          if (_selectedReportType == ReportType.employeePerformance)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: _buildEmployeeFilterDropdown(reportController),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.assessment),
            label: const Text("Generate Report"),
            onPressed: (reportController.reportStartDate == null || reportController.reportEndDate == null || _selectedReportType == ReportType.none)
              ? null
              : () {
                  if (_selectedReportType == ReportType.income) {
                    reportController.generateIncomeReport();
                  } else if (_selectedReportType == ReportType.employeePerformance) {
                    reportController.generateEmployeePerformanceReport(employee: _selectedEmployeeFilter);
                  }
                },
          ),
          const Divider(),
          Expanded(child: _buildReportContent(reportController)),
        ],
      );

    return MainLayoutScaffold(
      title: "Reports Dashboard",
      body: screenBody,
      // No specific appBarActions for this screen, handled in body.
    );
  }
}
