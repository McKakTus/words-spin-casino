import 'dart:ui';
import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(Images.background, fit: BoxFit.cover),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.black.withAlpha(26)),
        ),

        Scaffold(
          backgroundColor: Colors.transparent, 
          body: Container(

          )
        ),
      ],
    );
  }
}