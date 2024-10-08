import 'package:attendence_tracker/res/widgets/custom_button.dart';
import 'package:attendence_tracker/res/widgets/custom_textfield.dart';
import 'package:attendence_tracker/utils/flushbar_helper.dart';
import 'package:attendence_tracker/view_model/admin/admin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog({super.key});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  TextEditingController employeeName = TextEditingController();
  TextEditingController employeeEmail = TextEditingController();
  TextEditingController employeeId = TextEditingController();
  bool isLoading = true;

  Future<void> _fetchOfficeData() async {
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    await adminViewModel.fetchOfficeData();
    await adminViewModel.fetchEmployees(); // Fetch employee data
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = Provider.of<AdminViewModel>(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners
      ),
      backgroundColor: Colors.white,
      elevation: 6,
      titlePadding: const EdgeInsets.only(left: 24, right: 8, top: 16),
      scrollable: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.person_add, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                'Add Employee',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            labelText: 'Employee Name',
            prefixIcon: Icons.person,
            controller: employeeName,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            labelText: 'Employee Email',
            prefixIcon: Icons.email,
            controller: employeeEmail,
          ),
          const SizedBox(height: 8),
          CustomTextField(
            labelText: 'Employee ID',
            prefixIcon: Icons.badge,
            controller: employeeId,
          ),
        ],
      ),
      actions: [
        CustomButton(
          label: 'Add Employee',
          icon: Icons.person_add,
          onPressed: () async {
            if (employeeName.text.isNotEmpty &&
                employeeEmail.text.isNotEmpty &&
                employeeId.text.isNotEmpty) {
              setState(() {
                isLoading = true;
              });
              await adminViewModel.addEmployee(
                employeeName.text,
                employeeEmail.text,
                employeeId.text,
              );
              employeeName.clear();
              employeeEmail.clear();
              employeeId.clear();
              await adminViewModel.fetchOfficeData(); // Fetch updated data
              Navigator.of(context).pop(); // Close dialog
            } else {
              FlushBarHelper.flushbarErrorMessage(
                'All fields are required!',
                context,
              );
            }
          },
          bgColor: Colors.blueAccent,
        ),
      ],
    );
  }
}
