*==============================================================================*
**#1				【子程序：env 环境检测】
*==============================================================================*
* - 独立检查运行依赖：Python、jinja2、esttab，不依赖主程序传入的地址。
* - 纯报告：可用则给出版本；缺失则报错并提示如何安装。
* - 目标：让用户据此补齐环境，下次运行主程序能正常找到依赖。
*==============================================================================*
capture program drop _textab_subcmd_env
program define _textab_subcmd_env
	version 17.0

	di as txt "Checking textab environment... / 正在检查 textab 运行环境..."
	local nprob 0

	*【1. Python】
	capture shell python -c "import sys; print(sys.version.split()[0])"
	if _rc {
		di as err "  [MISSING] Python not found. / 未找到 Python。"
		di as txt "     Install Python >=3.10 and add it to PATH (verify: python --version)."
		di as txt "     请安装 Python >=3.10 并加入 PATH（用 python --version 验证）。"
		local nprob = `nprob' + 1
	}
	else {
		di as result "  [OK] Python found on PATH. / Python 已在 PATH 中。"
	}

	*【2. jinja2】（仅 Python 可用时检查）
	capture shell python -c "import jinja2"
	if _rc {
		di as err "  [MISSING] jinja2 not installed. / 缺少 jinja2。"
		di as txt "     Run: pip install jinja2 / 请运行 pip install jinja2"
		local nprob = `nprob' + 1
	}
	else {
		di as result "  [OK] jinja2 installed. / jinja2 已安装。"
	}

	*【3. esttab】
	capture which esttab
	if _rc {
		di as err "  [MISSING] esttab not installed (needed by reg). / 缺少 esttab（reg 子命令需要）。"
		di as txt "     Run: ssc install estout, replace / 请运行 ssc install estout, replace"
		local nprob = `nprob' + 1
	}
	else {
		di as result "  [OK] esttab installed. / esttab 已安装。"
	}

	*【小结】
	if `nprob' == 0 {
		di as result "All dependencies are ready. / 所有依赖均已就绪。"
	}
	else {
		di as err "`nprob' problem(s) found. Fix them, then run 'textab env' again. / 发现 `nprob' 个问题，修复后请再次运行 textab env 检查。"
		exit 499
	}
end
