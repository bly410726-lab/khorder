import 'package:flutter/material.dart';
import 'package:khorder/service/provider.dart';
import 'package:khorder/view/user/mainpage.dart';
import 'package:provider/provider.dart';

void main(){
  runApp(
   ChangeNotifierProvider(create: (context) => ProviDer(),
   child: MyWidget(),)
  );
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Mainpage(),
    );
  }
}