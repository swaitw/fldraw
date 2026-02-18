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
      debugShowCheckedModeBanner: false,
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
  FlDrawController controller = FlDrawController();

  @override
  void initState() {
    svgs = Assets.svgs.values.map((e) => e.path).toList();
    super.initState();
  }

  void loadFromText() {
    final fldrawCode = """
   // Vertical workflow with grouped steps

start [shape: node, heading: "Start", text: "Begin the process"]

// Group for input & validation phase
inputPhase [label: "Input Phase"] {
  collect [shape: rect, text: "Collect User Info"]
  validate [shape: node, heading: "Validate", text: "Check Input Data"]
}

// Group for processing phase
processPhase [label: "Processing Phase"] {
  transform [shape: rect, text: "Transform Data"]
  compute [shape: node, heading: "Compute", text: "Perform Calculations"]
  cache [shape: rect, text: "Cache Results"]
}

// Group for output & cleanup
outputPhase [label: "Output Phase", figure: true] {
  save [shape: circle, text: "Save to Database"]
  notify [shape: node, heading: "Notify", text: "Send Confirmation"]
  cleanup [shape: rect, text: "Clean Temp Files"]
}

end [shape: node, heading: "End", text: "Workflow Complete"]

// --- Relationships ---
start -> inputPhase
inputPhase -> processPhase
processPhase -> outputPhase
outputPhase -> end

start -> outputPhase
  """;

    try {
      final parser = FlDrawParser();

      final jsonString = parser.parse(fldrawCode);

      final projectData = jsonDecode(jsonString);
      controller.loadProject(projectData);

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
      floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                      maxWidth: 250,
                    ),
                    child: HistoryPanel(controller: controller),
                  ),
                ),
              ],
            ),
      body: FlDraw(
        controller: controller,
        onControllerCreated: (controller) {
          loadFromText();
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
