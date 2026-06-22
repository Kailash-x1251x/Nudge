import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'theme_provider.dart';
import 'theme_toggle.dart';
import 'station_coordinates.dart';
import 'tracking_screen.dart';
import 'main.dart';

class RouteOption {
  final String? interchange;
  final int totalStops;
  final bool isRecommended;
  final bool requiresSwitch;

  RouteOption({this.interchange, required this.totalStops, this.isRecommended = false, this.requiresSwitch = false});
}

class LocationScreen extends StatefulWidget {
  final String transportMode;
  const LocationScreen({super.key, required this.transportMode});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _useCurrentLocation = false;
  bool _isLoadingGps = false;
  String? _selectedStart;
  String? _selectedDest;

  final TextEditingController _startSearchController = TextEditingController();
  final TextEditingController _destSearchController = TextEditingController();

  List<String> _startFiltered = [];
  List<String> _destFiltered = [];
  bool _showStartList = false;
  bool _showDestList = false;
  List<RouteOption> _routeOptions = [];
  String? _selectedInterchange;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'nudge_tracking_channel',
        channelName: 'Nudge 2.0 Transit Monitor',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        playSound: true, // Tells Android to play the default notification sound
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: true,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  Future<void> _startBackgroundTrackingService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Nudge 2.0 Engine Fired',
        notificationText: 'Tracking your metro progress safely...',
        callback: startCallback,
      );
    }
  }

  List<String> _getAllStationsList() {
    final stations = [...blueLineStations, ...greenLineStations.where((s) => !blueLineStations.contains(s))];
    stations.sort((a, b) => a.compareTo(b));
    return stations;
  }

  bool get _canContinue => (_useCurrentLocation || _selectedStart != null) && _selectedDest != null;

  void _filterStations(String query, bool isStart) {
    final filtered = _getAllStationsList().where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();
    setState(() {
      if (isStart) { _startFiltered = filtered; _showStartList = query.isNotEmpty; }
      else { _destFiltered = filtered; _showDestList = query.isNotEmpty; }
    });
  }

  void _selectStation(String station, bool isStart) {
    setState(() {
      if (isStart) { _selectedStart = station; _startSearchController.text = station; _showStartList = false; }
      else { _selectedDest = station; _destSearchController.text = station; _showDestList = false; }
      _updateRouteOptions();
    });
  }

  List<String> _buildRouteStationsList() => []; // Kept simple to clear paths

  void _updateRouteOptions() {
    if (_selectedDest != null && _selectedStart != null) {
      _routeOptions = [RouteOption(totalStops: 5, requiresSwitch: false)];
    }
  }

  @override
  void dispose() {
    _startSearchController.dispose();
    _destSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              IconButton(icon: Icon(Icons.arrow_back, color: theme.primary), onPressed: () => Navigator.pop(context)),
              const SizedBox(height: 24),
              Text('Where to?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primary)),
              const SizedBox(height: 32),
              _buildSearchableStationField(label: 'Destination station', hint: 'Search station...', searchController: _destSearchController, selectedValue: _selectedDest, suggestions: _destFiltered, showList: _showDestList, isStart: false, theme: theme),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedDest != null
                      ? () async {
                          await _startBackgroundTrackingService();
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrackingScreen(
                                  transportMode: widget.transportMode,
                                  startStation: _selectedStart,
                                  destStation: _selectedDest!,
                                  interchange: _selectedInterchange,
                                  routeStations: const [],
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: theme.background, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Start Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableStationField({required String label, required String hint, required TextEditingController searchController, required String? selectedValue, required List<String> suggestions, required bool showList, required bool isStart, required ThemeProvider theme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.secondary)),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          onChanged: (v) => _filterStations(v, isStart),
          style: TextStyle(color: theme.primary),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: theme.secondary), prefixIcon: Icon(Icons.flag_outlined, color: theme.secondary), filled: true, fillColor: theme.cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        if (showList && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.border)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) => ListTile(dense: true, title: Text(suggestions[index], style: TextStyle(color: theme.primary)), onTap: () => _selectStation(suggestions[index], isStart)),
            ),
          ),
      ],
    );
  }
}