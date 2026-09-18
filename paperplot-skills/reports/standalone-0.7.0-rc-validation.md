# standalone-0.7.0-rc.1 实施与验收记录

更新：2026-09-17。基线：`9ae461e / standalone-0.6.0`。
分支：`codex/standalone-0.7.0`；实现提交：`44f5a76739b1725d7ed20ce9367bf205f497093a`。具体安装来源提交见 `installation.json`；后续记录提交不改变运行代码。

当前状态：14 项全量工程检查全部通过，跳过 0 项。版本保持 RC，不能宣称个人论文场景已验收。

## 已实现

| 工作包 | 实际变化 |
|---|---|
| 科学信息与输入 | 禁止隐式模拟；显式统计参数；PCA/NMDS/PERMANOVA 使用提供的结果；森林图区间和分组不合并；比例、配对、重复键、NA、概率与坐标有检查。配对检验的 n 为配对数；Spearman/Wilcoxon 不再强制使用渐近计算，并记录实际置信水平及警告。 |
| 全目录后端 | 保留 84 个 ID，以 manifest 的 24 个 handler 分派；ComplexHeatmap、ComplexUpset、ggraph、ggalluvial、circlize、sf、ggtree 等实际运行。Manhattan 使用真实 bp，GSEA 使用提供的 running score，树与网络不推断虚构关系。 |
| 尺寸与修改 | render spec 统一尺寸；旧尺寸冲突报错；物理字体、字形、线宽与标签受导出链路约束。保留候选图与 QA；移除旧模板静默丢标签路径；嵌套图按外层 panel 编号，保持矢量元素。基础主题不再覆盖局部图例设置，边缘分布与主图共享测量范围；坐标裁剪不能被当作纯样式修改。 |
| QA 与项目 | 必需检查缺失不通过；精确失败不能被批准覆盖；审查绑定 revision、文件与检测器。项目 schema 2、带备份迁移、分离 build/QA freshness；后续 panel 否决使整图批准失效。嵌套或原生后端的测量盲区明确进入人工待审项。 |
| 环境与安装 | 独立 R 4.6.0 / Python 3.13.15 / Bioconductor 3.23；125 个 R 包锁定；Pillow 12.3.0、pypdf 6.19.0。安装先校验、再备份切换，失败回滚；安装后从仓库外执行真实导出和项目命令。 |

`SKILL.md` 已精简为入口、数据规则、项目流程与交付边界；依赖说明集中到 INSTALL.md。recipe 与模板目录由 manifest 管理，避免重复维护支持清单。

## 验证范围与证据

最新完整运行目录：`visual-checks/formal-20260917-013852/`。其中 `formal-render.json` 记录整体结果、各项日志及源码/环境指纹。
入口：`paperplot-skills/scripts/paperplot-run paperplot-skills/scripts/formal-render.R`。
以下生成文件保留在本机的 ignored 目录，可按脚本重建，不作为私有数据或大体积图像提交到 Git。

| 检查 | 验证内容 |
|---|---|
| 84 个 recipe | 最小合法字段、缺必需字段、科学反例、实际构建；逐项 PDF/SVG/PNG 尺寸、字体、嵌入与标签核对。模拟夹具明确标为 demo。 |
| 36 个模板 | 全部实际生成，metadata、notes 与最终 QA 接通。生成成功不等于 manuscript-ready。 |
| 33 个公开案例 | 覆盖 24 个 handler。真实原始/上游数据、处理说明及来源哈希均保留；逐例执行物理导出检查。 |
| 专用后端反例 | 非法集合成员、负流量/边权、越界区间、错误 CRS/纬度、树节点不匹配等必须失败。 |
| 物理与组成 | 单栏、双栏、180×70 mm Manhattan、183×105 mm IGS 机制夹具、4/6-panel 异构矢量组装。 |
| 项目流程 | 布局确认、B-only 修改、未改 panel 复用、失败不替换 current、恢复、数据/检测器/文件失效、后续否决。新增真实公开数据的 nested/native 项目，检查外层标签与审查路径。 |
| 审批正反路径 | 使用真实导出文件验证通过路径；故意制造尺寸错误后，批准仍不能把 fail 改成 pass。测试审查人明确标记 AUTOMATED FIXTURE，不算真实人工批准。 |
| 安装 | 6 项安全/升级测试；缺依赖、下载失败、错误 profile、断链与安装后验证失败均不破坏旧安装。 |

公开来源包括 R datasets（iris、ToothGrowth、sleep、mtcars、HairEyeColor、UKgas）、CMplot pig60K、公开 airway DESeq2 结果、fgsea exampleRanks/examplePathways、ape bird.orders、igraph Zachary、sf North Carolina。上游 fixture 准备过程与任何筛选、PCA、加权富集路径或 Fisher/BH 计算均在 `test-public-cases.R` 中明确记录，不是绘图入口暗中执行的专业分析。

## 本机安装

- 稳定目录：`~/.agents/skills/paperplot-skills`。
- Codex 入口：`~/.codex/skills/paperplot-skills`，已链接稳定目录，不再链接开发仓库。
- 环境：`~/.local/share/paperplot/runtime-0.7.0`；R 库独立，锁文件恢复已实际验证。
- 安装凭据：稳定目录下 `installation.json`，记录版本、来源提交、dirty-source、环境与哈希。
- 安装后从仓库外执行了真实导出、项目创建与状态检查；138 个运行文件已逐项核对源码哈希。
- 旧安装：`~/.agents/skill-backups/`；原开发链接：`~/.codex/skill-backups/`。备份在技能发现目录外，不会作为第二份 skill 被加载。
- 本次失败的 1.7 GB 临时环境已移到 `~/.Trash/paperplot-failed-runtime-20260917`，可以恢复；未移动或改写原始科研数据。
- Arial 使用本机现有字体，未将字体文件打包进仓库。

## 尚未完成的发布门槛

1. 用户原始 IGS 数据与脚本未提供，真实顺序、分箱、计数、Median/Max、0.95 阈值与原图对比仍待验收。
2. 用户独立 4–6-panel 主图的数据、脚本/项目未提供，不能用公开或模拟案例代替。
3. 最终真实人工审阅尚未完成。自动化审查夹具只证明状态机可达，不构成论文批准。
4. 本次提交尚未 push；当前 GitHub CI、远程安装与正式 runner 未执行。GitHub 的 formal-render 定义需要具备锁定环境和合法 Arial 的受控 runner，不会用跳过冒充成功。
5. 精确系统环境锁目前验证于 macOS ARM64；其他平台的 environment.yml 是 bootstrap，不宣称已完成跨平台正式验收。

因此只交付 RC。未创建稳定版标签、未合并 main，也不声称整份论文验收目标已完成。
