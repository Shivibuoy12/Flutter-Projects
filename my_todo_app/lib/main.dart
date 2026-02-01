import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Note: Ensure your logic file is imported or in the same file

class InvestmentApp extends ConsumerWidget {
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController expenseController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(financeProvider);

    return Scaffold(
      appBar: AppBar(title: Text("DV Wealth Planner")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: salaryController,
              decoration: InputDecoration(labelText: "Monthly Salary"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: expenseController,
              decoration: InputDecoration(labelText: "Monthly Expenses"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: () {
                double sal = double.tryParse(salaryController.text) ?? 0;
                double exp = double.tryParse(expenseController.text) ?? 0;
                ref.read(financeProvider.notifier).calculate(sal, exp);
              },
              child: Text("Calculate My Future"),
            ),
            Divider(),
            Text("Monthly Investment: ₹${data.investableAmount.toStringAsFixed(2)}"),
            Text("Value in 10 Years (8%): ₹${data.projectedReturn.toStringAsFixed(0)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }
}