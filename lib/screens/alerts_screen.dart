import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/alert.dart';
import '../providers/alert_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/helpers.dart';
import '../widgets/loading_widget.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    await context.read<AlertProvider>().refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCreateAlertSheet() async {
    final alertProvider = context.read<AlertProvider>();
    final formKey = GlobalKey<FormState>();
    final symbolController = TextEditingController();
    final stockNameController = TextEditingController();
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCondition = 'above';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              right: 20,
              left: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'إنشاء تنبيه جديد',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Symbol field
                  TextFormField(
                    controller: symbolController,
                    decoration: InputDecoration(
                      labelText: 'رمز السهم',
                      hintText: 'مثال: CIB',
                      prefixIcon: const Icon(Icons.tag),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال رمز السهم';
                      }
                      return null;
                    },
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),

                  // Stock name field
                  TextFormField(
                    controller: stockNameController,
                    decoration: InputDecoration(
                      labelText: 'اسم السهم',
                      hintText: 'مثال: البنك التجاري الدولي',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم السهم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Condition dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCondition,
                    decoration: InputDecoration(
                      labelText: 'الشرط',
                      prefixIcon: const Icon(Icons.swap_vert),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'above',
                        child: Text('أعلى من'),
                      ),
                      DropdownMenuItem(
                        value: 'below',
                        child: Text('أقل من'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        selectedCondition = value;
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Target price field
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'السعر المستهدف',
                      hintText: '0.00',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال السعر المستهدف';
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),

                  // Notes field
                  TextFormField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      prefixIcon: const Icon(Icons.notes),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Create button
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await alertProvider.createAlert(
                          symbol: symbolController.text.trim(),
                          stockName: stockNameController.text.trim(),
                          condition: selectedCondition,
                          targetPrice: double.parse(priceController.text.trim()),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إنشاء التنبيه بنجاح'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إنشاء التنبيه',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );

    symbolController.dispose();
    stockNameController.dispose();
    priceController.dispose();
    notesController.dispose();
  }

  Future<void> _confirmDeleteAlert(BuildContext context, PriceAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف التنبيه'),
          content: Text(
            'هل تريد حذف تنبيه "${alert.stockName}" عند ${alert.conditionText} ${Helpers.formatCurrency(alert.targetPrice)}؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AlertProvider>().deleteAlert(alert.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف التنبيه'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('التنبيهات'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            tabs: const [
              Tab(text: 'النشطة'),
              Tab(text: 'المُنفذة'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateAlertSheet,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_alert, color: Colors.white),
        ),
        body: Consumer<AlertProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.alerts.isEmpty) {
              return TabBarView(
                controller: _tabController,
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return const LoadingShimmer(height: 100, margin: EdgeInsets.only(bottom: 12));
                    },
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return const LoadingShimmer(height: 100, margin: EdgeInsets.only(bottom: 12));
                    },
                  ),
                ],
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Active Alerts Tab
                _buildActiveTab(provider, isDark),
                // Triggered Alerts Tab
                _buildTriggeredTab(provider, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveTab(AlertProvider provider, bool isDark) {
    final activeAlerts = provider.activeAlerts;

    if (activeAlerts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.notifications_none_rounded,
        title: 'لا توجد تنبيهات نشطة',
        subtitle: 'أنشئ تنبيه جديد لتلقي إشعار عند وصول السعر للهدف',
        actionText: 'إنشاء تنبيه',
        onAction: _showCreateAlertSheet,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activeAlerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final alert = activeAlerts[index];
        final isAbove = alert.condition == 'above';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Alert icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAbove
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAbove ? Icons.trending_up : Icons.trending_down,
                    color: isAbove ? AppColors.gain : Colors.orange,
                  ),
                ),
                const SizedBox(width: 14),

                // Alert info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            alert.symbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isAbove ? Colors.green : Colors.orange).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              alert.conditionText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isAbove ? AppColors.gain : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.stockName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'السعر المستهدف: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            Helpers.formatCurrency(alert.targetPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  onPressed: () => _confirmDeleteAlert(context, alert),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTriggeredTab(AlertProvider provider, bool isDark) {
    final triggeredAlerts = provider.triggeredAlerts;

    if (triggeredAlerts.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: 'لا توجد تنبيهات مُنفذة',
        subtitle: 'ستظهر هنا التنبيهات التي تم تنفيذها عند وصول السعر للهدف',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: triggeredAlerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final alert = triggeredAlerts[index];

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            alert.symbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'تم التنفيذ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.stockName,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${alert.conditionText} ${Helpers.formatCurrency(alert.targetPrice)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
