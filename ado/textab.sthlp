{smcl}
{* *! version 0.3.0  20oct2026}{...}
{viewerjumpto "syntax" "Syntax"}{...}
{viewerjumpto "description" "Description"}{...}
{viewerjumpto "options" "Options"}{...}
{viewerjumpto "install" "Installation"}{...}
{viewerjumpto "examples" "Examples"}{...}
{viewerjumpto "output" "输出效果"}{...}
{title:textab — Stata 表格转 LaTeX 三线表}

{pstd}
{cmd:textab} 把 Stata 的统计结果（回归、频数/交叉表、描述统计、变量定义表）
直接输出成 {cmd:booktabs} 三线表 LaTeX 片段，可直接 {cmd:\input} 进 thuthesis 论文，
也可独立编译预览。

{pstd}
底层不手写表格，而是薄包装两个成熟命令：
{cmd:reg} 包 {help esttab}（读已存估计、t 分布星号），
{cmd:tab}/{cmd:stat}/{cmd:table} 包 {help table}（多级行列表头 + 小计），
导出原始 tex 后再经 retex.py 换表头统一成三线表。

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:textab} {cmd:reg} [{it:estnames}] [using {it:filename}] {cmd:,}
[{opth caption:(string)} {opth label:(string)}
{opt mode(independ|input)} {opt orientation(portrait|landscape)}
{opth models:(string)} {opth note:(string)} {opt replace}]

{p 8 16 2}
{cmd:textab} {cmd:tab} {it:varlist} [{cmd:min=1 max=2}] [using {it:filename}] {cmd:,}
[{opth statistic:(string)} {it:options}]

{p 8 16 2}
{cmd:textab} {cmd:stat} {it:varlist} [using {it:filename}] {cmd:,}
[{opth statistic:(string)} {opth by:(varname)} {it:options}]

{p 8 16 2}
{cmd:textab} {cmd:table} [{it:dimspec}] [using {it:filename}] {cmd:,}
[{opth statistic:(string)} {opth collectopts:(string)} {it:options}]

{p 8 16 2}
{cmd:textab} {cmd:list} {it:varlist} [using {it:filename}] {cmd:,}
[{opth template:(string)} {opth columns:(string)} {opth colformat:(string)} {it:options}]

{p 8 16 2}
{cmd:textab} {cmd:env}

{pstd}
其中 {it:options} 为公共选项（见下）。

{marker description}{...}
{title:Description}

{pstd}
{cmd:textab reg} 输出线性回归结果表：系数 + 括号内标准误 + 显著性星号
（t 分布，* p<0.05 / ** p<0.01 / *** p<0.001）+ 样本量 N + R{superscript:2}。
{it:estnames} 为 {cmd:estimates store} 存的估计名；省略时用最近一次回归的 {cmd:e()}。

{pstd}
{cmd:textab tab} 输出一维频数表或二维交叉表（含行列 Total 小计）。
{cmd:textab stat} 输出描述统计表：默认行为「行=统计量、列=变量」，
加 {cmd:by()} 后「行=分组（含小计）、列=统计量」。
{cmd:textab table} 是逃生舱，{it:dimspec} 直接按 {help table} 的维度语法写
（如 {cmd:(foreign) (rep78)}），适合任意多级表。

{pstd}
{cmd:textab env} 检测运行环境：逐一检查 Python、jinja2、esttab 是否就绪，
报告当前可用的环境路径，缺哪个则报错并提示如何安装。

{marker options}{...}
{title:Options}

{pstd}
公共选项（各子命令通用）：

{phang}
{opth caption:(string)} 表题，放在 {cmd:\caption} 内。未指定时用输出文件名兜底。

{phang}
{opth label:(string)} 标签，自动生成 {cmd:\label\{tab:XXX\}}（只需写 XXX，不含 {cmd:tab:} 前缀）。未指定时用输出文件名兜底。

{phang}
{opt mode(independ|input)} 输出模式。默认 {cmd:independ}（套导言区 + 文档壳，可独立编译）；
{cmd:input} 只出表格片段，交给论文主文件 {cmd:\input}。默认 {cmd:independ}。

{phang}
{opt orientation(portrait|landscape)} 排版方向。{cmd:landscape} 时把表格包进
{cmd:\begin\{landscape\}}（{cmd:pdflscape} 宏包）。默认 {cmd:portrait}。

{phang}
{opt replace} 覆盖同名输出文件；不加 {cmd:replace} 且文件已存在时自动改名加序号。

{phang}
{opt lang(en|zh)} 表格内文本语言，仅 {cmd:tab}/{cmd:stat}/{cmd:table} 支持。
{cmd:zh} 时把 collect 导出的 {cmd:Total} 换成「合计」；默认 {cmd:en}（不替换）。

{pstd}
各子命令专属选项：

{phang}
{cmd:reg}：{opth models:(string)} 表头列名（映射 esttab 的 {cmd:mtitles()}）；
{opth note:(string)} 表注（默认给出中文显著性说明）。

{phang}
{cmd:stat}：{opth statistic:(string)} 统计量列表（空格分隔，如
{cmd:mean sd min max}），{cmd:n} 等价于 {cmd:count}（样本量）。默认 {cmd:mean sd min max n}；
{opth by:(varname)} 分组变量，自动带 Total 小计。

{phang}
{cmd:tab}：{opth statistic:(string)} 单元格统计量，默认 {cmd:freq}（频数）。

