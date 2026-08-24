# Replica Code Pattern Index

Library: `~/Documents/1-博士课题/3-科研资料/MsTt笔记100+绘图合集/R科研绘图合集`
Scripts indexed: 142

## Suitability Summary

- `decorative_or_case_specific`: 16
- `production_recipe`: 26
- `specialized_reference`: 45
- `template_candidate`: 55

## Figure Family Summary

- map / spatial: 25
- heatmap / matrix: 20
- scatter / regression: 16
- grouped bar / stacked bar / errorbar: 13
- circos / chord / circular: 10
- PCA / PCoA / ordination: 9
- volcano / enrichment: 8
- ridgeline / density: 8
- multi-panel manuscript / other: 8
- raincloud / violin / jitter: 7
- network / sankey: 5
- enrichment / GSEA: 4
- upset / set plot: 4
- lollipop / dumbbell / dotplot: 2
- boxplot / jitter: 2
- phylogenetic tree: 1

## Script-Level Index

| Case | Script | Family | Suitability | Packages | Geoms | Input roles | Risks |
|---|---|---|---|---|---|---|---|
| 1.柱状图-散点图-误差线-p值显著性 | `1.柱状图-散点图-误差线-p值显著性/bar_dot_error_sig.R` | map / spatial | `specialized_reference` | ggsignif, multcomp, readxl, tidyverse | geom_bar, geom_errorbar, geom_jitter, geom_signif | error, group, value |  |
| 10.Nature复现-添加显著性星号标记的热图 | `10.Nature复现-添加显著性星号标记的热图/heatmap-significant-facet.R` | heatmap / matrix | `template_candidate` | readxl, tidyverse | geom_text, geom_tile | error, network, sample |  |
| 10.Nature复现-添加显著性星号标记的热图 | `10.Nature复现-添加显著性星号标记的热图/heatmap-significant.R` | heatmap / matrix | `template_candidate` | cowplot, readxl, tidyverse | geom_rect, geom_text, geom_tile | error, network, sample |  |
| 11.Nature复现-散点图+边缘直方图+拟合曲线+残差箱式图 | `11.Nature复现-散点图+边缘直方图+拟合曲线+残差箱式图/comprehensive_correlation.R` | map / spatial | `specialized_reference` | ggExtra, ggsignif, grid, scales, tidyverse | geom_boxplot, geom_point, geom_signif, geom_smooth | group, network |  |
| 12.Nature复现-相关性热图+边缘条形图 | `12.Nature复现-相关性热图+边缘条形图/correlation_heatmap.R` | heatmap / matrix | `decorative_or_case_specific` | corrplot, grid, tidyverse | geom_col, geom_rect | error, network, sample, spatial, value | decorative_or_polar_layout |
| 13.Nature复现-倒三角相关性热图+层次聚类树 | `13.Nature复现-倒三角相关性热图+层次聚类树/correlation_heatmap_hcluster.R` | heatmap / matrix | `decorative_or_case_specific` | cowplot, factoextra, ggplotify, grid, reshape2, tidyverse | geom_path, geom_point, geom_polygon, geom_tile | error, network, sample, spatial, value | decorative_or_polar_layout |
| 14.Nature复现-折线图和箱式图+误差线+显著性检验 | `14.Nature复现-折线图和箱式图+误差线+显著性检验/groups_bar_line_error_sig.R` | grouped bar / stacked bar / errorbar | `template_candidate` | ggpubr, patchwork, readxl, reshape2, rstatix, tidyverse | geom_bar, geom_jitter, geom_line, geom_point, geom_text | coordinate, group, value |  |
| 15.Nature复现-小提琴图+箱式图+蜂窝图（云雨图） | `15.Nature复现-小提琴图+箱式图+蜂窝图（云雨图）/raincloud.R` | raincloud / violin / jitter | `template_candidate` | gghalves, readxl, tidyverse | geom_boxplot, geom_dotplot, geom_half_violin | network |  |
| 16.Nature复现-散点图+拟合曲线+均值+双向误差线 | `16.Nature复现-散点图+拟合曲线+均值+双向误差线/dot_group_bierrorbar.R` | grouped bar / stacked bar / errorbar | `template_candidate` | ggh4x, ggplot2, plyr | geom_errorbar, geom_errorbarh, geom_point, geom_smooth | error, group, network |  |
| 17.Nature复现-分组和弦图+外围条形图 | `17.Nature复现-分组和弦图+外围条形图/group_chord_bar.R` | circos / chord / circular | `specialized_reference` | circlize, grid, readxl, tidyverse | geom_bar, geom_text | error, group, sample, value | specialized_package, decorative_or_polar_layout |
| 18.Science复现-火山图+GSEA_MSigDB富集得分 | `18.Science复现-火山图+GSEA_MSigDB富集得分/volcano_gsea.R` | volcano / enrichment | `template_candidate` | dplyr, ggplot2, ggrepel | geom_hline, geom_label_repel, geom_linerange, geom_point, geom_vline | coordinate, effect, error, feature, pvalue, sample, value |  |
| 19.Cell复现-渐变色背景+分组小提琴图-箱式图+显著性P | `19.Cell复现-渐变色背景+分组小提琴图-箱式图+显著性P/gradient_grob_box.R` | map / spatial | `specialized_reference` | ggsignif, ggtext, grid, patchwork, reshape2, stringr, tidyverse | geom_boxplot, geom_signif | group, value | case_specific_grob_layout |
| 19.Cell复现-渐变色背景+分组小提琴图-箱式图+显著性P | `19.Cell复现-渐变色背景+分组小提琴图-箱式图+显著性P/gradient_grob_violin.R` | map / spatial | `specialized_reference` | ggplot2, ggsignif, ggtext, grid, patchwork, stringr | geom_signif, geom_violin | group, value | case_specific_grob_layout |
| 2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA | `2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA/scripts/NMDS.R` | PCA / PCoA / ordination | `template_candidate` | ggplot2, vegan | geom_hline, geom_point, geom_text, geom_vline | group, ordination, sample |  |
| 2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA | `2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA/scripts/NMDS_box_dot_ANOSIM.R` | PCA / PCoA / ordination | `template_candidate` | ggplot2, patchwork, vegan | geom_boxplot, geom_hline, geom_jitter, geom_point, geom_text, geom_vline | group, ordination, sample |  |
| 2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA | `2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA/scripts/PCA_FactoMineR.R` | PCA / PCoA / ordination | `template_candidate` | FactoMineR, RColorBrewer, factoextra, ggplot2 | geom_hline, geom_point, geom_text, geom_vline | group, ordination, sample |  |
| 2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA | `2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA/scripts/PCA_ade4.R` | PCA / PCoA / ordination | `template_candidate` | RColorBrewer, ade4, ggplot2 | geom_hline, geom_point, geom_text, geom_vline | group, ordination, sample |  |
| 2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA | `2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA/scripts/PCoA.R` | PCA / PCoA / ordination | `template_candidate` | ggplot2, vegan | geom_hline, geom_point, geom_text, geom_vline | group, ordination, sample |  |
| 2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA | `2.SCI复现-PCoA可视化+边缘箱式图+PERMANOVA/scripts/PCoA_box_dot_PERMANOVA.R` | PCA / PCoA / ordination | `template_candidate` | ggplot2, patchwork, vegan | geom_boxplot, geom_hline, geom_jitter, geom_point, geom_text, geom_vline | group, ordination, sample |  |
| 20.Nature复现-表格形式的热图 | `20.Nature复现-表格形式的热图/table_heatmap.R` | heatmap / matrix | `production_recipe` | RColorBrewer, dplyr, funkyheatmap, ggplot2 |  | error, feature, group, sample, spatial, value |  |
| 21.Nature复现-渐变色山脊图+双向柱形图 | `21.Nature复现-渐变色山脊图+双向柱形图/bidirect_ridge_bar.R` | ridgeline / density | `template_candidate` | ggridges, patchwork, tidyr, tidyverse | geom_bar, geom_density_ridges_gradient, geom_vline | error, network, sample, value |  |
| 22.Nature复现-堆积柱形图+哑铃图 | `22.Nature复现-堆积柱形图+哑铃图/dumbbell_stacked_bar.R` | lollipop / dumbbell / dotplot | `template_candidate` | dplyr, ggplot2, patchwork | geom_bar, geom_point, geom_segment | error, network, sample |  |
| 23.Nature复现-火山图+EnrichmentMap-GSEA | `23.Nature复现-火山图+EnrichmentMap-GSEA/volcano.R` | volcano / enrichment | `template_candidate` | dplyr, ggplot2, ggrepel | geom_hline, geom_point, geom_text_repel, geom_vline | effect, feature, pvalue, sample, value |  |
| 25.Science+Cell复现-差异基因FC-FC散点图 | `25.Science+Cell复现-差异基因FC-FC散点图/FC_FC_cell.R` | scatter / regression | `template_candidate` | ggplot2, ggrepel | geom_abline, geom_hline, geom_point, geom_text_repel, geom_vline | coordinate, effect, error, feature, group, pvalue, sample, value |  |
| 25.Science+Cell复现-差异基因FC-FC散点图 | `25.Science+Cell复现-差异基因FC-FC散点图/FC_FC_science.R` | scatter / regression | `template_candidate` | dplyr, ggplot2, ggrepel, tibble | geom_hline, geom_point, geom_text_repel, geom_vline | coordinate, effect, error, feature, group, pvalue, sample, spatial, value |  |
| 26.SCI复现-核密度图+箱线图+蜂群图-模型验证 | `26.SCI复现-核密度图+箱线图+蜂群图-模型验证/model_recovery.R` | ridgeline / density | `template_candidate` | dplyr, ggbeeswarm, ggplot2, patchwork | geom_beeswarm, geom_boxplot, geom_density | effect, group |  |
| 27.Cell复现-堆积柱形图+散点图 | `27.Cell复现-堆积柱形图+散点图/stacked_bar.R` | grouped bar / stacked bar / errorbar | `decorative_or_case_specific` | cowplot, dplyr, forcats, ggplot2, gridExtra | geom_bar, geom_point | group, value | case_specific_grob_layout |
| 28.Nature复现-小提琴图+四分位线+抖动散点+显著性P | `28.Nature复现-小提琴图+四分位线+抖动散点+显著性P/violin_facet_sig.R` | map / spatial | `specialized_reference` | dplyr, ggplot2, ggsignif, readxl | geom_crossbar, geom_errorbar, geom_point, geom_signif, geom_violin | pvalue |  |
| 29.Nature复现-渐变色桑基图 | `29.Nature复现-渐变色桑基图/sankey_networkD3_v1.R` | network / sankey | `specialized_reference` | htmlwidgets, networkD3, readxl, tidyverse, webshot |  | error, group, sample | specialized_package |
| 29.Nature复现-渐变色桑基图 | `29.Nature复现-渐变色桑基图/sankey_networkD3_v2.R` | network / sankey | `specialized_reference` | htmlwidgets, networkD3, readxl, tidyverse, webshot |  | error, group, sample | specialized_package |
| 3.Nature复现-折线图+柱状图+误差线+多重比较 | `3.Nature复现-折线图+柱状图+误差线+多重比较/line_bar_errorbar_significant.R` | grouped bar / stacked bar / errorbar | `decorative_or_case_specific` | reshape2, tidyverse | geom_hline, geom_jitter, geom_rect, geom_vline | network, value | case_specific_grob_layout |
| 30.Nature复现-分面散点饼图 | `30.Nature复现-分面散点饼图/scatterpie_facet.R` | scatter / regression | `template_candidate` | ggh4x, ggpubr, scatterpie, tidyverse | geom_scatterpie, geom_scatterpie_legend | error, feature, network, sample, value | specialized_package |
| 31.Nature复现-绝美环形图 | `31.Nature复现-绝美环形图/demongarphic_info_circos.R` | circos / chord / circular | `specialized_reference` | circlize, gghalves, readxl, tidyverse | geom_bar, geom_boxplot, geom_dotplot | coordinate, error, group, network, sample, value | specialized_package |
| 32.SCI复现-绝美极坐标条形图 | `32.SCI复现-绝美极坐标条形图/circlize_bar_with_errorbar.R` | circos / chord / circular | `specialized_reference` | circlize, readxl |  | error, group, value | specialized_package |
| 32.SCI复现-绝美极坐标条形图 | `32.SCI复现-绝美极坐标条形图/circlize_bar_with_errorbar_11variant-4treat.R` | circos / chord / circular | `specialized_reference` | circlize, readxl, showtext |  | error, group, value | specialized_package |
| 32.SCI复现-绝美极坐标条形图 | `32.SCI复现-绝美极坐标条形图/circlize_bar_without_errorbar.R` | circos / chord / circular | `specialized_reference` | circlize, readxl |  | error, group, value | specialized_package |
| 33.顶刊复现-样本地理分布图 | `33.顶刊复现-样本地理分布图/sampling_map_scatterpie_v1.R` | map / spatial | `specialized_reference` | ggplot2, scatterpie, tidyverse | geom_polygon, geom_scatterpie, geom_scatterpie_legend | coordinate, group, sample, spatial | specialized_package, decorative_or_polar_layout |
| 33.顶刊复现-样本地理分布图 | `33.顶刊复现-样本地理分布图/sampling_map_scatterpie_v2.R` | map / spatial | `specialized_reference` | dplyr, ggplot2, rnaturalearth, rnaturalearthdata, scatterpie, sf, tidyverse | geom_scatterpie, geom_scatterpie_legend, geom_sf | coordinate, group, sample, spatial | specialized_package, decorative_or_polar_layout |
| 33.顶刊复现-样本地理分布图 | `33.顶刊复现-样本地理分布图/sampling_map_scatterpie_v3.R` | map / spatial | `specialized_reference` | ggnewscale, ggplot2, scatterpie, tidyverse | geom_polygon, geom_scatterpie, geom_scatterpie_legend | coordinate, group, network, sample, spatial | specialized_package |
| 34.Lancet复现-绝美极坐标棒棒糖图 | `34.Lancet复现-绝美极坐标棒棒糖图/circlize_ploar_Lollipop.R` | circos / chord / circular | `specialized_reference` | circlize, readxl, tidyverse |  | feature, group, value | specialized_package |
| 35.Cell复现-环形热图 | `35.Cell复现-环形热图/circlize_heatmap.R` | heatmap / matrix | `production_recipe` | ComplexHeatmap, RColorBrewer, circlize, eulerr, grid, readxl, scales, tidyverse |  | feature, group | specialized_package |
| 36.Nature复现-配对散点图 | `36.Nature复现-配对散点图/paired_scatter.R` | ridgeline / density | `template_candidate` | ggside, readxl, tidyverse | geom_point, geom_segment, geom_smooth, geom_ysidedensity | group, metric, value |  |
| 37.Nature复现-网络条形图 | `37.Nature复现-网络条形图/network_bar.R` | network / sankey | `specialized_reference` | ggraph, glue, grid, tidygraph, tidyverse | geom_bar, geom_edge_diagonal, geom_node_point, geom_node_text, geom_text | error, network, sample | specialized_package, decorative_or_polar_layout |
| 37.Nature复现-网络条形图 | `37.Nature复现-网络条形图/network_bubble.R` | network / sankey | `specialized_reference` | ggraph, glue, tidygraph, tidyverse | geom_edge_diagonal, geom_node_point, geom_node_text | error, network | specialized_package |
| 38.顶刊复现-相关性热图 | `38.顶刊复现-相关性热图/corrplot/corrplot.R` | heatmap / matrix | `decorative_or_case_specific` | RColorBrewer, corrplot, ggplot2, grid | geom_rect, geom_text | error, feature, group, metric, network, sample, spatial, value | decorative_or_polar_layout |
| 38.顶刊复现-相关性热图 | `38.顶刊复现-相关性热图/mantel_test/mantel_test.R` | heatmap / matrix | `template_candidate` | Hmisc, dplyr, ggplot2, linkET | geom_couple, geom_mark, geom_square | error, feature, group, metric, network, pvalue, sample, spatial, value |  |
| 38.顶刊复现-相关性热图 | `38.顶刊复现-相关性热图/pheatmap/pheatmap.R` | heatmap / matrix | `production_recipe` | dplyr, pheatmap, scico, viridis |  | error, feature, group, metric, network, sample, spatial, value |  |
| 39.Nature复现-分组柱状图+ANOVA+事后多重比较 | `39.Nature复现-分组柱状图+ANOVA+事后多重比较/groups-bar-dot-errorbar-Dunnett.R` | map / spatial | `specialized_reference` | DescTools, broom, car, ggfun, readxl, reshape2, tidyverse | geom_bar, geom_hline, geom_jitter, geom_text | group, value |  |
| 39.Nature复现-分组柱状图+ANOVA+事后多重比较 | `39.Nature复现-分组柱状图+ANOVA+事后多重比较/groups-bar-dot-errorbar-break-LSD.R` | map / spatial | `specialized_reference` | DescTools, broom, car, ggbreak, ggprism, ggpubr, readxl, reshape2, ... | geom_bar, geom_jitter | group, value | many_dependencies |
| 4.Nature复现-绝美云雨图 | `4.Nature复现-绝美云雨图/box-violin-dot.R` | map / spatial | `specialized_reference` | gghalves, ggsignif, tidyverse | geom_boxplot, geom_half_violin, geom_jitter, geom_signif | error, network, tree |  |
| 40.Nature复现-平滑曲线-3种方法 | `40.Nature复现-平滑曲线-3种方法/smooth_line1.R` | scatter / regression | `template_candidate` | ggplot2, ggprism, readxl, scales | geom_point, geom_smooth | group, value |  |
| 40.Nature复现-平滑曲线-3种方法 | `40.Nature复现-平滑曲线-3种方法/smooth_line2.R` | scatter / regression | `production_recipe` | ggalt, ggplot2, grid, readxl | geom_point | group, network, value |  |
| 40.Nature复现-平滑曲线-3种方法 | `40.Nature复现-平滑曲线-3种方法/smooth_line3.R` | scatter / regression | `template_candidate` | dplyr, ggplot2, readxl | geom_line, geom_point | group, value |  |
| 41.顶刊复现-分面山脊图 | `41.顶刊复现-分面山脊图/ridges_facet1.R` | ridgeline / density | `production_recipe` | ggridges, readxl, tidyverse | geom_density_ridges | group, network, value |  |
| 41.顶刊复现-分面山脊图 | `41.顶刊复现-分面山脊图/ridges_facet2.R` | ridgeline / density | `production_recipe` | cowplot, ggprism, ggridges, readxl, scales, tidyverse | geom_density_ridges | group, network, sample, value |  |
| 42.顶刊复现-蝴蝶图+小提琴图-堆积柱形图 | `42.顶刊复现-蝴蝶图+小提琴图-堆积柱形图/butterfly_bar.R` | grouped bar / stacked bar / errorbar | `decorative_or_case_specific` | cowplot, grid, patchwork, readxl, tidyverse | geom_col | error, group | case_specific_grob_layout |
| 42.顶刊复现-蝴蝶图+小提琴图-堆积柱形图 | `42.顶刊复现-蝴蝶图+小提琴图-堆积柱形图/butterfly_violin.R` | raincloud / violin / jitter | `template_candidate` | patchwork, readxl, tidyverse | geom_boxplot, geom_violin, geom_vline | error, group, metric, value |  |
| 43.顶刊复现-散点图+线性回归 | `43.顶刊复现-散点图+线性回归/scatter_plot1.R` | scatter / regression | `template_candidate` | ggpmisc, patchwork, readxl, scales, tidyverse | geom_abline, geom_point, geom_smooth | group |  |
| 43.顶刊复现-散点图+线性回归 | `43.顶刊复现-散点图+线性回归/scatter_plot2.R` | enrichment / GSEA | `decorative_or_case_specific` | RColorBrewer, ggplot2, ggpubr, ggrepel, grid, readxl | geom_hline, geom_point, geom_smooth, geom_text_repel, geom_vline | group | case_specific_grob_layout |
| 44.Nature复现-RCS | `44.Nature复现-RCS/RCS_merge.R` | multi-panel manuscript / other | `decorative_or_case_specific` | ggplot2, patchwork, readxl, rms, survival | geom_hline, geom_line, geom_ribbon | error, metric, network, sample | case_specific_grob_layout |
| 45.Nature复现-分面堆积柱形图+误差线+显著性 | `45.Nature复现-分面堆积柱形图+误差线+显著性/stacked_bar_1.R` | grouped bar / stacked bar / errorbar | `template_candidate` | readxl, tidyverse | geom_bar, geom_errorbar, geom_text, geom_vline | coordinate, error, group, value |  |
| 45.Nature复现-分面堆积柱形图+误差线+显著性 | `45.Nature复现-分面堆积柱形图+误差线+显著性/stacked_bar_2.R` | grouped bar / stacked bar / errorbar | `template_candidate` | readxl, reshape2, tidyverse | geom_bar, geom_errorbar, geom_segment, geom_text | coordinate, error, group, value |  |
| 46.SCI复现-相关矩阵图 | `46.SCI复现-相关矩阵图/correlation_ggpair.R` | map / spatial | `specialized_reference` | GGally, ggplotify, ggpmisc, patchwork, readxl, tidyverse | geom_histogram, geom_point, geom_rect, geom_smooth, geom_text | error |  |
| 47.Nature复现-绝美雷达图 | `47.Nature复现-绝美雷达图/1_radar_fmsb.R` | multi-panel manuscript / other | `production_recipe` | fmsb, scales |  | error, group, metric, sample |  |
| 47.Nature复现-绝美雷达图 | `47.Nature复现-绝美雷达图/2_radar_fmsb.R` | multi-panel manuscript / other | `production_recipe` | fmsb, scales |  | error, group, metric, sample |  |
| 47.Nature复现-绝美雷达图 | `47.Nature复现-绝美雷达图/3_radar_facet.R` | multi-panel manuscript / other | `production_recipe` | cowplot, ggh4x, ggiraphExtra, readxl, scales, tidyverse |  | error, group, metric, sample |  |
| 47.Nature复现-绝美雷达图 | `47.Nature复现-绝美雷达图/4_radar_facet.R` | grouped bar / stacked bar / errorbar | `decorative_or_case_specific` | ggradar, patchwork, readxl, scales, tidyverse | geom_bar | error, group, metric, sample | decorative_or_polar_layout |
| 48.Nature复现-差异云雨图 | `48.Nature复现-差异云雨图/diff_raincloud_1.R` | map / spatial | `specialized_reference` | Hmisc, cowplot, gghalves, readxl, tidyverse | geom_boxplot, geom_half_violin, geom_jitter, geom_point, geom_segment | effect, group, value |  |
| 48.Nature复现-差异云雨图 | `48.Nature复现-差异云雨图/diff_raincloud_2.R` | raincloud / violin / jitter | `template_candidate` | gghalves, ggpubr, readxl, rstatix, tidyverse | geom_boxplot, geom_half_violin, geom_point | group, value |  |
| 48.Nature复现-差异云雨图 | `48.Nature复现-差异云雨图/diff_raincloud_3.R` | network / sankey | `specialized_reference` | ggdist, ggpubr, readxl, tidyverse | geom_boxplot | group, value |  |
| 49.顶刊复现-双Y轴+GO富集-嵌套柱形图 | `49.顶刊复现-双Y轴+GO富集-嵌套柱形图/doubleY_GO-enrich.R` | enrichment / GSEA | `template_candidate` | tidyverse | geom_col, geom_line, geom_point, geom_rect, geom_text | feature, group, metric, pvalue, value |  |
| 49.顶刊复现-双Y轴+GO富集-嵌套柱形图 | `49.顶刊复现-双Y轴+GO富集-嵌套柱形图/doubleY_nested-bar.R` | grouped bar / stacked bar / errorbar | `template_candidate` | readxl, scales, tidyverse | geom_col, geom_errorbar, geom_hline, geom_jitter | error, feature, group, metric, network, pvalue, value |  |
| 5.Nature复现-分组柱状图+误差线+抖点图+t检验 | `5.Nature复现-分组柱状图+误差线+抖点图+t检验/bar-groups-error-dot.R` | grouped bar / stacked bar / errorbar | `template_candidate` | readxl, reshape2, rstatix, tidyverse | geom_bar, geom_jitter, geom_text | group, spatial, value |  |
| 50.Nature复现-绝美时序图 | `50.Nature复现-绝美时序图/time_series_1.R` | multi-panel manuscript / other | `production_recipe` | ggplot2, readxl | geom_line, geom_ribbon, geom_vline | error, group, value |  |
| 50.Nature复现-绝美时序图 | `50.Nature复现-绝美时序图/time_series_2.R` | multi-panel manuscript / other | `production_recipe` | ggplot2, patchwork, readxl | geom_line, geom_ribbon | error, group, value |  |
| 50.Nature复现-绝美时序图 | `50.Nature复现-绝美时序图/time_series_3.R` | grouped bar / stacked bar / errorbar | `template_candidate` | ggplot2, patchwork, readxl | geom_errorbar, geom_hline, geom_line | error, group, value |  |
| 50.Nature复现-绝美时序图 | `50.Nature复现-绝美时序图/time_series_4.R` | grouped bar / stacked bar / errorbar | `production_recipe` | ggpubr, readxl, rstatix, tidyverse |  | error, group, value |  |
| 51.Nature复现-小提琴图+NMDS分析 | `51.Nature复现-小提琴图+NMDS分析/violin_NMDS.R` | PCA / PCoA / ordination | `template_candidate` | ggpubr, patchwork, readxl, scales, tidyverse, vegan | geom_boxplot, geom_point, geom_polygon, geom_signif, geom_violin | coordinate, error, group, network, sample, spatial, value |  |
| 52.Nature复现-FC-FC散点+象限图 | `52.Nature复现-FC-FC散点+象限图/FC-FC_grid_1.R` | scatter / regression | `template_candidate` | ggrepel, readxl, scales, tidyverse | geom_abline, geom_hline, geom_point, geom_text_repel, geom_vline | effect, error, feature, network, pvalue, sample |  |
| 52.Nature复现-FC-FC散点+象限图 | `52.Nature复现-FC-FC散点+象限图/FC-FC_grid_2.R` | scatter / regression | `decorative_or_case_specific` | grid, readxl, tidyverse | geom_hline, geom_point, geom_vline | effect, error, feature, network, pvalue, sample | case_specific_grob_layout |
| 53.Nature复现-PCoA+多分组边缘图 | `53.Nature复现-PCoA+多分组边缘图/PCoA_marginalBox.R` | PCA / PCoA / ordination | `template_candidate` | cowplot, patchwork, readxl, tidyverse, vegan | geom_boxplot, geom_point | group |  |
| 54.SCI复现-分组散点矩阵图+相关性网络图 | `54.SCI复现-分组散点矩阵图+相关性网络图/corr-link_ggpair.R` | map / spatial | `specialized_reference` | GGally, Hmisc, cowplot, ggplotify, linkET, patchwork, readxl, tidyverse | geom_couple, geom_point, geom_smooth | group, network, pvalue, sample, value |  |
| 55.Nature复现-细胞丰度差异蜂群图 | `55.Nature复现-细胞丰度差异蜂群图/logFC_beeswarm_1.R` | multi-panel manuscript / other | `decorative_or_case_specific` | ggbeeswarm, ggtext, grid, patchwork, readxl, tidyverse | geom_beeswarm, geom_vline | effect, group | case_specific_grob_layout |
| 55.Nature复现-细胞丰度差异蜂群图 | `55.Nature复现-细胞丰度差异蜂群图/logFC_beeswarm_2.R` | multi-panel manuscript / other | `decorative_or_case_specific` | ggbeeswarm, grid, readxl, tidyverse | geom_quasirandom, geom_vline | effect, group | case_specific_grob_layout |
| 56.Nature复现-散点图+线性和对数拟合线 | `56.Nature复现-散点图+线性和对数拟合线/scatter_fits_1.R` | scatter / regression | `template_candidate` | ggpmisc, patchwork, readxl, tidyverse | geom_hline, geom_line, geom_point, geom_smooth | value |  |
| 57.Cell复现-冲击图+背靠背堆积柱形图 | `57.Cell复现-冲击图+背靠背堆积柱形图/butterfly_stacked_bar.R` | grouped bar / stacked bar / errorbar | `template_candidate` | ggtext, patchwork, readxl, scales, tidyverse | geom_bar, geom_col, geom_text | error, network, sample |  |
| 57.Cell复现-冲击图+背靠背堆积柱形图 | `57.Cell复现-冲击图+背靠背堆积柱形图/ggalluvial_plot.R` | map / spatial | `specialized_reference` | ggalluvial, readxl, tidyverse | geom_alluvium, geom_stratum, geom_text | error, sample | specialized_package |
| 58.Nature复现-环状渐变柱形图+环状分组折线图+显著性 | `58.Nature复现-环状渐变柱形图+环状分组折线图+显著性/circlize-bar.R` | circos / chord / circular | `specialized_reference` | RColorBrewer, readxl, tidyverse | geom_bar, geom_errorbar, geom_segment, geom_text | coordinate, error, group, network, sample, value | decorative_or_polar_layout |
| 58.Nature复现-环状渐变柱形图+环状分组折线图+显著性 | `58.Nature复现-环状渐变柱形图+环状分组折线图+显著性/circlize-group-line.R` | circos / chord / circular | `specialized_reference` | readxl, tidyverse | geom_line, geom_point, geom_segment, geom_text | coordinate, error, group, network, sample, value | decorative_or_polar_layout |
| 59.Nature复现-箱线图+扇形+半圆形 | `59.Nature复现-箱线图+扇形+半圆形/boxplot_point.R` | boxplot / jitter | `production_recipe` | ggbeeswarm, ggpubr, readxl, tidyr, tidyverse | geom_boxplot, geom_quasirandom, geom_text | group, sample, value |  |
| 59.Nature复现-箱线图+扇形+半圆形 | `59.Nature复现-箱线图+扇形+半圆形/boxplot_point_sector.R` | boxplot / jitter | `production_recipe` | ggbeeswarm, readxl, tidyr, tidyverse | geom_boxplot, geom_quasirandom, geom_text | group, sample, value |  |
| 59.Nature复现-箱线图+扇形+半圆形 | `59.Nature复现-箱线图+扇形+半圆形/boxplot_point_semicircle.R` | raincloud / violin / jitter | `template_candidate` | readxl, tidyverse | geom_boxplot, geom_text, geom_violin | group, sample, value |  |
| 6.Cell复现-双Y轴+富集条形图 | `6.Cell复现-双Y轴+富集条形图/doubleY-enrich-col.R` | enrichment / GSEA | `template_candidate` | tidyverse | geom_col, geom_line, geom_point, geom_rect, geom_text | feature, metric, pvalue, value |  |
| 60.Nature复现-相关性矩阵Dotplot+显著性 | `60.Nature复现-相关性矩阵Dotplot+显著性/corr_Dotplot_sig1.R` | scatter / regression | `template_candidate` | cowplot, readxl, tidyverse | geom_point, geom_text | error, feature, group, pvalue, spatial, value |  |
| 60.Nature复现-相关性矩阵Dotplot+显著性 | `60.Nature复现-相关性矩阵Dotplot+显著性/corr_Dotplot_sig2.R` | scatter / regression | `template_candidate` | readxl, tidyverse | geom_point, geom_text, geom_vline | error, feature, group, pvalue, spatial, value |  |
| 61.Nature复现-差异雷达图 | `61.Nature复现-差异雷达图/diff_radar_1.R` | ridgeline / density | `decorative_or_case_specific` | emmeans, ggradar, lme4, lmerTest, patchwork, readxl, tidyverse | geom_text | error, group, sample, value | decorative_or_polar_layout |
| 61.Nature复现-差异雷达图 | `61.Nature复现-差异雷达图/diff_radar_2.R` | map / spatial | `specialized_reference` | ggradar, readxl, tidyverse |  | error, group, sample, value |  |
| 62.Nature复现-分组型和单组型环状条形图 | `62.Nature复现-分组型和单组型环状条形图/circlize_gradient_bar.R` | heatmap / matrix | `production_recipe` | ComplexHeatmap, RColorBrewer, circlize, dplyr, readxl |  | error, group, value | specialized_package |
| 62.Nature复现-分组型和单组型环状条形图 | `62.Nature复现-分组型和单组型环状条形图/circlize_group_bar.R` | circos / chord / circular | `specialized_reference` | circlize, dplyr, readxl |  | error, group, value | specialized_package |
| 63.Nature复现-填充型和渐变型等高线图 | `63.Nature复现-填充型和渐变型等高线图/contour_filled.R` | ridgeline / density | `decorative_or_case_specific` | RColorBrewer, ggpubr, readxl, tidyverse | geom_density2d_filled | coordinate, error, feature, group, sample | case_specific_grob_layout |
| 63.Nature复现-填充型和渐变型等高线图 | `63.Nature复现-填充型和渐变型等高线图/contour_gradient.R` | map / spatial | `specialized_reference` | ggnewscale, ggrepel, readxl, tidyverse | geom_abline, geom_density_2d, geom_point, geom_text_repel | coordinate, error, feature, group, sample |  |
| 64.Nature复现-深度美化散点气泡图 | `64.Nature复现-深度美化散点气泡图/group_bubble.R` | lollipop / dumbbell / dotplot | `template_candidate` | dplyr, ggplot2, readxl, showtext | geom_point, geom_segment | error, group |  |
| 64.Nature复现-深度美化散点气泡图 | `64.Nature复现-深度美化散点气泡图/group_point.R` | map / spatial | `specialized_reference` | dplyr, ggplot2, ggpubr, readxl, scales, tidyr | geom_point, geom_vline | error, group |  |
| 65.Cell复现-基础热图-分面和对称风格 | `65.Cell复现-基础热图-分面和对称风格/facet_tiles.R` | map / spatial | `specialized_reference` | ggplot2, patchwork, plyr, readxl, scales | geom_point | error, group, sample |  |
| 65.Cell复现-基础热图-分面和对称风格 | `65.Cell复现-基础热图-分面和对称风格/paired_tiles.R` | heatmap / matrix | `template_candidate` | ggnewscale, ggplot2, readxl | geom_point, geom_tile | error, group, sample |  |
| 66.iMeta-Nature-多分组火山图 | `66.iMeta-Nature-多分组火山图/volcano_facet1.R` | volcano / enrichment | `production_recipe` | cowplot, ggh4x, readxl, scales, tidyverse | geom_point | effect, feature, group |  |
| 66.iMeta-Nature-多分组火山图 | `66.iMeta-Nature-多分组火山图/volcano_facet2.R` | volcano / enrichment | `template_candidate` | ggrepel, readxl, tidyverse | geom_hline, geom_point, geom_text_repel | effect, feature, group |  |
| 66.iMeta-Nature-多分组火山图 | `66.iMeta-Nature-多分组火山图/volcano_facet3.R` | volcano / enrichment | `production_recipe` | corrplot, readxl, scRNAtoolVis |  | effect, feature, group |  |
| 67.iMeta-Nature-火山图+富集图 | `67.iMeta-Nature-火山图+富集图/volcano_enrich1.R` | volcano / enrichment | `template_candidate` | aPEAR, clusterProfiler, ggrepel, ggtext, org.Hs.eg.db, patchwork, readxl, tidyverse | geom_point, geom_text_repel | effect, feature, pvalue, sample, value |  |
| 67.iMeta-Nature-火山图+富集图 | `67.iMeta-Nature-火山图+富集图/volcano_enrich2.R` | volcano / enrichment | `template_candidate` | dplyr, ggplot2, ggrepel, patchwork, readxl | geom_bar, geom_hline, geom_point, geom_text, geom_vline | effect, feature, pvalue, sample, value |  |
| 67.iMeta-Nature-火山图+富集图 | `67.iMeta-Nature-火山图+富集图/volcano_enrich3.R` | volcano / enrichment | `template_candidate` | dplyr, ggplot2, ggrepel, patchwork, readxl, stringr | geom_bar, geom_hline, geom_point, geom_text, geom_text_repel, geom_vline | effect, feature, metric, pvalue, sample, value |  |
| 68.顶刊复现-upset图 | `68.顶刊复现-upset图/ComplexUpset_plot/ComplexUpset_plot.R` | upset / set plot | `specialized_reference` | ComplexUpset, ggplot2, readxl | geom_bar, geom_point | effect, error, feature, pvalue, sample, value | specialized_package |
| 68.顶刊复现-upset图 | `68.顶刊复现-upset图/ComplexUpset_plot/Venn_plot.R` | upset / set plot | `specialized_reference` | VennDiagram, dplyr, grid |  | effect, feature, pvalue, sample | case_specific_grob_layout |
| 68.顶刊复现-upset图 | `68.顶刊复现-upset图/upsetR_plot/upsetR_plot.R` | upset / set plot | `specialized_reference` | UpSetR, corrplot, ggplot2, grid, readxl, tibble |  | effect, feature, pvalue, sample | specialized_package, case_specific_grob_layout |
| 68.顶刊复现-upset图 | `68.顶刊复现-upset图/upsetR_plot/utils.R` | upset / set plot | `specialized_reference` | UpSetR | geom_line, geom_point, geom_rect | effect, error, feature, pvalue, sample | specialized_package |
| 69.SciAdv复现-差异OTU曼哈顿图 | `69.SciAdv复现-差异OTU曼哈顿图/beautiful_bubble.R` | map / spatial | `specialized_reference` | dplyr, ggplot2, patchwork, readxl | geom_hline, geom_point, geom_segment, geom_text, geom_vline | coordinate, error, group | decorative_or_polar_layout |
| 7.Nature复现-气泡热图（绿色系） | `7.Nature复现-气泡热图（绿色系）/bubble-heatmap-nature.R` | heatmap / matrix | `production_recipe` | ggpubr, readxl, tidyverse | geom_point | feature, group, network |  |
| 7.Nature复现-气泡热图（绿色系） | `7.Nature复现-气泡热图（绿色系）/bubble-heatmap.R` | heatmap / matrix | `production_recipe` | ggpubr, readxl, tidyverse | geom_point | feature, group, network |  |
| 70.Nature-PNAS-中国地图 | `70.Nature-PNAS-中国地图/map1.R` | map / spatial | `specialized_reference` | dplyr, ggnewscale, ggplot2, ggspatial, readxl, rnaturalearth, rnaturalearthdata, scatterpie, ... | geom_scatterpie, geom_scatterpie_legend, geom_sf, geom_text | error, network, sample, value | specialized_package, case_specific_grob_layout |
| 70.Nature-PNAS-中国地图 | `70.Nature-PNAS-中国地图/map2.R` | map / spatial | `specialized_reference` | dplyr, ggplot2, ggspatial, purrr, readxl, sf | geom_point, geom_sf, geom_text | error, sample, value | specialized_package, case_specific_grob_layout |
| 71.Cell-上下三角双热图 | `71.Cell-上下三角双热图/double_heatmap_1color.R` | heatmap / matrix | `production_recipe` | ComplexHeatmap, RColorBrewer, circlize, dplyr, tidyr |  | coordinate, error, feature, group, network, sample, tree | specialized_package |
| 71.Cell-上下三角双热图 | `71.Cell-上下三角双热图/double_heatmap_2colors.R` | heatmap / matrix | `production_recipe` | ComplexHeatmap, circlize, dplyr, tidyr |  | coordinate, error, feature, group, network, sample, tree | specialized_package |
| 72.Cell-Nature-带显著性的小提琴图 | `72.Cell-Nature-带显著性的小提琴图/compare_violin_1.R` | raincloud / violin / jitter | `production_recipe` | ggh4x, ggpubr, readxl, tidyverse | geom_violin | group |  |
| 72.Cell-Nature-带显著性的小提琴图 | `72.Cell-Nature-带显著性的小提琴图/compare_violin_2.R` | raincloud / violin / jitter | `decorative_or_case_specific` | ggpubr, grid, readxl, rstatix, tidyverse | geom_jitter, geom_violin | group | case_specific_grob_layout |
| 72.Cell-Nature-带显著性的小提琴图 | `72.Cell-Nature-带显著性的小提琴图/compare_violin_3.R` | raincloud / violin / jitter | `template_candidate` | ggplot2, grid, readxl, tidyverse | geom_hline, geom_violin | group |  |
| 73.Cell-Nature-三元图 | `73.Cell-Nature-三元图/ternary_plot1.R` | scatter / regression | `template_candidate` | ggtern, readxl, tidyverse | geom_mask, geom_point | feature, group, sample | specialized_package |
| 73.Cell-Nature-三元图 | `73.Cell-Nature-三元图/ternary_plot2.R` | scatter / regression | `production_recipe` | ggtern, readxl, tidyverse | geom_point | feature, group, sample | specialized_package |
| 73.Cell-Nature-三元图 | `73.Cell-Nature-三元图/ternary_plot3.R` | enrichment / GSEA | `template_candidate` | dplyr, ggtern, readxl, tidyr | geom_mask, geom_point | feature, group, sample | specialized_package |
| 73.Cell-Nature-三元图 | `73.Cell-Nature-三元图/ternary_plot4.R` | scatter / regression | `template_candidate` | ggtern, readxl | geom_mask, geom_point | feature, group, sample | specialized_package |
| 74.Nature-密度+相关性矩阵 | `74.Nature-密度+相关性矩阵/density_corr_matrix.R` | heatmap / matrix | `template_candidate` | GGally, cowplot, ggplot2, ggplotify, readxl | geom_text, geom_tile | error |  |
| 75.Nature-绝美点线图 | `75.Nature-绝美点线图/line_dot.R` | scatter / regression | `template_candidate` | dplyr, ggplot2, ggprism, readxl, scales, tidyr, viridis | geom_line, geom_point | group |  |
| 76.Cell-环形热图+upset图 | `76.Cell-环形热图+upset图/circlize_heatmap_upset.R` | heatmap / matrix | `production_recipe` | ComplexHeatmap, RColorBrewer, circlize, grid, readxl, tidyverse |  | feature, group | specialized_package |
| 76.Cell-环形热图+upset图 | `76.Cell-环形热图+upset图/circlize_heatmap_venn.R` | heatmap / matrix | `production_recipe` | ComplexHeatmap, RColorBrewer, circlize, eulerr, grid, readxl, scales, tidyverse |  | feature, group | specialized_package |
| 77.Nature-对角线散点图+直方图 | `77.Nature-对角线散点图+直方图/scatter_histogram.R` | phylogenetic tree | `specialized_reference` | ggpubr, grid, patchwork, readxl, tidyverse | geom_abline, geom_histogram, geom_hline, geom_point, geom_segment, geom_text, geom_vline | group | case_specific_grob_layout |
| 78.Cell-umap+环形分组信息 | `78.Cell-umap+环形分组信息/circ_umap.R` | PCA / PCoA / ordination | `decorative_or_case_specific` | ComplexHeatmap, Seurat, circlize, grid, scales, tidyverse |  |  | specialized_package, decorative_or_polar_layout |
| 79.Nature-环状条形图+饼图 | `79.Nature-环状条形图+饼图/circlize_bar_pie.R` | circos / chord / circular | `specialized_reference` | circlize, dplyr, grid, readxl |  | value | specialized_package |
| 8.顶刊复现-系统发育树+外圈热图-条形图 | `8.顶刊复现-系统发育树+外圈热图-条形图/Rimal.2024.Nature.figure1d/Figure1d.R` | heatmap / matrix | `template_candidate` | forcats, ggnewscale, ggsci, ggtext, ggtree, phangorn, tidyverse | geom_cladelab, geom_hilight, geom_point2, geom_tiplab | coordinate, error, feature, group, network, sample, spatial | specialized_package |
| 8.顶刊复现-系统发育树+外圈热图-条形图 | `8.顶刊复现-系统发育树+外圈热图-条形图/example1.R` | map / spatial | `specialized_reference` | ggnewscale, ggtree, ggtreeExtra, readxl, tidyverse, treeio | geom_fruit, geom_text | coordinate, error, feature, group, network, sample, spatial | specialized_package |
| 8.顶刊复现-系统发育树+外圈热图-条形图 | `8.顶刊复现-系统发育树+外圈热图-条形图/example2.R` | heatmap / matrix | `production_recipe` | ggnewscale, ggtree, ggtreeExtra, phangorn, tidyverse, treeio | geom_fruit | coordinate, error, feature, group, network, sample, spatial | specialized_package |
| 8.顶刊复现-系统发育树+外圈热图-条形图 | `8.顶刊复现-系统发育树+外圈热图-条形图/example3.R` | map / spatial | `specialized_reference` | ggnewscale, ggtree, ggtreeExtra, tidyverse, treeio | geom_fruit, geom_highlight, geom_tiplab | coordinate, error, feature, group, network, sample, spatial | specialized_package |
| 80.Nature-分面山脊图+垂直刻度 | `80.Nature-分面山脊图+垂直刻度/facet_ridge.R` | ridgeline / density | `template_candidate` | ggridges, readxl, scales, tidyverse, viridis | geom_density_ridges2, geom_point, geom_text | group, sample, value |  |
| 9.Nature复现-山脊图 | `9.Nature复现-山脊图/ridges.R` | map / spatial | `specialized_reference` | ggpubr, ggridges, tidyverse | geom_density_ridges, geom_signif | network, value |  |

## How To Use This Index

- Use `production_recipe` and `template_candidate` cases as source evidence for reusable code recipes.
- Use `specialized_reference` cases to learn data requirements and layout boundaries, not default thresholds.
- Use `decorative_or_case_specific` cases as caution examples when grob-level or polar decoration is hard to generalize.
- Original scripts are provenance. Executable skill recipes must remove hard-coded local paths and expose a clean input schema.
