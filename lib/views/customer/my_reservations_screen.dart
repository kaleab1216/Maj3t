import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/reservation_model.dart';
import '../../view_models/reservation_view_model.dart';
import '../../view_models/auth_view_model.dart';
import 'package:maj3t/l10n/app_localizations.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservations();
    });
  }

  void _loadReservations() {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final reservationViewModel = Provider.of<ReservationViewModel>(context, listen: false);

    if (authViewModel.currentUser != null) {
      reservationViewModel.loadCustomerReservations(authViewModel.currentUser!.userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservationViewModel = Provider.of<ReservationViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myReservations,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E8B57)),
            onPressed: _loadReservations,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              labelColor: const Color(0xFF2E8B57),
              unselectedLabelColor: const Color(0xFF7F8C8D),
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              tabs: [
                Tab(text: AppLocalizations.of(context)!.upcoming),
                Tab(text: AppLocalizations.of(context)!.history),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsList(reservationViewModel, isUpcoming: true),
          _buildReservationsList(reservationViewModel, isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildReservationsList(ReservationViewModel viewModel, {required bool isUpcoming}) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)));
    }

    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!, style: GoogleFonts.inter(color: Colors.red)));
    }

    List<Reservation> filteredReservations;
    if (isUpcoming) {
      filteredReservations = viewModel.upcomingReservations;
    } else {
      filteredReservations = viewModel.reservations
          .where((r) => !r.isUpcoming && r.status != 'cancelled')
          .toList();
    }

    if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today_outlined : Icons.history_edu_outlined,
              size: 60,
              color: const Color(0xFFBDC3C7),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? AppLocalizations.of(context)!.noUpcomingBookings : AppLocalizations.of(context)!.noPastReservations,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7F8C8D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcoming 
                  ? AppLocalizations.of(context)!.planNextDining
                  : AppLocalizations.of(context)!.diningHistory,
              style: GoogleFonts.inter(color: const Color(0xFF95A5A6)),
            ),
             if (isUpcoming) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.findTable, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = filteredReservations[index];
        return _buildReservationCard(reservation, viewModel);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation, ReservationViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                         DateFormat('MMM').format(reservation.reservationDate).toUpperCase(),
                         style: GoogleFonts.inter(
                           fontSize: 12,
                           fontWeight: FontWeight.bold,
                           color: const Color(0xFF2E8B57),
                         ),
                      ),
                      Text(
                        DateFormat('dd').format(reservation.reservationDate),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.restaurantName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            reservation.formattedTime,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF7F8C8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${reservation.partySize} ${AppLocalizations.of(context)!.guests}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF7F8C8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (reservation.isUpcoming && reservation.status != 'cancelled')
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F2F6))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showCancelDialog(reservation, viewModel),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(AppLocalizations.of(context)!.cancel, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Container(width: 1, height: 24, color: const Color(0xFFF1F2F6)),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _showReservationDetails(reservation),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E8B57),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(AppLocalizations.of(context)!.viewDetails, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showReservationDetails(Reservation reservation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.reservationDetails,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(AppLocalizations.of(context)!.status, reservation.statusText),
              _buildDetailRow(AppLocalizations.of(context)!.table, reservation.tableNumber != null ? '${AppLocalizations.of(context)!.table} ${reservation.tableNumber}' : AppLocalizations.of(context)!.pendingAssignment),
              if (reservation.specialRequests?.isNotEmpty ?? false)
                _buildDetailRow(AppLocalizations.of(context)!.note, reservation.specialRequests!),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E8B57)),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(Reservation reservation, ReservationViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cancelReservation, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.confirmCancel),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.no)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.yesCancel, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await viewModel.cancelReservation(reservationId: reservation.reservationId);
    }
  }
}