import 'package:attendence_tracker/res/widgets/custom_button.dart';
import 'package:attendence_tracker/view/admin/components/add_edit_office_form.dart';
import 'package:attendence_tracker/view/admin/components/add_employee_dialog.dart';
import 'package:attendence_tracker/view/admin/components/employee_list.dart';
import 'package:attendence_tracker/view/admin/components/widgets/office_details_widget.dart';
import 'package:attendence_tracker/view_model/admin/admin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OfficeDetails extends StatefulWidget {
  const OfficeDetails({super.key});

  @override
  State<OfficeDetails> createState() => _OfficeDetailsState();
}

class _OfficeDetailsState extends State<OfficeDetails> {
  bool isLoading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchOfficeData();
  }

  Future<void> _fetchOfficeData() async {
    final adminViewModel = Provider.of<AdminViewModel>(context, listen: false);
    await adminViewModel.fetchOfficeData();
    await adminViewModel.fetchEmployees(); // Fetch employee data
    setState(() {
      isLoading = false;
    });
  }

  void _onOfficeAdded() {
    setState(() {
      isEditing = false;
      _fetchOfficeData(); // Refresh data when a new office is added
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminViewModel = Provider.of<AdminViewModel>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business, color: Colors.blueAccent), // Icon for office
              SizedBox(width: 8),
              Text(
                'Your Office',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Accent color for better visuals
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          adminViewModel.officeData != null
              ? Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 12),
                        // Office Name section with icon
                        OfficeDetailsWidget(
                          text:
                              'Office Name: ${adminViewModel.officeData!['officeName']}',
                          icon: Icons.location_city,
                        ),

                        const SizedBox(height: 8),

                        // Latitude section with icon
                        OfficeDetailsWidget(
                          text:
                              'Office Latitude: ${adminViewModel.officeData!['officeLat']}',
                          icon: Icons.my_location,
                        ),

                        const SizedBox(height: 8),

                        // Longitude section with icon
                        OfficeDetailsWidget(
                          text:
                              'Office Longitude: ${adminViewModel.officeData!['officeLong']}',
                          icon: Icons.my_location,
                        ),

                        const SizedBox(height: 8),
                        OfficeDetailsWidget(
                          text:
                              'Office Range: ${adminViewModel.officeData!['range']} meters',
                          icon: Icons.radar,
                        ),

                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomButton(
                              label: 'Edit Office',
                              icon: Icons.edit,
                              onPressed: () {
                                setState(() {
                                  isEditing = !isEditing;
                                });
                              },
                              bgColor: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            CustomButton(
                              label: 'Add Employee',
                              icon: Icons.person_add,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return const AddEmployeeDialog();
                                  },
                                );
                              },
                              bgColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const Text('No office details available.'),
          const SizedBox(height: 20),
          isEditing
              ? AddEditOfficeForm(
                  isEditing: isEditing,
                  onOfficeAdded: _onOfficeAdded,
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.people, color: Colors.blueAccent), // Icon for office
              SizedBox(width: 8),
              Text(
                'Employee Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // Accent color for better visuals
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const EmployeeList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
