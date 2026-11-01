*==============================================================================*
**#1					【子程序：SEM 结果直接排版（读 e(b)/e(V)）】
*==============================================================================*
capture program drop _textab_sem_render
//////////////////////////////////【程序目标】//////////////////////////////////
* - sem/gsem 的结果结构（多方程 + 误差方差 + 拟合指标）与 esttab 的
*   「行=系数、列=模型」心智模型不匹配，esttab 硬套会输出乱表。
*   故不走 esttab，直接读 e(b)/e(V) 排版成三线表：
*   按内生变量分块 + 路径系数(系数/SE/星号) + 底部拟合指标 + 误差方差可选项。
//////////////////////////////////【程序语法】//////////////////////////////////
program define _textab_sem_render
	version 17.0
	syntax, RAW(string)						/// 输出原始 tex（供 retex 套壳）
		[ESTnames(string)					/// 估计名列表（空格分隔；空=当前 e()）
		MODELS(string)						/// 列标题（| 分隔，主程序预解析）
		VARIANCE]							/// 是否显示误差方差 var(e.xx)

	local varflag = cond("`variance'" != "", "1", "0")
	mata: _textab_sem_write("`raw'", "`estnames'", "`varflag'", `"`models'"')
end

*==============================================================================*
**#2					【Mata：读 e(b)/e(V) 排版写文件】
*==============================================================================*
mata:

string scalar _textab_stars(real scalar p)
{
	if (p < 0.001) return("\sym{***}")
	if (p < 0.01)  return("\sym{**}")
	if (p < 0.05)  return("\sym{*}")
	return("")
}

string scalar _textab_lab(string scalar nm)
{
	if (nm == "_cons") return("Constant")
	if (nm == "") return("")
	/* var(e.xx)、含 () . : 的名字不是普通变量，直接返回原名，
	   避免 st_varindex() 对非法变量名报 r(3500)。 */
	if (strpos(nm, "(") > 0 | strpos(nm, ")") > 0 | strpos(nm, ".") > 0 | strpos(nm, ":") > 0) {
		return(nm)
	}
	if (st_varindex(nm) != .) {
		if (st_varlabel(nm) != "") return(st_varlabel(nm))
	}
	return(nm)
}

string rowvector _textab_split(string scalar s, string scalar delim)
{
	string rowvector out
	out = J(1, 0, "")
	if (s == "") return(out)
	while (s != "") {
		p = strpos(s, delim)
		if (p > 0) {
			out = out, substr(s, 1, p - 1)
			s = substr(s, p + strlen(delim), .)
		}
		else {
			out = out, s
			s = ""
		}
	}
	return(out)
}

real scalar _textab_scalar(string scalar name)
{
	/* 安全读 e() 标量：不存在的标量 st_numscalar() 返回 0x0 空矩阵，
	   直接交给 sprintf 会报 "matrix found where scalar required"，
	   这里统一把「空 / 缺失」归一成 missing(.)。 */
	real matrix x
	x = st_numscalar(name)
	if (rows(x) == 0 | cols(x) == 0) return(.)
	return(x[1, 1])
}

