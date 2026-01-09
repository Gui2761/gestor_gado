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
    // 1. Configura Fuso Horário
    tz.initializeTimeZones();
    try {
      var timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Configura Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    
    // 3. Pede Permissões
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    
    // CRIAÇÃO EXPLÍCITA DO CANAL (Isso resolve muitos problemas de "não tocar")
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'canal_vacinas', 
      'Lembretes de Vacina',
      description: 'Notificações agendadas para o gado',
      importance: Importance.max,
      playSound: true,
    );
    await androidImplementation?.createNotificationChannel(channel);
  }

  // --- TESTE RÁPIDO (1 MINUTO) ---
  Future<void> agendarTesteRapido() async {
    final agora = tz.TZDateTime.now(tz.local);
    final daquiUmMinuto = agora.add(const Duration(minutes: 1));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      999, 
      'Teste Agendado ⏳',
      'Se você viu isso, as vacinas vão funcionar!',
      daquiUmMinuto,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_vacinas', // Mesmo canal das vacinas
          'Lembretes de Vacina',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // --- TESTE IMEDIATO ---
  Future<void> mostrarNotificacaoImediata() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_vacinas',
      'Lembretes de Vacina',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      888,
      'Teste Imediato 🔔',
      'O sistema de notificações está ativo.',
      details,
    );
  }

  // --- AGENDAMENTO REAL ---
  Future<void> agendarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime dataAgendada,
  }) async {
    // Tenta agendar para as 08:00
    var dataAlvo = DateTime(
      dataAgendada.year,
      dataAgendada.month,
      dataAgendada.day,
      8, 0, 
    );

    // Se já passou das 08:00 de hoje, não agenda (ou agende para teste mudando a hora aqui)
    if (dataAlvo.isBefore(DateTime.now())) {
        print("Tentativa de agendar para o passado ignorada: $dataAlvo");
        return;
    }

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
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  
  Future<void> cancelarNotificacao(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}