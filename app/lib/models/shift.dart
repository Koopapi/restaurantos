/// Turno de un empleado (`/shifts`). `type` ∈ matutino | vespertino | completo.
class Shift {
  final String id;
  final String employeeId;
  final String date; // YYYY-MM-DD
  final String type;
  final String? start; // HH:MM
  final String? end;

  const Shift({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.type,
    this.start,
    this.end,
  });

  factory Shift.fromJson(Map<String, dynamic> j) => Shift(
        id: j['id'] as String,
        employeeId: j['employeeId'] as String,
        date: (j['date'] as String?) ?? '',
        type: (j['type'] as String?) ?? 'completo',
        start: j['start'] as String?,
        end: j['end'] as String?,
      );
}
