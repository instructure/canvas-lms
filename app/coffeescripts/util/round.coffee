define ->

  # rounds a number to m digits
  round = (n, digits) ->
    x = Math.pow 10, digits
    Math.round(n * x) / x
