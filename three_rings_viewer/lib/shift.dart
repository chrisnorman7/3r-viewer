import 'volunteer.dart';

class Shift{
  Shift(
    {
      this.rotaId,
      this.name,
      this.start,
      this.end,
      this.volunteers
    }
  );

  final String name;
  final int rotaId;
  final DateTime start, end;
  final List<Volunteer> volunteers;

  @override
  String toString() {
    return '$name ($startString-$endString)';
  }
  
  String get startString {
    return '${start.hour.toString().padLeft(2, "0")}:${start.minute.toString().padLeft(2, "0")}';
  }

  String get endString {
    return '${end.hour.toString().padLeft(2, "0")}:${end.minute.toString().padLeft(2, "0")}';
  }
}
