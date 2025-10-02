enum PatientPriority {
  critical,
  high,
  medium,
  low,
}

class Patient {
  final String id;
  final String name;
  final String age;
  final String gender;
  final String condition;
  final String lastVisit;
  final String nextVisit;
  final PatientPriority priority;
  final String phone;
  final String address;
  final String? bloodGroup;
  final String? abhaId;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.condition,
    required this.lastVisit,
    required this.nextVisit,
    required this.priority,
    required this.phone,
    required this.address,
    this.bloodGroup,
    this.abhaId,
  });
}

class DashboardStats {
  final int totalPatients;
  final int pendingVisits;
  final int highRiskPatients;
  final int vaccinesDue;
  final int pregnantWomen;
  final int childrenUnder5;
  final int todayVisits;
  final String completionRate;

  DashboardStats({
    required this.totalPatients,
    required this.pendingVisits,
    required this.highRiskPatients,
    required this.vaccinesDue,
    required this.pregnantWomen,
    required this.childrenUnder5,
    required this.todayVisits,
    required this.completionRate,
  });
}
