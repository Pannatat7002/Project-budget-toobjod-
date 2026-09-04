import 'package:equatable/equatable.dart';

/// Base abstract class for all UseCases in Clean Architecture
/// [Type] is the return type of the use case
/// [Params] is the parameter type passed into call()
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Class to be used when a UseCase takes no parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
