import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';
import '../routing/app_router.dart';

class QuickActionsService {
  static final QuickActions _quickActions = const QuickActions();

  static void initialize() {
    if (kIsWeb) return; // Quick actions only work on iOS/Android

    _quickActions.initialize((String shortcutType) {
      debugPrint('Quick action triggered: $shortcutType');
      
      // Delay slightly to ensure GoRouter is fully mounted if cold started
      Future.delayed(const Duration(milliseconds: 500), () {
        switch (shortcutType) {
          case 'action_need_it_now':
            appRouter.go('/requests/create_urgent');
            break;
          case 'action_share_item':
            // Assuming this routes to the share selection page
            appRouter.go('/share/lend'); 
            break;
          case 'action_chats':
            appRouter.go('/chat');
            break;
          case 'action_radar':
            appRouter.go('/requests');
            break;
        }
      });
    });

    _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_need_it_now',
        localizedTitle: 'SOS / Need It Now',
        icon: 'ic_sos', // Ensure this icon exists in android/app/src/main/res/drawable
      ),
      const ShortcutItem(
        type: 'action_share_item',
        localizedTitle: 'Share an Item',
        icon: 'ic_share',
      ),
      const ShortcutItem(
        type: 'action_chats',
        localizedTitle: 'Chats',
        icon: 'ic_chat',
      ),
      const ShortcutItem(
        type: 'action_radar',
        localizedTitle: 'Live Radar',
        icon: 'ic_radar',
      ),
    ]).catchError((e) {
      debugPrint('Error setting quick actions: $e');
    });
  }
}
