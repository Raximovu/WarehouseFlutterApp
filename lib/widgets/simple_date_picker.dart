import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SimpleDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const SimpleDatePicker({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor, // Kalendar urg'u rangi
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(selectedDate);

    return OutlinedButton.icon(
      onPressed: () => _selectDate(context),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(
        formattedDate,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
