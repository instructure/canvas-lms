define ->

  # rounds a number to m digits
  round = (n, digits=0) ->
    n = parseFloat(n) unless typeof n is 'number' or n instanceof Number
    x = Math.pow 10, digits
    Math.round(n * x) / x

  round.DEFAULT = 2

  round
