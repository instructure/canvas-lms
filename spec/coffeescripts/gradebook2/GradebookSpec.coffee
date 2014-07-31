define ['compiled/gradebook2/Gradebook'], (Gradebook) ->

  module "Gradebook2"

  test "gradeSort - total_grade", ->
    gradeSort = (showTotalGradeAsPoints, a, b, field, asc) ->
      asc = true unless asc?

      Gradebook.prototype.gradeSort.call options:
        show_total_grade_as_points: showTotalGradeAsPoints
      , a, b, field, asc

    ok gradeSort(false
    , {total_grade: {score: 10, possible: 20}}
    , {total_grade: {score: 5, possible: 10}}
    , 'total_grade') == 0
    , "total_grade sorts by percent (normally)"

    ok gradeSort(true
    , {total_grade: {score: 10, possible: 20}}
    , {total_grade: {score: 5, possible: 10}}
    , 'total_grade') > 0
    , "total_grade sorts by score when if show_total_grade_as_points"

    ok gradeSort(true
    , {assignment_group_1: {score: 10, possible: 20}}
    , {assignment_group_1: {score: 5, possible: 10}}
    , 'assignment_group_1') == 0
    , "assignment groups are always sorted by percent"

    ok gradeSort(false
    , {assignment1: {score: 5, possible: 10}}
    , {assignment1: {score: 10, possible: 20}}
    , 'assignment1') < 0
    , "other fields are sorted by score"
