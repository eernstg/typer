import 'package:test/test.dart';
import 'package:typer/typer.dart';

void main() {
  test('Relational operators', () {
    final t1 = Typer<int>();
    final t2 = Typer<num>();

    expect(t1 <= t2, isTrue);
    expect(t2 <= t1, isFalse);
  });

  test('`is` and `as`', () {
    Typer<num> typeHelper = Typer<int>();
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
    Typer<num> typeHelper = Typer<int>();

    expect(typeHelper.containsInstance(2), isTrue);
    expect(typeHelper.containsInstance(1.5), isFalse);
    typeHelper.cast(2); // OK.
    expect(() => typeHelper.cast(1.5), throws);
  });

  test('The getter `type`', () {
    Typer<num> typeHelper = Typer<int>();
    expect(typeHelper.type, int);
  });

  test('The method `callWith`', () {
    Typer<num> typeHelper = Typer<int>();

    List<X> createList<X>(Typer<X> typeHelper) =>
        typeHelper.callWith(<Y>() => <Y>[] as List<X>);

    List<num> xs = createList(typeHelper);
    expect(xs is List<int>, isTrue);
  });

  test('The method `promoteOrNull`', () {
    num p = 2;
    Typer<num> typeHelper = Typer<int>();
    List<num>? ps = typeHelper.promoteOrNull(p, <X extends num>(X x) => <X>[x] as List<num>);
    expect(ps.runtimeType, List<int>);

    p = 2.5;
    ps = typeHelper.promoteOrNull(p, <X extends num>(X x) => <X>[x]);
    expect(ps.runtimeType, Null);
  });

  test('The method `promote`', () {
    num p = 3;
    Typer<int> typeHelper = Typer();
    int c = typeHelper.promote(
      p,
      <X extends int>(X x) {
        expect(x.isEven, isFalse);
        return x as int;
      },
      orElse: () => 14,
    );
    expect(c, 3);

    p = 3.75;
    c = typeHelper.promote(
      p,
      <X extends int>(X x) => throw 'Not reached',
      orElse: () => 14,
    );
    expect(c, 14);
  });
}
