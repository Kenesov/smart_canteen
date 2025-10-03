import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
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
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMealLogs();
  }

  Future<void> _loadMealLogs() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getMealsByDate(date: _selectedDate);

    if (!mounted) return;

    result.when(
      success: (logs) {
        setState(() {
          _allMealLogs = logs;
          _isLoading = false;
        });
        Logger.success('Loaded ${logs.length} meal logs');
      },
      failure: (error) {
        setState(() {
          _allMealLogs = [];
          _isLoading = false;
        });
        Logger.error('Failed to load meals: ${error.message}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  List<MealLog> _filterMealsByType(String mealType) {
    return _allMealLogs.where((log) => log.mealType == mealType).toList();
  }

  /// Kun tanlash dialog
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      // locale ni olib tashladik - default locale ishlatadi
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMealLogs();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Bugun';
    } else if (selectedDay == today.subtract(const Duration(days: 1))) {
      return 'Kecha';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ovqat Ro\'yxati - ${_formatDate(_selectedDate)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Kun tanlash',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Logger.info('Refreshing meal logs');
              _loadMealLogs();
            },
            tooltip: 'Yangilash',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Nonushta'),
            Tab(text: 'Tushlik'),
            Tab(text: 'Kechki ovqat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Yuklanmoqda...'),
          ],
        ),
      )
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
              Icons.no_meals_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Hech kim ovqat olmagan',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(_selectedDate),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMealLogs,
      color: AppConstants.primaryColor,
      child: Column(
        children: [
          // Summary header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppConstants.primaryColor.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jami: ${meals.length} ta student',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.secondaryColor,
                  ),
                ),
                Text(
                  AppConstants.mealTypeDisplayNames[mealType] ?? mealType,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: meals.length,
              physics: const BouncingScrollPhysics(),
              // Cache optimization
              cacheExtent: 100,
              itemBuilder: (context, index) {
                return MealLogItem(log: meals[index], showTime: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}