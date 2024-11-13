import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> attendanceData = [];
  Map<String, dynamic> liveStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
    _fetchLiveStatus();
  }

  void _fetchAttendanceData() {
    _databaseReference.child('attendance').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          // Chuyển đổi dữ liệu và sắp xếp theo thời gian
          attendanceData = (data as Map<dynamic, dynamic>)
              .values
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // Sắp xếp theo thời gian, mới nhất lên trước
          attendanceData.sort((a, b) {
            DateTime timeA = DateTime.parse(a['time']);
            DateTime timeB = DateTime.parse(b['time']);
            return timeB.compareTo(timeA); // So sánh để đảo ngược thứ tự
          });
        });
      } else {
        print("Attendance data is null or not in the expected format.");
      }
    }).onError((error) {
      print("Error fetching attendance data: $error");
    });
  }

  void _fetchLiveStatus() {
    _databaseReference.child('users').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          liveStatus = Map<String, dynamic>.from(data);
        });
      } else {
        print("Live status data is null or not in the expected format.");
      }
    }).onError((error) {
      print("Error fetching live status data: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Attendance History"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchAttendanceData();
              _fetchLiveStatus();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAttendanceTable(),
              const SizedBox(height: 20),
              // _buildLiveStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey),
        columns: const [
          DataColumn(label: Text('User ID')),
          DataColumn(label: Text('Device ID')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Status')),
        ],
        rows: attendanceData.map((data) {
          String formattedTime = data['time'] ?? 'Invalid time';
          return DataRow(
            cells: [
              DataCell(Text(data['uid'] ?? 'N/A')),
              DataCell(Text(data['id'] ?? 'N/A')),
              DataCell(Text(formattedTime)),
              DataCell(
                Text(
                  data['status'],
                  style: TextStyle(
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Widget _buildLiveStatus() {
  //   if (liveStatus.isEmpty) return const Text('No live data available');
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: liveStatus.keys.map((key) {
  //       final isCheckedIn = liveStatus[key] == 1;
  //       return Card(
  //         child: ListTile(
  //           leading: Icon(
  //             isCheckedIn ? Icons.check_circle : Icons.cancel,
  //             color: isCheckedIn ? Colors.green : Colors.red,
  //           ),
  //           title: Text('UID: $key'),
  //           subtitle: Text(isCheckedIn ? 'Checked-in' : 'Checked-out'),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }
}
