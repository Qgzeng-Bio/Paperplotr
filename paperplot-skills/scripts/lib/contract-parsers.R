# Dependency-free contract parsers for paperplot-skills.

pp_contract_fail <- function(...) stop(paste(..., collapse = ""), call. = FALSE)

pp_json_null <- function() structure(list(), class = "pp_json_null")
pp_is_json_null <- function(x) inherits(x, "pp_json_null")

pp_parse_json_text <- function(text, source = "JSON", max_depth = 128L,
                               max_bytes = 16L * 1024L * 1024L,
                               max_tokens = 1000000L,
                               max_string_chars = 1000000L,
                               max_container_items = 100000L) {
  if (length(text) != 1L || is.na(text)) pp_contract_fail("JSON input must be one non-missing string: ", source)
  if (nchar(text, type = "bytes") > max_bytes) pp_contract_fail("JSON input exceeds byte limit: ", source)
  if (!is.numeric(max_depth) || length(max_depth) != 1L || is.na(max_depth) || max_depth < 1) pp_contract_fail("max_depth must be a positive scalar")
  max_depth <- as.integer(max_depth)
  text <- enc2utf8(text)
  if (startsWith(text, "\ufeff")) text <- substring(text, 2L)

  state <- new.env(parent = emptyenv())
  state$pos <- 1L
  state$n <- nchar(text, type = "chars")
  state$tokens <- 0L
  use_token <- function() {
    state$tokens <- state$tokens + 1L
    if (state$tokens > max_tokens) pp_contract_fail("Invalid JSON in ", source, ": token limit exceeded")
  }
  peek <- function(offset = 0L) {
    at <- state$pos + offset
    if (at <= state$n) substr(text, at, at) else ""
  }
  advance <- function(n = 1L) state$pos <- state$pos + as.integer(n)
  skip_ws <- function() while (peek() %in% c(" ", "\t", "\r", "\n")) advance()
  fail_at <- function(message) pp_contract_fail("Invalid JSON in ", source, " at character ", state$pos, ": ", message)

  parse_hex4 <- function() {
    hex <- substr(text, state$pos, state$pos + 3L)
    if (nchar(hex, type = "chars") != 4L || !grepl("^[0-9A-Fa-f]{4}$", hex)) fail_at("invalid Unicode escape")
    advance(4L)
    strtoi(hex, base = 16L)
  }
  parse_string <- function() {
    if (peek() != '"') fail_at("expected string")
    advance()
    capacity <- 64L
    out <- character(capacity)
    used <- 0L
    push <- function(value) {
      used <<- used + 1L
      if (used > max_string_chars) fail_at("string length limit exceeded")
      if (used > length(out)) length(out) <<- length(out) * 2L
      out[[used]] <<- value
    }
    repeat {
      ch <- peek()
      if (!nzchar(ch)) fail_at("unterminated string")
      if (ch == '"') { advance(); break }
      if (ch == "\\") {
        advance(); esc <- peek()
        if (!nzchar(esc)) fail_at("unterminated escape")
        advance()
        if (esc %in% c('"', "\\", "/")) push(esc)
        else if (esc == "b") push("\b")
        else if (esc == "f") push("\f")
        else if (esc == "n") push("\n")
        else if (esc == "r") push("\r")
        else if (esc == "t") push("\t")
        else if (esc == "u") {
          code <- parse_hex4()
          if (code >= 0xD800L && code <= 0xDBFFL) {
            if (!(peek() == "\\" && peek(1L) == "u")) fail_at("high surrogate is not followed by a low surrogate")
            advance(2L); low <- parse_hex4()
            if (low < 0xDC00L || low > 0xDFFFL) fail_at("high surrogate is not followed by a valid low surrogate")
            code <- 0x10000L + (code - 0xD800L) * 0x400L + (low - 0xDC00L)
          } else if (code >= 0xDC00L && code <= 0xDFFFL) fail_at("isolated low surrogate")
          push(intToUtf8(code))
        } else fail_at("invalid escape")
      } else {
        if (utf8ToInt(ch)[[1L]] < 32L) fail_at("unescaped control character")
        push(ch); advance()
      }
    }
    if (used == 0L) "" else paste(out[seq_len(used)], collapse = "")
  }

  parse_value <- NULL
  parse_array <- function(depth) {
    if (depth > max_depth) fail_at(paste0("maximum nesting depth ", max_depth, " exceeded"))
    advance(); skip_ws(); out <- list()
    if (peek() == "]") { advance(); return(out) }
    repeat {
      if (length(out) >= max_container_items) fail_at("array item limit exceeded")
      out[length(out) + 1L] <- list(parse_value(depth)); skip_ws()
      if (peek() == "]") { advance(); break }
      if (peek() != ",") fail_at("expected comma in array")
      advance(); skip_ws()
    }
    out
  }
  parse_object <- function(depth) {
    if (depth > max_depth) fail_at(paste0("maximum nesting depth ", max_depth, " exceeded"))
    advance(); skip_ws(); out <- list()
    if (peek() == "}") { advance(); return(out) }
    repeat {
      if (length(out) >= max_container_items) fail_at("object member limit exceeded")
      key <- parse_string()
      if (key %in% names(out)) fail_at(paste0("duplicate object key: ", key))
      skip_ws(); if (peek() != ":") fail_at("expected colon in object")
      advance(); skip_ws(); out[key] <- list(parse_value(depth)); skip_ws()
      if (peek() == "}") { advance(); break }
      if (peek() != ",") fail_at("expected comma in object")
      advance(); skip_ws()
    }
    out
  }
  parse_value <- function(depth = 0L) {
    use_token(); skip_ws(); ch <- peek()
    if (ch == '"') return(parse_string())
    if (ch == "{") return(parse_object(depth + 1L))
    if (ch == "[") return(parse_array(depth + 1L))
    rest <- substr(text, state$pos, state$n)
    if (startsWith(rest, "true")) { advance(4L); return(TRUE) }
    if (startsWith(rest, "false")) { advance(5L); return(FALSE) }
    if (startsWith(rest, "null")) { advance(4L); return(pp_json_null()) }
    hit <- regexpr("^-?(?:0|[1-9][0-9]*)(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?", rest, perl = TRUE)
    if (hit[[1L]] == 1L) {
      token <- regmatches(rest, hit); advance(nchar(token, type = "chars"))
      value <- suppressWarnings(as.numeric(token))
      if (!is.finite(value)) fail_at("number is outside the supported finite range")
      return(value)
    }
    fail_at("unexpected token")
  }

  value <- parse_value(0L); skip_ws()
  if (state$pos <= state$n) fail_at("trailing content")
  value
}

