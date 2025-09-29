import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class BottomNavigationItem {
  Widget? item;
  Widget? child;
  Function? action;

  BottomNavigationItem({this.item, this.child, this.action});
}

class BottomNavigationPage extends StatefulWidget {
  int index;
  List<BottomNavigationItem>? items;

  BottomNavigationPage({Key? key, this.index = 0, @required this.items})
    : super(key: key);
  @override
  _BottomNavigationPageState createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  Widget? _myView;
  int? _index;
  GlobalKey _bottomNavigationKey = GlobalKey();
  @override
  void initState() {
    initView(widget.index);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedSwitcher(
        //        transitionBuilder: (child, animation) {
        //          return ScaleTransition(child: child, scale: animation);
        //        },
        duration: Duration(milliseconds: 500),
        child: _myView,
      ),
      bottomNavigationBar: SafeArea(
        child: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _index ?? 0,
          height: 50.0,
          color: Color(0xFF768CEB),
          buttonBackgroundColor: Color(0xFF768CEB),
          backgroundColor: Color.fromARGB(255, 255, 255, 255),
          animationCurve: Curves.easeInOut,
          animationDuration: Duration(milliseconds: 500),
          onTap: (index) {
            setState(() {
              initView(index);
            });
          },
          items: widget.items!
              .map((p) => Container(color: Colors.transparent, child: p.item))
              .toList(),
        ),
      ),
    );
  }

  /// cần xem lại
  void initView(int index) {
    setState(() {
      // _index = index;
      // _myView = widget.items![_index].child;
      // if (widget.items![_index].action != null) {
      //   widget.items![_index].action();
      _myView = widget.items![index].child;
      if (widget.items![index].action != null) {
        widget.items![index].action!();
      }
    });
  }
}
