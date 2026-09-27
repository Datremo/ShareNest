import 'dart:io';

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8081);
  print('Server running on http://localhost:8081');

  await for (var request in server) {
    final html = '''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Test Keys</title>
      </head>
      <body>
        <h1>Testing Keys</h1>
        <div id="results"></div>
        <script>
          const keys = {
            'Maps': 'AIzaSyChnT95erRQTX3IWYl7jocZ1mgL38F0Mwc',
            'Places': 'AIzaSyCVf0EriwuMaiXjUgdpw1gg6YXAuWTFrUg',
            'Directions': 'AIzaSyDGpqAPBSP4O3ZkXxnDqtX0hYbuNIyDJPM',
            'Geocoding': 'AIzaSyDvxih6DWk1ozvhAEWf_Rrldi0bi2fOnc0'
          };
          
          let index = 0;
          const keyNames = Object.keys(keys);
          
          function logResult(name, status) {
            document.getElementById('results').innerHTML += `<p>\${name}: \${status}</p>`;
          }

          function testNext() {
            if (index >= keyNames.length) return;
            const name = keyNames[index];
            const key = keys[name];
            index++;
            
            window[`initMap_\${name}`] = function() {
              // Now we test AutocompleteService
              try {
                const service = new google.maps.places.AutocompleteService();
                service.getPlacePredictions({ input: 'tapal', componentRestrictions: { country: 'in' } }, function(predictions, status) {
                  logResult(name, 'Success: ' + status);
                  testNext();
                });
              } catch (e) {
                logResult(name, 'Init Error: ' + e);
                testNext();
              }
            };

            const oldAuth = window.gm_authFailure;
            window.gm_authFailure = function() {
              logResult(name, 'Auth Failure (ApiNotActivatedMapError)');
              testNext();
            };

            const script = document.createElement('script');
            script.src = `https://maps.googleapis.com/maps/api/js?key=\${key}&libraries=places&callback=initMap_\${name}`;
            script.onerror = function() {
              logResult(name, 'Script Load Error');
              testNext();
            };
            document.body.appendChild(script);
          }
          
          testNext();
        </script>
      </body>
      </html>
    ''';
    
    request.response
      ..headers.contentType = ContentType.html
      ..write(html)
      ..close();
  }
}
