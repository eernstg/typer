import 'package:test/test.dart';
import 'package:typer/typer.dart';

void main() {
  test('Relational operators', () {
    final t1 = TypeHelper<int>();
    final t2 = TypeHelper<num>();

    expect(t1 <= t2, isTrue);
    expect(t2 <= t1, isFalse);
  });

  test('`is` and `as`', () {
    TypeHelper<num> typeHelper = TypeHelper<int>();
    // These are compile-time errors, it's a stupid question:
    //   expect(2.isA(typeHelper), isTrue);
    //   expect(1.5.isA(typeHelper), isFalse);
    //   expect(2.asA(typeHelper), 2);
    //   expect(() => 1.5.asA(typeHelper), throws);

    // But we can forget the type of the receiver, and do it.
    expect((2 as num).isA(typeHelper), isTrue);
    expect((1.5 as num).isA(typeHelper), isFalse);
    expect((2 as num).asA(typeHelper), 2);
    expect(() => (1.5 as num).asA(typeHelper), throws);
  });

  test('Instance methods doing `is` and `as`', () {
    TypeHelper<num> typeHelper = TypeHelper<int>();

    expect(typeHelper.containsInstance(2), isTrue);
    expect(typeHelper.containsInstance(1.5), isFalse);
    typeHelper.cast(2); // OK.
    expect(() => typeHelper.cast(1.5), throws);
  });

  test('The getter `type`', () {
    TypeHelper<num> typeHelper = TypeHelper<int>();
    expect(typeHelper.type, int);
  });

  test('The method `callWith`', () {
    TypeHelper<num> typeHelper = TypeHelper<int>();

    List<X> createList<X>(TypeHelper<X> typeHelper) =>
        typeHelper.callWith(<Y>() => <Y>[] as List<X>);

    List<num> xs = createList(typeHelper);
    expect(xs is List<int>, isTrue);
  });

  test('The method `promoting`', () {
    num p = 2;
    TypeHelper<num> typeHelper = TypeHelper<int>();
    List<num>? ps = typeHelper.promoting(p, <X extends num>(X x) => <X>[x]);
    expect(ps.runtimeType, List<int>);

    p = 2.5;
    ps = typeHelper.promoting(p, <X extends num>(X x) => <X>[x]);
    expect(ps.runtimeType, Null);
  });

  test('The method `promotingOrElse`', () {
    num p = 3;
    TypeHelper<int> typeHelper = TypeHelper();
    int c = typeHelper.promotingOrElse(
      p,
      <X extends int>(X x) {
        expect(x.isEven, isFalse);
        return x as int;
      },
      orElse: () => 14,
    );
    expect(c, 3);

    p = 3.75;
    c = typeHelper.promotingOrElse(
      p,
      <X extends int>(X x) => throw 'Not reached',
      orElse: () => 14,
    );
    expect(c, 14);
  });
}
