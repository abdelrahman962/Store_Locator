import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LocationData? currentLocation;
  List<Marker> markers = [];
  List<LatLng> routePoints = [];
  final orsApikey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjNmMTNiZWU1ZDkyYTQyMWY5OWNlNDczNGFlYzYwZjA2IiwiaCI6Im11cm11cjY0In0=';

  TextEditingController sourceController = TextEditingController();
  TextEditingController destController = TextEditingController();

  Future<LatLng> _searchLocation(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );
    final response = await http.get(
      url,
      headers: {'User-Agent': 'store_locator_app/1.0'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      } else {
        throw Exception('Location not found');
      }
    } else {
      throw Exception('Failed to search location: ${response.statusCode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Store Locator"), centerTitle: true),
      body: currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      currentLocation!.latitude!,
                      currentLocation!.longitude!,
                    ),
                    initialZoom: 15.0,
                    onTap: (tapPosition, point) => _addDestinationMarker(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.store_locator',
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Card(
                    color: Colors.white70,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: sourceController,
                            decoration: InputDecoration(
                              labelText: 'Source location name',
                            ),
                          ),
                          TextField(
                            controller: destController,
                            decoration: InputDecoration(
                              labelText: 'Destination location name',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final source = await _searchLocation(
                                sourceController.text,
                              );
                              final dest = await _searchLocation(
                                destController.text,
                              );

                              _mapController.move(source, 15.0);

                              setState(() {
                                markers.clear();
                                markers.add(
                                  Marker(
                                    width: 80,
                                    height: 80,
                                    point: source,
                                    child: Icon(
                                      Icons.my_location,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                );
                                markers.add(
                                  Marker(
                                    width: 80,
                                    height: 80,
                                    point: dest,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                );
                              });

                              _getRoute(dest);
                            },
                            child: Text('Show Route'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<String> _getAddressName(LatLng location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json',
    );
    final response = await http.get(
      url,
      headers: {'User-Agent': 'store_locator_app/1.0'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'] ?? "Unknown location";
    } else {
      return "Unknown location";
    }
  }

  Future<void> _getCurrentLocation() async {
    var location = Location();
    try {
      var userLocation = await location.getLocation();
      String current = await _getAddressName(
        LatLng(userLocation.latitude!, userLocation.longitude!),
      );
      setState(() {
        currentLocation = userLocation;
        sourceController.text = current;
        markers.add(
          Marker(
            width: 80.0,
            height: 80.0,
            point: LatLng(userLocation.latitude!, userLocation.longitude!),
            child: const Icon(Icons.my_location, color: Colors.red, size: 40),
          ),
        );
      });
    } on Exception catch (e) {
      currentLocation = null;
      print('Could not get location: $e');
    }
    location.onLocationChanged.listen((LocationData newLocation) {
      setState(() {
        currentLocation = newLocation;
      });
    });
  }

  Future<void> _getRoute(LatLng destination) async {
    if (currentLocation == null) return;

    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/foot-walking?api_key=$orsApikey&start=${currentLocation!.longitude},${currentLocation!.latitude}&end=${destination.longitude},${destination.latitude}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> coordinates =
          data['features'][0]['geometry']['coordinates'];

      setState(() {
        if (coordinates.isNotEmpty) {
          routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();

          markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: destination,
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          );
        } else {
          debugPrint("No route coordinates returned from API.");
        }
      });
    } else {
      debugPrint('Failed to get route: ${response.statusCode}');
    }
  }

  void _addDestinationMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    });
    _getRoute(point);
  }
}
