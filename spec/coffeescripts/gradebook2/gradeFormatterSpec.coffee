define [
  'compiled/gradebook2/gradeFormatter'
], (GradeFormatter) ->
  module 'gradebook2.GradeFormatter',
    setup: () ->
    teardown: () ->

  test 'returns "-" if score is null', () ->
    gradeFormatter = new GradeFormatter(null, 100)
    result = gradeFormatter.toString()
    equal(result, '-')

  test 'returns "-" if possibleScore is 0 and score is 0', () -> # Evaluates to NaN
    gradeFormatter = new GradeFormatter(0, 0)
    result = gradeFormatter.toString()
    equal(result, '-')

  test 'returns "-" if possibleScore is 0 and score is > 0', () -> # Evaluates to Infinity
    gradeFormatter = new GradeFormatter(5, 0)
    result = gradeFormatter.toString()
    equal(result, '-')

  test 'returns "-" if possibleScore is null', () ->
    gradeFormatter = new GradeFormatter(5, null)
    result = gradeFormatter.toString()
    equal(result, '-')

  test 'returns "-" if score / possibleScore is NaN', () ->
    gradeFormatter = new GradeFormatter(5, 'a')
    result = gradeFormatter.toString()
    equal(result, '-')

  test 'returns score with a percent when valid', () ->
    gradeFormatter = new GradeFormatter(5, 5)
    result = gradeFormatter.toString()
    equal(result, '100%')
