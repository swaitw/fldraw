import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'selection_event.dart';
part 'selection_state.dart';

class SelectionBloc extends Bloc<SelectionEvent, SelectionState> {
  SelectionBloc() : super(const SelectionState()) {
    on<SelectionObjectsAdded>(_onSelectionObjectsAdded);
    on<SelectionReplaced>(_onSelectionReplaced);
    on<SelectionCleared>(_onSelectionCleared);
  }

  void _onSelectionObjectsAdded(
      SelectionObjectsAdded event, Emitter<SelectionState> emit) {
    emit(state.copyWith(
      selectedNodeIds: {...state.selectedNodeIds, ...event.nodeIds},
      selectedDrawingObjectIds: {
        ...state.selectedDrawingObjectIds,
        ...event.drawingObjectIds
      },
    ));
  }

  void _onSelectionReplaced(
      SelectionReplaced event, Emitter<SelectionState> emit) {
    emit(state.copyWith(
      selectedNodeIds: event.nodeIds,
      selectedDrawingObjectIds: event.drawingObjectIds,
    ));
  }

  void _onSelectionCleared(
      SelectionCleared event, Emitter<SelectionState> emit) {
    emit(const SelectionState());
  }
}