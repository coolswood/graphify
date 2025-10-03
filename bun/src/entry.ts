// ЯДРО
import * as echarts from 'echarts/core';
import {
  LineChart,
} from 'echarts/charts';

import {
  DatasetComponent,
  GridComponent,
  LegendComponent,
  TitleComponent,
  TransformComponent,
  GraphicComponent,
} from 'echarts/components';

import { UniversalTransition } from 'echarts/features';

// РЕНДЕРЕР (обязательно выбрать хотя бы один)
import { CanvasRenderer } from 'echarts/renderers';

// РЕГИСТРАЦИЯ МИНИМАЛЬНОГО НАБОРА
echarts.use([
  CanvasRenderer,
  LineChart,
  DatasetComponent,
  GridComponent,
  LegendComponent,
  TitleComponent,
  TransformComponent,
  GraphicComponent,
  UniversalTransition,
]);

// Экспорт на window для совместимости с WebView/graphify (формат iife + global name)
declare global {
  interface Window { echarts: typeof echarts }
}
(window as any).echarts = echarts;

// Также дефолтный экспорт — удобно, если будете подключать модульно
export default echarts;

/**
 * Дальше вы сами ДОБАВЛЯЕТЕ НУЖНОЕ.
 *
 * Примеры:
 *
 * // 1) столбцы без линий:
 * import { BarChart } from 'echarts/charts';
 * import { GridComponent, TooltipComponent, TitleComponent, LegendComponent } from 'echarts/components';
 * echarts.use([BarChart, GridComponent, TooltipComponent, TitleComponent, LegendComponent]);
 *
 * // 2) круговые диаграммы:
 * import { PieChart } from 'echarts/charts';
 * echarts.use([PieChart]);
 *
 * // 3) dataset:
 * import { DatasetComponent } from 'echarts/components';
 * echarts.use([DatasetComponent]);
 *
 * // 4) если нужен SVG-рендерер вместо Canvas:
 * import { SVGRenderer } from 'echarts/renderers';
 * echarts.use([SVGRenderer]); // можно заменить CanvasRenderer или добавить оба
 */
