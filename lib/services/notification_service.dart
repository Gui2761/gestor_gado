import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // CORREÇÃO 1: Usamos 'var' porque o tipo retornado pode variar dependendo da versão
    var timeZoneName = await FlutterTimezone.getLocalTimezone();
    
    try {
      // CORREÇÃO 2: Forçamos .toString() para garantir que seja texto
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      // Se falhar, usa UTC como segurança
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataAgendada,
  }) async {
    
    final dataAlvo = DateTime(
      dataAgendada.year,
      dataAgendada.month,
      dataAgendada.day,
      8, 
      0, // 08:00 da manhã
    );

    if (dataAlvo.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(dataAlvo, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_vacinas',
          'Lembretes de Vacina',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Se o erro vermelho persistir aqui, é bug visual do VS Code.
      // O comando 'flutter pub get' abaixo resolve.
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  Future<void> cancelarNotificacao(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}