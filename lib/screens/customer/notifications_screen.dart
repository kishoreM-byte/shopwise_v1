import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color primary = ShopWiseColors.emerald;
  static const Color textPrimary = ShopWiseColors.textPrimary;
  static const Color textSecondary = ShopWiseColors.textSecondary;
  static const Color background = ShopWiseColors.background;

  static final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.watchUnreadCount(),
            builder: (context, snapshot) {
              final unread = snapshot.data ?? 0;

              if (unread == 0) {
                return const SizedBox(width: 8);
              }

              return TextButton(
                onPressed: () async {
                  try {
                    await _notificationService.markAllAsRead();
                  } catch (_) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to mark notifications as read.'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _notificationService.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () {
                // StreamBuilder reconnects automatically.
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          final notifications = snapshot.data ?? const <AppNotification>[];

          if (notifications.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 350));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return _NotificationCard(
                  notification: notification,
                  onTap: () => _markAsRead(context, notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  static Future<void> _markAsRead(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update notification.')),
      );
    }
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool unread = !notification.isRead;
    final IconData icon = _iconForType(notification.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: unread ? ShopWiseColors.surface : ShopWiseColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: unread
                  ? ShopWiseColors.emeraldSoft
                  : ShopWiseColors.border,
            ),
            boxShadow: unread
                ? [
                    BoxShadow(
                      color: ShopWiseColors.emerald.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ShopWiseColors.emerald.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: ShopWiseColors.emerald, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: ShopWiseColors.textPrimary,
                              fontSize: 14,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: ShopWiseColors.emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: ShopWiseColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        color: unread
                            ? ShopWiseColors.emerald
                            : ShopWiseColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'offer':
      case 'deal':
        return Icons.local_offer_rounded;
      case 'stock':
      case 'availability':
        return Icons.inventory_2_rounded;
      case 'enquiry':
      case 'enquiry_accepted':
        return Icons.mark_email_read_rounded;
      case 'enquiry_rejected':
        return Icons.mark_email_unread_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'route':
      case 'smart_trip':
        return Icons.route_rounded;
      case 'price':
      case 'price_drop':
        return Icons.trending_down_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: ShopWiseColors.border,
            ),
            SizedBox(height: 18),
            Text(
              'You’re all caught up',
              style: TextStyle(
                color: ShopWiseColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'New offers, stock updates and important activity will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: ShopWiseColors.emerald,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: ShopWiseColors.border,
            ),
            const SizedBox(height: 16),
            const Text(
              'Couldn’t load notifications',
              style: TextStyle(
                color: ShopWiseColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ShopWiseColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Try again',
                style: TextStyle(
                  color: ShopWiseColors.emerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
