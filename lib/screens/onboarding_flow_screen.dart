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

  // Step 1: Gender Selection
  String? _selectedGender;

  // Step 2: Profile Information
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _currentWeightController =
      TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();

  // Step 3: Activity Level
  final Map<String, double> _activityLevels = {
    'ไม่ออกกำลังกายเลย หรือน้อยมาก (Sedentary)': 1.2,
    'ออกกำลังกายเบา (Lightly Active)': 1.375,
    'ออกกำลังกายปานกลาง (Moderately Active)': 1.55,
    'ออกกำลังกายหนัก (Very Active)': 1.725,
    'ออกกำลังกายหนักมาก (Extremely Active/Super Active)': 1.9,
  };
  String? _selectedActivityLevel;

  // Step 4: Plan Selection
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

  // Navigation functions
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

  // Validation functions
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

    // ถ้าน้ำหนักเท่ากัน (รักษาน้ำหนัก) ไม่ต้องเลือก plan speed
    if (currentWeight == targetWeight) return true;

    // ถ้าต้องการเปลี่ยนน้ำหนัก ต้องเลือก plan speed
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
      // Get form data
      final age = int.parse(_ageController.text.trim());
      final height = double.parse(_heightController.text.trim());
      final currentWeight = double.parse(_currentWeightController.text.trim());
      final targetWeight = double.parse(_targetWeightController.text.trim());
      final activityFactor = _activityLevels[_selectedActivityLevel]!;

      // Calculate values
      final bmi = _calculateBMI(currentWeight, height);
      final bmr = _calculateBMR(currentWeight, height, age, _selectedGender!);
      final tdee = _calculateTDEE(bmr, activityFactor);

      // Plan calculations
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

      // Create or update user
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

      // นำทางไปยัง HomeScreen และลบหน้า Onboarding ออกจาก stack
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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ขั้นตอนที่ ${_currentPage + 1} จาก 5',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
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

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('ย้อนกลับ'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                backgroundColor: const Color(0xFF4CAF50),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                _currentPage == 4 ? 'เริ่มใช้งาน' : 'ถัดไป',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'ยินดีต้อนรับสู่แคลอรี่ ไดอารี่!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'กรุณาบอกเราเกี่ยวกับตัวคุณสักนิด',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          Image.asset('assets/app.png', height: 120),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGenderOption(
                'Female',
                'หญิง',
                'assets/app.png',
                Colors.pink,
              ),
              _buildGenderOption('Male', 'ชาย', 'assets/app.png', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
    String gender,
    String label,
    String assetPath,
    Color color,
  ) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        height: 170,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, height: 90),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
            'กรุณากรอกข้อมูลส่วนตัวของคุณ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'อายุ (ปี)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'ส่วนสูง (ซม.)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentWeightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'น้ำหนักปัจจุบัน (กก.)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _targetWeightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'น้ำหนักที่ต้องการ (กก.)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: Activity Level
  Widget _buildActivityLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'คุณออกกำลังกายบ่อยแค่ไหน?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children:
                  _activityLevels.keys.map((String key) {
                    return RadioListTile<String>(
                      title: Text(key, style: const TextStyle(fontSize: 14)),
                      value: key,
                      groupValue: _selectedActivityLevel,
                      onChanged:
                          (value) =>
                              setState(() => _selectedActivityLevel = value),
                      activeColor: const Color(0xFF4CAF50),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Page 4: Plan Selection
  Widget _buildPlanSelectionPage() {
    if (!_isStep2Valid()) {
      return const Center(
        child: Text('กรุณากรอกข้อมูลในขั้นตอนก่อนหน้าให้ครบถ้วน'),
      );
    }

    final currentWeight = double.parse(_currentWeightController.text.trim());
    final targetWeight = double.parse(_targetWeightController.text.trim());

    String planType = 'รักษาน้ำหนัก';
    if (targetWeight > currentWeight) {
      planType = 'เพิ่มน้ำหนัก';
    } else if (targetWeight < currentWeight) {
      planType = 'ลดน้ำหนัก';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'เป้าหมายของคุณ: $planType',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'น้ำหนักปัจจุบัน: ${currentWeight.toStringAsFixed(1)} กก.',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            'น้ำหนักที่ต้องการ: ${targetWeight.toStringAsFixed(1)} กก.',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          if (planType != 'รักษาน้ำหนัก') ...[
            const Text(
              'เลือกระดับความเร็วของแผน:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: Text(
                'แบบธรรมดา (${planType.replaceAll('น้ำหนัก', '')}สัปดาห์ละ 0.25 กก.)',
              ),
              value: 'Normal',
              groupValue: _selectedPlanSpeed,
              onChanged: (value) => setState(() => _selectedPlanSpeed = value),
              activeColor: const Color(0xFF4CAF50),
            ),
            RadioListTile<String>(
              title: Text(
                'แบบเร็ว (${planType.replaceAll('น้ำหนัก', '')}สัปดาห์ละ 0.5 กก.)',
              ),
              value: 'Fast',
              groupValue: _selectedPlanSpeed,
              onChanged: (value) => setState(() => _selectedPlanSpeed = value),
              activeColor: const Color(0xFF4CAF50),
            ),
            RadioListTile<String>(
              title: Text(
                'แบบเร็วมาก (${planType.replaceAll('น้ำหนัก', '')}สัปดาห์ละ 1 กก.)',
              ),
              value: 'Very Fast',
              groupValue: _selectedPlanSpeed,
              onChanged: (value) => setState(() => _selectedPlanSpeed = value),
              activeColor: const Color(0xFF4CAF50),
            ),
          ] else ...[
            const Text(
              'คุณเลือกแผนรักษาน้ำหนัก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'เราจะคำนวณแคลอรี่ที่เหมาะสมสำหรับการรักษาน้ำหนักให้คุณ',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  // Page 5: Summary Page - แสดงข้อมูลที่คำนวณเสร็จแล้ว
  Widget _buildSummaryPage() {
    if (!_isStep2Valid() || !_isStep3Valid()) {
      return const Center(child: Text('กรุณากรอกข้อมูลให้ครบถ้วน'));
    }

    // คำนวณข้อมูลทั้งหมด
    final age = int.parse(_ageController.text.trim());
    final height = double.parse(_heightController.text.trim());
    final currentWeight = double.parse(_currentWeightController.text.trim());
    final targetWeight = double.parse(_targetWeightController.text.trim());
    final activityFactor = _activityLevels[_selectedActivityLevel]!;

    final bmi = _calculateBMI(currentWeight, height);
    final bmr = _calculateBMR(currentWeight, height, age, _selectedGender!);
    final tdee = _calculateTDEE(bmr, activityFactor);

    // คำนวณแผน
    double weeklyTarget = 0.0;
    String planType = 'รักษาน้ำหนัก';

    if (targetWeight > currentWeight) {
      planType = 'เพิ่มน้ำหนัก';
    } else if (targetWeight < currentWeight) {
      planType = 'ลดน้ำหนัก';
    }

    if (targetWeight != currentWeight && _selectedPlanSpeed != null) {
      if (_selectedPlanSpeed == 'Normal') {
        weeklyTarget = 0.25;
      } else if (_selectedPlanSpeed == 'Fast') {
        weeklyTarget = 0.5;
      } else if (_selectedPlanSpeed == 'Very Fast') {
        weeklyTarget = 1.0;
      }
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'ตรวจสอบข้อมูลก่อนเริ่มใช้งาน',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // ข้อมูลพื้นฐาน
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

          // ข้อมูลการคำนวณ
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

          // ข้อมูลแผน
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

          const SizedBox(height: 30),

          // คำแนะนำ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'คำแนะนำ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (planType == 'ลดน้ำหนัก')
                  const Text(
                    '• ดื่มน้ำเปล่าให้เพียงพอ อย่างน้อย 8 แก้วต่อวัน\n'
                    '• เลือกรับประทานอาหารที่มีโปรตีนสูง\n'
                    '• หลีกเลี่ยงอาหารที่มีน้ำตาลและไขมันสูง\n'
                    '• ออกกำลังกายสม่ำเสมอ',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  )
                else if (planType == 'เพิ่มน้ำหนัก')
                  const Text(
                    '• รับประทานอาหารที่มีคุณค่าทางโภชนาการสูง\n'
                    '• เพิ่มโปรตีนและคาร์โบไฮเดรตที่ดี\n'
                    '• ออกกำลังกายแบบ Weight Training\n'
                    '• รับประทานอาหารบ่อยๆ แต่ในปริมาณที่เหมาะสม',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  )
                else
                  const Text(
                    '• รักษาสมดุลของการรับประทานอาหาร\n'
                    '• ออกกำลังกายสม่ำเสมอ\n'
                    '• ดื่มน้ำเปล่าให้เพียงพอ\n'
                    '• ตรวจสอบน้ำหนักเป็นประจำ',
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
              ],
            ),
          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
