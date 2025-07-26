part of 'tool_bloc.dart';

abstract class ToolEvent extends Equatable {
  const ToolEvent();

  @override
  List<Object> get props => [];
}

/// Event dispatched when a new tool is selected from the toolbar.
class ToolSelected extends ToolEvent {
  final EditorTool tool;

  const ToolSelected(this.tool);

  @override
  List<Object> get props => [tool];
}