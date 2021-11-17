import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dapp/extensions/extension.dart' as dapp;
import 'package:flutter_dapp/extensions/fetch.dart';
import 'package:flutter_dapp/extensions/html_parse.dart';
import 'package:flutter_dapp/extensions/main.dart';
import 'package:flutter_dapp/extensions/storage.dart' as dapp;
import 'package:flutter_dapp/flutter_dapp.dart';
import 'package:xml_layout/xml_layout.dart';
import 'localizations/localizations.dart';
import 'utils/plugin/plugin.dart';

const String env_git_url = "https://github.com/gsioteam/glib_env.git";
const String project_link = 'https://github.com/gsioteam/kinoko';

Map<String, String> cachedTemplates = {};
Map<String, dynamic> share_cache = Map();

const String collection_download = "download";
const String collection_mark = "mark";

const String home_page_name = "home";

const String last_chapter_key = "last-chapter";
const String direction_key = "direction";
const String device_key = "device";
const String page_key = "page";

const String disclaimer_key = "disclaimer";

const String language_key = "language";

const String history_key = "history";

const String viewed_key = "viewed";

const String v2_key = "v2_2_setup";

const String theme_key = "theme_key";

const int BOOK_INDEX = 0;
const int CHAPTER_INDEX = 1;

const String _localStorageKey = 'localStorage';

class PluginLocalStorage extends dapp.LocalStorage {

  final Plugin? plugin;
  late Map<String, dynamic> localStorage;

  PluginLocalStorage(this.plugin) {
    String? str = plugin?.storage.get(_localStorageKey);
    if (str?.isNotEmpty == true) {
      localStorage = jsonDecode(str!);
    } else {
      localStorage = {};
    }
  }

  @override
  void clear() {
    localStorage.clear();
    this.plugin?.storage.set(_localStorageKey, jsonEncode(localStorage));
  }

  @override
  String? get(String key) {
    return localStorage[key];
  }

  @override
  void remove(String key) {
    localStorage.remove(key);
    this.plugin?.storage.set(_localStorageKey, jsonEncode(localStorage));
  }

  @override
  void set(String key, String value) {
    localStorage[key] = value;
    this.plugin?.storage.set(_localStorageKey, jsonEncode(localStorage));
  }
}

class Configs with ChangeNotifier {

  static const bool isDebug = true;
  Plugin? _current;

  final Uint8List publicKey = Uint8List.fromList([2,169,116,121,28,94,121,148,224,164,101,4,129,150,179,221,230,79,31,104,57,165,189,188,150,139,234,217,84,155,201,149,10,]);

  static Configs? _instance;
  static Configs get instance {
    if (_instance == null) {
      _instance = Configs();
    }
    return _instance!;
  }

  Plugin? get current => _current;
  set current(Plugin? v) {
    if (_current != v) {
      _current = v;
      notifyListeners();
    }
  }

  JsCompiled? _storageCompiled;
  List<dapp.Extension> _extensions = [];

  Future<void> initialize(BuildContext context) async {
    JsScript script = JsScript();

    Main main = Main();
    await main.initialize(context, script);
    _extensions.add(main);

    Fetch fetch = Fetch();
    await fetch.initialize(context, script);
    _extensions.add(fetch);

    HTMLParser htmlParser = HTMLParser();
    await htmlParser.initialize(context, script);
    _extensions.add(htmlParser);

    dapp.Storage storage = dapp.Storage(localStorage: PluginLocalStorage(null));
    String code = await storage.loadCode(context);
    _storageCompiled = script.compile(code);

    script.dispose();

    XmlLayout.registerInlineMethod("loc", (method, status) {
      return lc(status.context)(method[0]);
    });
    XmlLayout.registerInlineMethod("color", (method, status) {
      ThemeData theme = Theme.of(status.context);
      String name = method[0];
      switch (name) {
        case 'primary':
          return theme.primaryColor;
        case 'canvas':
          return theme.canvasColor;
        case 'background':
          return theme.backgroundColor;
        case 'scaffold':
          return theme.scaffoldBackgroundColor;
        case 'disabled':
          return theme.disabledColor;
      }
    });
  }

  void setupJS(JsScript script, Plugin plugin) {

    PluginLocalStorage localStorage = PluginLocalStorage(plugin);
    JsValue value = script.bind(localStorage, classInfo: dapp.storageClass);
    script.global['_storage'] = value;

    if (_storageCompiled != null) {
      script.loadCompiled(_storageCompiled!);
    }
    for (var ex in _extensions) {
      ex.attachTo(script);
    }
  }

}