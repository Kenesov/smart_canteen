import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/services/api_service.dart';
import '../../data/models/meal_log.dart';
import '../widgets/meal_log_item.dart';

class HistoryScreen extends StatefulWidget {
  final CameraDescription camera;
  const HistoryScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  List<MealLog> _allMealLogs = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTodayMealLogs();
  }

  Future<void> _loadTodayMealLogs() async {
    setState(() => _isLoading = true);

    final logs = await _apiService.getTodayMealLogs();

    if (mounted) {
      setState(() {
        _allMealLogs = logs;
        _isLoading = false;
      });
      Logger.success('Loaded ${logs.length} meal logs');
    }
  }

  List<MealLog> _filterMealsByType(String mealType) {
    return _allMealLogs.where((log) => log.mealType == mealType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bugungi Ro\'yxat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Logger.info('Refreshing meal logs');
              _loadTodayMealLogs();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Nonushta'),
            Tab(text: 'Tushlik'),
            Tab(text: 'Kechki ovqat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildMealList('BREAKFAST'),
          _buildMealList('LUNCH'),
          _buildMealList('DINNER'),
        ],
      ),
    );
  }

  Widget _buildMealList(String mealType) {
    final meals = _filterMealsByType(mealType);

    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_meals,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Hech kim ovqat olmagan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTodayMealLogs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: meals.length,
        itemBuilder: (context, index) {
          return MealLogItem(log: meals[index]);
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}