import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/models/profile.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/item_request.dart';
import '../presentation/main_scaffold.dart';
import 'page_transitions.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/login_username_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/reset_password_otp_screen.dart';
import '../../features/profile/presentation/edit_profile_page.dart';
import '../../features/requests/presentation/urgent_request_detail_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/requests/presentation/create_urgent_request_page.dart';
import '../../features/requests/presentation/live_radar_dashboard.dart';
import '../../features/requests/presentation/my_sos_signals_page.dart';
import '../../features/explore/presentation/explore_page.dart';
import '../../features/activity/presentation/activity_page.dart';
import '../../features/profile/presentation/profile_page.dart';
import '../../features/profile/presentation/settings_page.dart';
import '../../features/profile/presentation/tracking_dashboard_page.dart';
import '../../features/item/presentation/item_detail_page.dart';
import '../../features/explore/presentation/free_items_page.dart';
import '../../features/messages/presentation/messages_page.dart';
import '../../features/messages/presentation/conversation_page.dart';
import '../../features/activity/presentation/live_requests_page.dart';
import '../../features/profile/presentation/my_listings_page.dart';
import '../../features/profile/presentation/my_requests_page.dart';
import '../../features/profile/presentation/my_posts_page.dart';
import '../../features/profile/presentation/my_borrowing_page.dart';
import '../../features/profile/presentation/my_lending_page.dart';
import '../../features/share/presentation/create_lend_post_page.dart';
import '../../features/share/presentation/create_give_post_page.dart';
import '../../features/share/presentation/create_exchange_post_page.dart';
import '../../features/share/presentation/edit_lend_post_page.dart';
import '../../features/explore/presentation/borrow_hub_page.dart';
import '../../features/explore/presentation/borrow_results_page.dart';
import '../../features/requests/presentation/request_free_item_page.dart';
import '../../features/requests/presentation/request_borrow_page.dart';
import '../../features/activity/presentation/pickup_details_page.dart';
import '../../features/requests/presentation/request_accepted_page.dart';
import '../../features/activity/presentation/item_received_page.dart';
import '../../features/explore/presentation/exchange_hub_page.dart';
import '../../features/requests/presentation/request_exchange_page.dart';
import '../../features/requests/presentation/owner_requests_list_page.dart';
import '../../features/requests/presentation/owner_request_detail_page.dart';
import '../../features/profile/presentation/mark_as_returned_page.dart';
import '../../features/requests/presentation/owner_decline_request_page.dart';
import '../../features/profile/presentation/impact_summary_page.dart';
import '../../features/requests/presentation/owner_exchange_request_page.dart';
import '../../features/item/presentation/exchange_completed_page.dart';
import '../../features/requests/presentation/requester_request_detail_page.dart';
import '../../features/requests/presentation/request_sent_page.dart';
import '../../features/explore/presentation/search_results_page.dart';
import '../../features/share/presentation/review_post_page.dart';
import '../../features/share/presentation/post_published_page.dart';
import 'package:image_picker/image_picker.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorExploreKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellExplore');
final GlobalKey<NavigatorState> _shellNavigatorActivityKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellActivity');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/auth', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/login_username',
      builder: (context, state) => const LoginUsernameScreen(),
    ),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/forgot_password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset_password',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return ResetPasswordOtpScreen(email: email);
      },
    ),
    GoRoute(
      path: '/item',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final listing = state.extra as Listing;
        return ItemDetailPage(listing: listing);
      },
    ),
    GoRoute(
      path: '/request-sent',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RequestSentPage(),
    ),
    GoRoute(
      path: '/search_results',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchResultsPage(
          query: extra?['query'] ?? '',
          category: extra?['category'],
        );
      },
    ),
    GoRoute(
      path: '/review_post',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final listing = extra['listing'] as Listing;
        final images = extra['images'] as List<XFile>;
        return SpringBottomUpTransitionPage(
          key: state.pageKey,
          child: ReviewPostPage(listing: listing, images: images),
        );
      },
    ),
    GoRoute(
      path: '/post_published',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PostPublishedPage(),
    ),
    GoRoute(
      path: '/create_urgent_request',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => SpringBottomUpTransitionPage(
        key: state.pageKey,
        child: const CreateUrgentRequestPage(),
      ),
    ),
    GoRoute(
      path: '/urgent_request_detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return SpringBottomUpTransitionPage(
          key: state.pageKey,
          child: UrgentRequestDetailPage(requestId: id),
        );
      },
    ),

    GoRoute(
      path: '/messages',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MessagesPage(),
    ),
    GoRoute(
      path: '/conversation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ConversationPage(),
    ),
    GoRoute(
      path: '/my_listings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyListingsPage(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const SettingsPage();
      },
    ),
    GoRoute(
      path: '/tracking_dashboard',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const TrackingDashboardPage();
      },
    ),
    GoRoute(
      path: '/live_requests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LiveRequestsPage(),
    ),
    GoRoute(
      path: '/live_radar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LiveRadarDashboardPage(),
    ),
    GoRoute(
      path: '/my_sos_signals',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MySosSignalsPage(),
    ),
    GoRoute(
      path: '/my_requests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyRequestsPage(),
    ),
    GoRoute(
      path: '/my_posts',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyPostsPage(),
    ),
    GoRoute(
      path: '/my_borrowing',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyBorrowingPage(),
    ),
    GoRoute(
      path: '/my_lending',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MyLendingPage(),
    ),
    GoRoute(
      path: '/free_items',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FreeItemsPage(),
    ),
    GoRoute(
      path: '/edit_profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return const EditProfilePage();
      },
    ),
    GoRoute(
      path: '/user_profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'];
        return ProfilePage(userId: userId);
      },
    ),
    GoRoute(
      path: '/borrow_hub',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BorrowHubPage(),
    ),
    GoRoute(
      path: '/borrow_results',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BorrowResultsPage(),
    ),
    GoRoute(
      path: '/request_free_item',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final listing = state.extra as Listing;
        return RequestFreeItemPage(listing: listing);
      },
    ),
    GoRoute(
      path: '/request_borrow',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final listing = state.extra as Listing;
        return RequestBorrowPage(listing: listing);
      },
    ),
    GoRoute(
      path: '/pickup_details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PickupDetailsPage(),
    ),
    GoRoute(
      path: '/request_accepted',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        return const RequestAcceptedPage();
      },
    ),
    GoRoute(
      path: '/item_received',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ItemReceivedPage(),
    ),
    GoRoute(
      path: '/create_post',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final type = state.uri.queryParameters['type'] ?? 'lend';
        Widget child;
        if (type == 'give') {
          child = const CreateGivePostPage();
        } else if (type == 'exchange') {
          child = const CreateExchangePostPage();
        } else {
          child = const CreateLendPostPage();
        }
        return SpringBottomUpTransitionPage(
          key: state.pageKey,
          child: child,
        );
      },
    ),
    GoRoute(
      path: '/edit_post',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final listing = state.extra as Listing;
        return SpringBottomUpTransitionPage(
          key: state.pageKey,
          child: EditLendPostPage(listing: listing),
        );
      },
    ),
    GoRoute(
      path: '/exchange_hub',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExchangeHubPage(),
    ),
    GoRoute(
      path: '/request_exchange',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final listing = state.extra as Listing;
        return RequestExchangePage(listing: listing);
      },
    ),
    GoRoute(
      path: '/owner_requests_list',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final listing = state.extra as Listing;
        return OwnerRequestsListPage(listing: listing);
      },
    ),
    GoRoute(
      path: '/owner_request_detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;

        final dynamic reqData = extra['requester'];
        Profile? requesterProfile;
        if (reqData is Profile) {
          requesterProfile = reqData;
        } else if (reqData is Map<String, dynamic>) {
          requesterProfile = Profile.fromJson(reqData);
        } else {
          requesterProfile = Profile(
            id: 'unknown',
            displayName: 'Unknown',
            trustScore: 0,
          );
        }

        final dynamic reqParam = extra['request'];
        final requestObj = reqParam is ItemRequest ? reqParam : ItemRequest.fromJson(reqParam);
        
        final dynamic listParam = extra['listing'];
        final listingObj = listParam is Listing ? listParam : Listing.fromJson(listParam);

        return OwnerRequestDetailPage(
          request: requestObj,
          listing: listingObj,
          requester: requesterProfile!,
        );
      },
    ),
    GoRoute(
      path: '/requester_request_detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        
        final dynamic reqParam = extra['request'];
        final requestObj = reqParam is ItemRequest ? reqParam : ItemRequest.fromJson(reqParam);
        
        final dynamic listParam = extra['listing'];
        final listingObj = listParam is Listing ? listParam : Listing.fromJson(listParam);

        return RequesterRequestDetailPage(
          request: requestObj,
          listing: listingObj,
        );
      },
    ),
    GoRoute(
      path: '/owner_decline_request',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OwnerDeclineRequestPage(),
    ),
    GoRoute(
      path: '/mark_as_returned',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MarkAsReturnedPage(),
    ),
    GoRoute(
      path: '/impact_summary',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ImpactSummaryPage(),
    ),
    GoRoute(
      path: '/owner_exchange_request',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OwnerExchangeRequestPage(),
    ),
    GoRoute(
      path: '/exchange_completed',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExchangeCompletedPage(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorExploreKey,
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExplorePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorActivityKey,
          routes: [
            GoRoute(
              path: '/activity',
              builder: (context, state) => const ActivityPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
