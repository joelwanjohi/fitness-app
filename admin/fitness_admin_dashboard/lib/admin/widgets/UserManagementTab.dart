import 'package:fitness_admin_dashboard/admin/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class UserManagementTab extends StatefulWidget {
  final List<AppUser> users;
  final Function(String, UserStatus) onStatusChanged;
  final Function(String, bool) onAdminToggled;
  final Function(String) onUserDeleted;
  
  const UserManagementTab({
    Key? key,
    required this.users,
    required this.onStatusChanged,
    required this.onAdminToggled,
    required this.onUserDeleted,
  }) : super(key: key);
  
  @override
  _UserManagementTabState createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  List<AppUser> _filteredUsers = [];
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortField = 'activity';
  bool _sortAscending = false;
  
  @override
  void initState() {
    super.initState();
    _filteredUsers = List.from(widget.users);
    _sortUsers();
  }
  
  @override
  void didUpdateWidget(UserManagementTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.users != oldWidget.users) {
      _applyFilters();
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredUsers = widget.users.where((user) {
        // Apply status filter
        if (_filterStatus != 'All') {
          final statusString = user.status.toString().split('.').last;
          if (statusString.toLowerCase() != _filterStatus.toLowerCase()) {
            return false;
          }
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        
        return true;
      }).toList();
      
      _sortUsers();
    });
  }
  
  void _sortUsers() {
    setState(() {
      switch (_sortField) {
        case 'name':
          _filteredUsers.sort((a, b) => _sortAscending
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name));
          break;
        case 'email':
          _filteredUsers.sort((a, b) => _sortAscending
              ? a.email.compareTo(b.email)
              : b.email.compareTo(a.email));
          break;
        case 'status':
          _filteredUsers.sort((a, b) => _sortAscending
              ? a.status.toString().compareTo(b.status.toString())
              : b.status.toString().compareTo(a.status.toString()));
          break;
        case 'created':
          _filteredUsers.sort((a, b) => _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt));
          break;
        case 'lastActive':
          _filteredUsers.sort((a, b) {
            if (a.lastLoginAt == null && b.lastLoginAt == null) return 0;
            if (a.lastLoginAt == null) return _sortAscending ? -1 : 1;
            if (b.lastLoginAt == null) return _sortAscending ? 1 : -1;
            return _sortAscending
                ? a.lastLoginAt!.compareTo(b.lastLoginAt!)
                : b.lastLoginAt!.compareTo(a.lastLoginAt!);
          });
          break;
        case 'activity':
        default:
          _filteredUsers.sort((a, b) => _sortAscending
              ? a.totalActivity.compareTo(b.totalActivity)
              : b.totalActivity.compareTo(a.totalActivity));
          break;
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _filterStatus,
                    items: ['All', 'Active', 'Inactive', 'Blocked']
                        .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value ?? 'All';
                        _applyFilters();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Divider(height: 1),
        
        // Table header
        Container(
          color: Colors.grey[100],
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              _buildSortableHeader('Name', 'name', flex: 2),
              _buildSortableHeader('Email', 'email', flex: 2),
              _buildSortableHeader('Status', 'status'),
              _buildSortableHeader('Created', 'created'),
              _buildSortableHeader('Last Active', 'lastActive', flex: 2),
              _buildSortableHeader('Activity', 'activity'),
              SizedBox(width: 100, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        
        Divider(height: 1),
        
        // User list
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    _searchQuery.isNotEmpty || _filterStatus != 'All'
                        ? 'No users match your filters'
                        : 'No users found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredUsers.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserRow(user);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSortableHeader(String title, String field, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortField == field) {
              _sortAscending = !_sortAscending;
            } else {
              _sortField = field;
              _sortAscending = false;
            }
            _sortUsers();
          });
        },
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_sortField == field)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserRow(AppUser user) {
    final statusColor = user.status == UserStatus.active
        ? Colors.green
        : user.status == UserStatus.inactive
            ? Colors.orange
            : Colors.red;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              user.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(user.email),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.status.toString().split('.').last,
                style: TextStyle(color: statusColor),
              ),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('MM/dd/yyyy').format(user.createdAt),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.lastLoginAt != null
                  ? DateFormat('MM/dd/yyyy h:mm a').format(user.lastLoginAt!)
                  : 'Never',
            ),
          ),
          Expanded(
            child: Text(
              user.totalActivity.toString(),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showUserEditDialog(user),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(user),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showUserEditDialog(AppUser user) async {
    UserStatus newStatus = user.status;
    bool isAdmin = user.isAdmin;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit User: ${user.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user.email}'),
                  SizedBox(height: 16),
                  Text('Status:'),
                  DropdownButton<UserStatus>(
                    value: newStatus,
                    isExpanded: true,
                    items: UserStatus.values
                        .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toString().split('.').last),
                        ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          newStatus = value;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Admin Privileges:'),
                      Spacer(),
                      Switch(
                        value: isAdmin,
                        onChanged: (value) {
                          setState(() {
                            isAdmin = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    // Update status if changed
                    if (newStatus != user.status) {
                      widget.onStatusChanged(user.id, newStatus);
                    }
                    
                    // Update admin status if changed
                    if (isAdmin != user.isAdmin) {
                      widget.onAdminToggled(user.id, isAdmin);
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _showDeleteConfirmation(AppUser user) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this user?'),
              SizedBox(height: 16),
              Text('Name: ${user.name}'),
              Text('Email: ${user.email}'),
              SizedBox(height: 16),
              Text(
                'This action cannot be undone.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onUserDeleted(user.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}