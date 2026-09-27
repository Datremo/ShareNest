import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/models/item_request.dart';
import '../../../core/data/models/listing.dart';
import '../../../core/data/models/profile.dart';

class RequestLoaderPage extends StatefulWidget {
  final String requestId;
  final String role; // 'owner' or 'requester'

  const RequestLoaderPage({
    super.key,
    required this.requestId,
    required this.role,
  });

  @override
  State<RequestLoaderPage> createState() => _RequestLoaderPageState();
}

class _RequestLoaderPageState extends State<RequestLoaderPage> {
  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final res = await Supabase.instance.client
          .from('item_requests')
          .select('*, listings!item_requests_listing_id_fkey(*), profiles:requester_id(*)')
          .eq('id', widget.requestId)
          .single();
      
      final request = ItemRequest.fromJson(res);
      final listing = Listing.fromJson(res['listings']);
      final requester = Profile.fromJson(res['profiles']);

      if (!mounted) return;

      if (widget.role == 'owner') {
        context.pushReplacement('/owner_request_detail', extra: {
          'request': request,
          'listing': listing,
          'requester': requester,
        });
      } else {
        context.pushReplacement('/requester_request_detail', extra: {
          'request': request,
          'listing': listing,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading request: $e')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
      ),
    );
  }
}
