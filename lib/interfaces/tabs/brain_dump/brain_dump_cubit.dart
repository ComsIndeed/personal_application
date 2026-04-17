import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrainDumpCubit extends Cubit<BrainDumpState> {
  BrainDumpCubit() : super(BrainDumpState());

  void updateFiles(List<PlatformFile> files) {
    emit(state.copyWith(files: files));
  }

  void sendRaw() {}

  void sendProcessed() {}
}

class BrainDumpState {
  // Inputs
  final List<PlatformFile> files;

  // View

  BrainDumpState({this.files = const []});

  BrainDumpState copyWith({List<PlatformFile>? files}) {
    return BrainDumpState(files: files ?? this.files);
  }
}
