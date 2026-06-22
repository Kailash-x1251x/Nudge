import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'theme_provider.dart';
import 'theme_toggle.dart';
import 'station_coordinates.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(TrackingTaskHandler());
}

class TrackingTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _sub;
  late FlutterTts _tts;
  
  String? destStation;
  String? interchange;
  List<String> routeStations = [];
  int currentStopIndex = 0;
  
  bool interchangeAlertFired = false;
  bool destinationAlertFired = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _tts = FlutterTts();
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);

    final args = await FlutterForegroundTask.getData(key: 'trackingArgs') as Map?;
    if (args != null) {
      destStation = args['destStation'];
      interchange = args['interchange'];
      routeStations = List<String>.from(args['routeStations'] ?? []);
    }

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen((position) async {
      if (routeStations.isEmpty) return;

      FlutterForegroundTask.updateService(
        notificationTitle: 'Nudge 2.0 Live Journey',
        notificationText: 'Currently near: ${routeStations[currentStopIndex]} (${routeStations.length - 1 - currentStopIndex} stops remaining)',
      );

      FlutterForegroundTask.sendDataToMain({
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'stopIndex': currentStopIndex,
      });

      for (int i = currentStopIndex; i < routeStations.length; i++) {
        final currentStation = routeStations[i];
        final coord = getStationCoord(currentStation);
        if (coord == null) continue;

        final distance = coord.distanceTo(position.latitude, position.longitude);
        final radius = getAlertRadius(currentStation, destStation ?? '', interchange);

        if (distance <= radius) {
          if (i > currentStopIndex) {
            currentStopIndex = i;
          }

          if (currentStation == destStation && !destinationAlertFired) {
            destinationAlertFired = true;
            await _tts.speak("Arriving at your destination station, $destStation. Please get ready to exit.");
            FlutterForegroundTask.sendDataToMain({'action': 'arrived'});
            FlutterForegroundTask.stopService();
          } else if (currentStation == interchange && !interchangeAlertFired) {
            interchangeAlertFired = true;
            await _tts.speak("Arriving at your switch station, $interchange. Please prepare to change lines.");
            FlutterForegroundTask.sendDataToMain({'action': 'switch'});
          }
          break;
        }
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
  }
}

class TrackingScreen extends StatefulWidget {
  final String transportMode;
  final String? startStation;
  final String destStation;
  final String? interchange;
  final List<String> routeStations;

  const TrackingScreen({
    super.key,
    required this.transportMode,
    this.startStation,
    required this.destStation,
    required this.interchange,
    required this.routeStations,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  int _currentStopIndex = 0;
  bool _isFlashing = false;
  bool _journeyComplete = false;
  bool _showInterchangeAlert = false;
  double _gpsAccuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flashAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeInOut));
    _initForegroundService();
  }

  Future<void> _initForegroundService() async {
    if (!await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }
    
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'nudge_tracking_channel',
        channelName: 'Nudge 2.0 Tracking Service',
        channelDescription: 'Keeps running GPS location metrics inside the background layer safely.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: true),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    await FlutterForegroundTask.saveData(key: 'trackingArgs', value: {
      'destStation': widget.destStation,
      'interchange': widget.interchange,
      'routeStations': widget.routeStations,
    });

    await FlutterForegroundTask.startService(
      notificationTitle: 'Nudge 2.0 Engine Fired',
      notificationText: 'Tracking your metro progress safely in the background...',
      callback: startCallback,
    );

    FlutterForegroundTask.addTaskDataCallback(_onReceiveBackgroundData);
  }

  void _onReceiveBackgroundData(dynamic data) {
    if (data is! Map || !mounted) return;

    if (data.containsKey('action')) {
      if (data['action'] == 'arrived') {
        setState(() {
          _journeyComplete = true;
          _showInterchangeAlert = false;
        });
        _triggerVisualFlashes();
      } else if (data['action'] == 'switch') {
        setState(() {
          _showInterchangeAlert = true;
        });
        _triggerVisualFlashes();
      }
      return;
    }

    setState(() {
      _currentStopIndex = data['stopIndex'] ?? _currentStopIndex;
      _gpsAccuracy = data['accuracy'] ?? _gpsAccuracy;
    });
  }

  Future<void> _triggerVisualFlashes() async {
    setState(() => _isFlashing = true);
    for (int i = 0; i < 4; i++) {
      if (!mounted) break;
      await _flashController.forward();
      await _flashController.reverse();
    }
    if (mounted) setState(() => _isFlashing = false);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveBackgroundData);
    FlutterForegroundTask.stopService();
    _flashController.dispose();
    super.dispose();
  }

  Widget _buildBanner(ThemeProvider theme, {required IconData icon, required String text, bool outlined = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: outlined ? theme.background : theme.primary, 
        borderRadius: BorderRadius.circular(14), 
        border: Border.all(color: theme.primary, width: outlined ? 1.5 : 0),
      ),
      child: Row(
        children: [
          Icon(icon, color: outlined ? theme.primary : theme.background, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: outlined ? theme.primary : theme.background, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeProvider theme, String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: theme.secondary, letterSpacing: 1, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        SizedBox(
          width: 140,
          child: Text(value, style: TextStyle(fontSize: 12, color: theme.primary, fontWeight: FontWeight.w500), textAlign: alignEnd ? TextAlign.end : TextAlign.start, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildMiniTag(String label, ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: theme.primary), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, color: theme.primary, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _buildProgressBar(ThemeProvider theme, double progress, double interchangeProgress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trainX = progress * width;

        return SizedBox(
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: 24, left: 0, right: 0, child: Container(height: 4, decoration: BoxDecoration(color: theme.border, borderRadius: BorderRadius.circular(2)))),
              Positioned(
                top: 24,
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  width: trainX.clamp(0.0, width),
                  height: 4,
                  decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Positioned(top: 19, left: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle))),
              Positioned(top: 19, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: _journeyComplete ? theme.primary : theme.background, shape: BoxShape.circle, border: Border.all(color: theme.primary, width: 2)))),
              if (interchangeProgress >= 0)
                Positioned(
                  top: 8,
                  left: (interchangeProgress * width) - 16,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(4)),
                        child: Text('SWITCH', style: TextStyle(fontSize: 7, color: theme.background, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                      Container(width: 2, height: 8, color: theme.primary),
                    ],
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                top: 2,
                left: (trainX - 16).clamp(0.0, width - 32),
                child: Icon(Icons.train, size: 26, color: theme.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final stations = widget.routeStations;
    final total = stations.length - 1;
    final progress = total == 0 ? 1.0 : _currentStopIndex / total;
    final currentStation = stations.isNotEmpty ? stations[_currentStopIndex] : '';
    final stopsLeft = total - _currentStopIndex;
    final interchangeIndex = widget.interchange != null ? stations.indexOf(widget.interchange!) : -1;
    final interchangeProgress = interchangeIndex >= 0 && total > 0 ? interchangeIndex / total : -1.0;

    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        final flashColor = _isFlashing
            ? Color.lerp(theme.background, theme.primary.withOpacity(0.2), _flashAnimation.value)!
            : theme.background;

        return Scaffold(
          backgroundColor: flashColor,
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: theme.primary),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                          const Spacer(),
                          if (_gpsAccuracy > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.border)),
                              child: Text('±${_gpsAccuracy.toStringAsFixed(0)}m accuracy', style: TextStyle(fontSize: 11, color: theme.secondary)),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.border)),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('Live Engine', style: TextStyle(fontSize: 12, color: theme.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      if (_journeyComplete)
                        _buildBanner(theme, icon: Icons.check_circle, text: 'You have arrived at ${widget.destStation}! 🎉')
                      else if (_showInterchangeAlert)
                        _buildBanner(theme, icon: Icons.sync_alt, text: 'Switch lines at ${widget.interchange}! Prepare to move.')
                      else if (stopsLeft <= 2 && stopsLeft > 0)
                        _buildBanner(theme, icon: Icons.notifications_active, text: '$stopsLeft stop${stopsLeft == 1 ? '' : 's'} remaining — look out for your station!', outlined: true),
                      const SizedBox(height: 16),
                      Text(_journeyComplete ? 'Arrived at destination' : 'Currently near', style: TextStyle(fontSize: 13, color: theme.secondary)),
                      const SizedBox(height: 4),
                      Text(currentStation, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primary)),
                      const SizedBox(height: 40),
                      _buildProgressBar(theme, progress, interchangeProgress),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel(theme, 'FROM', stations.isNotEmpty ? stations.first : ''),
                          _buildLabel(theme, 'TO', widget.destStation, alignEnd: true),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child: ListView.builder(
                          itemCount: stations.length,
                          itemBuilder: (context, index) {
                            final isPassed = index < _currentStopIndex;
                            final isCurrent = index == _currentStopIndex;
                            final isInterchange = stations[index] == widget.interchange;
                            final isLast = index == stations.length - 1;

                            return Row(
                              children: [
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (index != 0) Container(width: 2, height: 14, color: isPassed || isCurrent ? theme.primary : theme.border),
                                      Container(
                                        width: isCurrent ? 16 : 10,
                                        height: isCurrent ? 16 : 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isPassed || isCurrent ? theme.primary : theme.background,
                                          border: Border.all(color: theme.primary, width: 1.5),
                                        ),
                                      ),
                                      if (!isLast) Container(width: 2, height: 14, color: isPassed ? theme.primary : theme.border),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            stations[index],
                                            style: TextStyle(
                                              fontSize: isCurrent ? 15 : 13,
                                              fontWeight: isCurrent || isInterchange ? FontWeight.w600 : FontWeight.normal,
                                              color: isPassed ? theme.secondary : theme.primary,
                                            ),
                                          ),
                                        ),
                                        if (isInterchange) _buildMiniTag('SWITCH', theme),
                                        if (isCurrent && !_journeyComplete) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.train, size: 16, color: theme.primary)),
                                        if (isLast && _journeyComplete) Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, size: 16, color: theme.primary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const ThemeToggle(),
            ],
          ),
        );
      },
    );
  }
}