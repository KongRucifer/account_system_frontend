import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🔇 หยุดเสียงเมื่อเข้าหน้า notifications
      ref.read(notificationsProvider.notifier).stopAllSounds();
      ref.read(notificationsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('ແຈ້ງເຕືອນ'), // Notifications
        actions: [
          // WebSocket connection status indicator
          Consumer(
            builder: (context, ref, child) {
              final notificationsAsync = ref.watch(notificationsProvider);
              return notificationsAsync.when(
                data: (state) => Icon(
                  state.isWebSocketConnected ? Icons.wifi : Icons.wifi_off,
                  color: state.isWebSocketConnected ? Colors.green : Colors.red,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).refresh();
        },
        child: notificationsAsync.when(
          data: (state) {
            if (state.isLoading && state.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null && state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'ເກີດຂໍ້ຜິດພາດ: ${state.error}', // Error occurred
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(notificationsProvider.notifier).refresh();
                      },
                      child: Text('ລອງໃໝ່'), // Retry
                    ),
                  ],
                ),
              );
            }

            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ບໍ່ມີການແຈ້ງເຕືອນ', // No notifications
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                final isRead = notification.isRead;

                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref
                        .read(notificationsProvider.notifier)
                        .markAsRead(notification.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    color: isRead ? null : Colors.blue[50],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            isRead ? Colors.grey : Colors.blue,
                        child: Icon(
                          isRead
                              ? Icons.notifications
                              : Icons.notifications_active,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        notification.message,
                        style: TextStyle(
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ວັນປະຊຸມ: ${notification.meetingDate}', // Meeting date
                          ),
                          Text(
                            _formatDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: isRead
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              color: Colors.green,
                              onPressed: () {
                                ref
                                    .read(notificationsProvider.notifier)
                                    .markAsRead(notification.id);
                              },
                            ),
                      onTap: () {
                        if (!isRead) {
                          ref
                              .read(notificationsProvider.notifier)
                              .markAsRead(notification.id);
                        }
                        // TODO: Navigate to meeting details if needed
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('ເກີດຂໍ້ຜິດພາດ: $error'), // Error occurred
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(notificationsProvider.notifier).refresh();
                  },
                  child: Text('ລອງໃໝ່'), // Retry
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTestDialog(context);
        },
        child: const Icon(Icons.build),
        tooltip: 'Test Notifications',
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'ມື້ກີ້ນີ້'; // Just now
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} ນາທີກ່ອນ'; // minutes ago
    } else if (diff.inDays < 1) {
      return '${diff.inHours} ຊົ່ວໂມງກ່ອນ'; // hours ago
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ມື້ກ່ອນ'; // days ago
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifications'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.preview),
              title: const Text('Preview Meetings'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final result = await ref
                      .read(notificationRepositoryProvider)
                      .previewMeetings();
                  _showResultDialog(context, 'Preview', result.toString());
                } catch (e) {
                  _showResultDialog(context, 'Error', e.toString());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Trigger Meeting Reminder'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final result = await ref
                      .read(notificationRepositoryProvider)
                      .triggerMeetingReminder();
                  _showResultDialog(context, 'Triggered', result.toString());
                } catch (e) {
                  _showResultDialog(context, 'Error', e.toString());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reconnect WebSocket'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(notificationsProvider.notifier)
                    .reconnectWebSocket();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reconnecting WebSocket...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
