import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:places_autocomplete/src/blocs/application_bloc.dart';
import 'package:places_autocomplete/src/models/place.dart';
import 'package:provider/provider.dart';
import 'package:places_autocomplete/constant.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Completer<GoogleMapController> _mapController = Completer();
  StreamSubscription locationSubscription;
  StreamSubscription boundsSubscription;
  final _locationController = TextEditingController();

  @override
  void initState() {
    final applicationBloc =
        Provider.of<ApplicationBloc>(context, listen: false);

    //Listen for selected Location
    locationSubscription =
        applicationBloc.selectedLocation.stream.listen((place) {
      if (place != null) {
        _locationController.text = place.name;
        _goToPlace(place);
      } else
        _locationController.text = "";
    });

    applicationBloc.bounds.stream.listen((bounds) async {
      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    });
    super.initState();
  }

  @override
  void dispose() {
    final applicationBloc =
        Provider.of<ApplicationBloc>(context, listen: false);
    applicationBloc.dispose();
    _locationController.dispose();
    locationSubscription.cancel();
    boundsSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final applicationBloc = Provider.of<ApplicationBloc>(context);
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => exit(0),
          child: Icon(Icons.exit_to_app_outlined),
        ),
        body: (applicationBloc.currentLocation == null)
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Search by City',
                        hintStyle: TextStyle(
                          fontFamily: 'Aleg',
                          fontSize: 22.0,
                          letterSpacing: 0.7,
                          color: Colors.grey,
                        ),
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => applicationBloc.searchPlaces(value),
                      onTap: () => applicationBloc.clearSelectedLocation(),
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        height: 450.0,
                        child: GoogleMap(
                          mapType: MapType.normal,
                          myLocationEnabled: true,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                                applicationBloc.currentLocation.latitude,
                                applicationBloc.currentLocation.longitude),
                            zoom: 14,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController.complete(controller);
                          },
                          markers: Set<Marker>.of(applicationBloc.markers),
                        ),
                      ),
                      if (applicationBloc.searchResults != null &&
                          applicationBloc.searchResults.length != 0)
                        Container(
                            height: 450.0,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(.6),
                                backgroundBlendMode: BlendMode.darken)),
                      if (applicationBloc.searchResults != null)
                        Container(
                          height: 450.0,
                          child: ListView.builder(
                              itemCount: applicationBloc.searchResults.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(
                                    applicationBloc
                                        .searchResults[index].description,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onTap: () {
                                    applicationBloc.setSelectedLocation(
                                        applicationBloc
                                            .searchResults[index].placeId);
                                  },
                                );
                              }),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(
                      child: Text(
                        'FIND NEAREST',
                        style: TextStyle(
                          fontSize: 25.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Aleg',
                          letterSpacing: 0.9,
                          color: Colors.teal.shade900,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Center(
                      child: Wrap(
                        spacing: 15.0,
                        children: [
                          FilterChip(
                            label: Text('Restaurant',
                                style: kFliterChipDecoration),
                            onSelected: (val) => applicationBloc
                                .togglePlaceType('restaurant', val),
                            selected: applicationBloc.placeType == 'restaurant',
                            selectedColor: Colors.blue,
                          ),
                          FilterChip(
                              label:
                                  Text('School', style: kFliterChipDecoration),
                              onSelected: (val) => applicationBloc
                                  .togglePlaceType('school', val),
                              selected: applicationBloc.placeType == 'school',
                              selectedColor: Colors.blue),
                          FilterChip(
                              label: Text('Pharmacy',
                                  style: kFliterChipDecoration),
                              onSelected: (val) => applicationBloc
                                  .togglePlaceType('pharmacy', val),
                              selected: applicationBloc.placeType == 'pharmacy',
                              selectedColor: Colors.blue),
                          FilterChip(
                              label: Text('Pet Store',
                                  style: kFliterChipDecoration),
                              onSelected: (val) => applicationBloc
                                  .togglePlaceType('pet_store', val),
                              selected:
                                  applicationBloc.placeType == 'pet_store',
                              selectedColor: Colors.blue),
                          FilterChip(
                              label:
                                  Text('Lawyer', style: kFliterChipDecoration),
                              onSelected: (val) => applicationBloc
                                  .togglePlaceType('lawyer', val),
                              selected: applicationBloc.placeType == 'lawyer',
                              selectedColor: Colors.blue),
                          FilterChip(
                              label: Text('Bank', style: kFliterChipDecoration),
                              onSelected: (val) =>
                                  applicationBloc.togglePlaceType('bank', val),
                              selected: applicationBloc.placeType == 'bank',
                              selectedColor: Colors.blue),
                        ],
                      ),
                    ),
                  )
                ],
              ));
  }

  Future<void> _goToPlace(Place place) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(
                place.geometry.location.lat, place.geometry.location.lng),
            zoom: 14.0),
      ),
    );
  }
}
