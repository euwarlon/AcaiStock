import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) {},
    );
    _initialized = true;
  }

  Future<void> notifyLowStock({
    required int id,
    required String productName,
    required int quantity,
    required int reorderPoint,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Notificacoes para ponto de pedido',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: id,
      title: 'Estoque critico',
      body: '$productName atingiu ponto de pedido ($quantity/$reorderPoint).',
      notificationDetails: details,
      payload: 'low_stock_$id',
    );
  }
}
