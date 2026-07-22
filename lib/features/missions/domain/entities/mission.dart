import 'package:equatable/equatable.dart';

enum RequestOutcome {
  found,
  notFound;

  static RequestOutcome? fromString(String? s) => switch (s) {
        'found'     => found,
        'not_found' => notFound,
        _           => null,
      };

  String get supabaseValue => switch (this) {
        found    => 'found',
        notFound => 'not_found',
      };
}

enum MissionStatus {
  open,
  underReview,
  carAssigned,
  onTheWay,
  onSite,
  returning,
  completed,
  cancelled;

  static MissionStatus fromString(String s) => switch (s) {
        'open'         => open,
        'under_review' => underReview,
        'car_assigned' => carAssigned,
        'on_the_way'   => onTheWay,
        'on_site'      => onSite,
        'returning'    => returning,
        'completed'    => completed,
        'cancelled'    => cancelled,
        _              => throw ArgumentError('Status desconhecido: $s'),
      };

  String get supabaseValue => switch (this) {
        open        => 'open',
        underReview => 'under_review',
        carAssigned => 'car_assigned',
        onTheWay    => 'on_the_way',
        onSite      => 'on_site',
        returning   => 'returning',
        completed   => 'completed',
        cancelled   => 'cancelled',
      };

  // RN-10.2
  bool get isActive => {carAssigned, onTheWay, onSite, returning}.contains(this);
  bool get isTerminal => {completed, cancelled}.contains(this);

  // RN-10.3 — next driver action
  MissionStatus? get nextDriverStatus => switch (this) {
        carAssigned => onTheWay,
        onTheWay    => onSite,
        onSite      => returning,
        returning   => completed,
        _           => null,
      };

  String get actionLabel => switch (this) {
        carAssigned => 'Iniciar',
        onTheWay    => 'Cheguei',
        onSite      => 'Retornando',
        returning   => 'Concluir',
        _           => '',
      };
}

class Mission extends Equatable {
  final String id;
  final String event;
  final String stage;
  final String street;
  final String streetNumber;
  final String neighborhood;
  final String objective;
  final String? mapsLink;
  final String? notes;
  final MissionStatus status;
  final RequestOutcome? outcome;
  final String? leaderName;
  final String? leaderPhone;
  final DateTime createdAt;

  const Mission({
    required this.id,
    required this.event,
    required this.stage,
    required this.street,
    required this.streetNumber,
    required this.neighborhood,
    required this.objective,
    this.mapsLink,
    this.notes,
    required this.status,
    this.outcome,
    this.leaderName,
    this.leaderPhone,
    required this.createdAt,
  });

  factory Mission.fromMap(Map<String, dynamic> map) {
    final leader = map['leaders'] as Map<String, dynamic>?;
    return Mission(
      id:           map['id'] as String,
      event:        map['event'] as String,
      stage:        map['stage'] as String,
      street:       map['street'] as String,
      streetNumber: map['street_number'] as String,
      neighborhood: map['neighborhood'] as String,
      objective:    map['objective'] as String,
      mapsLink:     map['maps_link'] as String?,
      notes:        map['notes'] as String?,
      status:       MissionStatus.fromString(map['status'] as String),
      outcome:      RequestOutcome.fromString(map['outcome'] as String?),
      leaderName:   leader?['name'] as String?,
      leaderPhone:  leader?['phone'] as String?,
      createdAt:    DateTime.parse(map['created_at'] as String),
    );
  }

  String get fullAddress => '$street, $streetNumber — $neighborhood';

  @override
  List<Object?> get props => [id, status, outcome];
}
