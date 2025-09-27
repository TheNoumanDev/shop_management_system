import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../models/category_model.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  CategoryType _selectedType = CategoryType.product;
  String _selectedColor = Category.defaultColors.first;
  String? _selectedIcon;
  bool _showAddForm = false;
  String _searchQuery = '';
  CategoryType? _filterType;
  Category? _editingCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => setState(() {
              _showAddForm = !_showAddForm;
              if (!_showAddForm) _cancelForm();
            }),
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            tooltip: _showAddForm ? 'Cancel' : 'Add Category',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_defaults',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Add Default Categories'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'add_defaults') {
                context.read<CategoryProvider>().addDefaultCategories();
              }
            },
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Stats and Controls Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Categories',
                            '${provider.categories.length}',
                            Colors.blue,
                            Icons.category,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Product Categories',
                            '${provider.productCategories.length}',
                            Colors.green,
                            Icons.inventory_2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Service Categories',
                            '${provider.serviceCategories.length}',
                            Colors.purple,
                            Icons.build,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Expense Categories',
                            '${provider.expenseCategories.length}',
                            Colors.red,
                            Icons.receipt_long,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search and Filter
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search categories...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<CategoryType?>(
                            value: _filterType,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Type',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Types')),
                              ...CategoryType.values.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getTypeDisplayName(type)),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filterType = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Add/Edit Category Form
              if (_showAddForm) _buildCategoryForm(),

              // Category List
              Expanded(
                child: _buildCategoryList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingCategory == null ? 'Add New Category' : 'Edit Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // First Row: Name and Type
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Name is required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<CategoryType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: CategoryType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getTypeIcon(type), size: 20),
                            const SizedBox(width: 8),
                            Text(_getTypeDisplayName(type)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? CategoryType.product;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Second Row: Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Third Row: Color Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Category.defaultColors.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: _cancelForm,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _submitCategory,
                  icon: Icon(_editingCategory == null ? Icons.add : Icons.save),
                  label: Text(_editingCategory == null ? 'Add Category' : 'Update Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

  Widget _buildCategoryList(CategoryProvider provider) {
    final filteredCategories = _getFilteredCategories(provider);

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No categories found matching "$_searchQuery"'
                  : 'No categories yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Add your first category using the + button above'),
          ],
        ),
      );
    }

    // Group categories by type
    final groupedCategories = <CategoryType, List<Category>>{};
    for (final category in filteredCategories) {
      groupedCategories.putIfAbsent(category.type, () => []).add(category);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedCategories.length,
      itemBuilder: (context, groupIndex) {
        final type = groupedCategories.keys.elementAt(groupIndex);
        final categories = groupedCategories[type]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (groupIndex > 0) const SizedBox(height: 16),
            // Group Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getTypeIcon(type), color: _getTypeColor(type)),
                  const SizedBox(width: 8),
                  Text(
                    _getTypeDisplayName(type),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(type),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${categories.length} categories',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Categories in this group
            ...categories.map((category) => _buildCategoryCard(category)),
          ],
        );
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.colorValue),
          child: Icon(
            _getTypeIcon(category.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: category.description?.isNotEmpty ?? false
            ? Text(category.description!)
            : Text('${category.typeDisplayName} • Created ${_formatDate(category.createdAt)}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editCategory(category);
                break;
              case 'delete':
                _showDeleteConfirmation(category);
                break;
            }
          },
        ),
      ),
    );
  }

  List<Category> _getFilteredCategories(CategoryProvider provider) {
    List<Category> categories = provider.categories;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      categories = provider.searchCategories(_searchQuery);
    }

    // Apply type filter
    if (_filterType != null) {
      categories = categories.where((c) => c.type == _filterType).toList();
    }

    return categories;
  }

  String _getTypeDisplayName(CategoryType type) {
    switch (type) {
      case CategoryType.product:
        return 'Product';
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.service:
        return 'Service';
      case CategoryType.general:
        return 'General';
    }
  }

  IconData _getTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.product:
        return Icons.inventory_2;
      case CategoryType.expense:
        return Icons.receipt_long;
      case CategoryType.service:
        return Icons.build;
      case CategoryType.general:
        return Icons.category;
    }
  }

  Color _getTypeColor(CategoryType type) {
    switch (type) {
      case CategoryType.product:
        return Colors.green;
      case CategoryType.expense:
        return Colors.red;
      case CategoryType.service:
        return Colors.purple;
      case CategoryType.general:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _editCategory(Category category) {
    setState(() {
      _editingCategory = category;
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _selectedType = category.type;
      _selectedColor = category.color;
      _selectedIcon = category.icon;
      _showAddForm = true;
    });
  }

  void _submitCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final category = Category(
      id: _editingCategory?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      color: _selectedColor,
      icon: _selectedIcon,
      createdAt: _editingCategory?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = context.read<CategoryProvider>();
    final success = _editingCategory == null
        ? await provider.addCategory(category)
        : await provider.updateCategory(category);

    if (success && mounted) {
      _cancelForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "${category.name}" ${_editingCategory == null ? 'added' : 'updated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to ${_editingCategory == null ? 'add' : 'update'} category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelForm() {
    setState(() {
      _showAddForm = false;
      _editingCategory = null;
    });
    _clearForm();
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _selectedType = CategoryType.product;
    _selectedColor = Category.defaultColors.first;
    _selectedIcon = null;
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final provider = context.read<CategoryProvider>();
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              final success = await provider.deleteCategory(category.id);
              if (success && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Category deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}