pp_parse_json_file <- function(path, max_depth = 128L, max_bytes = 16L * 1024L * 1024L) {
  if (!file.exists(path)) pp_contract_fail("JSON file not found: ", path)
  size <- unname(file.info(path)[["size"]])
  if (is.na(size) || size > max_bytes) pp_contract_fail("JSON file exceeds byte limit: ", path)
  text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  pp_parse_json_text(text, source = path, max_depth = max_depth, max_bytes = max_bytes)
}

pp_parse_yaml_scalar <- function(value, path, line_number) {
  value <- trimws(value)
  where <- paste0(path, ":", line_number)
  if (!nzchar(value)) pp_contract_fail("Frontmatter nested/empty values are not supported at ", where)
  if (startsWith(value, '"')) {
    parsed <- pp_parse_json_text(value, source = where, max_depth = 4L, max_bytes = 4096L, max_tokens = 16L, max_string_chars = 350L)
    if (!is.character(parsed) || length(parsed) != 1L) pp_contract_fail("Frontmatter value must be a scalar string at ", where)
    return(parsed)
  }
  if (startsWith(value, "'")) {
    if (!endsWith(value, "'") || nchar(value) < 2L) pp_contract_fail("Unterminated single-quoted frontmatter value at ", where)
    inner <- substr(value, 2L, nchar(value) - 1L)
    if (grepl("'", gsub("''", "", inner, fixed = TRUE), fixed = TRUE)) pp_contract_fail("Single quotes inside frontmatter values must be escaped as '' at ", where)
    return(gsub("''", "'", inner, fixed = TRUE))
  }
  implicit <- grepl("^(?:null|~|true|false|yes|no|on|off|[-+]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)|[0-9]{4}-[0-9]{2}-[0-9]{2})(?:$|[[:space:]])", value, ignore.case = TRUE, perl = TRUE)
  if (implicit || startsWith(value, "#") || grepl("#", value, fixed = TRUE) ||
      grepl("(^|[[:space:]]):[[:space:]]|:[[:space:]]", value, perl = TRUE) ||
      grepl("^[\\[\\]{}&*!|>@`]", value, perl = TRUE)) {
    pp_contract_fail("Invalid or unsupported plain frontmatter scalar at ", where, "; quote values containing YAML syntax or implicit types")
  }
  value
}

pp_parse_skill_frontmatter <- function(path, allowed_keys = c("name", "description", "license", "metadata", "allowed-tools")) {
  size <- unname(file.info(path)[["size"]])
  if (is.na(size) || size > 1024L * 1024L) pp_contract_fail("SKILL.md exceeds 1 MiB: ", path)
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) < 3L || !identical(lines[[1L]], "---")) pp_contract_fail("SKILL.md must start with --- frontmatter")
  closing <- which(lines[-1L] == "---")
  if (length(closing) == 0L) pp_contract_fail("SKILL.md frontmatter closing --- not found")
  end <- closing[[1L]] + 1L
  if (end > 100L) pp_contract_fail("SKILL.md frontmatter exceeds 100 lines")
  body <- lines[seq.int(2L, end - 1L)]
  values <- list()
  for (i in seq_along(body)) {
    line <- body[[i]]; line_number <- i + 1L
    if (!nzchar(trimws(line))) next
    if (grepl("\t", line, fixed = TRUE)) pp_contract_fail("Tabs are not allowed in frontmatter at ", path, ":", line_number)
    if (grepl("^[[:space:]]", line)) pp_contract_fail("Nested frontmatter is not supported at ", path, ":", line_number)
    hit <- regexec("^([A-Za-z][A-Za-z0-9-]*):[[:space:]]*(.*)$", line, perl = TRUE)
    parts <- regmatches(line, hit)[[1L]]
    if (length(parts) != 3L) pp_contract_fail("Invalid frontmatter syntax at ", path, ":", line_number)
    key <- parts[[2L]]
    if (key %in% names(values)) pp_contract_fail("Duplicate frontmatter key at ", path, ":", line_number, ": ", key)
    if (!key %in% allowed_keys) pp_contract_fail("Unsupported cross-harness SKILL.md frontmatter: ", key)
    values[key] <- list(pp_parse_yaml_scalar(parts[[3L]], path, line_number))
  }
  list(values = values, end_line = end, lines = lines)
}
