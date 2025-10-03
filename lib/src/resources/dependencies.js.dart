import 'dart:async';

import 'package:flutter/services.dart';
import 'package:graphify/src/controller/js_methods.dart';

const _echartsAssetPath = 'packages/graphify/assets/js/echarts.custom.min.js';

String? _cachedDependencies;
Future<String>? _loadingDependencies;

Future<String> loadDependencies() {
  final cached = _cachedDependencies;
  if (cached != null) {
    return Future.value(cached);
  }

  return _loadingDependencies ??=
      rootBundle.loadString(_echartsAssetPath).then((echartsSource) {
    final combined = '$consoleBridgeScripts $echartsSource $chartScripts';
    _cachedDependencies = combined;
    return combined;
  }).catchError((error, stackTrace) {
    _loadingDependencies = null;
    throw error;
  });
}

const String consoleBridgeScripts = """
    const GRAPHIFY_CONSOLE_SOURCE = 'graphify-console';
    const GRAPHIFY_CONSOLE_MAX_DEPTH = 4;
    
    (function setupGraphifyConsoleBridge() {
      if (window.__graphifyConsoleBridgeInstalled) return;
      window.__graphifyConsoleBridgeInstalled = true;

      const levels = ['log', 'info', 'warn', 'error'];

      const formatArgument = (arg) => {
        if (arg == null) return String(arg);
        if (typeof arg === 'string') return arg;
        if (typeof arg === 'number' || typeof arg === 'boolean') return String(arg);
        if (arg instanceof Error) return arg.stack || arg.message || String(arg);
        try {
          return JSON.stringify(arg);
        } catch (_) {
          return String(arg);
        }
      };

      const sanitizeValue = (value, depth = 0) => {
        if (depth > GRAPHIFY_CONSOLE_MAX_DEPTH) {
          return typeof value === 'object' ? '[Object]' : String(value);
        }
        if (value == null || typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
          return value;
        }
        if (value instanceof Error) {
          return {
            name: value.name,
            message: value.message,
            stack: value.stack,
          };
        }
        if (Array.isArray(value)) {
          return value.map((item) => sanitizeValue(item, depth + 1));
        }
        if (typeof value === 'object') {
          const result = {};
          Object.keys(value).slice(0, 20).forEach((key) => {
            try {
              result[key] = sanitizeValue(value[key], depth + 1);
            } catch (_) {
              result[key] = '[unserializable]';
            }
          });
          return result;
        }
        return String(value);
      };

      const dispatch = (level, args, meta) => {
        try {
          const formatted = Array.from(args || []).map(formatArgument);
          const payload = {
            source: GRAPHIFY_CONSOLE_SOURCE,
            level,
            message: formatted.join(' '),
            args: formatted,
            meta: meta ? sanitizeValue(meta) : null,
            timestamp: Date.now(),
          };

          if (window.GraphifyConsole?.postMessage) {
            window.GraphifyConsole.postMessage(JSON.stringify(payload));
          }

          if (window.parent && window.parent !== window) {
            window.parent.postMessage(payload, '*');
          }
        } catch (_) {
          // Swallow errors to avoid recursive console failures.
        }
      };

      levels.forEach((level) => {
        const original = console[level];
        console[level] = function (...args) {
          dispatch(level, args);
          if (typeof original === 'function') {
            return original.apply(console, args);
          }
        };
      });

      window.addEventListener('error', (event) => {
        const error = event?.error;
        const detail = (error && (error.stack || error.message)) || event?.message || 'Unknown runtime error';
        dispatch('error', [detail], {
          type: 'error',
          message: event?.message,
          filename: event?.filename,
          lineno: event?.lineno,
          colno: event?.colno,
          error: error ? sanitizeValue(error) : null,
        });
      });

      window.addEventListener('unhandledrejection', (event) => {
        const reason = event?.reason;
        const detail = (reason && (reason.stack || reason.message)) || formatArgument(reason) || 'Unhandled promise rejection';
        dispatch('error', ['Unhandled promise rejection', detail], {
          type: 'unhandledrejection',
          reason: sanitizeValue(reason),
          stack: reason && reason.stack,
        });
      });
    })();
""";

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
