import 'package:flutter/material.dart';

class DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final Function(int)? onRowTap;
  final List<DataColumnSortStatus>? sortStatus;
  final Function(int, bool)? onSort;

  const DataTableWidget({
    Key? key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.sortStatus,
    this.onSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _buildColumns(),
          rows: _buildRows(),
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          columnSpacing: 24,
          horizontalMargin: 16,
          headingRowHeight: 56,
          dataRowHeight: 52,
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return List.generate(columns.length, (index) {
      return DataColumn(
        label: Text(
          columns[index],
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        onSort: sortStatus != null && onSort != null
            ? (columnIndex, ascending) {
                onSort!(columnIndex, ascending);
              }
            : null,
        tooltip: columns[index],
        numeric: _isNumeric(columns[index]),
      );
    });
  }

  List<DataRow> _buildRows() {
    return List.generate(rows.length, (rowIndex) {
      return DataRow(
        cells: List.generate(rows[rowIndex].length, (cellIndex) {
          return DataCell(
            Text(rows[rowIndex][cellIndex]),
          );
        }),
        onSelectChanged: onRowTap != null
            ? (selected) {
                if (selected != null && selected) {
                  onRowTap!(rowIndex);
                }
              }
            : null,
      );
    });
  }

  bool _isNumeric(String str) {
    return ['id', 'count', 'total', 'amount', 'number', 'quantity']
        .any((element) => str.toLowerCase().contains(element));
  }
}

class DataColumnSortStatus {
  final int columnIndex;
  final bool ascending;

  DataColumnSortStatus({
    required this.columnIndex,
    required this.ascending,
  });
}