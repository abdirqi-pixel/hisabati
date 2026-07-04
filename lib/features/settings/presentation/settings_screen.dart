import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          _SettingTile(
            icon: Icons.public_rounded,
            title: 'البلد والعملة',
            subtitle: 'اختيار البلد وتغيير العملة تلقائيًا',
            route: '/country-currency',
          ),
          _SettingTile(
            icon: Icons.add_circle_rounded,
            title: 'الإضافة السريعة',
            subtitle: 'مصروف، إيراد، صندوق، سلفة، شخص، مشروع',
            route: '/quick-add',
          ),
          _SettingTile(
            icon: Icons.repeat_rounded,
            title: 'العمليات الدورية',
            subtitle: 'مصروفات وإيرادات تتكرر تلقائيًا',
            route: '/recurring',
          ),
          _SettingTile(
            icon: Icons.search_rounded,
            title: 'البحث الذكي',
            subtitle: 'بحث موحد في كل بيانات التطبيق',
            route: '/global-search',
          ),
          _SettingTile(
            icon: Icons.attach_file_rounded,
            title: 'إدارة المرفقات',
            subtitle: 'عرض وفتح ومشاركة مرفقات العمليات',
            route: '/attachments',
          ),
          _SettingTile(
            icon: Icons.document_scanner_rounded,
            title: 'ماسح الفواتير',
            subtitle: 'قراءة الفواتير وتحويلها إلى مصروف',
            route: '/invoice-scanner',
          ),
          _SettingTile(
            icon: Icons.folder_rounded,
            title: 'إدارة المشاريع',
            subtitle: 'إضافة وتعديل وأرشفة المشاريع',
            route: '/projects',
          ),
          _SettingTile(
            icon: Icons.people_alt_rounded,
            title: 'إدارة الأشخاص',
            subtitle: 'إضافة وتعديل وحذف الأشخاص',
            route: '/persons',
          ),
          _SettingTile(
            icon: Icons.manage_accounts_rounded,
            title: 'إدارة المستخدمين',
            subtitle: 'مدير، محاسب، موظف، مشاهد',
            route: '/users',
          ),
          _SettingTile(
            icon: Icons.category_rounded,
            title: 'إدارة التصنيفات',
            subtitle: 'تعديل التصنيفات والألوان والأيقونات',
            route: '/categories',
          ),
          _SettingTile(
            icon: Icons.receipt_long_rounded,
            title: 'العمليات',
            subtitle: 'عرض كل المصروفات المسجلة',
            route: '/expenses',
          ),
          _SettingTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'الصندوق',
            subtitle: 'إيداعات وسحوبات ورصيد المشروع',
            route: '/treasury',
          ),
          _SettingTile(
            icon: Icons.trending_up_rounded,
            title: 'الإيرادات',
            subtitle: 'تسجيل واردات ودخل المشروع',
            route: '/incomes',
          ),
          _SettingTile(
            icon: Icons.handshake_rounded,
            title: 'الديون والسلف',
            subtitle: 'تسجيل السلف والتسديدات والمتبقي',
            route: '/advances',
          ),
          _SettingTile(
            icon: Icons.bar_chart_rounded,
            title: 'التقارير',
            subtitle: 'مصروفات حسب الشخص والتصنيف واليوم',
            route: '/reports',
          ),
          _SettingTile(
            icon: Icons.picture_as_pdf_rounded,
            title: 'التقارير الاحترافية',
            subtitle: 'PDF وExcel وطباعة ومشاركة',
            route: '/professional-reports',
          ),
          _SettingTile(
            icon: Icons.savings_rounded,
            title: 'الميزانيات',
            subtitle: 'ميزانيات شهرية وسنوية للمشاريع',
            route: '/budgets',
          ),
          _SettingTile(
            icon: Icons.query_stats_rounded,
            title: 'مؤشرات الأداء',
            subtitle: 'الإيرادات، المصروفات، الصافي، وأكثر العناصر نشاطًا',
            route: '/kpi',
          ),
          _SettingTile(
            icon: Icons.insights_rounded,
            title: 'التحليلات',
            subtitle: 'مقارنات شهرية وسنوية وتوقعات الإنفاق',
            route: '/analytics',
          ),
          _SettingTile(
            icon: Icons.dashboard_rounded,
            title: 'اللوحة التنفيذية',
            subtitle: 'ملخص إداري ومقارنة المشاريع والتنبيهات',
            route: '/executive-dashboard',
          ),
          _SettingTile(
            icon: Icons.monitor_heart_rounded,
            title: 'المراقبة المالية',
            subtitle: 'توقع التدفق النقدي والأهداف المالية',
            route: '/financial-monitor',
          ),
          _SettingTile(
            icon: Icons.analytics_rounded,
            title: 'التقارير المتقدمة',
            subtitle: 'فلاتر حسب المشروع والشخص والتصنيف والتاريخ والمبلغ',
            route: '/advanced-reports',
          ),
          _SettingTile(
            icon: Icons.bookmarks_rounded,
            title: 'الفلاتر المحفوظة',
            subtitle: 'حفظ وتطبيق فلاتر التقارير المتكررة',
            route: '/saved-report-filters',
          ),
          _SettingTile(
            icon: Icons.dashboard_customize_rounded,
            title: 'تخصيص لوحة التحكم',
            subtitle: 'إظهار وإخفاء وترتيب بطاقات الرئيسية',
            route: '/dashboard-settings',
          ),
          _SettingTile(
            icon: Icons.palette_rounded,
            title: 'المظهر',
            subtitle: 'الوضع النهاري والليلي وحسب النظام',
            route: '/appearance',
          ),
          _SettingTile(
            icon: Icons.notifications_active_rounded,
            title: 'التنبيهات',
            subtitle: 'تذكير يومي وتنبيهات الميزانية',
            route: '/notifications-settings',
          ),
          _SettingTile(
            icon: Icons.notifications_rounded,
            title: 'مركز الإشعارات',
            subtitle: 'عرض التنبيهات الذكية وسجلها',
            route: '/notification-center',
          ),
          _SettingTile(
            icon: Icons.lock_rounded,
            title: 'الأمان',
            subtitle: 'تفعيل رمز PIN وقفل التطبيق',
            route: '/security-settings',
          ),
          _SettingTile(
            icon: Icons.history_rounded,
            title: 'سجل النشاط',
            subtitle: 'عرض الإضافات والتعديلات والحذف',
            route: '/activity-log',
          ),
          _SettingTile(
            icon: Icons.delete_rounded,
            title: 'سلة المحذوفات',
            subtitle: 'استعادة المشاريع والأشخاص والعمليات',
            route: '/trash',
          ),
          _SettingTile(
            icon: Icons.speed_rounded,
            title: 'صيانة البيانات',
            subtitle: 'ضغط قاعدة البيانات وتنظيف السجلات',
            route: '/maintenance',
          ),
          _SettingTile(
            icon: Icons.rocket_launch_rounded,
            title: 'الأداء والإصدار التجريبي',
            subtitle: 'فهارس، تحسينات، وتجهيز Beta',
            route: '/performance',
          ),
          _SettingTile(
            icon: Icons.verified_rounded,
            title: 'جاهزية الإصدار',
            subtitle: 'فحص Beta v1.0 ومعلومات النسخة',
            route: '/release-readiness',
          ),
          _SettingTile(
            icon: Icons.fact_check_rounded,
            title: 'التثبيت النهائي',
            subtitle: 'فحوصات Release Candidate وخطة QA',
            route: '/stabilization',
          ),
          _SettingTile(
            icon: Icons.android_rounded,
            title: 'تجهيز البناء',
            subtitle: 'APK و AAB ودليل النشر',
            route: '/build-readiness',
          ),
          _SettingTile(
            icon: Icons.store_rounded,
            title: 'جاهزية المتجر',
            subtitle: 'وصف التطبيق وسياسة الخصوصية ومواد النشر',
            route: '/store-readiness',
          ),
          _SettingTile(
            icon: Icons.info_rounded,
            title: 'حول التطبيق',
            subtitle: 'الإصدار ومعلومات حساباتي',
            route: '/about-app',
          ),
          _SettingTile(
            icon: Icons.flag_circle_rounded,
            title: 'الإطلاق النهائي',
            subtitle: 'قائمة نشر v1.0 Final',
            route: '/final-launch',
          ),
          _SettingTile(
            icon: Icons.groups_rounded,
            title: 'الاختبار الميداني',
            subtitle: 'خطة اختبار المستخدمين وبلاغات الأخطاء',
            route: '/field-test',
          ),
          _SettingTile(
            icon: Icons.feedback_rounded,
            title: 'ملاحظات المختبرين',
            subtitle: 'تسجيل ومتابعة أخطاء الاختبار',
            route: '/tester-feedback',
          ),
          _SettingTile(
            icon: Icons.engineering_rounded,
            title: 'تسليم المطور',
            subtitle: 'شرح بنية المشروع وخريطة الميزات',
            route: '/developer-handoff',
          ),
          _SettingTile(
            icon: Icons.lightbulb_rounded,
            title: 'طلبات الميزات',
            subtitle: 'متابعة أفكار المستخدمين بعد الإطلاق',
            route: '/feature-requests',
          ),
          _SettingTile(
            icon: Icons.design_services_rounded,
            title: 'مراجعة الواجهة',
            subtitle: 'RTL والنصوص العربية وتجربة المستخدم',
            route: '/ux-review',
          ),
          _SettingTile(
            icon: Icons.support_agent_rounded,
            title: 'الدعم والمشاكل',
            subtitle: 'بلاغات دعم وسياسة التعامل مع الأخطاء',
            route: '/support-tickets',
          ),
          _SettingTile(
            icon: Icons.new_releases_rounded,
            title: 'سجل الإصدارات',
            subtitle: 'متابعة تغييرات وتحديثات التطبيق',
            route: '/app-releases',
          ),
          _SettingTile(
            icon: Icons.manage_search_rounded,
            title: 'فحص هيكل المشروع',
            subtitle: 'تحقق من الملفات الأساسية قبل البناء',
            route: '/structural-audit',
          ),
          _SettingTile(
            icon: Icons.terminal_rounded,
            title: 'فحص أوامر Flutter',
            subtitle: 'pub get و analyze و build',
            route: '/flutter-checks',
          ),
          _SettingTile(
            icon: Icons.lock_clock_rounded,
            title: 'تجميد الميزات',
            subtitle: 'إيقاف الميزات الجديدة والتركيز على الإصلاح',
            route: '/feature-freeze',
          ),
          _SettingTile(
            icon: Icons.bug_report_rounded,
            title: 'إصلاحات البناء',
            subtitle: 'تسجيل أخطاء analyze و build وحلولها',
            route: '/build-fix-log',
          ),
          _SettingTile(
            icon: Icons.construction_rounded,
            title: 'إصلاح الكود فقط',
            subtitle: 'تتبع الملفات المعدلة بدون ميزات جديدة',
            route: '/code-fix-only',
          ),
          _SettingTile(
            icon: Icons.backup_rounded,
            title: 'النسخ الاحتياطي',
            subtitle: 'تصدير واستعادة البيانات',
            route: '/backup',
          ),
          _SettingTile(
            icon: Icons.enhanced_encryption_rounded,
            title: 'النسخ المشفر',
            subtitle: 'حماية النسخة الاحتياطية بكلمة مرور',
            route: '/secure-backup',
          ),
          _SettingTile(
            icon: Icons.cloud_sync_rounded,
            title: 'المزامنة السحابية',
            subtitle: 'مزامنة اختيارية عبر مجلد Drive أو iCloud',
            route: '/cloud-sync',
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: route == null ? null : () => context.go(route!),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
    );
  }
}