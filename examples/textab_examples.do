*==============================================================================*
**#1            textab 示例脚本：6 个子命令 + 关键选项典型用法
*==============================================================================*
* 运行前需已安装 textab（见 setup / textab.sthlp 的 Installation）：
*   把 ado/ 加入 adopath 即可，textab 会自动定位 code_py/ 与 templates/。
* 本脚本用自带 auto 数据演示，输出 8 张表格到当前目录。

set more off

*------------------------------------------------------------------------------
* 0. env：环境依赖自检
*------------------------------------------------------------------------------
textab env

sysuse auto, clear

*------------------------------------------------------------------------------
* 1. reg：回归结果表（读已存估计，t 分布星号，括号内标准误 + N + R²）
*------------------------------------------------------------------------------
regress price mpg weight
estimates store m1
regress price mpg weight length
estimates store m2
textab reg m1 m2 using 01_reg.tex, ///
    caption("线性回归结果") label(reg) mode(input)

*------------------------------------------------------------------------------
* 2. stat：描述统计（行=统计量，列=变量）
*------------------------------------------------------------------------------
textab stat price mpg weight using 02_stat.tex, ///
    statistic(mean sd min max n) caption("变量描述统计") label(stat) mode(input)

*------------------------------------------------------------------------------
* 3. stat + by：分组描述统计（含 Total 小计）
*------------------------------------------------------------------------------
textab stat price using 03_stat_by.tex, ///
    by(foreign) statistic(mean sd) caption("分国产/进口描述统计") label(statby) mode(input)

*------------------------------------------------------------------------------
* 4. tab：一维频数 / 二维交叉表（含行列小计）
*------------------------------------------------------------------------------
textab tab rep78 using 04_tab_1d.tex, caption("维修记录频数") label(tab1d) mode(input)
textab tab foreign rep78 using 05_tab_2d.tex, caption("国产×维修交叉表") label(tab2d) mode(input)

*------------------------------------------------------------------------------
* 5. table：通用多级表（逃生舱，维度语法同 help table）
*------------------------------------------------------------------------------
textab table (foreign) (rep78) using 06_table.tex, ///
    statistic(freq) caption("通用多级表") label(table) mode(input)

*------------------------------------------------------------------------------
* 6. list：变量定义/编码表（变量标签、值标签自动展开）
*------------------------------------------------------------------------------
textab list make foreign rep78 using 07_list.tex, ///
    caption("变量定义表") label(list) mode(input)

*------------------------------------------------------------------------------
* 7. 横向 + 独立编译：orientation(landscape) + mode(independ)
*------------------------------------------------------------------------------
textab stat price mpg weight headroom using 08_stat_land.tex, ///
    statistic(mean sd) caption("横向宽表（独立编译）") label(statland) ///
    mode(independ) orientation(landscape)

exit, clear
