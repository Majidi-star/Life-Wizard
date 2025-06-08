import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme_utils.dart';
import 'reward_repository.dart';
import 'points_service.dart';
import '../../main.dart' as app_main;

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final RewardRepository _rewardRepository = RewardRepository();
  final PointsService _pointsService = PointsService();

  int _points = 0;
  double _hoursWorked = 0.0;
  String _badge = 'beginner';
  List<dynamic> _cookieJar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rewards = await _rewardRepository.getRewards();

      setState(() {
        _points = rewards['points'] as int;
        _hoursWorked = rewards['hours_worked'] as double;
        _badge = rewards['badges'] as String;
        _cookieJar = rewards['cookie_jar'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rewards: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = app_main.settingsBloc.state;

    return Scaffold(
      backgroundColor: settingsState.primaryColor,
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        backgroundColor: settingsState.thirdlyColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRewards,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadRewards,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rewards Summary Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Progress',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: settingsState.secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Points display
                              _buildStatRow(
                                icon: Icons.star,
                                iconColor: Colors.amber,
                                title: 'Points',
                                value: _points.toString(),
                              ),
                              const SizedBox(height: 12),

                              // Hours worked display
                              _buildStatRow(
                                icon: Icons.timer,
                                iconColor: Colors.blue,
                                title: 'Hours Worked',
                                value: _hoursWorked.toStringAsFixed(1),
                              ),
                              const SizedBox(height: 12),

                              // Badge display
                              _buildStatRow(
                                icon: Icons.military_tech,
                                iconColor: Colors.purple,
                                title: 'Current Badge',
                                value: _badge.toUpperCase(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Cookie jar section
                      Text(
                        'Cookie Jar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: settingsState.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child:
                            _cookieJar.isEmpty
                                ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: Text(
                                      'No accomplishments yet. Complete tasks to fill your cookie jar!',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _cookieJar.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.cookie,
                                        color: Colors.brown,
                                      ),
                                      title: Text(_cookieJar[index].toString()),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
