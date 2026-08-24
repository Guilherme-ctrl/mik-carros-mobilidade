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

// Request-level status (narrowed, ADR-3 — U1). Per-car progress moved to
// [CarStatus]; this enum no longer carries on_the_way/on_site/returning.
enum RequestStatus {
  open,
  underReview,
  carAssigned,
  completed,
  cancelled;

  static RequestStatus fromString(String s) => switch (s) {
        'open'         => open,
        'under_review' => underReview,
        'car_assigned' => carAssigned,
        'completed'    => completed,
        'cancelled'    => cancelled,
        _              => throw ArgumentError('Status de missão desconhecido: $s'),
      };

  String get supabaseValue => switch (this) {
        open        => 'open',
        underReview => 'under_review',
        carAssigned => 'car_assigned',
        completed   => 'completed',
        cancelled   => 'cancelled',
      };

  bool get isTerminal => this == completed || this == cancelled;
}

// Per-car progress (ADR-3 — U1). Backed by request_cars.status.
enum CarStatus {
  carAssigned,
  onTheWay,
  onSite,
  returning;

  static CarStatus fromString(String s) => switch (s) {
        'car_assigned' => carAssigned,
        'on_the_way'   => onTheWay,
        'on_site'      => onSite,
        'returning'    => returning,
        _              => throw ArgumentError('Status de carro desconhecido: $s'),
      };

  String get supabaseValue => switch (this) {
        carAssigned => 'car_assigned',
        onTheWay    => 'on_the_way',
        onSite      => 'on_site',
        returning   => 'returning',
      };

  // RN-10.2 (unchanged meaning, now scoped to this car's own progress)
  bool get isActive => true; // every CarStatus value is, by construction, "in progress"

  // RN-10.3 — next driver action
  CarStatus? get nextDriverStatus => switch (this) {
        carAssigned => onTheWay,
        onTheWay    => onSite,
        onSite      => returning,
        returning   => null, // "Concluir" is now reporting an outcome (FR6.1), not a status step
      };

  String get actionLabel => switch (this) {
        carAssigned => 'Iniciar',
        onTheWay    => 'Cheguei',
        onSite      => 'Retornando',
        returning   => '',
      };
}

// FR3.3 — identification-only view of another car assigned to the same
// mission. Deliberately has no location field: co-assigned drivers see who
// else is on the mission, never where they are (car_locations RLS stays
// central-only, ADR-8).
class CarSummary extends Equatable {
  final String carNumber;
  final String pilotName;
  final String? copilotName;

  // null = este carro ainda não reportou. Entrou junto com o encerramento
  // manual (20260824000002): close_request recusa enquanto qualquer carro
  // ativo estiver sem desfecho, então a tela precisa poder dizer POR QUE o
  // botão de encerrar ainda não está disponível, em vez de só desabilitá-lo.
  final RequestOutcome? outcome;

  const CarSummary({
    required this.carNumber,
    required this.pilotName,
    this.copilotName,
    this.outcome,
  });

  factory CarSummary.fromMap(Map<String, dynamic> map) => CarSummary(
        carNumber:   map['number'] as String,
        pilotName:   map['pilot_name'] as String,
        copilotName: map['copilot_name'] as String?,
        outcome:     RequestOutcome.fromString(map['outcome'] as String?),
      );

  @override
  List<Object?> get props => [carNumber, pilotName, copilotName, outcome];
}

class Mission extends Equatable {
  final String id;
  final String event;
  final String stage;
  final String street;
  final String streetNumber;
  final String neighborhood;
  // Guardada desde 20260824000006. Antes o app colava ", Blumenau, SC" fixo no
  // destino, então uma missão em Gaspar mandava o motorista para a rua de mesmo
  // nome em Blumenau.
  final String city;
  // Só quando o endereço veio da busca de endereço. Nulas na digitação manual.
  final double? latitude;
  final double? longitude;
  final String objective;
  final String? mapsLink;
  final String? notes;
  final RequestStatus requestStatus;
  final CarStatus ownStatus;
  final RequestOutcome? ownOutcome;
  final List<CarSummary> coAssignedCars;
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
    this.city = 'Blumenau',
    this.latitude,
    this.longitude,
    required this.objective,
    this.mapsLink,
    this.notes,
    required this.requestStatus,
    required this.ownStatus,
    this.ownOutcome,
    this.coAssignedCars = const [],
    this.leaderName,
    this.leaderPhone,
    required this.createdAt,
  });

  // Built from a request_cars row joined to requests(*, leaders(name, phone))
  // — see MissionsRemoteDatasourceImpl.getMissionsForCar. coAssignedCars is
  // populated separately (a second query, per FR3.3) and merged in by the
  // repository, not parsed here.
  factory Mission.fromMap(Map<String, dynamic> map, {List<CarSummary> coAssignedCars = const []}) {
    final request = map['requests'] as Map<String, dynamic>;
    final leader = request['leaders'] as Map<String, dynamic>?;
    return Mission(
      id:            request['id'] as String,
      event:         request['event'] as String,
      stage:         request['stage'] as String,
      street:        request['street'] as String,
      streetNumber:  request['street_number'] as String,
      neighborhood:  request['neighborhood'] as String,
      // Fallback para 'Blumenau' porque a coluna nasceu depois das primeiras
      // solicitações; o backfill da migration cobre o passado, isto cobre um
      // app novo lendo uma linha que por algum motivo veio sem cidade.
      city:          (request['city'] as String?) ?? 'Blumenau',
      // Chegam como num (int ou double) do PostgREST conforme o valor.
      latitude:      (request['latitude'] as num?)?.toDouble(),
      longitude:     (request['longitude'] as num?)?.toDouble(),
      objective:     request['objective'] as String,
      mapsLink:      request['maps_link'] as String?,
      notes:         request['notes'] as String?,
      requestStatus: RequestStatus.fromString(request['status'] as String),
      ownStatus:     CarStatus.fromString(map['status'] as String),
      ownOutcome:    RequestOutcome.fromString(map['outcome'] as String?),
      coAssignedCars: coAssignedCars,
      leaderName:    leader?['name'] as String?,
      leaderPhone:   leader?['phone'] as String?,
      createdAt:     DateTime.parse(map['assigned_at'] as String),
    );
  }

  String get fullAddress => '$street, $streetNumber — $neighborhood';

  // O que vai para o app de mapas quando não há coordenada. A cidade vem daqui
  // e não mais fixa no código de navegação — era isso que mandava quem estava
  // em Gaspar para a rua homônima de Blumenau.
  String get navigationAddress =>
      '$street, $streetNumber, $neighborhood, $city, SC';

  bool get hasCoordinates => latitude != null && longitude != null;

  // Encerramento manual (20260824000002): close_request só aceita quando TODO
  // carro ativo já reportou. A regra é replicada aqui para a tela poder
  // explicar a espera em vez de deixar o motorista bater num erro — o RPC
  // continua sendo a autoridade, esta é só a versão que a UI consegue ler.
  bool get allCarsReported =>
      ownOutcome != null && coAssignedCars.every((c) => c.outcome != null);

  // Quem ainda falta, para a mensagem na tela.
  List<String> get carsPendingOutcome =>
      coAssignedCars.where((c) => c.outcome == null).map((c) => c.carNumber).toList();

  @override
  List<Object?> get props =>
      [id, ownStatus, ownOutcome, coAssignedCars, city, latitude, longitude];
}
