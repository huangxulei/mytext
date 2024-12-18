import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:paginated_text/src/constants.dart';
import 'package:paginated_text/src/models/models.dart';
import 'package:paginated_text/src/utils/fitted_text.dart';

import '../utils/get_cap_font_size.dart';

typedef OnPaginateCallback = void Function(PaginatedController);

final _reFirstSpacesInLine = RegExp(r'^\s+');

class NextLinesData {
  final List<String> lines;
  final int nextPosition;
  final bool didExceedMaxLines;

  NextLinesData({
    required this.lines,
    required this.nextPosition,
    required this.didExceedMaxLines,
  });

  @override
  String toString() => [
        '$runtimeType(',
        '    lines: $lines,',
        '    nextPosition: $nextPosition,',
        '    didExceedMaxLines: $didExceedMaxLines,',
        ')',
      ].join('\n');
}

/// The controller with `ChangeNotifier` that computes the text pages from `PaginateData`.
class PaginatedController with ChangeNotifier {
  PaginatedController(
    this._data, {
    this.onPaginate,
    int defaultMaxLinesPerPage = 10,
  })  : _layoutSize = Size.zero,
        _maxLinesPerPage = defaultMaxLinesPerPage;

  /// The data this controller was instantiated with.
  /// 此控制器实例化时使用的数据
  PaginateData get paginateData => _data;

  /// Whether the current page is the first page.
  /// 当前页面是否为第一页。
  bool get isFirst => pageIndex == 0;

  /// Whether the current page is the last page.
  /// 是否最后一页
  bool get isLast => pageIndex == pages.length - 1;

  /// The current page model.
  PageInfo get currentPage =>
      pages.isNotEmpty ? pages[_pageIndex] : PageInfo.empty;

  /// An unmodifiable list of the current paginated page models.
  late final pages = UnmodifiableListView(_pages);

  /// The index of the current page.
  int get pageIndex => _pageIndex;

  /// The index of the page previously viewed.
  int get previousPageIndex => _previousPageIndex;

  /// The 1-based number of the current page (pageIndex + 1).
  int get pageNumber => _pageIndex + 1;

  /// The number or count of pages after pagination.
  int get numPages => pages.length;

  /// The size of the layout used for the current pagination.
  Size get layoutSize => _layoutSize;

  /// The maximum number of lines that can be shown on the page,
  /// given the `layoutSize`.
  int get maxLinesPerPage => _maxLinesPerPage;

  /// The height of a single line given the configured `PaginateData.style`.
  double get lineHeight => _lineHeight;

  PaginateData _data;
  Size _layoutSize;
  final List<PageInfo> _pages = []; //全部页
  int _pageIndex = 0; //当前页码
  int _previousPageIndex = 0; //上一页码
  int _maxLinesPerPage; //每页最大行数
  double _lineHeight = 0.0; //行高

  OnPaginateCallback? onPaginate; //分页回调函数

  /// Tells the controller to update its `layoutSize`. Causes repagination if needed.
  /// 告诉控制器更新其“layoutSize”。如果需要，会导致重新分页。
  void updateLayoutSize(Size layoutSize) {
    //第一次获取dx 肯定是true
    final dx =
        (layoutSize.width - _layoutSize.width).abs() > _data.resizeTolerance;

    final dy = dx ||
        (layoutSize.height - _layoutSize.height).abs() > _data.resizeTolerance;

    if (dx || dy) {
      update(_data, layoutSize);
    }
  }

  /// Go to the next page. Do nothing if on the last page.
  /// 下一页, 当前页如果是最后一页 什么都不做
  void next() {
    if (_pageIndex == _pages.length - 1) {
      return;
    }
    _previousPageIndex = _pageIndex;
    _pageIndex++;
    notifyListeners();
  }

  /// Go to the previous page. Do nothing if on the first page.
  /// 上一页
  void previous() {
    if (_pageIndex == 0) {
      return;
    }
    _previousPageIndex = _pageIndex;
    _pageIndex--;
    notifyListeners();
  }