void _textab_sem_write(string scalar raw, string scalar estnames,
					   string scalar varflag, string scalar models)
{
	real scalar nmod, i, k, K, showvar, nrow, j, pos, found, anytitle
	string rowvector mnames, titles
	string rowvector union_full
	pointer(string rowvector) scalar PF
	pointer(real rowvector) scalar PB
	pointer(real rowvector) scalar PS
	real scalar fh, colon, bv, sv, z, p, N, v
	string scalar full, eq, nm, cureq, lab, star, line, col0

	showvar = (varflag == "1")

	/* ---- 解析模型名 / 列标题 ---- */
	if (estnames == "") {
		nmod = 1
		mnames = J(1, 1, "")
	}
	else {
		mnames = tokens(estnames)
		nmod = cols(mnames)
	}
	if (models == "") titles = J(1, nmod, "")
	else {
		titles = _textab_split(models, "|")
		if (cols(titles) < nmod) titles = titles, J(1, nmod - cols(titles), "")
	}

	/* ---- 逐模型收集系数 ---- */
	PF = J(1, nmod, NULL)
	PB = J(1, nmod, NULL)
	PS = J(1, nmod, NULL)
	union_full = J(1, 0, "")

	for (i = 1; i <= nmod; i++) {
		if (mnames[i] != "") stata(sprintf("qui estimates restore %s", mnames[i]))
		b = st_matrix("e(b)")
		V = st_matrix("e(V)")
		se = sqrt(diagonal(V))
		stripe = st_matrixcolstripe("e(b)")
		K = cols(b)
		fnk = J(1, 0, "")
		bk = J(1, 0, .)
		sk = J(1, 0, .)
		for (k = 1; k <= K; k++) {
			eq = stripe[k, 1]
			nm = stripe[k, 2]
			if (!showvar & eq == "/") continue
			if (eq != "") full = eq + ":" + nm
			else full = nm
			fnk = fnk, full
			bk = bk, b[k]
			sk = sk, se[k]
			found = 0
			for (j = 1; j <= cols(union_full); j++) {
				if (union_full[j] == full) found = 1
			}
			if (!found) union_full = union_full, full
		}
		PF[i] = &fnk
		PB[i] = &bk
		PS[i] = &sk
	}

	nrow = cols(union_full)

	/* ---- 写文件 ---- */
	fh = fopen(raw, "w")
	if (fh < 0) {
		errprintf("cannot open %s\n", raw)
		exit(601)
	}
	col0 = "                    "
	fput(fh, "{")
	fput(fh, "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}")
	fput(fh, sprintf("\\begin{tabular}{l*{%g}{c}}", nmod))
	fput(fh, "\toprule")

	/* 表头：第一行 (1)(2)... */
	line = col0
	for (i = 1; i <= nmod; i++) {
		line = line + "&\multicolumn{1}{c}{(" + strofreal(i) + ")}"
	}
	fput(fh, line + "\\")
	/* 表头：第二行 列标题（全空则跳过） */
	anytitle = 0
	for (i = 1; i <= nmod; i++) if (titles[i] != "") anytitle = 1
	if (anytitle) {
		line = col0
		for (i = 1; i <= nmod; i++) {
			line = line + "&\multicolumn{1}{c}{" + titles[i] + "}"
		}
		fput(fh, line + "\\")
	}
	fput(fh, "\midrule")

	/* 系数行：按方程分块 */
	cureq = ""
	for (j = 1; j <= nrow; j++) {
		full = union_full[j]
		colon = strpos(full, ":")
		if (colon > 0) {
			eq = substr(full, 1, colon - 1)
			nm = substr(full, colon + 1, .)
		}
		else {
			eq = ""
			nm = full
		}
		if (eq != cureq) {
			cureq = eq
			if (eq == "/") {
				fput(fh, sprintf("\\multicolumn{%g}{l}{\\textit{Error variances}}\\\\", nmod + 1))
			}
			else if (eq != "") {
				fput(fh, sprintf("\\multicolumn{%g}{l}{\\textit{%s}}\\\\", nmod + 1, _textab_lab(eq)))
			}
		}
		/* 系数行 */
		line = sprintf("%-20s", _textab_lab(nm))
		for (i = 1; i <= nmod; i++) {
			pos = 0
			tmp = *PF[i]
			for (k = 1; k <= cols(tmp); k++) if (tmp[k] == full) pos = k
			if (pos > 0) {
				bv = (*PB[i])[pos]
				sv = (*PS[i])[pos]
				z = bv / sv
				p = 2 * normal(-abs(z))
				star = _textab_stars(p)
				line = line + sprintf("& %15.3f%s", bv, star)
			}
			else line = line + "&            "
		}
		fput(fh, line + "\\")
		/* 标准误行 */
		line = col0
		for (i = 1; i <= nmod; i++) {
			pos = 0
			tmp = *PF[i]
			for (k = 1; k <= cols(tmp); k++) if (tmp[k] == full) pos = k
			if (pos > 0) {
				sv = (*PS[i])[pos]
				line = line + sprintf("& %15.3f", sv)
			}
			else line = line + "&            "
		}
		fput(fh, line + "\\")
		fput(fh, "\addlinespace")
	}

	/* ---- 底部拟合指标 ---- */
	fput(fh, "\midrule")
	/* N */
	line = sprintf("%-20s", "N")
	for (i = 1; i <= nmod; i++) {
		if (mnames[i] != "") stata(sprintf("qui estimates restore %s", mnames[i]))
		N = _textab_scalar("e(N)")
		if (N == .) line = line + "&            "
		else line = line + sprintf("& %15.0f", N)
	}
	fput(fh, line + "\\")
	/* chi2 / df / rmsea / cfi / tli / srmr */
	fitnames = ("chi2", "df_m", "rmsea", "cfi", "tli", "srmr")
	fitlabs  = ("$\chi^2$", "df", "RMSEA", "CFI", "TLI", "SRMR")
	for (j = 1; j <= cols(fitnames); j++) {
		line = sprintf("%-20s", fitlabs[j])
		for (i = 1; i <= nmod; i++) {
			if (mnames[i] != "") stata(sprintf("qui estimates restore %s", mnames[i]))
			v = _textab_scalar("e(" + fitnames[j] + ")")
			if (v == .) line = line + "&            "
			else {
				if (fitnames[j] == "df_m") line = line + sprintf("& %15.0f", v)
				else line = line + sprintf("& %15.3f", v)
			}
		}
		fput(fh, line + "\\")
	}

	fput(fh, "\bottomrule")
	fput(fh, "\end{tabular}")
	fput(fh, "}")
	fclose(fh)
}

end
