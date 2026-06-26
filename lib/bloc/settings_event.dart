import 'package:equatable/equatable.dart';
import '../models/settings_model.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSettingsEvent extends SettingsEvent {
  const InitializeSettingsEvent();
}

class UpdateSettingsEvent extends SettingsEvent {
  final AppSettings settings;

  const UpdateSettingsEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}
