import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_label_usecase.dart';
import '../../domain/usecases/delete_label_usecase.dart';
import '../../domain/usecases/get_labels_usecase.dart';
import 'label_event.dart';
import 'label_state.dart';

class LabelBloc extends Bloc<LabelEvent, LabelState> {
  LabelBloc(
    this._getLabelsUsecase,
    this._createLabelUsecase,
    this._deleteLabelUsecase,
  ) : super(const LabelState()) {
    on<LabelsStarted>(_onStarted);
    on<LabelAdded>(_onAdded);
    on<LabelDeleted>(_onDeleted);
  }

  final GetLabelsUsecase _getLabelsUsecase;
  final CreateLabelUsecase _createLabelUsecase;
  final DeleteLabelUsecase _deleteLabelUsecase;

  void _logError(String context, Object error, StackTrace stackTrace) {
    developer.log(
      context,
      name: 'LabelBloc',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _onStarted(LabelsStarted event, Emitter<LabelState> emit) async {
    await _reload(emit);
  }

  Future<void> _onAdded(LabelAdded event, Emitter<LabelState> emit) async {
    try {
      await _createLabelUsecase(
        name: event.name,
        width: event.width,
        height: event.height,
      );
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao criar etiqueta.', error, stackTrace);
      emit(
        state.copyWith(
          status: LabelStatus.failure,
          errorMessage: 'Nao foi possivel criar a etiqueta.',
        ),
      );
    }
  }

  Future<void> _onDeleted(LabelDeleted event, Emitter<LabelState> emit) async {
    try {
      await _deleteLabelUsecase(event.id);
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao remover etiqueta.', error, stackTrace);
      emit(
        state.copyWith(
          status: LabelStatus.failure,
          errorMessage: 'Nao foi possivel remover a etiqueta.',
        ),
      );
    }
  }

  Future<void> _reload(Emitter<LabelState> emit) async {
    emit(state.copyWith(status: LabelStatus.loading));
    try {
      final labels = await _getLabelsUsecase();
      emit(state.copyWith(status: LabelStatus.success, labels: labels));
    } catch (error, stackTrace) {
      _logError('Erro ao carregar etiquetas.', error, stackTrace);
      emit(
        state.copyWith(
          status: LabelStatus.failure,
          errorMessage: 'Nao foi possivel carregar as etiquetas.',
        ),
      );
    }
  }
}
