import 'package:attendence_tracker/view_model/home/attendence_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DistanceFromOffice extends StatefulWidget {
  const DistanceFromOffice({super.key});

  @override
  State<DistanceFromOffice> createState() => _DistanceFromOfficeState();
}

class _DistanceFromOfficeState extends State<DistanceFromOffice> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AttendanceViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'Distance from office: ${viewModel.distanceFromOffice?.toStringAsFixed(2) ?? "Calculating..."} meters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: viewModel.isCheckedIn
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
        );
      },
    );
  }
}
