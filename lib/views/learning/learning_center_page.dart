import 'package:flutter/material.dart';

import '../../widgets/ads/inline_banner_ad.dart';
import '../../widgets/common/section_card.dart';

class LearningCenterPage extends StatefulWidget {
  const LearningCenterPage({super.key});

  @override
  State<LearningCenterPage> createState() => _LearningCenterPageState();
}

class _LearningCenterPageState extends State<LearningCenterPage> {
  final List<_CourseItem> _courses = const [
    _CourseItem(
      title: 'أساسيات الاستثمار',
      subtitle: 'مفاهيم السوق، أنواع الأوامر، وكيف تبدأ بشكل آمن.',
      hours: 4,
      lessons: 12,
      progress: 0.72,
    ),
    _CourseItem(
      title: 'التحليل الفني',
      subtitle: 'الدعوم والمقاومات، الاتجاه، والزخم، وإشارات الدخول.',
      hours: 6,
      lessons: 18,
      progress: 0.44,
    ),
    _CourseItem(
      title: 'إدارة المخاطر',
      subtitle: 'حجم الصفقة، وقف الخسارة، والتعامل مع التذبذب.',
      hours: 3,
      lessons: 9,
      progress: 0.18,
    ),
  ];

  final List<_PatternItem> _patterns = const [
    _PatternItem(
      title: 'المطرقة',
      direction: 'انعكاس صاعد',
      description: 'تظهر بعد هبوط وقد تشير إلى بداية ارتداد شرائي.',
    ),
    _PatternItem(
      title: 'الرجل المشنوق',
      direction: 'انعكاس هابط',
      description: 'قد يظهر بعد صعود ويعطي إشارة حذر قبل التصحيح.',
    ),
    _PatternItem(
      title: 'ابتلاع شرائي',
      direction: 'تأكيد صاعد',
      description: 'شمعة صاعدة قوية تبتلع الجسم السابق وتدعم تغير الاتجاه.',
    ),
    _PatternItem(
      title: 'ابتلاع بيعي',
      direction: 'تأكيد هابط',
      description: 'شمعة هابطة تسيطر على الحركة السابقة وتلمّح لضغط بيعي.',
    ),
  ];

  final List<_QuizQuestion> _questions = const [
    _QuizQuestion(
      question: 'ما الهدف الأساسي من وقف الخسارة؟',
      options: [
        'زيادة عدد الصفقات',
        'تقليل الخسارة المحتملة',
        'رفع العمولات',
        'تأكيد الربح دائمًا',
      ],
      correctIndex: 1,
    ),
    _QuizQuestion(
      question: 'عندما تكون المحفظة مركزة جدًا في سهم واحد فهذا يعني:',
      options: [
        'تنويع ممتاز',
        'مخاطر أعلى',
        'ربح مضمون',
        'سيولة أكبر بالضرورة',
      ],
      correctIndex: 1,
    ),
    _QuizQuestion(
      question: 'الشمعة المطرقة غالبًا ترتبط بـ:',
      options: [
        'إشارة انعكاس صاعد',
        'توزيع أرباح',
        'ثبات كامل للسوق',
        'انعدام حجم التداول',
      ],
      correctIndex: 0,
    ),
  ];

  int _quizIndex = 0;
  int _quizScore = 0;
  bool _quizFinished = false;

  double _cash = 100000;
  double _shares = 0;
  double _avgCost = 0;
  double _marketPrice = 142.5;
  final List<String> _simulationLog = <String>[];

  void _buySimulationShares() {
    const quantity = 50.0;
    final cost = quantity * _marketPrice;
    if (_cash < cost) return;

    final totalCost = (_shares * _avgCost) + cost;
    setState(() {
      _cash -= cost;
      _shares += quantity;
      _avgCost = _shares == 0 ? 0 : totalCost / _shares;
      _simulationLog.insert(
        0,
        'شراء ${quantity.toInt()} سهم بسعر ${_marketPrice.toStringAsFixed(2)}',
      );
    });
  }

  void _sellSimulationShares() {
    const quantity = 50.0;
    if (_shares < quantity) return;

    setState(() {
      _cash += quantity * _marketPrice;
      _shares -= quantity;
      if (_shares == 0) _avgCost = 0;
      _simulationLog.insert(
        0,
        'بيع ${quantity.toInt()} سهم بسعر ${_marketPrice.toStringAsFixed(2)}',
      );
    });
  }

  void _moveMarketPrice(bool up) {
    setState(() {
      _marketPrice += up ? 3.5 : -3.5;
      if (_marketPrice < 1) _marketPrice = 1;
    });
  }

