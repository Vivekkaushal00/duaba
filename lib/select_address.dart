import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_google_maps_webservices/places.dart';

class SelectAddress extends StatefulWidget {
  const SelectAddress({super.key});

  @override
  State<SelectAddress> createState() => _SelectAddressState();
}

class _SelectAddressState extends State<SelectAddress> {
  GoogleMapController? mapController;
  LatLng? _center;
  Position? _currentPosition;

  BitmapDescriptor? _customMarker;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _places =
        GoogleMapsPlaces(apiKey: "AIzaSyBVKwR194A0AY3H2ag0VjtGXweClz-xuEg");
    _loadCustomMarker();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    });
  }

  final _searchController = TextEditingController();
  late GoogleMapsPlaces _places;

  List<Prediction> _placePredictions = [];

  Future<void> _onSearchChanged(String value) async {
    if (value.isNotEmpty) {
      final prediction = await _places.autocomplete(value);
      setState(() {
        _placePredictions = prediction.predictions;
      });
    } else {
      setState(() {
        _placePredictions = [];
      });
    }
  }

  Future<void> _onPlaceSelected(Prediction prediction) async {
    final placeId = prediction.placeId;
    final details = await _places.getDetailsByPlaceId(placeId!);

    final location = details.result.geometry?.location;
    if (location != null) {
      setState(() {
        _center = LatLng(location.lat, location.lng);
        _placePredictions =
            []; // Clear the suggestions after a place is selected
      });
      mapController?.animateCamera(CameraUpdate.newLatLng(_center!));
    }
  }

  Future<void> _loadCustomMarker() async {
    final BitmapDescriptor markerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/marker.png',
    );
    setState(() {
      _customMarker = markerIcon;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _center == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  height: double.infinity,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _center!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                          markerId: const MarkerId('User Location'),
                          position: _center!,
                          icon: _customMarker ?? BitmapDescriptor.defaultMarker,
                          infoWindow: const InfoWindow(title: 'Current Location')),
                    },
                  ),
                ),
          Positioned(
            top: 55,
            left: 16,
            right: 16,
            child: Column(
              children: [
                TextFormField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                      hintText: 'Search for a place',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey,),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                if (_placePredictions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                      ),
                      child: ListView.builder(
                          itemCount: _placePredictions.length,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            final prediction = _placePredictions[index];
                            return ListTile(
                              title: Text(prediction.description ?? ''),
                              onTap: () {
                                _onPlaceSelected(prediction);
                              },
                            );
                          }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
