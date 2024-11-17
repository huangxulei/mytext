import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paginated_text/paginated_text.dart';

/// From: “The Promise of World Peace”
/// https://www.bahai.org/documents/the-universal-house-of-justice/promise-world-peace
const String pwp = '''
开风气也，梁羽生；发扬光大者，金庸。梁羽生是新派武侠小说的开山祖师，开创了新派武侠小说的先河。其后，金庸、古龙、温瑞安等人出现，将武侠文学发扬光大，也将武侠小说推上了一个新的高峰。虽然后起的金庸、古龙的名声要比梁羽生还要大，作品改编也比较多，但梁羽生先生也有不少优秀的作品。

在梁羽生的一生中，共写有35部小说。这些故事按照时间线来看的话，主要分为唐、宋、明、清系列，以及其他系列。这些故事内容大多都是前后串联，有传承脉络可循的，唐、宋系列的后人在明清系列中也有出现过。

要看梁羽生小说，可以分系列来看。下面从时间线来看一下梁羽生的全部小说。


大唐系列
以大唐为背景的故事有四本，《大唐游侠传》、《龙凤宝钗缘》、《慧剑心魔》以及《女帝奇英传》。

在这四本以唐朝为背景的小说中，前三本是一个系列的，是为唐代三部曲。《大唐游侠传》的背景是唐玄宗时期，是一段平定安史之乱的武林传奇，主要人物是段珪璋、南霁云、铁摩勒等。《龙凤宝钗缘》的时间紧接着《大唐游侠传》，是唐肃宗时期的故事，主要人物段克邪就是段珪璋的儿子，主要就是讲述的段克邪和史若梅之间的故事。《慧剑心魔》是唐代三部曲终结篇，讲述了少年英雄的成长历程，展伯承、铁铮、铁凝都曾在《龙凤宝钗缘》中出现过。

《女帝奇英传》虽然也是以唐朝为背景，但却是独立成篇的故事。从女帝就可以知道这部小说讲述的是武则天时期，主要人物是李建成之孙李逸、武则天的侄女武玄霜、上官婉儿、武则天等人。

在唐系列的四部小说中，《大唐游侠传》和《女帝奇英传》都是优秀作品。《龙凤宝钗缘》不如《大唐游侠传》那样有着豪迈绝伦的侠气，而是一段普通而又深刻的爱情，是大潮澎湃般的热血汹涌过后的平静，也算是一本不错的小说。《慧剑心魔》就不行了，在梁羽生的作品中评价很低，算是一部比较失败的作品。

''';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final text = pwp.trim();
    final style = GoogleFonts.notoSerif(fontSize: 24, height: 1.5);
    final dropCapStyle = GoogleFonts.bellefair();
    // final dropCapStyle = GoogleFonts.calligraffitti();

    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: PaginatedExample(
          text: text,
          style: style,
          dropCapStyle: dropCapStyle,
        ),
      ),
    );
  }
}

class PaginatedExample extends StatefulWidget {
  const PaginatedExample({
    super.key,
    required this.text,
    required this.style,
    required this.dropCapStyle,
  });

  final String text;
  final TextStyle style;
  final TextStyle dropCapStyle;

  @override
  State<PaginatedExample> createState() => _PaginatedExampleState();
}

class _PaginatedExampleState extends State<PaginatedExample>
    with SingleTickerProviderStateMixin {
  late Future _googleFontsPending;
  late PaginatedController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PaginatedController(PaginateData(
      text: widget.text,
      dropCapLines: 3,
      style: widget.style,
      dropCapStyle: widget.dropCapStyle,
      pageBreakType: PageBreakType.word,
      breakLines: 1,
      resizeTolerance: 3,
      parseInlineMarkdown: true,
    ));

    _googleFontsPending = GoogleFonts.pendingFonts([
      widget.style,
      widget.dropCapStyle,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _googleFontsPending,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator.adaptive();
          }

          final reverse = _controller.pageIndex < _controller.previousPageIndex;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: PaginatedText(
              _controller, //上面进入
              builder: (context, child) {
                //child 之前定义
                return DefaultTextStyle(
                  style: widget.style,
                  child: Column(
                    children: [
                      Text('The Promise of World Peace',
                          style: widget.dropCapStyle.copyWith(
                              fontSize: 40, fontStyle: FontStyle.italic)),
                      Expanded(
                        child: PageTransitionSwitcher(
                          duration: const Duration(seconds: 1),
                          reverse: reverse,
                          transitionBuilder:
                              (child, primaryAnimation, secondaryAnimation) {
                            const offscreen = Offset(-1.5, 0.0);
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset.zero,
                                end: offscreen,
                              ).animate(secondaryAnimation),
                              child: FadeTransition(
                                opacity: Tween<double>(
                                  begin: 0.0,
                                  end: 1.0,
                                ).animate(primaryAnimation),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            key: ValueKey(_controller.currentPage.pageIndex),
                            padding: const EdgeInsets.all(40),
                            child: SelectionArea(child: child),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                          'Page ${_controller.pageNumber} of ${_controller.numPages}',
                          style: widget.style.copyWith(fontSize: 24)),
                      const SizedBox(height: 20),
                      OverflowBar(
                        alignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _controller.isFirst
                                ? null
                                : () {
                                    setState(() {
                                      _controller.previous();
                                    });
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text('Prev', style: TextStyle(fontSize: 30)),
                            ),
                          ),
                          TextButton(
                            onPressed: _controller.isLast
                                ? null
                                : () {
                                    setState(() {
                                      _controller.next();
                                    });
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child:
                                  Text('Next', style: TextStyle(fontSize: 30)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