{phang}
{cmd:table}：{opth statistic:(string)} 单个统计量；
{opth collectopts:(string)} 原样追加到 {cmd:table} 命令后（如 {cmd:nototals}、
额外的 {cmd:statistic()}、{cmd:nformat()} 等）。

{phang}
{cmd:list}：{opth template:(string)} 模板名（默认 {cmd:02_变量定义表.tex}）；
{opth columns:(string)} 三列表头；{opth colformat:(string)} 列对齐。

{marker install}{...}
{title:Installation}

{pstd}
把 ado 目录加入 {cmd:adopath} 后即可使用，无需手动配置路径：
{cmd:textab} 会自动定位 {cmd:code_py/} 与 {cmd:templates/}，
Python 默认走 PATH（{cmd:python}）；环境未就绪时先运行 {cmd:textab env} 排查。

{pstd}
依赖（Dependencies）：
{p 8 12 2}
- Stata 17+（{cmd:table}/{cmd:collect} 需要）
- Python >=3.10 + {cmd:jinja2}（{cmd:textab list} 需要；reg/tab/stat/table 只用标准库）
- {cmd:esttab}（{cmd:textab reg} 需要，来自 {cmd:ssc install estout}）
- LaTeX 发行版（编译预览 PDF 用，仅 {cmd:mode(independ)} 需要）

{pstd}
运行时若报错，先运行 {cmd:textab env} 排查依赖是否就绪。

{p 4 8 2}
1. 把 ado 目录加入搜索路径（或直接把 .ado 放进 personal/plus 目录）：
{cmd:adopath + "本仓库路径/ado"}。

{p 4 8 2}
2. 验证环境：运行 {cmd:textab env}。

{pstd}
下载后如果不确定依赖 / 环境是否就绪，运行 {cmd:textab env} 即可查看情况：
它会逐一检测 Python、jinja2、esttab，报告当前可用路径，缺哪个会提示如何安装
（Python 用 {cmd:python --version} 验证、esttab 用 {cmd:ssc install estout}、
jinja2 用 {cmd:pip install jinja2}），全部就绪则提示 {cmd:All dependencies are ready.}。

{marker examples}{...}
{title:Examples}

{pstd}
以下示例全部基于 Stata 官方示范数据 {cmd:auto.dta}（1978 年汽车数据），
先 {cmd:sysuse auto, clear} 载入，输出写到当前工作目录；均可直接复现。{p_end}

{pstd}（0）检查环境依赖{p_end}
{phang2}{cmd:. textab env}

{pstd}（1）回归结果表 —— 先存估计再出表{p_end}
{phang2}{cmd:. regress price mpg weight}
{phang2}{cmd:. estimates store m1}
{phang2}{cmd:. regress price mpg weight length}
{phang2}{cmd:. estimates store m2}
{phang2}{cmd:. textab reg m1 m2 using 01_reg.tex, caption("线性回归结果") label(reg)}

{pstd}（2）描述统计 —— 行=统计量、列=变量{p_end}
{phang2}{cmd:. textab stat price mpg weight using 02_stat.tex, statistic(mean sd min max n) caption("变量描述统计") label(stat)}

{pstd}（3）分组描述统计 —— 含 Total 小计{p_end}
{phang2}{cmd:. textab stat price using 03_stat_by.tex, by(foreign) statistic(mean sd) caption("分产地描述统计") label(statby)}

{pstd}（4）一维频数 / 二维交叉表{p_end}
{phang2}{cmd:. textab tab rep78 using 04_tab_1d.tex, caption("维修记录频数") label(tab1d)}
{phang2}{cmd:. textab tab foreign rep78 using 05_tab_2d.tex, caption("产地×维修交叉表") label(tab2d)}

{pstd}（5）通用多级表 —— 维度语法同 {help table}{p_end}
{phang2}{cmd:. textab table (foreign) (rep78) using 06_table.tex, statistic(freq) caption("通用多级表") label(table)}

{pstd}（6）变量定义表 —— 自动读变量标签与值标签{p_end}
{phang2}{cmd:. textab list make foreign rep78 using 07_list.tex, caption("变量定义表") label(list)}

{pstd}（7）横向宽表 + 独立编译 + 中文小计{p_end}
{phang2}{cmd:. textab stat price mpg weight headroom using 08_stat_land.tex, statistic(mean sd) caption("横向宽表") label(statland) mode(independ) orientation(landscape) lang(zh)}

{marker output}{...}
{title:输出效果}

{pstd}
每条命令生成一个 {cmd:booktabs} 三线表：{cmd:\toprule}（顶线）、{cmd:\midrule}（中线）、
{cmd:\bottomrule}（底线）三条横线，无竖线；表题在上、标签自动加 {cmd:tab:} 前缀、正文 {cmd:\small}。
以（2）描述统计为例，编译后是一张「变量 × 统计量」三线表：行是 price/mpg/weight 三个变量，
列是均值/标准差/最小值/最大值/样本量五列，顶部表题、底部三线。{p_end}

{pstd}
{cmd:mode(independ)}（默认）再套上 {cmd:ctexart} 导言区与文档壳，用 {cmd:xelatex} 即可直接编译成 PDF 预览；
{cmd:mode(input)} 只出表格片段，交给论文主文件 {cmd:\input}。
{cmd:lang(zh)} 会把分组表里的 {cmd:Total} 换成「合计」。{p_end}

{pstd}
仓库 {cmd:examples/} 目录附有各子命令的 {cmd:mode(input)} 输出片段
（{cmd:01_reg.tex} ~ {cmd:08_stat_land.tex}）与可复现脚本 {cmd:textab_examples.do}，可打开对照效果。{p_end}
