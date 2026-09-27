import 'package:http/http.dart' as http;
void main() async {
  var res = await http.get(Uri.parse('https://api.allorigins.win/get?url=https%3A%2F%2Fmaps.googleapis.com%2Fmaps%2Fapi%2Fplace%2Fautocomplete%2Fjson%3Finput%3Dtapal%26key%3DAIzaSyCVf0EriwuMaiXjUgdpw1gg6YXAuWTFrUg%26components%3Dcountry%3Ain'), headers: {'Origin': 'http://localhost'});
  print(res.statusCode);
  print(res.headers);
  print(res.body.substring(0, 100));
}
