import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/responsavel_entity.dart';
import '../../domain/usecases/create_responsavel_usecase.dart';
import '../../domain/usecases/delete_responsavel_usecase.dart';
import '../../domain/usecases/get_responsaveis_usecase.dart';
import '../../domain/usecases/update_responsavel_usecase.dart';
import 'responsavel_event.dart';
import 'responsavel_state.dart';

class ResponsavelBloc extends Bloc<ResponsavelEvent, ResponsavelState> {
  ResponsavelBloc(
    this._getResponsaveisUsecase,
    this._createResponsavelUsecase,
    this._updateResponsavelUsecase,
    this._deleteResponsavelUsecase,
  ) : super(const ResponsavelState()) {
    on<ResponsaveisStarted>(_onStarted);
    on<ResponsavelCreated>(_onCreated);
    on<ResponsavelUpdated>(_onUpdated);
    on<ResponsavelDeleted>(_onDeleted);
  }

  final GetResponsaveisUsecase _getResponsaveisUsecase;
  final CreateResponsavelUsecase _createResponsavelUsecase;
  final UpdateResponsavelUsecase _updateResponsavelUsecase;
  final DeleteResponsavelUsecase _deleteResponsavelUsecase;

  void _logError(String context, Object error, StackTrace stackTrace) {
    developer.log(
      context,
      name: 'ResponsavelBloc',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _onStarted(
    ResponsaveisStarted event,
    Emitter<ResponsavelState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _onCreated(
    ResponsavelCreated event,
    Emitter<ResponsavelState> emit,
  ) async {
    try {
      await _createResponsavelUsecase(ResponsavelEntity(nome: event.nome));
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao criar responsavel.', error, stackTrace);
      emit(
        state.copyWith(
          status: ResponsavelStatus.failure,
          errorMessage: 'Nao foi possivel criar o responsavel.',
        ),
      );
    }
  }

  Future<void> _onUpdated(
    ResponsavelUpdated event,
    Emitter<ResponsavelState> emit,
  ) async {
    try {
      await _updateResponsavelUsecase(
        event.id,
        ResponsavelEntity(nome: event.nome),
      );
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao atualizar responsavel.', error, stackTrace);
      emit(
        state.copyWith(
          status: ResponsavelStatus.failure,
          errorMessage: 'Nao foi possivel atualizar o responsavel.',
        ),
      );
    }
  }

  Future<void> _onDeleted(
    ResponsavelDeleted event,
    Emitter<ResponsavelState> emit,
  ) async {
    try {
      await _deleteResponsavelUsecase(event.id);
      await _reload(emit);
    } catch (error, stackTrace) {
      _logError('Erro ao remover responsavel.', error, stackTrace);
      emit(
        state.copyWith(
          status: ResponsavelStatus.failure,
          errorMessage: 'Nao foi possivel remover o responsavel.',
        ),
      );
    }
  }

  Future<void> _reload(Emitter<ResponsavelState> emit) async {
    emit(state.copyWith(status: ResponsavelStatus.loading));
    try {
      final responsaveis = await _getResponsaveisUsecase();
      emit(
        state.copyWith(
          status: ResponsavelStatus.success,
          responsaveis: responsaveis,
        ),
      );
    } catch (error, stackTrace) {
      _logError('Erro ao carregar responsaveis.', error, stackTrace);
      emit(
        state.copyWith(
          status: ResponsavelStatus.failure,
          errorMessage: 'Nao foi possivel carregar os responsaveis.',
        ),
      );
    }
  }
}
