import 'package:flutter/material.dart';

/// Determines how the page break should occur during pagination.
/// 确定分页过程中分页符应如何出现。
enum PageBreakType {
  /// Break pages on the last visible word of the page.
  /// 在页面的最后一个可见单词上打断页面。
  word,

  /// Attempt to break pages at a period, comma, semicolon, or em dash (-- / —).
  /// 尝试以句点、逗号、分号或破折号（--/--）分隔页面。
  sentenceFragment,

  /// Attempt to break pages at the end of a sentence.
  /// 尝试在句末分页。
  sentence,

  /// Attempt to break at paragraphs (two consecutive newlines).
  /// 尝试打断段落（连续两行）。
  paragraph;

  RegExp get regex {
    final regex = _regexMap[this];
    if (regex == null) {
      throw ArgumentError.value(this, 'regex', 'has no');
    }
    return regex;
  }

  static final Map<PageBreakType, RegExp> _regexMap = {
    PageBreakType.sentenceFragment: RegExp(r'([.,;:—–]|--)\s*'),
    PageBreakType.sentence: RegExp(r'\.[^a-z]*', caseSensitive: false),
    PageBreakType.paragraph: RegExp(r'[\r\n\s*]{2,}'),
  };
}

/// User-provided text and configuration of how the text should be formatted and paginated.
class PaginateData {
  /// The whole text to be paginated. The initial letter will be a drop cap
  /// 整篇文章都要分页。首字母将是大写字母
  /// if `dropCapLines` > 0.
  final String text;

  /// The `TextStyle` of the body text. This is required to paginate the
  /// text without a `BuildContext`.
  /// 正文的“TextStyle”。这是分页所必需的
  /// 没有“BuildContext”的文本。
  final TextStyle style;

  /// Number of lines high the drop cap should be. If 0, the text will
  /// not have a drop cap.
  /// 大写字母几个行高度
  final int dropCapLines;

  /// The style, if different than `style`, for the drop cap.
  /// 大写字母样式
  final TextStyle? dropCapStyle;

  /// Extra padding to add around drop cap letter.
  final EdgeInsets dropCapPadding;

  /// Attempts to split pages at the specified point.
  /// Falls back to the next lower `PageBreakType` if not found within `breakLines`
  /// of the last visible line of the page.
  /// 尝试在指定点拆分页面。
  /// 如果在“breakLines”中找不到，则回退到下一个较低的“PageBreakType”`
  /// 页面最后一行可见。
  final PageBreakType pageBreakType;

  /// Forces a page break when encountering this pattern.
  /// If set to an empty string, there are no manual page breaks.
  /// Defaults to "<page>".'

  ///遇到此模式时强制分页符。
  ///如果设置为空字符串，则没有手动分页符。
  ///默认为“<page>”。
  final Pattern hardPageBreak;

  /// Considers only this many lines from the last visible for `pageBreak`.
  /// Defaults to 1 (the last line only).
  /// If `pageBreak` is not encountered on these lines, falls back to `PageBreak.word`.
  /// 只考虑从“pageBreak”的最后一行开始的这么多行。
  /// 默认为1（仅最后一行）。
  /// 如果这些行上没有遇到“pageBreak”，则返回到“pageBreak.word”。
  final int breakLines;

  /// Pass in the text direction to be used. Defaults to `TextDirection.ltr`.
  final TextDirection textDirection;

  /// Pass in the text scaler to be used. Defaults to `TextScaler.noScaling`.
  /// 文本缩放器
  final TextScaler textScaler;

  /// The amount (in width or height) the layout size can change before
  /// the text should be repaginated.
  final double resizeTolerance;

  /// Whether or not to parse inline markdown.
  /// 是否解析内联markdown
  final bool parseInlineMarkdown;

  const PaginateData({
    required this.text,
    required this.style,
    required this.dropCapLines, //首字母行高
    this.dropCapStyle,
    this.dropCapPadding = EdgeInsets.zero,
    this.pageBreakType = PageBreakType.paragraph,
    this.hardPageBreak = r'<page>',
    this.breakLines = 1,
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
    this.resizeTolerance = 2.0,
    this.parseInlineMarkdown = false,
  });

  /// Make a copy of this object with specified modified properties.
  PaginateData copyWith({
    String? text,
    TextStyle? style,
    int? dropCapLines,
    TextStyle? dropCapStyle,
    bool clearDropCapStyle = false,
    TextDirection? textDirection,
    TextScaler? textScaler,
    double? resizeTolerance,
  }) =>
      PaginateData(
        text: text ?? this.text,
        style: style ?? this.style,
        dropCapStyle:
            dropCapStyle ?? (clearDropCapStyle ? null : this.dropCapStyle),
        dropCapLines: dropCapLines ?? this.dropCapLines,
        textDirection: textDirection ?? this.textDirection,
        textScaler: textScaler ?? this.textScaler,
        resizeTolerance: resizeTolerance ?? this.resizeTolerance,
      );

  @override
  int get hashCode => Object.hash(
        text,
        style.stableHash,
        dropCapLines,
        dropCapStyle?.stableHash,
        textDirection,
        textScaler,
        resizeTolerance,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaginateData &&
          text == other.text &&
          // style ==
          //     other.style.copyWith(
          //       background: _ignorePaintForHash,
          //       foreground: _ignorePaintForHash,
          //     ) &&
          dropCapLines == other.dropCapLines &&
          // dropCapStyle ==
          //     other.dropCapStyle?.copyWith(
          //       background: _ignorePaintForHash,
          //       foreground: _ignorePaintForHash,
          //     ) &&
          pageBreakType == other.pageBreakType &&
          breakLines == other.breakLines &&
          textDirection == other.textDirection &&
          textScaler == other.textScaler &&
          resizeTolerance == other.resizeTolerance);

  @override
  String toString() => [
        '$runtimeType(',
        '    text: $text',
        '    style: $style',
        '    dropCapLines: $dropCapLines',
        '    dropCapStyle: $dropCapStyle',
        '    dropCapPadding: $dropCapPadding',
        '    pageBreakType: $pageBreakType',
        '    hardPageBreak: $hardPageBreak',
        '    breakLines: $breakLines',
        '    textDirection: $textDirection',
        '    textScaler: $textScaler',
        '    resizeTolerance: $resizeTolerance',
        '    parseInlineMarkdown: $parseInlineMarkdown',
        ')',
      ].join('\n');
}

extension PaintStableHash on Paint {
  /// Flutter [Paint.hashCode] is not stable because
  /// [Paint] is not constant and it does not override [hashCode].
  int get stableHash => Object.hashAll([
        blendMode,
        color,
        colorFilter,
        filterQuality,
        imageFilter,
        invertColors,
        isAntiAlias,
        maskFilter,
        shader,
        strokeCap,
        strokeJoin,
        strokeMiterLimit,
        strokeWidth,
        style,
      ]);
}

extension TextStyleStableHash on TextStyle {
  int get stableHash => Object.hashAll([
        background?.stableHash,
        backgroundColor,
        color,
        decoration,
        decorationColor,
        decorationStyle,
        decorationThickness,
        fontFamily,
        fontFamilyFallback,
        fontFeatures,
        fontSize,
        fontStyle,
        fontVariations,
        fontWeight,
        foreground?.stableHash,
        height,
        inherit,
        leadingDistribution,
        letterSpacing,
        locale,
        overflow,
        shadows,
        textBaseline,
        wordSpacing,
      ]);
}
