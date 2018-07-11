package tokentreeformatter.marker;

import tokentreeformatter.codedata.CodeLine;
import tokentreeformatter.codedata.CodeLines;
import tokentreeformatter.config.IndentationConfig;

class Indenter {

	var config:IndentationConfig;
	var parsedCode:ParsedCode;

	public function new(config:IndentationConfig) {
		this.config = config;
		if (config.character.toLowerCase() == "tab") {
			config.character = "\t";
		}
	}

	public function setParsedCode(parsedCode:ParsedCode) {
		this.parsedCode = parsedCode;
	}

	public function makeIndent(token:TokenTree):String {
		return makeIndentString(calcIndent(token));
	}

	public function makeIndentString(count:Int):String {
		return StringTools.lpad("", config.character, config.character.length * count);
	}

	public function calcIndent(token:TokenTree):Int {
		var indent:Int = 0;
		if (token == null) {
			return 0;
		}

		switch (token.tok) {
			case BrClose, BkClose, PClose:
			// use BrOpen, BkOpen, POpen for calculation
				token = token.parent;
			case Sharp(_):
				if (config.conditionalPolicy == FIXED_ZERO) return 0;
			default:
		}

		while ((token.parent != null) && (token.parent.tok != null)) {
			token = token.parent;
			if (shouldIndent(token)) {
				indent++;
			}
		}
		return indent;
	}

	function shouldIndent(token:TokenTree):Bool {
		switch (token.tok) {
			case BrOpen, BkOpen, POpen:
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next == null) {
					return true;
				}
				if (shouldIndent(next.token)) {
					return false;
				}
				return true;
			case Binop(OpAssign):
				var next:TokenInfo = parsedCode.tokenList.getNextToken(token);
				if (next == null) {
					return true;
				}
				if (shouldIndent(next.token)) {
					return false;
				}
				return true;
			case DblDot:
				if ((token.parent.is(Kwd(KwdCase))) || (token.parent.is(Kwd(KwdDefault)))) {
					return true;
				}
			case Sharp(_):
				if (config.conditionalPolicy == ALIGNED_INCREASE) {
					return true;
				}
			default:
		}
		return false;
	}

	public function finalRun(codeLines:CodeLines) {
		var lastIndent:Int = 0;
		for (index in 0...codeLines.lines.length) {
			var line:CodeLine = codeLines.lines[index];
			if (line.indent > lastIndent + 1) {
				var diff:Int = line.indent - (lastIndent + 1);
				line.indent -= diff;
				for (index2 in (index + 1)...codeLines.lines.length) {
					var nextLine:CodeLine = codeLines.lines[index2];
					if (nextLine.indent <= lastIndent + 1) {
						break;
					}
					nextLine.indent -= diff;
				}
			}
			lastIndent = line.indent;
		}
	}
}