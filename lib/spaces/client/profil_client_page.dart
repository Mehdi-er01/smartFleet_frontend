import 'package:flutter/material.dart';
import 'package:smartfleet_frontend/dto/user_dto.dart';
import 'package:smartfleet_frontend/login_page.dart';
import 'package:smartfleet_frontend/service/storage_service.dart';

class ProfilClientPage extends StatelessWidget {
  final UserDto? currentUser;
  const ProfilClientPage({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header label ──
              Text(
                'PROFILE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              const Text('My Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black)),
              const SizedBox(height: 24),

              // ── Identity card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFF0F1F5),
                        child: Icon(Icons.person, size: 30, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.name ?? 'Guest',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            currentUser?.email ?? '—',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (currentUser?.phone != null && currentUser!.phone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              currentUser!.phone!,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        currentUser?.role.name ?? 'CLIENT',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Account section ──
              _sectionLabel('Account Settings'),
              const SizedBox(height: 10),
              _settingsGroup([
                _SettingsItem(icon: Icons.person_outline, label: 'Personal Information'),
                _SettingsItem(icon: Icons.location_on_outlined, label: 'Saved Addresses'),
                _SettingsItem(icon: Icons.payment_outlined, label: 'Payment Methods'),
              ]),

              const SizedBox(height: 20),

              // ── Preferences section ──
              _sectionLabel('Preferences'),
              const SizedBox(height: 10),
              _settingsGroup([
                _SettingsItem(icon: Icons.notifications_outlined, label: 'Notifications'),
                _SettingsItem(icon: Icons.language_outlined, label: 'Language'),
              ]),

              const SizedBox(height: 20),

              // ── Support section ──
              _sectionLabel('Support'),
              const SizedBox(height: 10),
              _settingsGroup([
                _SettingsItem(icon: Icons.help_outline, label: 'Help Center'),
                _SettingsItem(icon: Icons.policy_outlined, label: 'Privacy Policy'),
              ]),

              const SizedBox(height: 24),

              // ── Logout ──
              GestureDetector(
                onTap: () async {
                  await StorageService.deleteToken();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                      (route) => false,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.black87, size: 20),
                      SizedBox(width: 10),
                      Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _settingsGroup(List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: Colors.black87, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.black38),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF0F1F5)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  const _SettingsItem({required this.icon, required this.label});
}