  void _answerQuiz(int index) {
    if (_quizFinished) return;
    if (index == _questions[_quizIndex].correctIndex) {
      _quizScore++;
    }

    if (_quizIndex == _questions.length - 1) {
      setState(() => _quizFinished = true);
      return;
    }

    setState(() => _quizIndex++);
  }

  void _restartQuiz() {
    setState(() {
      _quizIndex = 0;
      _quizScore = 0;
      _quizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolioValue = _cash + (_shares * _marketPrice);
    final pnl = _shares == 0 ? 0.0 : (_marketPrice - _avgCost) * _shares;
    final progressPercent = ((_quizScore / _questions.length) * 100).round();

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز التعلّم'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الدورات'),
              Tab(text: 'المحاكاة'),
              Tab(text: 'الشموع'),
              Tab(text: 'الاختبار'),
              Tab(text: 'الإنجازات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionCard(
                  title: 'مسار التعلّم',
                  child: Text(
                    'ابدأ بالأساسيات ثم انتقل للتحليل الفني وإدارة المخاطر حتى تصبح قراراتك مبنية على منهج واضح.',
                  ),
                ),
                const SizedBox(height: 12),
                ..._courses.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      title: course.title,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(course.subtitle),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: course.progress),
                          const SizedBox(height: 8),
                          Text(
                            'التقدم ${(course.progress * 100).round()}% - ${course.lessons} دروس - ${course.hours} ساعات',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const InlineBannerAd(),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: 'المحاكاة الحية',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetricBox(label: 'الرصيد النقدي', value: _cash.toStringAsFixed(2)),
                          _MetricBox(label: 'السعر الحالي', value: _marketPrice.toStringAsFixed(2)),
                          _MetricBox(label: 'الأسهم المملوكة', value: _shares.toStringAsFixed(0)),
                          _MetricBox(label: 'القيمة الإجمالية', value: portfolioValue.toStringAsFixed(2)),
                          _MetricBox(label: 'الربح/الخسارة', value: pnl.toStringAsFixed(2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: _buySimulationShares,
                            child: const Text('شراء 50 سهم'),
                          ),
                          OutlinedButton(
                            onPressed: _sellSimulationShares,
                            child: const Text('بيع 50 سهم'),
                          ),
                          OutlinedButton(
                            onPressed: () => _moveMarketPrice(true),
                            child: const Text('رفع السعر'),
                          ),
                          OutlinedButton(
                            onPressed: () => _moveMarketPrice(false),
                            child: const Text('خفض السعر'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  title: 'سجل العمليات',
                  child: _simulationLog.isEmpty
                      ? const Text('ابدأ أول عملية لتظهر هنا نتائج المحاكاة.')
                      : Column(
                          children: _simulationLog
                              .take(8)
                              .map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.timeline),
                                  title: Text(item),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._patterns.map(
                  (pattern) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      title: pattern.title,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('النوع: ${pattern.direction}'),
                          const SizedBox(height: 8),
                          Text(pattern.description),
                        ],
                      ),
                    ),
                  ),
                ),
                const InlineBannerAd(),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionCard(
                  title: 'اختبار سريع',
                  child: _quizFinished
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('النتيجة: $_quizScore من ${_questions.length}'),
                            const SizedBox(height: 8),
                            Text('النسبة: $progressPercent%'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _restartQuiz,
                              child: const Text('إعادة الاختبار'),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السؤال ${_quizIndex + 1} من ${_questions.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(_questions[_quizIndex].question),
                            const SizedBox(height: 12),
                            ...List.generate(
                              _questions[_quizIndex].options.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _answerQuiz(index),
                                    child: Text(_questions[_quizIndex].options[index]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SectionCard(
                  title: 'الإنجازات',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مستكشف السوق: أتممت أول درس في الأساسيات'),
                      Text('محلل ناشئ: تعرفت على 4 أنماط شموع'),
                      Text('منضبط المخاطر: نجحت في اختبار إدارة المخاطر'),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                SectionCard(
                  title: 'مستوى التقدم',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الرتبة الحالية: مستثمر متعلّم'),
                      SizedBox(height: 8),
                      LinearProgressIndicator(value: 0.64),
                      SizedBox(height: 8),
                      Text('اقتربت من رتبة: محلل منضبط'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _CourseItem {
  const _CourseItem({
    required this.title,
    required this.subtitle,
    required this.hours,
    required this.lessons,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final int hours;
  final int lessons;
  final double progress;
}

class _PatternItem {
  const _PatternItem({
    required this.title,
    required this.direction,
    required this.description,
  });

  final String title;
  final String direction;
  final String description;
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
}
