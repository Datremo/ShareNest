import 'package:http/http.dart' as http;
void main() async {
  final target = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=tapal&key=AIzaSyCVf0EriwuMaiXjUgdpw1gg6YXAuWTFrUg&components=country:in';
  
  final proxies = [
    'https://api.cors.lol/?url=',
    'https://thingproxy.freeboard.io/fetch/',
    'https://corsproxy.io/?url=',
  ];

  for (var proxy in proxies) {
    print('Testing $proxy...');
    try {
      final res = await http.get(Uri.parse('$proxy${Uri.encodeComponent(target)}'), headers: {'Origin': 'http://localhost'});
      print('Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        print('CORS Headers: ${res.headers['access-control-allow-origin']}');
      }
    } catch(e) {
      print('Failed: $e');
    }
  }
}
