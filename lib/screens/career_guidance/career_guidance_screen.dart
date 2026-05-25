import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../widgets/app_illustrations.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/common_widgets.dart';
import '../../providers/career_guidance_provider.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../models/guidance_recommend_input.dart';
import '../../models/login_route_args.dart';
import '../../utils/exam_block_utils.dart';
import '../../utils/region_label_utils.dart';
import '../../utils/theme_colors.dart';
import '../../services/guidance_service.dart';
import '../../services/special_career_service.dart';
import '../../models/special_career_eligibility.dart';
import 'recommend_results.dart';

class CareerGuidanceScreen extends StatefulWidget {
  const CareerGuidanceScreen({Key? key}) : super(key: key);

  @override
  State<CareerGuidanceScreen> createState() => _CareerGuidanceScreenState();
}

class _CareerGuidanceScreenState extends State<CareerGuidanceScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Map<String, TextEditingController> _controllers = {
    's1': TextEditingController(),
    's2': TextEditingController(),
    's3': TextEditingController(),
  };

  String _selectedBlock = 'D01';
  List<String> _currentSubjectLabels = ExamBlockScores.blockToSubjects['D01']!;

  List<String> _selectedInterests = [];
  List<String> _selectedStrengths = [];
  String _selectedRegion = RegionLabelUtils.mienBac;

  final List<String> _strengths = [
    'Tư duy logic',
    'Sáng tạo',
    'Giao tiếp',
    'Lãnh đạo',
    'Phân tích',
    'Giải quyết vấn đề',
  ];

  final List<String> _regions = RegionLabelUtils.options;

  bool _interestedInSpecialCareer = false;
  String _selectedSpecialTrackId = 'cong_an';
  String _specialGender = 'Nam';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  List<SpecialCareerTrack> _specialTracks = [];

  int get _resultPageIndex => _interestedInSpecialCareer ? 6 : 5;

  List<String> get _stepLabels {
    if (_interestedInSpecialCareer) {
      return const [
        'Khối thi',
        'Điểm số',
        'Sở thích',
        'Ưu điểm',
        'Thể chất',
        'Khu vực',
        'Kết quả',
      ];
    }
    return const [
      'Khối thi',
      'Điểm số',
      'Sở thích',
      'Ưu điểm',
      'Khu vực',
      'Kết quả',
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadSpecialTracks();
  }

  Future<void> _loadSpecialTracks() async {
    await SpecialCareerService.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _specialTracks = SpecialCareerService.tracks;
      if (_specialTracks.isNotEmpty) {
        _selectedSpecialTrackId = _specialTracks.first.id;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  GuidanceRecommendInput? _buildRecommendInput() {
    final s1 = double.tryParse(_controllers['s1']!.text.trim());
    final s2 = double.tryParse(_controllers['s2']!.text.trim());
    final s3 = double.tryParse(_controllers['s3']!.text.trim());
    if (s1 == null || s2 == null || s3 == null) return null;

    double? heightCm;
    double? weightKg;
    String? trackId;
    String? gender;
    if (_interestedInSpecialCareer) {
      heightCm = double.tryParse(_heightController.text.trim());
      weightKg = double.tryParse(_weightController.text.trim());
      if (heightCm == null || weightKg == null) return null;
      trackId = _selectedSpecialTrackId;
      gender = _specialGender;
    }

    return GuidanceRecommendInput(
      examBlock: _selectedBlock,
      subject1: s1,
      subject2: s2,
      subject3: s3,
      subjectLabels: List<String>.from(_currentSubjectLabels),
      interests: _selectedInterests.map((e) => e.toLowerCase()).toList(),
      strengths: _selectedStrengths.map((e) => e.toLowerCase()).toList(),
      region: _selectedRegion,
      specialTrackId: trackId,
      specialGender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
    );
  }

  bool _validateSpecialPage() {
    if (!_interestedInSpecialCareer) return true;
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_weightController.text.trim());
    if (h == null || w == null || h < 100 || h > 220 || w < 30 || w > 150) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập chiều cao (cm) và cân nặng (kg) hợp lệ.'),
          backgroundColor: AppColors.error,
        ),
      );
      return false;
    }
    return true;
  }

  void _onContinue() {
    if (_interestedInSpecialCareer && _currentPage == 4) {
      if (!_validateSpecialPage()) return;
    }
    _goToNextPage();
  }

  void _onFinish() {
    final currentUser = context.read<auth.AuthProvider>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kết quả đã hiển thị phía trên. Đăng nhập nếu bạn muốn lưu vào hồ sơ.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }
    _submitGuidance();
  }

  void _submitGuidance() {
    final input = _buildRecommendInput();
    if (input == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập điểm hợp lệ (số).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final slots = input.guidanceSlots;
    final currentUser = context.read<auth.AuthProvider>().currentUser;
    if (currentUser == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Yêu cầu đăng nhập'),
          content: const Text('Bạn cần đăng nhập để lưu kết quả định hướng. Bạn muốn đăng nhập bây giờ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final result = await Navigator.of(context).pushNamed(
                  '/login',
                  arguments: const LoginRouteArgs(returnOnSuccess: true),
                );
                // If login returned true, automatically continue submission
                if (result == true) {
                  final newUser = context.read<auth.AuthProvider>().currentUser;
                  if (newUser != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đăng nhập — đang phân tích dữ liệu...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    // perform compute + save using same inputs
                    context.read<CareerGuidanceProvider>().computeGuidance(
                      userId: newUser.id,
                      mathScore: slots.math,
                      literatureScore: slots.literature,
                      englishScore: slots.english,
                      interests: input.interests,
                      strengths: input.strengths,
                      region: input.region,
                      examBlock: input.examBlock,
                    ).then((guidance) {
                      if (guidance != null) {
                        _pageController.jumpToPage(_resultPageIndex);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phân tích hoàn tất.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        final error = context.read<CareerGuidanceProvider>().error ?? 'Phân tích thất bại. Thử lại.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    });
                  }
                }
              },
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      );
      return;
    }

    final userId = currentUser.id;

    // Run compute and save
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang phân tích dữ liệu của bạn...'),
        backgroundColor: AppColors.primary,
      ),
    );

    context.read<CareerGuidanceProvider>().computeGuidance(
      userId: userId,
      mathScore: slots.math,
      literatureScore: slots.literature,
      englishScore: slots.english,
      interests: input.interests,
      strengths: input.strengths,
      region: input.region,
      examBlock: input.examBlock,
    ).then((guidance) {
      if (guidance != null) {
        // Jump to result page
        _pageController.jumpToPage(_resultPageIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phân tích hoàn tất.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final error = context.read<CareerGuidanceProvider>().error ?? 'Phân tích thất bại. Thử lại.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  int get _wizardTotal => _stepLabels.length;

  @override
  Widget build(BuildContext context) {
    final stepLabels = _stepLabels;
    final pages = <Widget>[
      _buildBlockPage(),
      _buildScoresPage(),
      _buildInterestsPage(),
      _buildStrengthsPage(),
      if (_interestedInSpecialCareer) _buildSpecialCareerPage(),
      _buildRegionPage(),
      _buildResultPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Định hướng ngành học'),
      ),
      body: Column(
        children: [
          AppWizardProgress(
            currentStep: _currentPage,
            totalSteps: stepLabels.length,
            labels: stepLabels,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                if (index == _resultPageIndex) {
                  _ensureComputed();
                }
              },
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final tc = context.tc;
          return Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: tc.navBar,
          border: Border(top: BorderSide(color: tc.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: CustomButton(
                    label: 'Quay lại',
                    backgroundColor: tc.buttonSecondaryBg,
                    foregroundColor: tc.buttonSecondaryFg,
                    onPressed: _goToPreviousPage,
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: _currentPage == _resultPageIndex
                      ? 'Lưu kết quả'
                      : 'Tiếp tục',
                  onPressed: _currentPage == _resultPageIndex
                      ? _onFinish
                      : _onContinue,
                ),
              ),
            ],
          ),
        ),
      );
        },
      ),
    );
  }

  Future<void> _ensureComputed() async {
    final provider = context.read<CareerGuidanceProvider>();
    if (provider.currentGuidance != null) return;

    final input = _buildRecommendInput();
    if (input == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành biểu mẫu (nhập điểm hợp lệ).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentUser = context.read<auth.AuthProvider>().currentUser;
    final userId = currentUser?.id ?? 'anonymous';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang phân tích dữ liệu...'),
        backgroundColor: AppColors.primary,
      ),
    );

    final slots = input.guidanceSlots;
    final guidance = await provider.computeGuidance(
      userId: userId,
      mathScore: slots.math,
      literatureScore: slots.literature,
      englishScore: slots.english,
      interests: input.interests,
      strengths: input.strengths,
      region: input.region,
      examBlock: input.examBlock,
    );

    if (guidance == null) {
      final error = provider.error ?? 'Phân tích thất bại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildScoresPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWizardStepHeader(
            step: 2,
            total: _wizardTotal,
            title: 'Nhập điểm số',
            subtitle: 'Điểm trung bình 0–10 theo 3 môn của khối đã chọn.',
            illustration: AppIllustrationKind.wizardScores,
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          CustomTextField(
            label: _currentSubjectLabels[0],
            hint: 'Ví dụ: 8.5',
            controller: _controllers['s1']!,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          CustomTextField(
            label: _currentSubjectLabels[1],
            hint: 'Ví dụ: 7.5',
            controller: _controllers['s2']!,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          CustomTextField(
            label: _currentSubjectLabels[2],
            hint: 'Ví dụ: 8.0',
            controller: _controllers['s3']!,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockPage() {
    final tc = context.tc;
    final blocks = ExamBlockScores.blockOrder;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWizardStepHeader(
            step: 1,
            total: _wizardTotal,
            title: 'Chọn tổ hợp xét tuyển',
            subtitle: 'Hệ thống hiển thị đúng 3 môn và lọc ngành theo khối.',
            illustration: AppIllustrationKind.wizardBlock,
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Wrap(
            spacing: AppDimensions.paddingMd,
            runSpacing: AppDimensions.paddingMd,
            children: blocks
                .map((b) => ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _selectedBlock == b
                                  ? Colors.white
                                  : tc.textPrimary,
                            ),
                          ),
                          Text(
                            ExamBlockScores.blockSubjectsShort(b),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _selectedBlock == b
                                  ? Colors.white.withValues(alpha: 0.92)
                                  : tc.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      selected: _selectedBlock == b,
                      onSelected: (sel) {
                        if (!sel) return;
                        setState(() {
                          _selectedBlock = b;
                          _currentSubjectLabels = List<String>.from(
                            ExamBlockScores.blockToSubjects[b] ??
                                ExamBlockScores.blockToSubjects['D01']!,
                          );
                          _selectedInterests = GuidanceService.pruneInterestsForBlock(
                            _selectedInterests,
                            b,
                          );
                          _controllers['s1']!.text = '';
                          _controllers['s2']!.text = '';
                          _controllers['s3']!.text = '';
                        });
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    final visibleInterests =
        GuidanceService.interestsForExamBlock(_selectedBlock);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWizardStepHeader(
            step: 3,
            total: _wizardTotal,
            title: 'Chọn sở thích',
            subtitle: 'Chọn 1–3 mục phù hợp khối $_selectedBlock.',
            illustration: AppIllustrationKind.wizardInterests,
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          Text(
            'Đã chọn ${_selectedInterests.length}/3',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _selectedInterests.length >= 3
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleInterests
                .map(
                  (interest) => FilterChip(
                    label: Text(
                      interest,
                      style: const TextStyle(fontSize: 13),
                    ),
                    visualDensity: VisualDensity.compact,
                    selected: _selectedInterests.contains(interest),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedInterests.length >= 3 &&
                              !_selectedInterests.contains(interest)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chọn tối đa 3 sở thích.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          AppSurfaceCard(
            child: CheckboxListTile(
              value: _interestedInSpecialCareer,
              onChanged: (v) {
                setState(() {
                  _interestedInSpecialCareer = v ?? false;
                  if (_interestedInSpecialCareer &&
                      _specialTracks.isNotEmpty) {
                    _selectedSpecialTrackId = _specialTracks.first.id;
                  }
                });
              },
              title: const Text(
                'Quan tâm Công an / Quân đội / An ninh / Hàng không',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Thêm bước đánh giá sơ bộ chiều cao, cân nặng (tham khảo, không thay quy chế tuyển sinh).',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWizardStepHeader(
            step: 4,
            total: _wizardTotal,
            title: 'Chọn ưu điểm',
            subtitle: 'Chọn 2–3 kỹ năng nổi bật của bạn.',
            illustration: AppIllustrationKind.wizardStrengths,
          ),
          const SizedBox(height: AppDimensions.paddingSm),
          Text(
            'Đã chọn ${_selectedStrengths.length}/3',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _selectedStrengths.length >= 3
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _strengths
                .map(
                  (strength) => FilterChip(
                    label: Text(strength, style: const TextStyle(fontSize: 13)),
                    visualDensity: VisualDensity.compact,
                    selected: _selectedStrengths.contains(strength),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedStrengths.length >= 3 &&
                              !_selectedStrengths.contains(strength)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chọn tối đa 3 ưu điểm.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          _selectedStrengths.add(strength);
                        } else {
                          _selectedStrengths.remove(strength);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialCareerPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWizardStepHeader(
            step: 5,
            total: _wizardTotal,
            title: 'Thể chất (tham khảo)',
            subtitle:
                'Nhập số đo thực tế để app gợi ý sơ bộ trước khi xem ngành đại học.',
            illustration: AppIllustrationKind.wizardStrengths,
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          if (_specialTracks.isEmpty)
            Text(
              'Đang tải danh sách ngành đặc thù…',
              style: TextStyle(color: context.tc.textSecondary),
            )
          else
            DropdownButtonFormField<String>(
              value: _selectedSpecialTrackId,
              decoration: const InputDecoration(
                labelText: 'Nhóm ngành',
                border: OutlineInputBorder(),
              ),
              items: _specialTracks
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedSpecialTrackId = v);
              },
            ),
          const SizedBox(height: AppDimensions.paddingMd),
          const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Nam'),
                  value: 'Nam',
                  groupValue: _specialGender,
                  onChanged: (v) => setState(() => _specialGender = v!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Nữ'),
                  value: 'Nữ',
                  groupValue: _specialGender,
                  onChanged: (v) => setState(() => _specialGender = v!),
                ),
              ),
            ],
          ),
          CustomTextField(
            label: 'Chiều cao (cm)',
            hint: 'Ví dụ: 170',
            controller: _heightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          CustomTextField(
            label: 'Cân nặng (kg)',
            hint: 'Ví dụ: 62',
            controller: _weightController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppDimensions.paddingMd),
          Text(
            SpecialCareerService.disclaimer.isNotEmpty
                ? SpecialCareerService.disclaimer
                : 'Kết quả chỉ mang tính tham khảo; xem thông báo tuyển sinh chính thức.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.tc.textSecondary,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppWizardStepHeader(
            step: _interestedInSpecialCareer ? 6 : 5,
            total: _wizardTotal,
            title: 'Chọn khu vực',
            subtitle: 'Ưu tiên gợi ý trường theo miền bạn muốn học.',
            illustration: AppIllustrationKind.wizardRegion,
          ),
          const SizedBox(height: AppDimensions.paddingLg),
          Column(
            children: _regions
                .map(
                  (region) => RadioListTile(
                    title: Text(region),
                    value: region,
                    groupValue: _selectedRegion,
                    onChanged: (value) {
                      setState(() {
                        _selectedRegion = value!;
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPage() {
    final input = _buildRecommendInput();
    if (input == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Vui lòng nhập đủ điểm các môn trước khi xem kết quả.'),
        ),
      );
    }
    return RecommendResultsScreen(
      input: input,
      localGuidance: context.watch<CareerGuidanceProvider>().currentGuidance,
      embedded: true,
    );
  }
}
