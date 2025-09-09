import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_mate/models/user_model.dart';
import 'package:health_mate/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:health_mate/widgets/bottom_bar.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  static const Color _backgroundColor = Color(0xFF1A1A1A);
  static const Color _primaryColor = Color(0xFFB4FF39);
  static const Color _fieldColor = Color(0xFF2A2A2A);
  static const Color _textColor = Colors.white;
  static final Color _hintColor = Colors.grey[400]!;

  // Gender Selection
  String? _selectedGender;

  // Profile Information
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _currentWeightController =
      TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();

  // Activity Level
  final Map<String, double> _activityLevels = {
    'ไม่ออกกำลังกายเลย หรือน้อยมาก (Sedentary)': 1.2,
    'ออกกำลังกายเบา (Lightly Active)': 1.375,
    'ออกกำลังกายปานกลาง (Moderately Active)': 1.55,
    'ออกกำลังกายหนัก (Very Active)': 1.725,
    'ออกกำลังกายหนักมาก (Extremely Active/Super Active)': 1.9,
  };
  String? _selectedActivityLevel;

  // Plan Selection
  String? _selectedPlanSpeed;

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isStep1Valid() => _selectedGender != null;

  bool _isStep2Valid() {
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final currentWeight = double.tryParse(_currentWeightController.text.trim());
    final targetWeight = double.tryParse(_targetWeightController.text.trim());

    return age != null &&
        height != null &&
        currentWeight != null &&
        targetWeight != null &&
        age > 0 &&
        height > 0 &&
        currentWeight > 0 &&
        targetWeight > 0;
  }

  bool _isStep3Valid() => _selectedActivityLevel != null;

  bool _isStep4Valid() {
    final currentWeight =
        double.tryParse(_currentWeightController.text.trim()) ?? 0;
    final targetWeight =
        double.tryParse(_targetWeightController.text.trim()) ?? 0;
    if (currentWeight == targetWeight) return true;
    return _selectedPlanSpeed != null;
  }

  double _calculateBMI(double weight, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  double _calculateBMR(double weight, double heightCm, int age, String gender) {
    if (gender == 'Male') {
      return (10 * weight) + (6.25 * heightCm) - (5 * age) + 5;
    } else if (gender == 'Female') {
      return (10 * weight) + (6.25 * heightCm) - (5 * age) - 161;
    }
    return 0.0;
  }

  double _calculateTDEE(double bmr, double activityFactor) {
    return bmr * activityFactor;
  }

  double _calculateDailyCalorieTarget(
    double tdee,
    double currentWeight,
    double targetWeight,
    double weeklyTarget,
  ) {
    final calorieAdjustmentPerDay = (weeklyTarget * 7700) / 7;

    if (targetWeight > currentWeight) {
      return tdee + calorieAdjustmentPerDay;
    } else if (targetWeight < currentWeight) {
      return tdee - calorieAdjustmentPerDay;
    } else {
      return tdee;
    }
  }

  int _calculatePlanDurationDays(
    double currentWeight,
    double targetWeight,
    double weeklyTarget,
  ) {
    final weightDiff = (targetWeight - currentWeight).abs();
    if (weeklyTarget <= 0) return 0;
    final weeks = weightDiff / weeklyTarget;
    return (weeks * 7).ceil();
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'น้ำหนักน้อย';
    if (bmi < 25.0) return 'น้ำหนักปกติ';
    if (bmi < 30.0) return 'น้ำหนักเกิน';
    return 'อ้วน';
  }

  Future<void> _saveAllDataAndComplete() async {
    if (!_isStep1Valid() ||
        !_isStep2Valid() ||
        !_isStep3Valid() ||
        !_isStep4Valid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ผู้ใช้ไม่ได้เข้าสู่ระบบ')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final age = int.parse(_ageController.text.trim());
      final height = double.parse(_heightController.text.trim());
      final currentWeight = double.parse(_currentWeightController.text.trim());
      final targetWeight = double.parse(_targetWeightController.text.trim());
      final activityFactor = _activityLevels[_selectedActivityLevel]!;
      final bmi = _calculateBMI(currentWeight, height);
      final bmr = _calculateBMR(currentWeight, height, age, _selectedGender!);
      final tdee = _calculateTDEE(bmr, activityFactor);

      double weeklyTarget = 0.0;
      String planType = 'Maintain';

      if (targetWeight != currentWeight) {
        if (_selectedPlanSpeed == 'Normal') {
          weeklyTarget = 0.25;
        } else if (_selectedPlanSpeed == 'Fast') {
          weeklyTarget = 0.5;
        } else if (_selectedPlanSpeed == 'Very Fast') {
          weeklyTarget = 1.0;
        }
        planType = targetWeight > currentWeight ? 'Gain' : 'Lose';
      }

      final dailyCalorieTarget = _calculateDailyCalorieTarget(
        tdee,
        currentWeight,
        targetWeight,
        weeklyTarget,
      );
      final planDurationDays = _calculatePlanDurationDays(
        currentWeight,
        targetWeight,
        weeklyTarget,
      );

      final firestoreService = FirestoreService();
      final existingUser = await firestoreService.getUser(user.uid);

      final userData = UserModel(
        uid: user.uid,
        name: existingUser?.name ?? '',
        email: user.email ?? '',
        weight: currentWeight,
        targetWeight: targetWeight,
        height: height,
        age: age,
        gender: _selectedGender!,
        bmi: bmi,
        bmr: bmr,
        activityFactor: activityFactor,
        plan: planType,
        planWeeklyTarget: weeklyTarget,
        planStartDate: Timestamp.now(),
        planDurationDays: planDurationDays,
        planEndDate:
            planDurationDays > 0
                ? Timestamp.fromDate(
                  DateTime.now().add(Duration(days: planDurationDays)),
                )
                : null,
        dailyCalorieTarget: dailyCalorieTarget,
        lastQuestResetTimestamp: existingUser?.lastQuestResetTimestamp,
      );

      if (existingUser != null) {
        await firestoreService.updateUser(user.uid, userData.toFirestore());
      } else {
        await firestoreService.createUser(user.uid, userData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomBar()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                          decoration: BoxDecoration(
                            color:
                                index <= _currentPage
                                    ? _primaryColor
                                    : _fieldColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ขั้นตอนที่ ${_currentPage + 1} จาก 5',
                    style: TextStyle(fontSize: 14, color: _hintColor),
                  ),
                ],
              ),
            ),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildGenderSelectionPage(),
                  _buildProfileInputPage(),
                  _buildActivityLevelPage(),
                  _buildPlanSelectionPage(),
                  _buildSummaryPage(),
                ],
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'ย้อนกลับ',
                            style: const TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: _primaryColor,
                              ),
                            )
                            : SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_currentPage == 4) {
                                    _saveAllDataAndComplete();
                                  } else {
                                    bool canProceed = false;
                                    switch (_currentPage) {
                                      case 0:
                                        canProceed = _isStep1Valid();
                                        break;
                                      case 1:
                                        canProceed = _isStep2Valid();
                                        break;
                                      case 2:
                                        canProceed = _isStep3Valid();
                                        break;
                                      case 3:
                                        canProceed = _isStep4Valid();
                                        break;
                                    }

                                    if (canProceed) {
                                      _nextPage();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'กรุณากรอกข้อมูลให้ครบถ้วน',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                ),
                                child: Text(
                                  _currentPage == 4 ? 'เริ่มใช้งาน' : 'ถัดไป',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 1: Gender Selection
  Widget _buildGenderSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'ยินดีต้อนรับ!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาบอกเราเกี่ยวกับตัวคุณสักนิด',
            style: TextStyle(fontSize: 16, color: _hintColor),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderOption('Female', 'หญิง', Icons.female),
              _buildGenderOption('Male', 'ชาย', Icons.male),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String gender, String label, IconData icon) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        width: 140,
        height: 160,
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _fieldColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: isSelected ? Colors.black : _textColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isSelected ? Colors.black : _textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Input Fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: _textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _hintColor),
          prefixIcon: Icon(icon, color: _primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  // Page 2: Profile Input
  Widget _buildProfileInputPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ข้อมูลส่วนตัวของคุณ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildTextField(
            controller: _ageController,
            hintText: 'อายุ (ปี)',
            icon: Icons.cake_outlined,
          ),
          _buildTextField(
            controller: _heightController,
            hintText: 'ส่วนสูง (ซม.)',
            icon: Icons.height_outlined,
          ),
          _buildTextField(
            controller: _currentWeightController,
            hintText: 'น้ำหนักปัจจุบัน (กก.)',
            icon: Icons.monitor_weight_outlined,
          ),
          _buildTextField(
            controller: _targetWeightController,
            hintText: 'น้ำหนักที่ต้องการ (กก.)',
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    );
  }

  // Helper for Selection Options (replaces RadioListTile)
  Widget _buildSelectionOption({
    required String title,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _fieldColor,
          borderRadius: BorderRadius.circular(12),
          border:
              isSelected
                  ? Border.all(color: _primaryColor, width: 2)
                  : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? _primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: _textColor, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Page 3: Activity Level
  Widget _buildActivityLevelPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'คุณออกกำลังกายบ่อยแค่ไหน?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ..._activityLevels.keys.map((String key) {
            return _buildSelectionOption(
              title: key,
              value: key,
              groupValue: _selectedActivityLevel,
              onChanged:
                  (value) => setState(() => _selectedActivityLevel = value),
            );
          }),
        ],
      ),
    );
  }

  // Page 4: Plan Selection
  Widget _buildPlanSelectionPage() {
    if (!_isStep2Valid()) {
      return Center(
        child: Text(
          'กรุณากรอกข้อมูลในขั้นตอนก่อนหน้า',
          style: TextStyle(color: _hintColor),
        ),
      );
    }

    final currentWeight = double.parse(_currentWeightController.text.trim());
    final targetWeight = double.parse(_targetWeightController.text.trim());

    String planType = 'รักษาน้ำหนัก';
    if (targetWeight > currentWeight)
      planType = 'เพิ่มน้ำหนัก';
    else if (targetWeight < currentWeight)
      planType = 'ลดน้ำหนัก';

    final planSpeeds = {
      'Normal': 'ธรรมดา (0.25 กก./สัปดาห์)',
      'Fast': 'เร็ว (0.5 กก./สัปดาห์)',
      'Very Fast': 'เร็วมาก (1 กก./สัปดาห์)',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'เป้าหมายของคุณ: $planType',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          if (planType != 'รักษาน้ำหนัก') ...[
            const Text(
              'เลือกระดับความเร็วของแผน:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),
            ...planSpeeds.entries.map((entry) {
              return _buildSelectionOption(
                title: 'แบบ${entry.value}',
                value: entry.key,
                groupValue: _selectedPlanSpeed,
                onChanged: (val) => setState(() => _selectedPlanSpeed = val),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _fieldColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'คุณเลือกแผนรักษาน้ำหนัก เราจะคำนวณแคลอรี่ที่เหมาะสมให้คุณโดยอัตโนมัติ',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _hintColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Page 5: Summary Page
  Widget _buildSummaryPage() {
    if (!_isStep2Valid() || !_isStep3Valid()) {
      return Center(
        child: Text(
          'กรุณากรอกข้อมูลให้ครบถ้วน',
          style: TextStyle(color: _hintColor),
        ),
      );
    }

    final age = int.parse(_ageController.text.trim());
    final height = double.parse(_heightController.text.trim());
    final currentWeight = double.parse(_currentWeightController.text.trim());
    final targetWeight = double.parse(_targetWeightController.text.trim());
    final activityFactor = _activityLevels[_selectedActivityLevel]!;
    final bmi = _calculateBMI(currentWeight, height);
    final bmr = _calculateBMR(currentWeight, height, age, _selectedGender!);
    final tdee = _calculateTDEE(bmr, activityFactor);

    double weeklyTarget = 0.0;
    String planType = 'รักษาน้ำหนัก';
    if (targetWeight > currentWeight)
      planType = 'เพิ่มน้ำหนัก';
    else if (targetWeight < currentWeight)
      planType = 'ลดน้ำหนัก';

    if (targetWeight != currentWeight && _selectedPlanSpeed != null) {
      if (_selectedPlanSpeed == 'Normal')
        weeklyTarget = 0.25;
      else if (_selectedPlanSpeed == 'Fast')
        weeklyTarget = 0.5;
      else if (_selectedPlanSpeed == 'Very Fast')
        weeklyTarget = 1.0;
    }

    final dailyCalorieTarget = _calculateDailyCalorieTarget(
      tdee,
      currentWeight,
      targetWeight,
      weeklyTarget,
    );
    final planDurationDays = _calculatePlanDurationDays(
      currentWeight,
      targetWeight,
      weeklyTarget,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'สรุปข้อมูลของคุณ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ตรวจสอบข้อมูลก่อนเริ่มใช้งาน',
            style: TextStyle(fontSize: 16, color: _hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildSummaryCard('ข้อมูลส่วนตัว', [
            _buildSummaryRow('เพศ', _selectedGender == 'Male' ? 'ชาย' : 'หญิง'),
            _buildSummaryRow('อายุ', '$age ปี'),
            _buildSummaryRow('ส่วนสูง', '${height.toStringAsFixed(0)} ซม.'),
            _buildSummaryRow(
              'น้ำหนักปัจจุบัน',
              '${currentWeight.toStringAsFixed(1)} กก.',
            ),
            _buildSummaryRow(
              'น้ำหนักเป้าหมาย',
              '${targetWeight.toStringAsFixed(1)} กก.',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSummaryCard('ค่าทางโภชนาการ', [
            _buildSummaryRow(
              'BMI',
              '${bmi.toStringAsFixed(1)} (${_getBMICategory(bmi)})',
            ),
            _buildSummaryRow('BMR', '${bmr.toStringAsFixed(0)} แคลอรี่/วัน'),
            _buildSummaryRow('TDEE', '${tdee.toStringAsFixed(0)} แคลอรี่/วัน'),
            _buildSummaryRow(
              'แคลอรี่เป้าหมาย',
              '${dailyCalorieTarget.toStringAsFixed(0)} แคลอรี่/วัน',
            ),
          ]),
          const SizedBox(height: 16),
          _buildSummaryCard('แผนของคุณ', [
            _buildSummaryRow('ประเภทแผน', planType),
            if (weeklyTarget > 0)
              _buildSummaryRow(
                'เป้าหมายต่อสัปดาห์',
                '${weeklyTarget.toStringAsFixed(2)} กก.',
              ),
            if (planDurationDays > 0) ...[
              _buildSummaryRow(
                'ระยะเวลาแผน',
                '${(planDurationDays / 7).toStringAsFixed(0)} สัปดาห์',
              ),
              _buildSummaryRow(
                'วันที่สิ้นสุดแผน',
                DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.now().add(Duration(days: planDurationDays))),
              ),
            ],
            _buildSummaryRow('ระดับกิจกรรม', _getActivityLevelDisplay()),
          ]),
        ],
      ),
    );
  }

  String _getActivityLevelDisplay() {
    if (_selectedActivityLevel == null) return '';
    final activityMap = {
      'ไม่ออกกำลังกายเลย หรือน้อยมาก (Sedentary)': 'ไม่ออกกำลังกาย',
      'ออกกำลังกายเบา (Lightly Active)': 'ออกกำลังกายเบา',
      'ออกกำลังกายปานกลาง (Moderately Active)': 'ออกกำลังกายปานกลาง',
      'ออกกำลังกายหนัก (Very Active)': 'ออกกำลังกายหนัก',
      'ออกกำลังกายหนักมาก (Extremely Active/Super Active)':
          'ออกกำลังกายหนักมาก',
    };
    return activityMap[_selectedActivityLevel] ?? _selectedActivityLevel!;
  }

  Widget _buildSummaryCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const Divider(color: Colors.grey, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: _hintColor)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
