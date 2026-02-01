import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

// 1. DATA MODEL (Expanded)
class FinanceData {
  final double totalExpenses;
  final double investableAmount;
  final double projectedReturn;
  final double pfSavings;

  FinanceData({
    this.totalExpenses = 0,
    this.investableAmount = 0,
    this.projectedReturn = 0,
    this.pfSavings = 0,
  });
}

// 2. THE BRAIN (Logic)
class FinanceNotifier extends Notifier<FinanceData> {
  @override
  FinanceData build() => FinanceData();

  void calculate({
    required double salary,
    required double rent,
    required double grocery,
    required double household,
    required double pfPercentage,
  }) {
    double pfMonthly = salary * (pfPercentage / 100);
    double totalExp = rent + grocery + household;
    double surplus = salary - totalExp - pfMonthly;

    // Investment Math (8% annual, 10 years)
    double rate = 0.08 / 12;
    int months = 10 * 12;
    double futureValue = surplus > 0
        ? surplus * (pow(1 + rate, months) - 1) / rate * (1 + rate)
        : 0;

    state = FinanceData(
      totalExpenses: totalExp,
      investableAmount: surplus > 0 ? surplus : 0,
      projectedReturn: futureValue,
      pfSavings: pfMonthly,
    );
  }
}

final financeProvider = NotifierProvider<FinanceNotifier, FinanceData>(() => FinanceNotifier());

void main() {
  runApp(const ProviderScope(child: MaterialApp(debugShowCheckedModeBanner: false, home: WealthApp())));
}

// 3. THE UI
class WealthApp extends ConsumerStatefulWidget {
  const WealthApp({super.key});
  @override
  ConsumerState<WealthApp> createState() => _WealthAppState();
}

class _WealthAppState extends ConsumerState<WealthApp> {
  // Controllers
  final salaryController = TextEditingController();
  final rentController = TextEditingController();
  final groceryController = TextEditingController();
  final householdController = TextEditingController();
  final pfController = TextEditingController(text: "12"); // Default PF 12%

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(financeProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pro Wealth Planner", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // INPUT SECTION
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInput(salaryController, "Monthly In-Hand Salary", Icons.payments, Colors.green),
                    const Divider(),
                    _buildInput(rentController, "Rent / EMI", Icons.home, Colors.blue),
                    _buildInput(groceryController, "Groceries", Icons.shopping_cart, Colors.orange),
                    _buildInput(householdController, "Household & Bills", Icons.bolt, Colors.purple),
                    _buildInput(pfController, "PF Contribution (%)", Icons.savings, Colors.red),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        ref.read(financeProvider.notifier).calculate(
                          salary: double.tryParse(salaryController.text) ?? 0,
                          rent: double.tryParse(rentController.text) ?? 0,
                          grocery: double.tryParse(groceryController.text) ?? 0,
                          household: double.tryParse(householdController.text) ?? 0,
                          pfPercentage: double.tryParse(pfController.text) ?? 0,
                        );
                      },
                      child: const Text("CALCULATE STRATEGY", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // RESULT SECTION
            if (data.projectedReturn > 0) ...[
              _buildResultCard("Monthly Investment", "₹${data.investableAmount.toStringAsFixed(0)}", Colors.indigo),
              _buildResultCard("Monthly PF deducted", "₹${data.pfSavings.toStringAsFixed(0)}", Colors.blueGrey),
              _buildResultCard("Wealth in 10 Years", "₹${data.projectedReturn.toStringAsFixed(0)}", Colors.green, isMain: true),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, Color color) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildResultCard(String title, String value, Color color, {bool isMain = false}) {
    return Card(
      color: isMain ? color : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: TextStyle(color: isMain ? Colors.white : Colors.grey[600], fontSize: 14)),
        trailing: Text(value, style: TextStyle(
          color: isMain ? Colors.white : color,
          fontWeight: FontWeight.bold,
          fontSize: isMain ? 22 : 18,
        )),
      ),
    );
  }
}