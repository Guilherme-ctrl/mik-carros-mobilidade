import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/app_spacing.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../../features/location/domain/usecases/stop_location_tracking.dart';
import '../../../../../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../../../../../features/notifications/presentation/cubit/notifications_state.dart';
import '../cubit/missions_cubit.dart';
import '../cubit/missions_state.dart';
import '../widgets/active_mission_card.dart';
import '../widgets/location_disabled_banner.dart';
import '../widgets/mission_history_list.dart';
import '../widgets/no_mission_widget.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _locationDenied = false;
  StreamSubscription<bool>? _locationSub;
  MissionsLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<MissionsCubit>(context).init();
    BlocProvider.of<NotificationsCubit>(context).init();
    final locationService = Modular.get<LocationService>();
    _locationDenied = locationService.permissionDenied;
    _locationSub = locationService.permissionDeniedStream.listen((denied) {
      if (mounted) setState(() => _locationDenied = denied);
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    Modular.get<StopLocationTracking>()();
    Modular.to.navigate('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notifState) {
          final unread = notifState is NotificationsLoaded ? notifState.unreadCount : 0;
          return Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  DrawerHeader(
                    margin: EdgeInsets.zero,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset('assets/brand/jacare.svg', width: 100),
                          const SizedBox(height: 8),
                          const Text(
                            'Carros\nMik Dundee',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notificações'),
                    trailing: unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      Modular.to.pushNamed('/notifications/');
                    },
                  ),
                  const Spacer(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sair'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _logout();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                  BlocBuilder<NotificationsCubit, NotificationsState>(
                    builder: (context, state) {
                      final count = state is NotificationsLoaded ? state.unreadCount : 0;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            tooltip: 'Notificações',
                            onPressed: () => Modular.to.pushNamed('/notifications/'),
                          ),
                          if (count > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_locationDenied) const LocationDisabledBanner(),
            Expanded(
              child: BlocConsumer<MissionsCubit, MissionsState>(
                listener: (context, state) {
                  if (state is MissionsLoaded) {
                    _lastLoaded = state;
                  }
                  if (state is MissionsError && _lastLoaded != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        action: SnackBarAction(
                          label: 'Tentar novamente',
                          onPressed: () =>
                              BlocProvider.of<MissionsCubit>(context).retry(),
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is MissionsLoading || state is MissionsInitial) {
                    return _buildShimmerSkeleton();
                  }

                  if (state is CarNotConfigured) {
                    return _ErrorView(
                      icon: Icons.directions_car_outlined,
                      message:
                          'Carro não configurado para este usuário.\nContate a Mesa Central.',
                      onRetry: null,
                    );
                  }

                  if (state is MissionsError) {
                    if (_lastLoaded != null) {
                      return _buildLoadedContent(_lastLoaded!);
                    }
                    return _ErrorView(
                      icon: Icons.wifi_off_outlined,
                      message: state.message,
                      onRetry: () =>
                          BlocProvider.of<MissionsCubit>(context).retry(),
                    );
                  }

                  if (state is MissionsLoaded) {
                    return _buildLoadedContent(state);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(MissionsLoaded state) {
    final active = state.activeMission;
    final history = state.history;

    if (active == null && history.isEmpty) {
      return const NoMissionWidget();
    }

    return RefreshIndicator(
      onRefresh: () => BlocProvider.of<MissionsCubit>(context).retry(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active != null)
              ActiveMissionCard(mission: active)
            else
              const NoMissionWidget(),
            MissionHistoryList(missions: history),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface2,
      highlightColor: AppColors.surface3,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          children: [
            Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.onSurfaceDisabled),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceMuted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
