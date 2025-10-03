import 'dart:async';

import 'package:flutter/services.dart';
import 'package:graphify/src/controller/js_methods.dart';

const _echartsAssetPath = 'packages/graphify/assets/js/echarts.min.js';

String? _cachedDependencies;
Future<String>? _loadingDependencies;

Future<String> loadDependencies() {
  final cached = _cachedDependencies;
  if (cached != null) {
    return Future.value(cached);
  }

  return _loadingDependencies ??=
      rootBundle.loadString(_echartsAssetPath).then((echartsSource) {
    final combined = '$echartsSource $chartScripts';
    _cachedDependencies = combined;
    return combined;
  }).catchError((error, stackTrace) {
    _loadingDependencies = null;
    throw error;
  });
}

const String chartScripts = """
    
    const graphify_charts = {};
    
    function ${JsMethods.initChart}(chart_id, chart, option) {
      option = ${JsMethods.normalizeJson}(option);
      chart.setOption(option);
      graphify_charts[chart_id] = { chart, option };
    }
    
    function ${JsMethods.updateChart}(chart_id, option) {
      if (!graphify_charts[chart_id]) return;
      const chart = graphify_charts[chart_id].chart;
      option = ${JsMethods.normalizeJson}(option);
      chart.setOption(option);
      graphify_charts[chart_id].option = option;
    }
    
    function ${JsMethods.disposeChart} (chart_id) {
      const chart = graphify_charts[chart_id]?.chart;
      if (!chart) return;
      chart.dispose();
      delete graphify_charts[chart_id];
    }
    
    function ${JsMethods.normalizeJson}(option) {
      if (typeof option === 'object') return option;
      if (option instanceof String && option.length === 0 || option == null) return {};
      return JSON.parse(option);
    }
    
""";
