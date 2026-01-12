import 'package:flutter/material.dart';

class _CompanyCardDialog extends StatefulWidget {
  @override
  State<_CompanyCardDialog> createState() => _CompanyCardDialogState();
}

class _CompanyCardDialogState extends State<_CompanyCardDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _printCard() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print feature coming soon'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        height: 400,
        child: Column(
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Company Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Card pages
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate card size based on available space
                    // Standard business card: 85.6mm x 53.98mm (ratio: 1.586)
                    double maxWidth =
                        constraints.maxWidth * 0.9; // 90% of available width
                    double cardWidth =
                        maxWidth > 320 ? 320 : maxWidth; // Max 320px width
                    double cardHeight =
                        cardWidth / (85.6 / 53.98); // Maintain aspect ratio

                    return SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          _buildCardFront(),
                          _buildCardBack(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0),
                SizedBox(width: 8),
                _buildPageIndicator(1),
              ],
            ),
            SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_currentPage == 0) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: Icon(_currentPage == 0
                      ? Icons.arrow_forward
                      : Icons.arrow_back),
                  label: Text(_currentPage == 0 ? 'Back Side' : 'Front Side'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _printCard,
                  icon: Icon(Icons.print),
                  label: Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1B48),
            Color(0xFF1A237E),
            Color(0xFF283593),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/premier.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PT Premier Engineering Indonesia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Since 2005',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Leading Contractor & Supplier in Industrial Solutions',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildContactChip(
                  icon: Icons.phone_outlined,
                  text: '+62 21 1234 5678',
                ),
                _buildContactChip(
                  icon: Icons.email_outlined,
                  text: 'info@premier-engineering.co.id',
                ),
                _buildContactChip(
                  icon: Icons.location_on_outlined,
                  text: 'Jakarta, Indonesia',
                ),
                _buildContactChip(
                  icon: Icons.language_outlined,
                  text: 'www.premier-engineering.co.id',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 12,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1B48),
            Color(0xFF1A237E),
            Color(0xFF283593),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo di tengah
          Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/premier.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'PT Premier Engineering Indonesia is a leading contractor and supplier specializing in industrial solutions. With over 18 years of experience since 2005, we provide comprehensive engineering services and high-quality industrial products to meet your business needs.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 9,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.business_outlined,
                  color: Colors.white.withOpacity(0.9),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Committed to Excellence in Industrial Solutions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
