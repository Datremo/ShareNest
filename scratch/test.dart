import 'package:http/http.dart' as http;
void main() async {
  var res = await http.post(Uri.parse('https://places.googleapis.com/v1/places:autocomplete'), headers: {'X-Goog-Api-Key': 'AIzaSyCVf0EriwuMaiXjUgdpw1gg6YXAuWTFrUg', 'Content-Type': 'application/json', 'Origin': 'http://localhost'}, body: '{"input": "pizza"}');
  print(res.headers);
  print(res.body);
}
