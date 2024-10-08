import 'package:attendence_tracker/res/components/drawer.dart';
import 'package:attendence_tracker/res/widgets/shimmer_widget.dart';
import 'package:attendence_tracker/view/admin/components/add_edit_office_form.dart';
import 'package:attendence_tracker/view/admin/components/office_details.dart';
import 'package:attendence_tracker/view_model/admin/admin_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  TextEditingController officeName = TextEditingController();
  TextEditingController officeLat = TextEditingController();
  TextEditingController officeLong = TextEditingController();
  TextEditingController range = TextEditingController();

  TextEditingController employeeName = TextEditingController();
  TextEditingController employeeEmail = TextEditingController();
  TextEditingController employeeId = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final adminViewModel = Provider.of<AdminViewModel>(context);
    void onOfficeAdded() {
      setState(() {
        isEditing = false;
        _fetchOfficeData(); // Refresh data when a new office is added
      });
    }

    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Admin', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? Column(
              children: [
                // Shimmer for the "Your Office" card
                Container(
                  width: double.infinity,
                  height: 150,
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerWidget(
                          width: 150, height: 20), // Shimmer for Office Name
                      SizedBox(height: 8),
                      ShimmerWidget(
                          width: 200, height: 15), // Shimmer for Latitude
                      SizedBox(height: 8),
                      ShimmerWidget(
                          width: 200, height: 15), // Shimmer for Longitude
                      SizedBox(height: 8),
                      ShimmerWidget(
                          width: 200, height: 15), // Shimmer for Range
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Shimmer for each employee detail card
                for (int i = 0;
                    i < 3;
                    i++) // Display 3 shimmer employee cards as placeholders
                  Container(
                    width: double.infinity,
                    height: 80,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                Colors.grey, // Shimmer effect for avatar
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShimmerWidget(
                                  width: 100, height: 15), // Shimmer for Name
                              SizedBox(height: 6),
                              ShimmerWidget(
                                  width: 150, height: 12), // Shimmer for Email
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                          ), // Placeholder for action icon
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: adminViewModel.officeData != null && !isEditing
                    // ? _buildOfficeDetails(adminViewModel)
                    ? const OfficeDetails()
                    : AddEditOfficeForm(
                        isEditing: false,
                        onOfficeAdded: onOfficeAdded,
                      ),
              ),
            ),
    );
  }
}
