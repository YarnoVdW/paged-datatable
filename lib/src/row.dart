part of 'paged_datatable.dart';

abstract class _RowBuilder<K extends Comparable<K>, T> extends StatefulWidget {
  final int index;

  const _RowBuilder({required this.index, super.key});

  @override
  State<StatefulWidget> createState() => _RowBuilderState<K, T>();

  List<Widget> buildColumns(
    BuildContext context,
    int index,
    PagedDataTableController<K, T> controller,
    PagedDataTableThemeData theme,
    bool isExpandedRow,
  );
}

class _RowBuilderState<K extends Comparable<K>, T> extends State<_RowBuilder<K, T>> with SingleTickerProviderStateMixin {
  late final controller = TableControllerProvider.of<K, T>(context);
  late final theme = PagedDataTableTheme.of(context);
  late AnimationController expandController;
  late Animation<double> animation;
  late bool isExpansible;
  bool selected = false;
  bool expanded = false;

  @override
  void initState() {
    super.initState();

    expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    final Animation<double> curve = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
    animation = Tween(begin: 0.0, end: 1.0).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    controller.addRowChangeListener(widget.index, _onRowChanged);
    setState(() {
      selected = controller._selectedRows.contains(widget.index);
      expanded = controller._expandedRows.contains(widget.index);
      isExpansible = controller._expansibleRows.containsKey(widget.index);
    });
  }

  @override
  void didUpdateWidget(covariant _RowBuilder<K, T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (expanded) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      children: widget.buildColumns(context, widget.index, controller, theme, false),
    );
    var color = theme.rowColor?.call(widget.index);
    if (selected && theme.selectedRow != null) {
      color = theme.selectedRow;
    }
    if (color != null) {
      child = DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: child,
      );
    }

    child = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: theme.rowHeight, child: child),
        if (isExpansible)
          SizeTransition(
            axisAlignment: 1.0,
            sizeFactor: animation,
            child: SizedBox(
              height: theme.rowHeight * 2,
              child: Column(
                children: [
                  SizedBox(
                    height: theme.rowHeight,
                    child: Row(children: widget.buildColumns(context, widget.index, controller, theme, true)),
                  ),
                  SizedBox(
                    height: theme.rowHeight,
                    child: Row(children: widget.buildColumns(context, widget.index, controller, theme, true)),
                  ),
                ],
              ),
            ),
          )
      ],
    );

    return child;
    // return SizedBox(height: height, child: child);
  }

  void _onRowChanged(int index, T value) {
    if (mounted) {
      setState(() {
        selected = controller._selectedRows.contains(index);
        expanded = controller._expandedRows.contains(index);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    controller.removeRowChangeListener(widget.index, _onRowChanged);
    expandController.dispose();
  }
}

class _FixedPartRow<K extends Comparable<K>, T> extends _RowBuilder<K, T> {
  final int fixedColumnCount;
  final List<ReadOnlyTableColumn> columns;
  final List<double> sizes;

  const _FixedPartRow({
    required super.index,
    required this.fixedColumnCount,
    required this.columns,
    required this.sizes,
    super.key,
  });

  @override
  List<Widget> buildColumns(BuildContext context, int index, PagedDataTableController<K, T> controller,
      PagedDataTableThemeData theme, bool isExpandedRow) {
    final item = controller._currentDataset[index];
    final list = <Widget>[];

    for (int i = 0; i < fixedColumnCount; i++) {
      final column = columns[i];
      final widget = _buildCell(context, index, item, sizes[i], theme, column, isExpandedRow);
      list.add(widget);
    }

    return list;
  }
}

class _VariablePartRow<K extends Comparable<K>, T> extends _RowBuilder<K, T> {
  final List<ReadOnlyTableColumn> columns;
  final int fixedColumnCount;
  final List<double> sizes;

  const _VariablePartRow({
    required super.index,
    required this.fixedColumnCount,
    required this.columns,
    required this.sizes,
    super.key,
  });

  @override
  List<Widget> buildColumns(BuildContext context, int index, PagedDataTableController<K, T> controller,
      PagedDataTableThemeData theme, bool isExpandedRow) {
    final item = controller._currentDataset[index];
    final list = <Widget>[];

    for (int i = fixedColumnCount; i < columns.length; i++) {
      final column = columns[i];
      final widget = _buildCell(context, index, item, sizes[i], theme, column, isExpandedRow);
      list.add(widget);
    }

    return list;
  }
}

Widget _buildCell<T>(
  BuildContext context,
  int index,
  T value,
  double width,
  PagedDataTableThemeData theme,
  ReadOnlyTableColumn column,
  bool isExpandedRow,
) {
  if (isExpandedRow && !column.renderExpanded) {
    return const SizedBox.shrink();
  }

  Widget child = Container(
    padding: theme.cellPadding,
    margin: theme.padding,
    decoration: BoxDecoration(border: theme.cellBorderSide),
    child: column.format.transform(column.build(context, value, index)),
  );

  child = SizedBox(width: width, child: child);

  return child;
}
