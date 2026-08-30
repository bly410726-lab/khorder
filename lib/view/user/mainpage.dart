import 'package:flutter/material.dart';
import 'package:khorder/view/user/page/aipage.dart';
import 'package:khorder/view/user/page/cartpage.dart';
import 'package:khorder/view/user/page/homepage.dart';
import 'package:khorder/view/user/page/orderpage.dart';
import 'package:khorder/view/user/page/profilepage.dart';

class Mainpage extends StatelessWidget {
   Mainpage({super.key});
   List<Widget> screen =[
    Homepage(),
    Orderpage(),
    Aipage(),
    Cartpage(),
    Profilepage(),
   ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(

    );
  }
}