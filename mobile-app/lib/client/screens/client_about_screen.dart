import 'package:flutter/material.dart';

class ClientAboutScreen extends StatelessWidget {
  const ClientAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('About Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Logo & Header
            Center(
              child: Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDarkMode)
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Image.asset(
                  'assets/premier.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'PT Premier Engineering Indonesia',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Leading Contractor & Supplier in Industrial Solutions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // About Section
            _buildSection(
              context: context,
              title: 'About Us',
              content:
                  'PT Premier Engineering Indonesia is a leading company in the field of contractors and suppliers of industrial solutions. Since its establishment in 2005, we have served various clients throughout Indonesia with a commitment to providing high-quality products and services.\n\nWe specialize in providing industrial equipment, automation systems, and innovative technical solutions for various industrial sectors including manufacturing, energy, and infrastructure.',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Vision Section
            _buildSection(
              context: context,
              title: 'Vision',
              content:
                  'To become a trusted and leading partner in providing high-quality, innovative, and sustainable engineering and industrial solutions to support the growth of Indonesian industry.',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Mission Section
            _buildSection(
              context: context,
              title: 'Mission',
              content:
                  '• Provide high-quality engineering products and services\n• Deliver innovative and efficient solutions for industrial needs\n• Build long-term relationships with clients based on trust and satisfaction\n• Develop competent and professional human resources\n• Commit to sustainable and responsible business practices',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Services Section
            _buildSection(
              context: context,
              title: 'Our Services',
              content:
                  '• Industrial Equipment Supply\n• Automation & Control Systems\n• Engineering Consultation\n• Installation & Maintenance\n• Technical Training & Support',
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Contact Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isDarkMode)
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Us',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: '+62 21 1234 5678',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'info@premier-engineering.co.id',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: 'Jl. Industri Raya No. 123\nJakarta Pusat, 10110\nIndonesia',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.language_outlined,
                    label: 'Website',
                    value: 'www.premier-engineering.co.id',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Text(
                '© ${DateTime.now().year} PT Premier Engineering Indonesia\nAll Rights Reserved',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white54 : const Color(0xFF94A3B8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3B82F6),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

