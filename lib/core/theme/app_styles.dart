import 'package:flutter/material.dart';

/// Consistent styling constants for the entire app
class AppStyles {
  // Section Headers
  static TextStyle sectionHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  // Section Header Icon
  static Color sectionHeaderIconColor = Colors.white;

  // Table Headers
  static TextStyle tableHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }

  // Table Header Background
  static Color tableHeaderBackgroundColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  // Table Row Background (alternating)
  static Color tableRowBackgroundColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  // Filter Chip Styling
  static ChipThemeData filterChipTheme(BuildContext context) {
    return ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      secondarySelectedColor: Theme.of(context).primaryColor,
      brightness: Theme.of(context).brightness,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  // Selected Filter Chip Text Style
  static TextStyle selectedFilterChipTextStyle(BuildContext context) {
    return const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
  }

  // Unselected Filter Chip Text Style
  static TextStyle unselectedFilterChipTextStyle(BuildContext context) {
    return TextStyle(
      color: Colors.grey.shade700,
      fontWeight: FontWeight.w500,
    );
  }

  // Card Header Decoration
  static BoxDecoration cardHeaderDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).primaryColor.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
    );
  }

  // Form Card Decoration
  static BoxDecoration formCardDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor.withValues(alpha: 0.05),
          Theme.of(context).primaryColor.withValues(alpha: 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border(
        bottom: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }

  // Standard Form Field Decoration
  static InputDecoration standardInputDecoration(String labelText, {String? prefixText}) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      prefixText: prefixText,
    );
  }

  // DataTable Theme
  static DataTableThemeData dataTableTheme(BuildContext context) {
    return DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(tableHeaderBackgroundColor(context)),
      headingTextStyle: tableHeaderStyle(context),
      dataRowMaxHeight: 72,
      dataRowMinHeight: 56,
      columnSpacing: 16,
      horizontalMargin: 12,
    );
  }

  // Standard DataColumn
  static DataColumn standardDataColumn(BuildContext context, String text) {
    return DataColumn(
      label: Text(
        text,
        style: tableHeaderStyle(context),
      ),
    );
  }

  // Actions DataColumn
  static DataColumn actionsDataColumn(BuildContext context) {
    return DataColumn(
      label: Text(
        'Actions',
        style: tableHeaderStyle(context),
      ),
      numeric: false,
    );
  }

  // Standard Action Button Constraints
  static const BoxConstraints actionButtonConstraints = BoxConstraints(
    minWidth: 40,
    minHeight: 40,
  );

  // Action Button Row with proper constraints
  static Widget actionButtonRow({
    required List<Widget> children,
    double minWidth = 120,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  // Standard Edit Button
  static Widget editButton({
    required VoidCallback onPressed,
    String tooltip = 'Edit',
  }) {
    return IconButton(
      icon: const Icon(Icons.edit, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: actionButtonConstraints,
    );
  }

  // Standard Delete Button
  static Widget deleteButton({
    required VoidCallback onPressed,
    String tooltip = 'Delete',
  }) {
    return IconButton(
      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: actionButtonConstraints,
    );
  }

  // Standard View Button
  static Widget viewButton({
    required VoidCallback onPressed,
    String tooltip = 'View Details',
  }) {
    return IconButton(
      icon: const Icon(Icons.visibility, size: 18),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: actionButtonConstraints,
    );
  }

  // Responsive table constraints
  static BoxConstraints responsiveTableConstraints(BuildContext context) {
    return BoxConstraints(
      minWidth: MediaQuery.of(context).size.width - 32,
    );
  }

  // Standard table wrapper
  static Widget responsiveTable({
    required BuildContext context,
    required DataTable dataTable,
  }) {
    return Card(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: responsiveTableConstraints(context),
            child: dataTable,
          ),
        ),
      ),
    );
  }

  // Standard section header with icon
  static Widget sectionHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: sectionHeaderIconColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: sectionHeaderStyle(context),
          ),
        ],
      ),
    );
  }

  // Standard form card with header
  static Widget formCardWithHeader({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: formCardDecoration(context),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            sectionHeader(
              context: context,
              title: title,
              icon: icon,
              backgroundColor: backgroundColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // Category filter chips with proper theming
  static Widget categoryFilterChips({
    required BuildContext context,
    required List<String> categories,
    required String selectedCategory,
    required Function(String) onCategorySelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                category,
                style: isSelected
                    ? selectedFilterChipTextStyle(context)
                    : unselectedFilterChipTextStyle(context),
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
              backgroundColor: Colors.grey.shade200,
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}