  /// Sets the page explicitly to a given index, clamped to the range of pages.
  /// 设将页面显式设置为给定的索引，限制在页面范围内。跳转到页码
  void setPageIndex(int pageIndex) {
    _previousPageIndex = _pageIndex;
    _pageIndex = pageIndex.clamp(0, _pages.length - 1);
    notifyListeners();
  }

  /// Update this controller instance with given `data` and `layoutSize`.

  void update(PaginateData data, Size layoutSize) {
    if (data == _data && layoutSize == _layoutSize) {
      return;
    }

    _paginate(data, layoutSize);
  }

  //获取下一行数内容
  NextLinesData _getNextLines({
    required bool autoPageBreak,
    required int textPosition,
    required double width,
    required int maxLines,
  }) {
    //从当前焦点 获取文字内容
    final String currentText = _data.text.substring(textPosition);

    final fittedText = FittedText.fit(
      text: currentText,
      width: width,
      style: _data.style,
      textScaler: _data.textScaler,
      textDirection: _data.textDirection,
      maxLines: maxLines,
    );

    // Handle hard page break, if one exists.
    final hardPageBreakResult = _handleHardPageBreak(fittedText, textPosition);
    if (hardPageBreakResult != null) {
      return hardPageBreakResult;
    }

    // If auto page break is disabled, type is `word`, or all text fits, return as is.
    if (!autoPageBreak ||
        !fittedText.didExceedMaxLines ||
        _data.pageBreakType == PageBreakType.word) {
      return NextLinesData(
        lines: fittedText.lines,
        nextPosition: textPosition + fittedText.text.length,
        didExceedMaxLines: fittedText.didExceedMaxLines,
      );
    }

    // Handle auto page breaks based on page break type
    return _handleAutoPageBreak(fittedText, textPosition);
  }

  NextLinesData? _handleHardPageBreak(FittedText fittedText, int textPosition) {
    final firstHardPageBreakMatch =
        _data.hardPageBreak.allMatches(fittedText.text).firstOrNull;

    if (firstHardPageBreakMatch == null) {
      return null;
    }

    final lineIndex = fittedText.lines.indexWhere(
      (line) => line.contains(_data.hardPageBreak),
    );

    final List<String> lines =
        fittedText.lines.sublist(0, lineIndex).mapIndexed((index, line) {
      if (lineIndex == index) {
        return line.substring(0, line.indexOf(_data.hardPageBreak));
      }
      return line;
    }).toList();

    return NextLinesData(
      lines: lines,
      nextPosition: textPosition + firstHardPageBreakMatch.end + 1,
      didExceedMaxLines: fittedText.didExceedMaxLines,
    );
  }

  NextLinesData _handleAutoPageBreak(FittedText fittedText, int textPosition) {
    int nextPosition = textPosition + fittedText.text.length;

    if (!fittedText.didExceedMaxLines) {
      return NextLinesData(
        lines: fittedText.lines,
        nextPosition: nextPosition,
        didExceedMaxLines: fittedText.didExceedMaxLines,
      );
    }

    final pageBreakIndex = PageBreakType.values.indexOf(_data.pageBreakType);
    final int minBreakLine = fittedText.lines.length -
        min(fittedText.lines.length, _data.breakLines);

    for (int pb = pageBreakIndex; pb > 0; pb--) {
      final pageBreak = PageBreakType.values[pb].regex;
      final result = _findPageBreak(
        fittedText.lines,
        pageBreak,
        minBreakLine,
        textPosition,
      );

      if (result != null) {
        return result;
      }
    }

    return NextLinesData(
      lines: fittedText.lines,
      nextPosition: nextPosition,
      didExceedMaxLines: fittedText.didExceedMaxLines,
    );
  }

  NextLinesData? _findPageBreak(
    List<String> lines,
    RegExp pageBreak,
    int minBreakLine,
    int textPosition,
  ) {
    for (int i = lines.length - 1; i >= minBreakLine; i--) {
      final match = pageBreak.allMatches(lines[i]).lastOrNull;
      if (match == null) {
        continue;
      }
      // Trim the line up to the match
      lines[i] = lines[i].substring(0, match.end);

      // Remove lines after the break
      if (i < lines.length - 1) {
        lines.removeRange(i + 1, lines.length);
      }

      // Calculate the new next position
      final nextPosition = textPosition + lines.join().length;

      return NextLinesData(
        lines: lines,
        nextPosition: nextPosition,
        didExceedMaxLines: true,
      );
    }

    return null;
  }

