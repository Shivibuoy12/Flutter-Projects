import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

class FinanceData {
  final double salary;
  final double expenses;
  final double investableAmount;
  final double projectedReturn;

  FinanceData({
    this.salary = 0,
    this.expenses = 0,
    this.investableAmount = 0,
    this.projectedReturn = 0,
  });
}

class FinanceNotifier extends Notifier<FinanceData> {
  @override
  FinanceData build() => FinanceData();

  void calculate(double sal, double exp) {
    double surplus = sal - exp;
    double rate = 0.08 / 12; // Monthly rate
    int months = 10 * 12;    // 10 years

    // Future Value of a Monthly SIP
    double futureValue = surplus * (pow(1 + rate, months) - 1) / rate * (1 + rate);

    state = FinanceData(
      salary: sal,
      expenses: exp,
      investableAmount: surplus > 0 ? surplus : 0,
      projectedReturn: futureValue,
    );
  }
}

// The "Walkie-Talkie" (Provider)
final financeProvider = NotifierProvider<FinanceNotifier, FinanceData>(() {
  return FinanceNotifier();
});