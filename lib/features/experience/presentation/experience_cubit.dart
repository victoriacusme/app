import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/experience_layout.dart';
import '../domain/experience_repository.dart';

/// Layout del home. `null` mientras carga por primera vez.
class ExperienceCubit extends Cubit<ExperienceLayout?> {
  ExperienceCubit(this._repository) : super(null);

  final ExperienceRepository _repository;

  Future<void> load() => _repository.watchHome().forEach(emit);
}
