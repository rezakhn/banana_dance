class IncomeReportData {
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalExpenses; // Primarily from purchases in this simplified model

  double get netProfit => totalRevenue - totalExpenses;

  IncomeReportData({
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalExpenses,
  });

  @override
  String toString() {
    return 'IncomeReportData(startDate: $startDate, endDate: $endDate, revenue: $totalRevenue, expenses: $totalExpenses, profit: $netProfit)';
  }
}
