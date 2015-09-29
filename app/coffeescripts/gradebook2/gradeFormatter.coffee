define [
  'compiled/util/round'
], (round) ->
  GradeFormatter = (score, possibleScore, gradeAsPoints) ->
    @score = score
    @possibleScore = possibleScore
    @gradeAsPoints = gradeAsPoints

  GradeFormatter.prototype.toString = () ->
    maxDecimals = round.DEFAULT
    percentGrade = @score / @possibleScore * 100

    if (not @score || percentGrade == Infinity || isNaN(percentGrade))
      return '-'
    else
      return if @gradeAsPoints then @score else round(percentGrade, maxDecimals) + '%'

  return GradeFormatter
