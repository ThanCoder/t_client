sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T unwrap() {
    return switch (this) {
      Ok(value: final val) => val,
      Err() => throw StateError('Called `unwrap` an Err!'),
    };
  }

  E unwrapError() {
    return switch (this) {
      Err(value: final val) => val,
      Ok() => throw StateError('Called `unwrapError` an Ok!'),
    };
  }

  Result<R, E> map<R>(R Function(T value) transform) {
    return switch (this) {
      Ok(value: final val) => Ok(transform(val)),
      Err() => throw StateError('Called `map` an Err!'),
    };
  }

  Result<T, F> mapError<F>(F Function(E value) transform) {
    return switch (this) {
      Err(value: final val) => Err(transform(val)),
      Ok() => throw StateError('Called `mapError` an Ok!'),
    };
  }
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  final E value;
  const Err(this.value);
}
