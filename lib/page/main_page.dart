import 'package:embedded_system/page/fan_page.dart';
import 'package:embedded_system/page/led_page.dart';
import 'package:embedded_system/test_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  List<Widget> body = const [
    LedPage(),
    FanPage(),
    TestPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: GNav(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.black,
            color: Colors.grey[400],
            activeColor: Colors.black,
            tabBackgroundColor: Colors.white,
            gap: 8,
            tabs: const [
              GButton(
                icon: Icons.light,
                iconSize: 30,
                text: "Led",
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              GButton(
                icon: Icons.air,
                iconSize: 30,
                text: "Fan",
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              GButton(
                icon: Icons.aspect_ratio,
                iconSize: 30,
                text: "Test",
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
            ],
            onTabChange: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: body,
      ),
    );
  }
}
