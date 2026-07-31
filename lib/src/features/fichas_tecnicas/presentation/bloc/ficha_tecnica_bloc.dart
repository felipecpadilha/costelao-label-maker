import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/create_ficha_tecnica_usecase.dart';
import '../../domain/usecases/delete_ficha_tecnica_usecase.dart';
import '../../domain/usecases/get_fichas_tecnicas_usecase.dart';
import '../../domain/usecases/update_ficha_tecnica_usecase.dart';
import 'ficha_tecnica_event.dart';
import 'ficha_tecnica_state.dart';

class FichaTecnicaBloc extends Bloc<FichaTecnicaEvent, FichaTecnicaState> {
  FichaTecnicaBloc(
    this._getFichasUsecase,
    this._createFichaUsecase,
    this._updateFichaUsecase,
    this._deleteFichaUsecase,
  ) : super(const FichaTecnicaState()) {
    on<FichasTecnicasStarted>(_onStarted);
    on<FichaTecnicaCreated>(_onCreated);
    on<FichaTecnicaUpdated>(_onUpdated);
    on<FichaTecnicaDeleted>(_onDeleted);
  }

  final GetFichasTecnicasUsecase _getFichasUsecase;
  final CreateFichaTecnicaUsecase _createFichaUsecase;
  final UpdateFichaTecnicaUsecase _updateFichaUsecase;
  final DeleteFichaTecnicaUsecase _deleteFichaUsecase;

  void _logError(String context, Object error, StackTrace stackTrace) {
    developer.log(
      context,
      name: 'FichaTecnicaBloc',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _onStarted(
    FichasTecnicasStarted event,
    Emitter<FichaTecnicaState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _onCreated(
    FichaTecnicaCreated event,
    Emitter<FichaTecnicaState> emit,
  ) async {
    try {
      await _createFichaUsecase(event.ficha);
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao criar ficha tecnica.', error, stackTrace);
      emit(
        state.copyWith(
          status: FichaTecnicaStatus.failure,
          errorMessage: 'Nao foi possivel criar a ficha tecnica.',
        ),
      );
    }
  }

  Future<void> _onUpdated(
    FichaTecnicaUpdated event,
    Emitter<FichaTecnicaState> emit,
  ) async {
    try {
      await _updateFichaUsecase(event.id, event.ficha);
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao atualizar ficha tecnica.', error, stackTrace);
      emit(
        state.copyWith(
          status: FichaTecnicaStatus.failure,
          errorMessage: 'Nao foi possivel atualizar a ficha tecnica.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    FichaTecnicaDeleted event,
    Emitter<FichaTecnicaState> emit,
  ) async {
    try {
      await _deleteFichaUsecase(event.id);
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao remover ficha tecnica.', error, stackTrace);
      emit(
        state.copyWith(
          status: FichaTecnicaStatus.failure,
          errorMessage: 'Nao foi possivel remover a ficha tecnica.',
        ),
      );
    }
  }

  Future<void> _reload(Emitter<FichaTecnicaState> emit) async {
    emit(state.copyWith(status: FichaTecnicaStatus.loading));
    try {
      final fichas = await _getFichasUsecase();
      emit(state.copyWith(status: FichaTecnicaStatus.success, fichas: fichas));
    } catch (error, stackTrace) {
      _logError('Erro ao carregar fichas tecnicas.', error, stackTrace);
      emit(
        state.copyWith(
          status: FichaTecnicaStatus.failure,
          errorMessage: 'Nao foi possivel carregar as fichas tecnicas.',
        ),
      );
    }
  }
}
