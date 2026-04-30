import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiAgentState extends Equatable {
  const AiAgentState();

  @override
  List<Object?> get props => [];
}

// Different UIs that has their AI stuff would individually have their own cubit for handling their view
class AiAgentCubit extends Cubit<AiAgentState> {
  AiAgentCubit() : super(const AiAgentState());
}
