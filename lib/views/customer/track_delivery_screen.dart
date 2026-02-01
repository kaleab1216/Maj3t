import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../models/order_model.dart';
import '../../models/delivery_driver_model.dart';
import 'dart:async';

class TrackDeliveryScreen extends StatefulWidget {
  final String orderId;

  const TrackDeliveryScreen({super.key, required this.orderId});

  @override
  State<TrackDeliveryScreen> createState() => _TrackDeliveryScreenState();
}

class _TrackDeliveryScreenState extends State<TrackDeliveryScreen> {
  GoogleMapController? _mapController;
  Order? _order;
  DeliveryDriver? _driver;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  StreamSubscription? _orderSub;
  StreamSubscription? _driverSub;

  @override
  void initState() {
    super.initState();
    // Enable Hybrid Composition for Android
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
    _initTracking();
  }

  void _initTracking() {
    _orderSub = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((orderDoc) {
      if (orderDoc.exists) {
        final order = Order.fromMap(orderDoc.data() as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _order = order;
            _isLoading = false;
          });
          
          if (order.deliveryDriverId != null && _driverSub == null) {
            _startDriverTracking(order.deliveryDriverId!);
          }
           _updateMarkers();
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }, onError: (e) {
       if (mounted) {
          setState(() => _isLoading = false);
        }
    });
  }

  void _startDriverTracking(String driverId) {
    _driverSub = FirebaseFirestore.instance
        .collection('delivery_drivers')
        .doc(driverId)
        .snapshots()
        .listen((driverDoc) {
      if (driverDoc.exists && mounted) {
        final driver = DeliveryDriver.fromMap(driverDoc.data() as Map<String, dynamic>);
        setState(() {
          _driver = driver;
        });
        _updateMarkers();
        
        if (_mapController != null && driver.currentLatitude != null && driver.currentLongitude != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(LatLng(driver.currentLatitude!, driver.currentLongitude!)),
          );
        }
      }
    });
  }

  void _updateMarkers() {
    final order = _order;
    if (order == null) return;
    final markers = <Marker>{};

    // My Location
    if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(order.deliveryLatitude!, order.deliveryLongitude!),
        icon: BitmapDescriptor.defaultMarker,
      ));
    }

    // Driver Location
    final driver = _driver;
    if (driver != null && driver.currentLatitude != null && driver.currentLongitude != null) {
       markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driver.currentLatitude!, driver.currentLongitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    setState(() => _markers = markers);
  }

  @override
  void dispose() {
    _orderSub?.cancel();
    _driverSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57))));

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          _buildStatusPanel(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final order = _order;
    if (order == null || order.deliveryLatitude == null || order.deliveryLongitude == null) {
      return const Center(child: Text('Location data not available'));
    }

    return GoogleMap(
      key: const ValueKey('track_delivery_map'),
      initialCameraPosition: CameraPosition(
        target: LatLng(order.deliveryLatitude!, order.deliveryLongitude!),
        zoom: 15,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (controller) => _mapController = controller,
    );
  }

  Widget _buildStatusPanel() {
    final order = _order;
    if (order == null) return const SizedBox.shrink();
    
    final status = order.deliveryStatus ?? 'pending';
    final driver = _driver;

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2E8B57)),
                ),
                const Icon(Icons.delivery_dining, color: Color(0xFF2E8B57)),
              ],
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(value: 0.5, backgroundColor: Color(0xFFE8F5E9), valueColor: AlwaysStoppedAnimation(Color(0xFF2E8B57))),
            const SizedBox(height: 20),
            if (driver != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person)),
                title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${driver.vehicleType} • ${driver.vehicleNumber}'),
                trailing: IconButton(icon: const Icon(Icons.phone, color: Color(0xFF2E8B57)), onPressed: () {}),
              ),
            ] else 
              Text(
                'Waiting for driver assignment...',
                style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}
