import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_provider.dart';
import 'notifications_page.dart';

class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // 🔇 หยุดเสียงเมื่อ user กดเข้าไปดู notifications
            ref.read(notificationsProvider.notifier).stopAllSounds();
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            ).then((_) => ref.read(notificationsProvider.notifier).stopAllSounds());
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Widget แสดง snackbar เมื่อมี notification ใหม่
class NotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationListener> createState() =>
      _NotificationListenerState();
}

class _NotificationListenerState
    extends ConsumerState<NotificationListener> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    // Listen to notification stream
    final webSocketService = ref.read(webSocketServiceProvider);
    
    webSocketService.notificationStream.listen((event) {
      if (event['type'] == 'new_notification') {
        final data = event['data'];
        final message = data['data']?['message'] ?? 'ມີການແຈ້ງເຕືອນໃໝ່';

        // Show snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              action: SnackBarAction(
                label: 'ເບິ່ງ', // View
                onPressed: () {
                  // 🔇 หยุดเสียงเมื่อ user กดดู
                  ref.read(notificationsProvider.notifier).stopAllSounds();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              duration: const Duration(seconds: 5),
              onVisible: () {
                // เมื่อ snackbar แสดงแล้ว สามารถเพิ่ม logic อื่นๆ ได้
              },
            ),
          );
        }
      } else if (event['type'] == 'notification_read') {
        // 🔇 หยุดเสียงเมื่อ notification ถูก mark as read
        ref.read(notificationsProvider.notifier).stopAllSounds();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
