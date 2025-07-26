part of 'selection_bloc.dart';

class SelectionState extends Equatable {
  final Set<String> selectedNodeIds;
  final Set<String> selectedDrawingObjectIds;

  const SelectionState({
    this.selectedNodeIds = const {},
    this.selectedDrawingObjectIds = const {},
  });

  SelectionState copyWith({
    Set<String>? selectedNodeIds,
    Set<String>? selectedDrawingObjectIds,
  }) {
    return SelectionState(
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      selectedDrawingObjectIds:
      selectedDrawingObjectIds ?? this.selectedDrawingObjectIds,
    );
  }

  @override
  List<Object> get props => [selectedNodeIds, selectedDrawingObjectIds];
}