  //分页**
  void _paginate(PaginateData data, Size layoutSize) {
    _data = data;
    _layoutSize = layoutSize;
    _pages.clear();

    // Early return if layout size is zero or text is empty.
    if (layoutSize == Size.zero || data.text.isEmpty) {
      _pages.add(PageInfo.empty);
      _notifyPaginate();
      return;
    }

    // Calculate line height and max lines per page
    // 计算行高,字体高度
    final lineHeight = data.textScaler.scale(data.style.fontSize ?? 14.0) *
        (data.style.height ?? 1.0);
    _lineHeight = lineHeight;
    //每页最大行数
    final maxLinesPerPage =
        max(data.dropCapLines, (layoutSize.height / lineHeight).floor());
    _maxLinesPerPage = maxLinesPerPage;

    int pageIndex = 0;
    int textPosition = 0;

    while (textPosition < data.text.length - 1) {
      String capChars = '';
      List<String> dropCapLines = [];
      bool didExceedDropCapLines = false;

      // compute drop cap lines
      if (textPosition == 0 && data.dropCapLines > 0) {
        capChars = data.text.substring(0, 1);
        textPosition += capChars.length;
        //计算首字母的大小 会放大
        final wantedCapFontSize = getCapFontSize(
          textFontSize: data.style.fontSize ?? 14,
          lineHeight: data.style.height ?? 1.0,
          capLines: data.dropCapLines, //大写字母占几行
          textLetterHeightRatio: defaultLetterHeightRatio,
          capLetterHeightRatio: defaultLetterHeightRatio,
        );
        final capStyle = (data.dropCapStyle ?? data.style).copyWith(
          fontSize: wantedCapFontSize,
        );
        final capSpan = TextSpan(
          text: capChars,
          style: capStyle,
        );
        final capPainter = TextPainter(
          text: capSpan,
          textScaler: data.textScaler,
          textDirection: data.textDirection,
        )..layout(); //渲染首字母
        final nextLinesData = _getNextLines(
          autoPageBreak: false,
          textPosition: textPosition,
          width: layoutSize.width -
              capPainter.width -
              data.dropCapPadding.horizontal,
          maxLines: min(maxLinesPerPage, data.dropCapLines),
        );
        dropCapLines = nextLinesData.lines;
        textPosition = nextLinesData.nextPosition;
        didExceedDropCapLines = nextLinesData.didExceedMaxLines;

        // If our text did not exceed the drop cap lines area, break:
        if (!didExceedDropCapLines) {
          final pageInfo = PageInfo(
            pageIndex: pageIndex,
            text: capChars + dropCapLines.join(),
            lines: dropCapLines.length,
          );
          _pages.add(pageInfo);
          pageIndex++;
          break;
        }
      }

      List<String> nextLines = [];
      //剩下页面的行数 首页 7行 后面10行 每页10行
      final remainingLinesOnPage = maxLinesPerPage - dropCapLines.length;

      final nextLinesData = _getNextLines(
        autoPageBreak: true,
        textPosition: textPosition,
        width: layoutSize.width,
        maxLines: remainingLinesOnPage,
      );

      nextLines = nextLinesData.lines;
      textPosition = nextLinesData.nextPosition;
// 塞入 textPainer中, 然后根据函数 活的textposition位置
      final text = capChars + dropCapLines.join() + nextLines.join();
      final lines = dropCapLines.length + nextLines.length;

      final pageInfo = PageInfo(
        pageIndex: pageIndex,
        text: text,
        lines: lines,
      );
      _pages.add(pageInfo);
      pageIndex++;
    }

    _pageIndex = min(pageIndex, _pageIndex);
    _notifyPaginate();
  }

  void _notifyPaginate() {
    onPaginate?.call(this);
    notifyListeners();
  }
}
