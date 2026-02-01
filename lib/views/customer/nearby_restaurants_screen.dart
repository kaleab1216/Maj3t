import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/restaurant_model.dart';
import '../../services/restaurant_service.dart';
import '../../services/location_service.dart';
import '../../widgets/universal_image.dart';
import '../customer/menu_browser_screen.dart';

class NearbyRestaurantsScreen extends StatefulWidget {
  const NearbyRestaurantsScreen({super.key});

  @override
  State<NearbyRestaurantsScreen> createState() => _NearbyRestaurantsScreenState();
}

class _NearbyRestaurantsScreenState extends State<NearbyRestaurantsScreen> {
  final LocationService _locationService = LocationService();
  final RestaurantService _restaurantService = RestaurantService();
  
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<RestaurantWithDistance> _nearbyRestaurants = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  Restaurant? _selectedRestaurant;

  @override
  void initState() {
    super.initState();
    // Enable Hybrid Composition for Android to prevent native crashes during gestures
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _loadNearbyRestaurants();
  }

  @override
  void dispose() {
    // Do not manually dispose _mapController as it can cause native-side crashes
    super.dispose();
  }

  Future<void> _loadNearbyRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      if (position == null) {
        setState(() {
          _error = 'Unable to get your location. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _currentPosition = position);

      // Get all verified restaurants
      final restaurantsStream = _restaurantService.getAllRestaurants();
      final restaurants = await restaurantsStream.first;
      
      final verifiedRestaurants = restaurants
          .where((r) => r.verificationStatus == 'verified' && r.isActive)
          .toList();

      // Calculate distances and sort
      final restaurantsWithDistance = verifiedRestaurants
          .where((r) => r.latitude != null && r.longitude != null)
          .map((restaurant) {
            final distance = _locationService.calculateDistance(
              position.latitude,
              position.longitude,
              restaurant.latitude!,
              restaurant.longitude!,
            );
            return RestaurantWithDistance(restaurant, distance);
          })
          .toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));

      // Create markers
      final markers = <Marker>{};
      
      // User location marker
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      // Restaurant markers
      for (var item in restaurantsWithDistance) {
        final restaurant = item.restaurant;
        markers.add(
          Marker(
            markerId: MarkerId(restaurant.restaurantId),
            position: LatLng(restaurant.latitude!, restaurant.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: restaurant.name,
              snippet: '${_locationService.formatDistance(item.distance)} away • ⭐ ${restaurant.rating}',
            ),
            onTap: () {
              setState(() => _selectedRestaurant = restaurant);
            },
          ),
        );
      }

      setState(() {
        _nearbyRestaurants = restaurantsWithDistance;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading restaurants: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _buildMap(),
          
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),

          // Bottom sheet with restaurant list
          if (!_isLoading && _error == null && _nearbyRestaurants.isNotEmpty)
            _buildBottomSheet(),

          // Loading/Error overlay
          if (_isLoading || _error != null)
            _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_currentPosition == null) {
      return Container(color: const Color(0xFFF8F9FA));
    }

    return GoogleMap(
      key: const ValueKey('nearby_restaurants_map'),
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Nearby Restaurants',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadNearbyRestaurants,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDC3C7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '${_nearbyRestaurants.length} Restaurants Found',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _nearbyRestaurants.length,
                  itemBuilder: (context, index) {
                    return _buildRestaurantCard(_nearbyRestaurants[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestaurantCard(RestaurantWithDistance item) {
    final restaurant = item.restaurant;
    final distance = item.distance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedRestaurant?.restaurantId == restaurant.restaurantId
              ? const Color(0xFF9B59B6)
              : const Color(0xFFE0E0E0),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedRestaurant = restaurant);
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(restaurant.latitude!, restaurant.longitude!),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Restaurant Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                        ? UniversalImage(imageString: restaurant.imageUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.restaurant, color: Color(0xFF7F8C8D), size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C3E50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (restaurant.verificationStatus == 'verified')
                            const Icon(Icons.verified, size: 14, color: Color(0xFF2E8B57)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toString(),
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF9B59B6)),
                          const SizedBox(width: 4),
                          Text(
                            _locationService.formatDistance(distance),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9B59B6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerMenuScreen(
                          restaurantId: restaurant.restaurantId,
                          restaurantName: restaurant.name,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text('View', style: GoogleFonts.inter(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFF9B59B6))
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, size: 64, color: Color(0xFFBDC3C7)),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF7F8C8D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadNearbyRestaurants,
                      icon: const Icon(Icons.refresh),
                      label: Text('Try Again', style: GoogleFonts.inter()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B59B6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class RestaurantWithDistance {
  final Restaurant restaurant;
  final double distance;

  RestaurantWithDistance(this.restaurant, this.distance);
}
