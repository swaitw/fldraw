import 'dart:convert';

import 'package:example/gen/assets.gen.dart';
import 'package:fldraw/fldraw.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<String> svgs;
  FlDrawController? controller;

  @override
  void initState() {
    svgs = Assets.svgs.values.map((e) => e.path).toList();
    super.initState();
  }

  void loadFromText() {
    final fldrawCode = """
    // Define a node, explicitly setting its shape
LoginNode [shape: node, heading: "User Login", text: "Enter credentials here."]

// Define a shape with centered text
SubmitButton [shape: rect, text: "Submit"]

// Define a standalone text object
Instructions [shape: rect, text: "Please"]

// Relationships still work the same
LoginNode -> SubmitButton
SubmitButton -> Instructions
  """;

    try {
      final parser = FlDrawParser();

      final jsonString = parser.parse(fldrawCode);

      final projectData = jsonDecode(jsonString);
      controller?.loadProject(projectData);
    } on FormatException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Syntax Error: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: controller == null
          ? SizedBox()
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                      maxWidth: 250,
                    ),
                    child: HistoryPanel(controller: controller!),
                  ),
                ),
              ],
            ),
      body: FlDraw(
        onControllerCreated: (controller) {
          this.controller = controller;
          Future.delayed(Duration.zero, () {
            setState(() {});
          });
        },
        onCanvasStateChanged: (state) {
          print("====== CANVAS ======");
          print(state.drawingObjects);
          print(state.nodes);
          print(state.viewportZoom);
          print(state.viewportOffset);
          print(state.redoStack);
          print(state.undoStack);
          print("====== CANVAS ======\n");
        },
        onSelectionStateChanged: (state) {
          print("====== SELECTION ======");
          print(state.selectedDrawingObjectIds);
          print(state.selectedNodeIds);
          print("====== SELECTION ======\n");
        },
        onToolStateChanged: (state) {
          print("====== TOOL ======");
          print(state.activeTool);
          print("====== TOOL ======\n");
        },
        child: Stack(
          children: [
            FlDrawCanvas(),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: FlToolbar(svgs: svgs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
