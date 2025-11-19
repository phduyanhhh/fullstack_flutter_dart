import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final _router = Router(notFoundHandler: _notFoundHandler)
  ..get('/', _rootHandler)
  ..get('/api/v1/check', _checkHandler)
  ..post('/api/v1/submit', _submitHandler)
  ..get('/api/v1/echo/<message>', _echoHandler);

final _headers = {'Content-Type': 'application/json'};

Response _rootHandler(Request req) {
  return Response.ok(
    json.encode({'message': 'Welcome to the Dart Shelf Server'}),
    headers: _headers,
  );
}

Response _notFoundHandler(Request req) {
  return Response.notFound(
    json.encode({'error': 'Route not found'}),
    headers: _headers,
  );
}

Future<Response> _submitHandler(Request req) async {
  try {
    final payload = await req.readAsString();
    final data = json.decode(payload);

    final name = data['name'] as String?;
    if (name == null || name.isEmpty) {
      final response = {"error": "Name is required"};
      return Response.badRequest(
        body: json.encode(response),
        headers: _headers,
      );
    } else {
      final response = {"message": "Hello, $name!"};
      return Response.ok(json.encode(response), headers: _headers);
    }
  } catch (e) {
    final response = {"message": "Error processing request: ${e.toString()}"};
    return Response.badRequest(body: json.encode(response), headers: _headers);
  }
}

Response _echoHandler(Request req) {
  final message = req.params['message'];
  return Response.ok('$message\n');
}

Response _checkHandler(Request req) {
  return Response.ok(
    json.encode({'message': 'Server is running'}),
    headers: _headers,
  );
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final corsHeaders = createMiddleware(
    requestHandler: (req) {
      if (req.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods':
                'GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          },
        );
      }
      return null;
    },
    responseHandler: (res) {
      return res.change(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods':
              'GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );
    },
  );

  final handler = Pipeline()
      .addMiddleware(corsHeaders)
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port http://$server.address.host:${server.port}');
}
