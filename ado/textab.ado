*==============================================================================*
**#1					【stata表格 to latex表格程序介绍】
*==============================================================================*
//////////////////////////////////【程序功能】//////////////////////////////////
* 主程序
//////////////////////////////////【程序结构】//////////////////////////////////
* Stata -> esttab/collect -> tex -> retex换表头 -> LaTeX 三线表
//////////////////////////////////【运行环境】//////////////////////////////////
//	依赖：esttab（est 回归类用）、python + jinja2（list 用）、collect（Stata 17+ 自带）
//	主程序定位根目录 + 派生脚本/Python 地址，一并传给子命令；env 单独查环境
//	环境依赖详见 help textab；运行报错先执行 textab env 排查
//////////////////////////////////【程序预备】//////////////////////////////////
* 预删除防重复
capture program drop textab
* textab v0.4.0                                  	//  程序包版本
*==============================================================================*
**#2					【主程序：路由分发器】
*==============================================================================*
program define textab                             //  开始定义程序
	version 17.0                                    //  collect/table 需 Stata 17+

	*【命令抓取：第一个词为子命令】
	gettoken subcmd 0 : 0, parse(" ,")

	*【env 独立：只查环境，不依赖根目录，直接分发】
	if "`subcmd'" == "env" {
		_textab_subcmd_env
		exit
	}

	*【定位根目录 + 派生脚本/Python 地址（Python 默认走 PATH）】
	_textab_util_locate_root
	local script "`root'/code_py/json2tex.py"      // list 用
	local retex  "`root'/code_py/retex.py"         // reg/tab/stat/table 用
	local python "python"                           // PATH 相对地址；跑不了会自然报错

	*【程序分发】
	if "`subcmd'" == "tab" {
		_textab_subcmd_collect `0' type(tab) root(`"`root'"') retex(`"`retex'"') python(`"`python'"')
	}
	else if "`subcmd'" == "stat" {
		_textab_subcmd_collect `0' type(stat) root(`"`root'"') retex(`"`retex'"') python(`"`python'"')
	}
	else if "`subcmd'" == "table" {
		_textab_subcmd_collect `0' type(table) root(`"`root'"') retex(`"`retex'"') python(`"`python'"')
	}
	else if "`subcmd'" == "list" {
		_textab_subcmd_list `0' root(`"`root'"') script(`"`script'"') python(`"`python'"')
	}
	else if "`subcmd'" == "est" {
		_textab_subcmd_est `0' root(`"`root'"') retex(`"`retex'"') python(`"`python'"')
	}
	else if "`subcmd'" == "reg" {
		di as error "textab reg 已更名为 textab est，请改用：textab est ..."
		exit 198
	}
	else {
		di as error "subcommand `subcmd' not found. Please check help textab."
		di as error "子命令不正确，请 help textab 查看子命令列表。"
		exit 198
	}
end
