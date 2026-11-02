# textab

**textab for Stata, based on esttab and collect.**

Stata → LaTeX 三线表自动生成工具。在 Stata 里一条命令生成符合学术论文规范（booktabs 三线表）的 LaTeX 表格，用于 `\input` 进论文或独立编译预览。

核心思路：**Stata 负责算数出数据，Python 负责换表头/套模板，LaTeX（xelatex）负责排版出 PDF**。不手写表格代码，而是包装 Stata 成熟的 `esttab` / `collect` 命令，再用 Python 后处理统一换成 booktabs 三线表格式。

## 特性

- **一条命令出表**：`textab` 覆盖交叉表（tab）、描述统计（stat）、多级分组表（table）、估计结果表（est，回归/固定效应/结构方程）、变量定义表（list）五种需求。
- **包装成熟命令**：估计表回归类包装 `esttab`（读已存估计、t 分布星号）、SEM 直接读 `e(b)/e(V)` 排版，交叉/描述/分组表包装 `collect`（原生多级表头 + 小计），星号、分组全由成熟命令给出，不自己算。
- **统一三线表**：`retex.py` 把 esttab/collect 的原始 tex 换成 thuthesis booktabs 三线表（`\toprule`/`\midrule`/`\bottomrule`，去竖线）。
- **两种形态**：`mode(input)` 出纯片段（`\input` 进论文），`mode(independ)` 出完整文档（自带导言区，可独立编译预览）；`orientation(landscape)` 出横向宽表。

## 系统要求

- Stata 17+（`collect` 从 17 引入；`textab.ado` 声明 `version 17.0`）
- Python ≥3.10，需装 `jinja2`
- LaTeX 发行版（xelatex，中文依赖 xelatex）

## 安装

### 1. Python 依赖

```bash
pip install -r config/requirements.txt
```

### 2. 安装

把仓库放到本地后，把 `ado/` 目录加入 Stata 搜索路径即可（`textab` 会自动定位 `code_py/` 与 `templates/`，并识别 Python，无需手动配置）：

```stata
adopath + "F:/.project/07textab/ado"   // 换成你的实际路径
```

检查依赖（自动检测 esttab、Python、jinja2 是否就位）：

```stata
which textab
textab env
```

## 用法

```stata
* 交叉表（频数/百分比）
textab tab 行变量 列变量 using 输出.tex, caption("表题") label("章-序号") mode(input)

* 描述统计
textab stat 变量1 变量2, statistic(mean sd min max n)

* 多级分组表
textab table (行1 行2) (列1 列2), statistic(mean)

* 估计结果表（先 estimates store；regress/xtreg/logit/sem 均自动识别）
textab est est1 est2 using 输出.tex, caption("表题") label("章-序号")

* 结构方程模型（自动读 e(b)/e(V)，附拟合指标；加 variance 显示误差方差）
sem (price <- mpg weight) (mpg <- weight)
textab est using 输出_sem.tex, caption("结构方程模型") label("章-序号")

* 变量定义表
textab list 变量1 变量2, caption("表题") label("章-序号")
```

常用选项：`mode(input|independ)`（片段/独立编译）、`orientation(portrait|landscape)`（纵向/横向）、`caption()`（表题）、`label()`（标签，自动加 `tab:` 前缀）、`lang(en|zh)`（表格文本语言，仅 tab/stat/table）。

更多见 `examples/textab_examples.do` 与 `help textab`。

## 目录结构

| 路径 | 作用 |
| --- | --- |
| `ado/` | Stata 命令：`textab.ado` + `_textab_*.ado` + `textab.sthlp` |
| `code_py/` | Python：`retex.py`（换表头）+ `json2tex.py`（Jinja2 渲染） |
| `templates/` | LaTeX 模板：body 片段 + `_preamble.tex` 共享导言区 |
| `config/` | `config.json` + `requirements.txt` |
| `examples/` | 各子命令示例 |

## License

[MIT](LICENSE)
