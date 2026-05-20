import 'package:flutter/material.dart';

// ---------------------------------------------------------
// 1. DATA MODEL
// ---------------------------------------------------------
enum PackageStatus { pending, delivered, failed }

class PackageModel {
  final String id;
  final String customerName;
  final String address;
  final String instructions;
  PackageStatus status;

  PackageModel({
    required this.id,
    required this.customerName,
    required this.address,
    this.instructions = '',
    this.status = PackageStatus.pending,
  });
}

// ---------------------------------------------------------
// 2. INVENTORY PAGE
// ---------------------------------------------------------
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // Mock data representing the driver's truck load for the day
  final List<PackageModel> _manifest = [
    PackageModel(
      id: '#7620937',
      customerName: 'Ahmed R.',
      address: 'Route de Marrakech, Settat',
      instructions: 'Call upon arrival. Fragile.',
    ),
    PackageModel(
      id: '#7620938',
      customerName: 'Fatima Z.',
      address: 'Technopark, Casablanca',
      status: PackageStatus.delivered,
    ),
    PackageModel(
      id: '#7620939',
      customerName: 'Youssef B.',
      address: 'FSTS Campus, Settat',
      instructions: 'Leave at the main reception.',
    ),
  ];

  // Helper to count pending packages
  int get _pendingCount => 
      _manifest.where((p) => p.status == PackageStatus.pending).length;

  void _updateStatus(PackageModel package, PackageStatus newStatus) {
    setState(() {
      package.status = newStatus;
    });
    // TODO: Send API request to your Go (Gin) backend to update the database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 20),
            
            // Big Scanner Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildScanButton(),
            ),
            
            const SizedBox(height: 24),
            
            // Section Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Today\'s Manifest',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Scrollable List of Packages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 20, 
                  right: 20, 
                  bottom: 120, // Pad for the bottom nav bar
                ),
                itemCount: _manifest.length,
                itemBuilder: (context, index) {
                  return _buildPackageCard(_manifest[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_pendingCount packages remaining',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.sync, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Open QR Camera
        print("Opening Scanner...");
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Scan Package',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    final isDelivered = package.status == PackageStatus.delivered;
    final isFailed = package.status == PackageStatus.failed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDelivered 
              ? const Color(0xFF4CAF50).withOpacity(0.3) 
              : isFailed 
                  ? Colors.red.withOpacity(0.3)
                  : Colors.grey.shade200,
        ),
      ),
      child: Theme(
        // Removes the default divider lines from ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ${package.id}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              _buildStatusBadge(package.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              package.address,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Customer: ${package.customerName}', style: const TextStyle(fontWeight: FontWeight.w500)),
                  if (package.instructions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${package.instructions}',
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Action Buttons for the Driver
                  if (package.status == PackageStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(package, PackageStatus.delivered),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Mark Delivered'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(package, PackageStatus.failed),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Report Issue'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PackageStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case PackageStatus.delivered:
        bgColor = const Color(0xFFE2F6D1);
        textColor = const Color(0xFF2E7D32);
        label = 'Delivered';
        break;
      case PackageStatus.failed:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Failed';
        break;
      case PackageStatus.pending:
      default:
        bgColor = const Color(0xFFF0F1F5);
        textColor = Colors.black87;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}