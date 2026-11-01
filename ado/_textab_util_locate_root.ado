*==============================================================================*
**#					【公共工具：定位工具根目录】
*==============================================================================*
* - 用 findfile 找到 textab.ado 自己，反推 code_py/ 所在目录。
*   兼容两种布局：① 与 .ado 平铺（net install）② .ado 在 ado/ 子目录（git clone）。
* - 通过 c_local 回传 root（后续由各子程序自行派生 retex.py / json2tex.py 路径）。
*==============================================================================*
capture program drop _textab_util_locate_root
program define _textab_util_locate_root
	version 17.0

	capture findfile "textab.ado"
	if _rc {
		di as err "Cannot locate textab.ado."
		di as err "无法定位 textab.ado，请确认已安装或加入 adopath。"
		exit 198
	}
	local medir = subinstr("`r(fn)'", "\", "/", .)				//	替换斜杠
	local medir = subinstr("`medir'", "/textab.ado", "", .)	//	提取上层路径
	if fileexists("`medir'/code_py/retex.py") {					//	同级文件夹查找 py
		local root "`medir'"
	}
	else {														//	ado 和 py 非同级：取上一级目录
		local root = substr("`medir'", 1, strrpos("`medir'", "/") - 1)
	}
	if !fileexists("`root'/code_py/retex.py") {
		di as err "Found textab.ado, but code_py/retex.py is missing next to it."
		di as err "找到 textab.ado，但旁边缺少 code_py/retex.py。"
		exit 198
	}

	c_local root "`root'"
end
