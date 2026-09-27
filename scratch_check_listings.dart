import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://mujkfahnumvpabettrsx.supabase.co/rest/v1/listings?limit=1';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11amtmYWhudW12cGFiZXR0cnN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2MjQ0MDYsImV4cCI6MjEwNTIwMDQwNn0.MUiYl3BUhNBnf6FWJ3Md-Cg_rtCYoTIk0WZx48-f7WU',
      'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11amtmYWhudW12cGFiZXR0cnN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2MjQ0MDYsImV4cCI6MjEwNTIwMDQwNn0.MUiYl3BUhNBnf6FWJ3Md-Cg_rtCYoTIk0WZx48-f7WU'
    },
  );
  
  if (response.statusCode == 200) {
    print('Listings row: ${response.body}');
  } else {
    print('Error: ${response.body}');
  }
}
