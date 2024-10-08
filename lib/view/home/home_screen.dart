import 'package:attendence_tracker/res/components/drawer.dart';
import 'package:attendence_tracker/view/home/components/check_in_out.dart';
import 'package:attendence_tracker/view/home/components/distance_from_office.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/home/attendence_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Geo-Wave', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CheckedInOut(),
                  SizedBox(height: 20),
                  DistanceFromOffice(),
                ],
              )),
        ),
      ),
    );
  }
}
