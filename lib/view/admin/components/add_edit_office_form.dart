import 'package:attendence_tracker/res/widgets/custom_button.dart';
import 'package:attendence_tracker/res/widgets/custom_textfield.dart';
import 'package:attendence_tracker/utils/flushbar_helper.dart';
import 'package:attendence_tracker/view_model/admin/admin_view_model.dart';
import 'package:attendence_tracker/view_model/services/location_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddEditOfficeForm extends StatefulWidget {
  final bool isEditing;
  final VoidCallback onOfficeAdded; // Callback to notify when office is added

  const AddEditOfficeForm({
    super.key,
    required this.isEditing,
    required this.onOfficeAdded,
  });

  @override
  State<AddEditOfficeForm> createState() => _AddEditOfficeFormState();
}

class _AddEditOfficeFormState extends State<AddEditOfficeForm> {
  TextEditingController officeName = TextEditingController();
  TextEditingController officeLat = TextEditingController();
  TextEditingController officeLong = TextEditingController();
  TextEditingController range = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final adminViewModel = Provider.of<AdminViewModel>(context);
    final LocationService locationService = LocationService();
    widget.isEditing
        ? setState(() {
            officeName.text = adminViewModel.officeData?['officeName'] ?? '';
            officeLat.text = adminViewModel.officeData?['officeLat'] ?? '';
            officeLong.text = adminViewModel.officeData?['officeLong'] ?? '';
            range.text = adminViewModel.officeData?['range'] ?? '';
          })
        : null;
    Future<void> useCurrentLocation() async {
      try {
        var position = await locationService.getCurrentLocation();
        setState(() {
          officeLat.text = position.latitude.toString();
          officeLong.text = position.longitude.toString();
        });
        FlushBarHelper.flushbarSuccessMessage('Current Location set!', context);
      } catch (e) {
        FlushBarHelper.flushbarErrorMessage(
            'Failed to get location: $e', context);
      }
    }

    Future<void> handleFormSubmission() async {
      if (officeName.text.isEmpty ||
          officeLat.text.isEmpty ||
          officeLong.text.isEmpty ||
          range.text.isEmpty) {
        FlushBarHelper.flushbarErrorMessage(
            'All fields are required!', context);
        return;
      }

      if (widget.isEditing) {
        await adminViewModel.updateOffice(
          officeName.text,
          officeLat.text,
          officeLong.text,
          range.text,
        );
      } else {
        await adminViewModel.addOffice(
          officeName.text,
          officeLat.text,
          officeLong.text,
          range.text,
        );
      }

      // Fetch updated office data
      await adminViewModel.fetchOfficeData();

      // Notify the parent widget that the office was added/updated successfully
      widget.onOfficeAdded();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.isEditing ? Icons.edit : Icons.new_releases,
                color: Colors.blueAccent), // Icon for office
            const SizedBox(width: 8),
            Text(
              widget.isEditing ? 'Edit Office' : 'Add Office',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent, // Accent color for better visuals
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomTextField(
          labelText: 'Office Name',
          prefixIcon: Icons.business,
          controller: officeName,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          labelText: 'Office Latitude',
          prefixIcon: Icons.location_on,
          controller: officeLat,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          labelText: 'Office Longitude',
          prefixIcon: Icons.location_on,
          controller: officeLong,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          labelText: 'Range (In Meters)',
          prefixIcon: Icons.radar,
          controller: range,
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: 'Use Current Location',
          icon: Icons.my_location,
          onPressed: useCurrentLocation,
          bgColor: Colors.blueAccent,
        ),
        const SizedBox(height: 20),
        CustomButton(
          label: widget.isEditing ? 'Update Office' : 'Add Office',
          icon: widget.isEditing ? Icons.update : Icons.add,
          onPressed: handleFormSubmission,
          bgColor: widget.isEditing ? Colors.orange : Colors.green,
        ),
      ],
    );
  }
}
