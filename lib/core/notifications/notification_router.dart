import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationRouter {
  static void handleNotificationTap(BuildContext context, RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    final eventType = data['event_type'];
    final entityId = data['entity_id'];

    debugPrint('Notification tapped! Event: $eventType, Entity: $entityId');

    switch (eventType) {
      case 'BORROW_REQUEST_RECEIVED':
      case 'GIVE_REQUEST_RECEIVED':
      case 'REQUEST_ACCEPTED':
      case 'REQUEST_REJECTED':
        // Navigate to requests hub
        context.go('/requests');
        break;
      case 'URGENT_OFFER_RECEIVED':
      case 'OFFER_ACCEPTED':
      case 'OFFER_REJECTED':
      case 'URGENT_REQUEST_BROADCAST':
        // Navigate to the urgent request details or offers page
        if (entityId != null) {
          // Assuming entity_id is the urgent_request_id
          context.go('/requests/need_it_now/$entityId');
        } else {
          context.go('/requests');
        }
        break;
      case 'MESSAGE_RECEIVED':
        if (entityId != null) {
          // Navigate to specific conversation
          context.go('/chat/$entityId');
        } else {
          context.go('/chat');
        }
        break;
      case 'TRANSACTION_UPDATE':
        if (entityId != null) {
          context.go('/share/details/$entityId');
        }
        break;
      default:
        // Default fallback, could go home
        break;
    }
  }
}
