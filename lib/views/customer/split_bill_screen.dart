import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:maj3t/l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../models/split_request_model.dart';
import '../../services/split_service.dart';
import '../../view_models/auth_view_model.dart';
import 'package:share_plus/share_plus.dart';

class SplitBillScreen extends StatefulWidget {
  final Order order;
  const SplitBillScreen({super.key, required this.order});

  @override
  State<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen> {
  final SplitService _splitService = SplitService();
  int _numberOfPeople = 2;
  bool _isCreating = false;
  SplitRequest? _activeSplit;

  void _createSplit() async {
    setState(() => _isCreating = true);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    try {
      final split = await _splitService.createSplitRequest(
        orderId: widget.order.orderId,
        creatorId: authViewModel.currentUser?.userId ?? 'unknown',
        totalAmount: widget.order.totalAmount,
        numberOfPeople: _numberOfPeople,
      );
      setState(() {
        _activeSplit = split;
        _isCreating = false;
      });
    } catch (e) {
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _shareSplitLink() {
    if (_activeSplit == null) return;
    final amountPerPerson = _activeSplit!.totalAmount / _activeSplit!.participants.length;
    final text = 'Hey! Split the bill with me for ${widget.order.restaurantName}. Your share is ETB ${amountPerPerson.toStringAsFixed(2)}. Pay here: https://maj3t.app/pay/${_activeSplit!.id}';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.splitBill, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _activeSplit == null ? _buildSetupView() : _buildTrackingView(),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2E8B57).withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E8B57).withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.totalOrder, style: GoogleFonts.inter(color: Colors.grey[600])),
                    Text('ETB ${widget.order.totalAmount.toStringAsFixed(2)}', 
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(context)!.perPerson, style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[800])),
                    Text('ETB ${(widget.order.totalAmount / _numberOfPeople).toStringAsFixed(2)}', 
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2E8B57))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            AppLocalizations.of(context)!.splitHowMany,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.2),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountBtn(Icons.remove, () {
                if (_numberOfPeople > 2) setState(() => _numberOfPeople--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '$_numberOfPeople',
                  style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                ),
              ),
              _buildCountBtn(Icons.add, () {
                if (_numberOfPeople < 10) setState(() => _numberOfPeople++);
              }),
            ],
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createSplit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E8B57),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
              ),
              child: _isCreating 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(AppLocalizations.of(context)!.createSplitGroup, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingView() {
    return StreamBuilder<SplitRequest?>(
      stream: _splitService.streamSplitRequest(_activeSplit!.id),
      builder: (context, snapshot) {
        final split = snapshot.data ?? _activeSplit!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: CircularProgressIndicator(
                  value: split.paidAmount / split.totalAmount,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF2E8B57),
                  strokeWidth: 8,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ETB ${split.paidAmount.toStringAsFixed(0)} / ${split.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(AppLocalizations.of(context)!.totalPaid, style: GoogleFonts.inter(color: Colors.grey[600])),
              const SizedBox(height: 40),
              ...split.participants.map((p) => _buildParticipantTile(p)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _shareSplitLink,
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: Text(AppLocalizations.of(context)!.sharePaymentLink, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCountBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Icon(icon, color: const Color(0xFF2E8B57)),
      ),
    );
  }

  Widget _buildParticipantTile(SplitParticipant p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.isPaid ? const Color(0xFF2E8B57).withOpacity(0.2) : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: p.isPaid ? const Color(0xFFE8F5E9) : Colors.grey[100],
            child: Icon(p.isPaid ? Icons.check : Icons.person_outline, size: 20, color: p.isPaid ? const Color(0xFF2E8B57) : Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
                Text('ETB ${p.shareAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.isPaid ? const Color(0xFF2E8B57).withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              p.isPaid ? 'PAID' : 'PENDING',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: p.isPaid ? const Color(0xFF2E8B57) : Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
