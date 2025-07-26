part of 'tool_bloc.dart';

class ToolState extends Equatable {
  final EditorTool activeTool;

  const ToolState({this.activeTool = EditorTool.arrow});

  @override
  List<Object> get props => [activeTool];
}