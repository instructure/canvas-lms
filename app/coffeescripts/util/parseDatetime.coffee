define [
  'vendor/date' # Date.parse
], ->
  # a simple method to parse a user-input datetime string that may or may not
  # have an "at" or "by" embedded.
  #
  # NOTE: returns a still-fudged date, as it is parsing user input! do *not*
  # use to parse ISO8601 strings
  (text) ->
    Date.parse(text.replace(/\b(at|by)\b/, ""))
