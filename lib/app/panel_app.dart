import 'package:flutter/material.dart';

import '../features/panel/presentation/widgets/panel_root.dart';

class PanelApp extends StatelessWidget {
  const PanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: PanelRoot(),
      ),
    );
  }
}
