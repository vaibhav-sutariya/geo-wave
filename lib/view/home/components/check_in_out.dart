import 'package:attendence_tracker/view_model/home/attendence_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckedInOut extends StatefulWidget {
  const CheckedInOut({super.key});

  @override
  State<CheckedInOut> createState() => _CheckedInOutState();
}

class _CheckedInOutState extends State<CheckedInOut> {
  @override
  void initState() {
    super.initState();
    // Fetch the office coordinates and user location when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final attendanceViewModel =
          Provider.of<AttendanceViewModel>(context, listen: false);
      attendanceViewModel.fetchOfficeCoordinates().then((_) {
        attendanceViewModel.checkUserLocation();
      });
    });
  }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 30,
                color: viewModel.isCheckedIn ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Status: ${viewModel.isCheckedIn ? "Checked In" : "Checked Out"}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: viewModel.isCheckedIn ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
