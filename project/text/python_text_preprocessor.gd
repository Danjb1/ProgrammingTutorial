extends TextPreprocessor
## Text pre-processor that highlights code inside [python] tags.
## This is far from perfect, but it's good enough for our purposes.

const _python_keywords: PackedStringArray = [
	"if",
	"elif",
	"and",
	"for",
	"else",
	"in",
	"while",
	"def",
	"return",
	"import"
]

## Regex to find Python tags: [python]...[/python].
## Everything inside the tags is captured.
var _python_tags_re := RegEx.new()

## Regex to find Python keywords.
var _keywords_re := RegEx.new()

## Regex to find numerical constants.
var _numbers_re := RegEx.new()

## Regex to find quoted strings: "...".
var _quotes_re := RegEx.new()

func _init() -> void:
	# Compile Python tags regex
	var error := _python_tags_re.compile(
		r"(?s)"				# Dotall flag (match newlines)
		+ r"\[python\]"		# [python] opening tag
		+ "(.*?)"			# Capture group 1: any characters (non-greedy)
		+ r"\[\/python\]"	# [/python] closing tag
	)
	assert(not error, "Error compiling Python tags regex: %s" % error)

	# Compile all Python keywords into one giant regex.
	# Each keyword must be followed by whitespace to prevent accidental
	# highlighting inside functions and variable names.
	error = _keywords_re.compile(
		r"("									# (
		+ r")|(".join(_python_keywords)			# ...)|(...
		+ r")")									# )
	assert(not error, "Error compiling Python keywords regex: %s" % error)

	# Compile numbers regex
	error = _numbers_re.compile(
		r"\d+"
	)
	assert(not error, "Error compiling Python numbers regex: %s" % error)

	# Compile quotes regex
	error = _quotes_re.compile(
		r"\""			# Opening quote: "
		+ ".*"			# Any characters (non-greedy)
		+ r"\""			# Closing quote: "
	)
	assert(not error, "Error compiling Python quotes regex: %s" % error)

## Processes a string which may contain *multiple* Python tags.
func process(text: String) -> String:
	if not _python_tags_re.is_valid():
		return text
	# We pass group_id = 1 so that only the contents of the tags are used in
	# the replacement (the tags themselves will be stripped).
	return _regex_replace(text, _python_tags_re, "_replace_python_tag", 1)

## Searches using a regex and replaces all instances.
## The supplied function is used to find the replacement text.
## This function should have the signature func(String) -> String.
## If group_id is specified, this capture group is passed to the replacement
## function instead of the full string.
func _regex_replace(text: String, regex: RegEx, process_func: String, group_id = 0) -> String:
	var results := regex.search_all(text)
	var replacements := _find_replacements(results, process_func, group_id)
	return _replace_matches(text, results, replacements)

## Processes each match found by a RegEx search using the supplied function.
## Returns a list of string replacements (one for each match).
func _find_replacements(
		results: Array[RegExMatch],
		process_func: String,
		group_id = 0) -> Array[String]:
	var replacements: Array[String] = []
	var callable := Callable(self, process_func)
	for result in results:
		var tag_contents := result.get_string(group_id)
		var modified_text: String = callable.call(tag_contents)
		replacements.push_back(modified_text)
	return replacements

func _replace_matches(
		text: String,
		results: Array[RegExMatch],
		replacements: Array[String]) -> String:
	var new_text := ""
	var current_pos := 0
	for i in results.size():
		var tag := results[i]
		if not is_valid_match(text, tag):
			continue
		var tag_start := tag.get_start(0)
		var tag_end := tag.get_end(0)
		# Add all chars from the original text, up to the start of the current tag
		var substr_len := tag_start - current_pos
		var matched_text := text.substr(current_pos, substr_len)
		new_text += matched_text
		# Add the replacement text
		new_text += replacements[i]
		# Skip over the tag
		current_pos = tag_end
	# Add any remaining text
	new_text += text.substr(current_pos)
	return new_text

## Gets the replacement text for a Python tag.
func _replace_python_tag(text: String) -> String:
	var new_text := _regex_replace(text, _keywords_re, "_replace_keyword")
	new_text = _regex_replace(new_text, _numbers_re, "_replace_number")
	new_text = _regex_replace(new_text, _quotes_re, "_replace_quote")
	return new_text

func _replace_keyword(text: String) -> String:
	return "[color=CRIMSON]" + text + "[/color]"

func _replace_number(text: String) -> String:
	return "[color=DARK_TURQUOISE]" + text + "[/color]"

func _replace_quote(text: String) -> String:
	return "[color=GOLD]" + text + "[/color]"

func is_valid_match(text: String, p_match: RegExMatch) -> bool:
	# This is a horrible hack to stop us highlighting the "in" in "print".
	# To properly fix this we would need a much more sophisticated mechanism
	# to tokenize Python code.
	var match_start := p_match.get_start(0)
	var match_end := p_match.get_end(0)
	var substr_len := match_end - match_start
	var matched_text = text.substr(match_start, substr_len)
	if matched_text == "in":
		return text[match_end] != "t"
	return true
