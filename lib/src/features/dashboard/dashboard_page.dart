import 'package:flutter/material.dart';
import 'package:gbcc_connect_app/src/core/constants/constants.dart';
import 'package:provider/provider.dart';
import '../../core/models/user.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/service_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class DashboardPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;

  const DashboardPage({
    super.key,
    required this.user,
    required this.serviceManager,
  });

  static const routeName = AppRoutes.dashboard;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  int _contacts = 0;
  int _unreadMessageCount = 0;
  bool _isLoadingStats = false;
  Stream<int>? _unreadMessagesStream;
  Stream<int>? _contactsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      _setupRealTimeListeners();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh stats when app becomes visible
    if (state == AppLifecycleState.resumed) {
      _loadStats();
    }
  }

  void _setupRealTimeListeners() {
    debugPrint('Dashboard: Setting up real-time listeners');
    // Set up real-time listener for unread messages
    _unreadMessagesStream = _getUnreadMessagesStream();
    // Set up real-time listener for contacts count
    _contactsStream = _getContactsStream();
    // Get initial counts as fallback
    _getInitialUnreadCount();
    _getInitialContactsCount();
  }

  Stream<int> _getUnreadMessagesStream() {
    debugPrint(
        'Dashboard: Creating unread messages stream for user: ${widget.user.email}');
    // Create a stream that listens to message status changes
    return widget.serviceManager.messageService
        .streamUnreadMessageCount(widget.user.email);
  }

  Stream<int> _getContactsStream() {
    debugPrint(
        'Dashboard: Creating contacts stream for user: ${widget.user.id}');
    // Create a stream that listens to contact changes
    return widget.serviceManager.contactService
        .streamContactCount(widget.user.id);
  }

  Future<void> _getInitialUnreadCount() async {
    try {
      debugPrint(
          'Dashboard: Getting initial unread count for user: ${widget.user.email}');
      final initialCount = await widget.serviceManager.messageService
          .getInitialUnreadCount(widget.user.email);
      debugPrint('Dashboard: Initial unread count: $initialCount');
      if (mounted) {
        setState(() {
          _unreadMessageCount = initialCount;
        });
      }
    } catch (e) {
      debugPrint('Dashboard: Error getting initial unread count: $e');
    }
  }

  Future<void> _getInitialContactsCount() async {
    try {
      debugPrint(
          'Dashboard: Getting initial contacts count for user: ${widget.user.id}');
      final initialCount = await widget.serviceManager.contactService
          .getInitialContactCount(widget.user.id);
      debugPrint('Dashboard: Initial contacts count: $initialCount');
      if (mounted) {
        setState(() {
          _contacts = initialCount;
        });
      }
    } catch (e) {
      debugPrint('Dashboard: Error getting initial contacts count: $e');
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      // Load contacts count (this doesn't change frequently, so no need for real-time)
      final contactsCount = await _getContacts().catchError((e) {
        return 0;
      });

      // Also refresh unread count for pull-to-refresh
      final unreadCount = await widget.serviceManager.messageService
          .getInitialUnreadCount(widget.user.email)
          .catchError((e) {
        return _unreadMessageCount; // Keep current value on error
      });

      // Also refresh contacts count for pull-to-refresh
      final refreshedContactsCount = await widget.serviceManager.contactService
          .getInitialContactCount(widget.user.id)
          .catchError((e) {
        return _contacts; // Keep current value on error
      });

      if (mounted) {
        setState(() {
          _contacts = refreshedContactsCount;
          _unreadMessageCount = unreadCount;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard: Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<int> _getContacts() async {
    final stats = await widget.serviceManager.contactService
        .getContactStats(widget.user.id);
    return stats['total'] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppConstants.appName),
          backgroundColor: MyApp.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                }
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                _buildWelcomeSection(widget.user),
                SizedBox(height: 24),

                // Stats cards
                _buildStatsSection(),
                SizedBox(height: 24),

                // Quick actions
                _buildQuickActionsSection(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 0,
          selectedItemColor: MyApp.primaryColor,
          unselectedItemColor: Colors.grey[600],
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 1:
                Navigator.of(context).pushNamed(AppRoutes.contactLibrary);
                break;
              case 2:
                Navigator.of(context).pushNamed(AppRoutes.conversations);
                break;
              case 3:
                Navigator.of(context).pushNamed(AppRoutes.profile);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(User user) {
    final displayName =
        user.displayName ?? user.name ?? AppConstants.defaultDisplayName;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyApp.primaryColor, MyApp.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MyApp.primaryColor,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildContactsCard(),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildUnreadMessagesCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactsCard() {
    if (_contactsStream == null) {
      debugPrint(
          'Dashboard: Contacts stream is null, using fallback count: $_contacts');
      return _buildStatCard(
        'Total Contacts',
        _contacts.toString(),
        Icons.people,
        MyApp.primaryColor,
      );
    }

    return StreamBuilder<int>(
      stream: _contactsStream,
      builder: (context, snapshot) {
        int contactsCount = 0;
        bool isLoading = false;

        if (snapshot.hasData) {
          contactsCount = snapshot.data!;
          debugPrint(
              'Dashboard: Contacts stream received data - count: $contactsCount');
        } else if (snapshot.hasError) {
          contactsCount = _contacts; // Fallback to previous value
          debugPrint(
              'Dashboard: Contacts stream error - using fallback count: $contactsCount');
        } else {
          isLoading = true;
          debugPrint('Dashboard: Contacts stream loading...');
        }

        return _buildStatCard(
          'Total Contacts',
          contactsCount.toString(),
          Icons.people,
          MyApp.primaryColor,
          isLoading: isLoading,
        );
      },
    );
  }

  Widget _buildUnreadMessagesCard() {
    if (_unreadMessagesStream == null) {
      debugPrint(
          'Dashboard: Stream is null, using fallback count: $_unreadMessageCount');
      return _buildStatCard(
        'New Messages',
        _unreadMessageCount.toString(),
        Icons.mark_email_unread,
        Colors.green,
        isFullWidth: true,
      );
    }

    return StreamBuilder<int>(
      stream: _unreadMessagesStream,
      builder: (context, snapshot) {
        int unreadCount = 0;
        bool isLoading = false;

        if (snapshot.hasData) {
          unreadCount = snapshot.data!;
          debugPrint(
              'Dashboard: Stream received data - unread count: $unreadCount');
        } else if (snapshot.hasError) {
          unreadCount = _unreadMessageCount; // Fallback to previous value
          debugPrint(
              'Dashboard: Stream error - using fallback count: $unreadCount');
        } else {
          isLoading = true;
          debugPrint('Dashboard: Stream loading...');
        }

        return _buildStatCard(
          'New Messages',
          unreadCount.toString(),
          Icons.mark_email_unread,
          Colors.green,
          isFullWidth: true,
          isLoading: isLoading,
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool isFullWidth = false, bool isLoading = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              if (_isLoadingStats || isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Contact',
                Icons.person_add,
                MyApp.primaryColor,
                () => Navigator.of(context).pushNamed(AppRoutes.addContact),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Share QR',
                Icons.qr_code_scanner,
                Colors.green,
                () => Navigator.of(context).pushNamed(AppRoutes.qrCode),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'New Chat',
                Icons.chat_bubble_outline,
                Colors.orange,
                () => Navigator.of(context).pushNamed(AppRoutes.conversations),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
