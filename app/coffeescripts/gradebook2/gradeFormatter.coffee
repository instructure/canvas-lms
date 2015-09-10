define [
  'compiled/util/round'
], (round) ->
  GradeFormatter = (score, possibleScore) ->
    @score = score
    @possibleScore = possibleScore

  GradeFormatter.prototype.toString = () ->
    maxDecimals = round.DEFAULT
    result = @score / @possibleScore * 100

    if (result == Infinity || isNaN(result) || not @score?)
      return '-'
    else
      return round(result, maxDecimals) + '%'

  return GradeFormatter
