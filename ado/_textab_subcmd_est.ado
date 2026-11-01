*==============================================================================*
**#1					【子程序：estimation 结果表（回归类 + SEM）】
*==============================================================================*
capture program drop _textab_subcmd_est
//////////////////////////////////【程序目标】//////////////////////////////////
* - 统一处理各种估计模型，自动看 e(cmd) 分流：
*   回归类(regress/xtreg/reghdfe/logit/...)：包 esttab（t 星号、N/r2、变量标签）
*   SEM(sem/gsem)：不走 esttab，直接读 e(b)/e(V) 排版（按方程分块+拟合指标）
* - estnames 为空时读当前 e()（最近一次估计），无需手工重跑
//////////////////////////////////【程序语法】//////////////////////////////////
program define _textab_subcmd_est
	version 17.0
	syntax [anything(name=estnames)] [using/] , /// 估计名列表（estimates store 的 names），可空=当前 e()
		ROOT(string) RETEX(string) PYTHON(string)	/// 根目录 + retex.py + python（主程序传入）
		[											/// 【可选】
		CAPtion(string) 							/// 表题
		LABel(string) 								/// 标签(交叉引用)
		MODE(string) 								/// 模式 input/independ
		ORIENTation(string) 						/// 方向 portrait/landscape
		MODELS(string) 								/// 表头列名（回归类映射 mtitles；SEM 作列标题）
		NOTE(string) 								/// 表注
		STATS(string) 								/// 回归类统计量（默认 N r2；如 logit 用 N chi2 p）
		REPLACE										/// 替换同名文件
		VARIANCE									/// SEM：显示误差方差 var(e.xx)
		]

*==============================================================================*
**#2						【参数设置：公共与特殊】
*==============================================================================*
//////////////////////【公共工具程序：默认值与文件名处理】//////////////////////
	_textab_util_set_defaults, 			/// 必须先定 base 和 using
		type("est") mode("`mode'") 		/// cap > using > lab 名称优先级
		caption(`"`caption'"') using("`using'") label("`label'") orientation("`orientation'")
*【公共工具程序：文件名覆盖】
	_textab_util_check_file "`using'", `replace'
*【表注默认值】
	if `"`note'"' == "" {
		local note "注：$^{*}p<0.05$，$^{**}p<0.01$，$^{***}p<0.001$；括号内为标准误。"
	}

*==============================================================================*
**#3						【检测模型类型：读 e(cmd) 分流】
*==============================================================================*
	local first : word 1 of `estnames'
	if "`estnames'" != "" {
		capture quietly estimates restore `first'
	}
	local cmd = "`e(cmd)'"

* 原始 tex 临时文件（与 using 同基名、同目录，稍后清理）
	local raw = subinstr("`using'", ".tex", "_raw.tex", .)

	if inlist("`cmd'", "sem", "gsem") {
*==============================================================================*
**#4a						【SEM：直接读 e(b)/e(V) 排版】
*==============================================================================*
* models 解析成 | 分隔（保留标题内空格）；未指定时用估计名兜底
		local mdelim ""
		if `"`models'"' != "" {
			tokenize `"`models'"'
			local mdelim "`1'"
			local ni = 2
			while `"``ni''"' != "" {
				local mdelim "`mdelim'|``ni''"
				local ++ni
			}
		}
		else {
			local mdelim = subinstr("`estnames'", " ", "|", .)
		}

		capture erase "`raw'"
		_textab_sem_render, raw("`raw'") estnames("`estnames'") models(`"`mdelim'"') `variance'

		_textab_util_retex, using("`using'") python("`python'") retex("`retex'") raw("`raw'") ///
			source("esttab") mode("`mode'") orientation("`orientation'") ///
			caption(`"`caption'"') label("`label'") note(`"`note'"') jsonkeep("`jsonkeep'")
	}
	else {
*==============================================================================*
**#4b						【回归类：包 esttab】
*==============================================================================*
* esttab 固定选项：booktabs 三线 + 3 位小数 + 变量标签 + 去内建脚注（用我方 note）
		local estopts `"booktabs style(tex) b(3) se(3) nonotes label"'
* stats：默认 N r2；可被 STATS() 覆盖（如 logit 用 N chi2 p）
		if `"`stats'"' != "" {
			local estopts `"`estopts' stats(`stats')"'
		}
		else {
			local estopts `"`estopts' stats(N r2, fmt(%9.0f %9.3f))"'
		}
		if `"`models'"' != "" {
			local estopts `"`estopts' mtitles(`models')"'
		}

* esttab 导出：estnames 为空则读当前 e()
		esttab `estnames' using "`raw'", `estopts' replace

		_textab_util_retex, using("`using'") python("`python'") retex("`retex'") raw("`raw'") ///
			source("esttab") mode("`mode'") orientation("`orientation'") ///
			caption(`"`caption'"') label("`label'") note(`"`note'"') jsonkeep("`jsonkeep'")
	}

end
