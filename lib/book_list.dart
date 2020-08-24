

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glib/core/array.dart';
import 'package:glib/main/data_item.dart';
import 'package:glib/main/context.dart';
import 'package:glib/core/callback.dart';
import 'package:glib/main/error.dart' as glib;
import 'package:glib/main/project.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'book_page.dart';
import 'widgets/better_refresh_indicator.dart';
import 'widgets/book_item.dart';

class BookListPage extends StatefulWidget {
  Project project;
  Context context;
  BookListPage(this.project, this.context);

  @override
  State<StatefulWidget> createState()=>_BookListPageState();

}

class _BookListPageState extends State<BookListPage> {
  Array books;
  BetterRefreshIndicatorController controller = BetterRefreshIndicatorController();
  bool cooldown = true;
  GlobalKey _nullKey = GlobalKey();

  void itemClicked(int idx) async {
    Context ctx = widget.project.createBookContext(books[idx]).control();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookPage(ctx, widget.project)
    ));
    ctx.release();
  }

  bool onPullDownRefresh() {
    widget.context.reload();
    return false;
  }

  void onDataChanged(int type, Array data, int idx) {
    if (data != null) {
      setState(() {});
    }
  }

  void onLoadingStatus(bool isLoading) {
    if (isLoading) {
      controller.startLoading();
    } else {
      controller.stopLoading();
    }
  }

  void onError(glib.Error error) {
    Fluttertoast.showToast(
      msg: error.msg,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  void initState() {
    widget.context.control();
    widget.context.on_data_changed = Callback.fromFunction(onDataChanged).release();
    widget.context.on_loading_status = Callback.fromFunction(onLoadingStatus).release();
    widget.context.on_error = Callback.fromFunction(onError).release();
    controller.onRefresh = onPullDownRefresh;
    widget.context.enterView();
    books = widget.context.data.control();
    super.initState();
  }

  Widget cellWithData(DataItem item, int idx) {
    return makeBookItem(context, widget.project, item, () {
      itemClicked(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      child: BetterRefreshIndicator(
        child: buildMain(context),
        controller: controller,
      ),
      onNotification: (ScrollUpdateNotification notification) {
        if (notification.metrics.maxScrollExtent - notification.metrics.pixels < 20 && cooldown) {
          widget.context.loadMore();
          cooldown = false;
          Future.delayed(Duration(seconds: 2)).then((value) => cooldown = true);
        }
        return false;
      },
    );
  }

  Widget buildMain(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext context, int idx) {
            if (idx < books.length) {
              DataItem book = books[idx];
              return cellWithData(book, idx);
            } else {
              return Container(height: 10,);
            }
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(),
          itemCount: books.length + 1,
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: books.length == 0 ? 1 : 0,
            duration: Duration(milliseconds: 300),
            child: Center(
              child: Text("No data!", style: TextStyle(
                color: Color.fromRGBO(0xee, 0xee, 0xee, 1),
                shadows: [
                  Shadow(
                    offset: Offset(-1, -1),
                    blurRadius: 0,
                    color: Colors.black26
                  ),
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 0,
                    color: Colors.white
                  )
                ],
                fontSize: 26,
                fontFamily: "DancingScript",
                fontWeight: FontWeight.bold
              ),),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.context.on_data_changed = null;
    widget.context.on_loading_status = null;
    widget.context.on_error = null;
    widget.context.exitView();
    books.release();
    widget.context.release();
    super.dispose();
  }
}