import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrainDumpCubit extends Cubit<BrainDumpState> {
  BrainDumpCubit() : super(BrainDumpState());

  void updateTextInput(String text) {
    emit(state.copyWith(textInput: text));
  }

  void updateFiles(List<PlatformFile> files) {
    emit(state.copyWith(files: files));
  }
}

class BrainDumpState {
  // Inputs
  final String textInput;
  final List<PlatformFile> files;

  // View

  BrainDumpState({this.textInput = '', this.files = const []});

  BrainDumpState copyWith({String? textInput, List<PlatformFile>? files}) {
    return BrainDumpState(
      textInput: textInput ?? this.textInput,
      files: files ?? this.files,
    );
  }
}
