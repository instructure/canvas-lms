define [
  'compiled/gradebook2/Gradebook'
  'jsx/gradebook2/DataLoader'
  'underscore'
  'timezone'
], (Gradebook, DataLoader, _, tz) ->

  module "Gradebook2#gradeSort"

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

  gradebookStubs = ->
    indexedOverrides: Gradebook.prototype.indexedOverrides
    indexedGradingPeriods: _.indexBy(@gradingPeriods, 'id')

  module "Gradebook2#submissionOutsideOfGradingPeriod - assignment with no overrides",
    setupThis: (options) ->
      customOptions = options || {}
      defaults =
        mgpEnabled: true
        isAllGradingPeriods: -> false
        gradingPeriodToShow: '8'
        lastGradingPeriodAndDueAtNull: -> false
        dateIsInGradingPeriod: -> false

      _.defaults customOptions, defaults, gradebookStubs()

    setup: ->
      @subOutsideOfPeriod = Gradebook.prototype.submissionOutsideOfGradingPeriod
      @submission = { assignment_id: '1' }
      @student = { id: '5', sections: ['101','102','103'] }
      @gradingPeriods = {
        '8': { id: '8', start_date: '2015-04-01T06:00:00Z', end_date: '2015-05-01T05:59:59Z', is_last: false }
        '10': { id: '10', start_date: '2015-05-05T06:00:00Z', end_date: '2015-06-01T05:59:59Z', is_last: true }
      }
      @overrides = { studentOverrides: {}, sectionOverrides: {} }
    teardown: ->

  test 'returns false if multiple grading periods is not enabled', ->
    self = @setupThis(mgpEnabled: false)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    deepEqual result, false

  test 'returns false if "All Grading Periods" is selected', ->
    self = @setupThis(mgpEnabled: true, isAllGradingPeriods: -> true)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    deepEqual result, false

  test 'returns false if the assignment has a null due_at and the last grading period is selected', ->
    assignments = { '1': { id: '1', has_overrides: false, due_at: null } }
    self = @setupThis(assignments: assignments, gradingPeriodToShow: '10', lastGradingPeriodAndDueAtNull: -> true)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, false

  test 'returns true if the assignment has a null due_at and the last grading period is not selected', ->
    assignments = { '1': { id: '1', has_overrides: false, due_at: null } }
    self = @setupThis(assignments: assignments)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, true

  test 'returns false if the assignment due_at falls in the selected grading period', ->
    assignments = { '1': { id: '1', has_overrides: false, due_at: tz.parse('2015-04-15T06:00:00Z') } }
    self = @setupThis(assignments: assignments, dateIsInGradingPeriod: -> true)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-04-15T06:00:00Z')
    deepEqual result, false

  test 'returns true if the assignment due_at falls outside of the selected grading period', ->
    assignments = { '1': { id: '1', has_overrides: false, due_at: tz.parse('2015-05-15T06:00:00Z') } }
    self = @setupThis(assignments: assignments, dateIsInGradingPeriod: -> false)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-05-15T06:00:00Z')
    deepEqual result, true

  module "Gradebook2#submissionOutsideOfGradingPeriod - assignment with one student override that applies to the student",
    setupThis: (options, overrides) ->
      customOptions = options || {}
      assignments = { '1': { id: '1', has_overrides: true, due_at: tz.parse('2015-05-15T06:00:00Z'), overrides: overrides } }
      defaults =
        mgpEnabled: true
        assignments: assignments
        isAllGradingPeriods: -> false
        gradingPeriodToShow: '8'
        lastGradingPeriodAndDueAtNull: -> false
        dateIsInGradingPeriod: -> false

      _.defaults customOptions, defaults, gradebookStubs()

    generateOverrides: (dueAt) ->
      [
        { student_ids: ['5'], due_at: dueAt }
      ]

    setup: ->
      @subOutsideOfPeriod = Gradebook.prototype.submissionOutsideOfGradingPeriod
      @submission = { assignment_id: '1' }
      @student = { id: '5', sections: ['101','102','103'] }
      @gradingPeriods = {
        '8': { id: '8', start_date: '2015-04-01T06:00:00Z', end_date: '2015-05-01T05:59:59Z', is_last: false }
        '10': { id: '10', start_date: '2015-05-05T06:00:00Z', end_date: '2015-06-01T05:59:59Z', is_last: true }
      }
    teardown: ->

  test 'returns false if the due_at on the override falls within the grading period', ->
    overrides = @generateOverrides('2015-04-15T06:00:00Z')
    self = @setupThis({ dateIsInGradingPeriod: -> true }, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-04-15T06:00:00Z')
    deepEqual result, false

  test 'returns true if the due_at on the override falls outside of the grading period', ->
    overrides = @generateOverrides('2015-06-15T06:00:00Z')
    self = @setupThis({}, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-06-15T06:00:00Z')
    deepEqual result, true

  test 'returns true if the due_at on the override is null and the grading period is not the last', ->
    overrides = @generateOverrides(null)
    self = @setupThis({}, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok _.isNull(dateIsInGradingPeriodSpy.args[0][1])
    deepEqual result, true

  test 'returns false if the due_at on the override is null and the grading period is the last', ->
    overrides = @generateOverrides(null)
    self = @setupThis({ gradingPeriodToShow: '10', lastGradingPeriodAndDueAtNull: -> true }, overrides)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, false

  module "Gradebook2#submissionOutsideOfGradingPeriod - assignment with one section override that applies to the student",
    setupThis: (options, overrides) ->
      customOptions = options || {}
      assignments = { '1': { id: '1', has_overrides: true, due_at: tz.parse('2015-05-15T06:00:00Z'), overrides: overrides } }
      defaults =
        mgpEnabled: true
        assignments: assignments
        isAllGradingPeriods: -> false
        gradingPeriodToShow: '8'
        lastGradingPeriodAndDueAtNull: -> false
        dateIsInGradingPeriod: -> false

      _.defaults customOptions, defaults, gradebookStubs()

    generateOverrides: (dueAt) ->
      [
        { student_ids: ['5'], due_at: dueAt }
      ]

    setup: ->
      @subOutsideOfPeriod = Gradebook.prototype.submissionOutsideOfGradingPeriod
      @submission = { assignment_id: '1' }
      @student = { id: '5', sections: ['101','102','103'] }
      @gradingPeriods = {
        '8': { id: '8', start_date: '2015-04-01T06:00:00Z', end_date: '2015-05-01T05:59:59Z', is_last: false }
        '10': { id: '10', start_date: '2015-05-05T06:00:00Z', end_date: '2015-06-01T05:59:59Z', is_last: true }
      }
    teardown: ->

  test 'returns false if the due_at on the override falls within the grading period', ->
    overrides = @generateOverrides('2015-04-15T06:00:00Z')
    self = @setupThis({ dateIsInGradingPeriod: -> true }, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-04-15T06:00:00Z')
    deepEqual result, false

  test 'returns true if the due_at on the override falls outside of the grading period', ->
    overrides = @generateOverrides('2015-06-15T06:00:00Z')
    self = @setupThis({}, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-06-15T06:00:00Z')
    deepEqual result, true

  test 'returns true if the due_at on the override is null and the grading period is not the last', ->
    overrides = @generateOverrides(null)
    self = @setupThis({}, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok _.isNull(dateIsInGradingPeriodSpy.args[0][1])
    deepEqual result, true

  test 'returns false if the due_at on the override is null and the grading period is the last', ->
    overrides = @generateOverrides(null)
    self = @setupThis({ gradingPeriodToShow: '10', lastGradingPeriodAndDueAtNull: -> true }, overrides)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, false


  module "Gradebook2#submissionOutsideOfGradingPeriod - assignment with one group that applies to the student",
    setupThis: (options, overrides) ->
      customOptions = options || {}
      assignments = { '1': { id: '1', has_overrides: true, due_at: tz.parse('2015-05-15T06:00:00Z'), overrides: overrides } }
      defaults =
        mgpEnabled: true
        assignments: assignments
        isAllGradingPeriods: -> false
        gradingPeriodToShow: '8'
        lastGradingPeriodAndDueAtNull: -> false
        dateIsInGradingPeriod: -> false

      _.defaults customOptions, defaults, gradebookStubs()

    generateOverrides: (dueAt) ->
      [
        { group_id: '202', due_at: dueAt }
      ]

    setup: ->
      @subOutsideOfPeriod = Gradebook.prototype.submissionOutsideOfGradingPeriod
      @submission = { assignment_id: '1' }
      @student = { id: '5', sections: ['101','102','103'], group_ids: ['202'] }
      @gradingPeriods = {
        '8': { id: '8', start_date: '2015-04-01T06:00:00Z', end_date: '2015-05-01T05:59:59Z', is_last: false }
        '10': { id: '10', start_date: '2015-05-05T06:00:00Z', end_date: '2015-06-01T05:59:59Z', is_last: true }
      }
    teardown: ->

  test 'returns false if the due_at on the override falls within the grading period', ->
    overrides = @generateOverrides('2015-04-15T06:00:00Z')
    self = @setupThis({ dateIsInGradingPeriod: -> true }, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-04-15T06:00:00Z')
    deepEqual result, false

  test 'returns true if the due_at on the override falls outside of the grading period', ->
    overrides = @generateOverrides('2015-06-15T06:00:00Z')
    self = @setupThis({}, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-06-15T06:00:00Z')
    deepEqual result, true

  test 'returns true if the due_at on the override is null and the grading period is not the last', ->
    overrides = @generateOverrides(null)
    self = @setupThis({}, overrides)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok _.isNull(dateIsInGradingPeriodSpy.args[0][1])
    deepEqual result, true

  test 'returns false if the due_at on the override is null and the grading period is the last', ->
    overrides = @generateOverrides(null)
    self = @setupThis({ gradingPeriodToShow: '10', lastGradingPeriodAndDueAtNull: -> true }, overrides)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, false

  module "Gradebook2#submissionOutsideOfGradingPeriod - assignment with one override that does not apply to the student",
    setupThis: (options) ->
      customOptions = options || {}
      defaults =
        mgpEnabled: true
        isAllGradingPeriods: -> false
        gradingPeriodToShow: '8'
        lastGradingPeriodAndDueAtNull: -> false
        dateIsInGradingPeriod: -> false

      _.defaults customOptions, defaults, gradebookStubs()

    setup: ->
      @subOutsideOfPeriod = Gradebook.prototype.submissionOutsideOfGradingPeriod
      @submission = { assignment_id: '1' }
      @student = { id: '5', sections: ['101','102','103'] }
      @gradingPeriods = {
        '8': { id: '8', start_date: '2015-04-01T06:00:00Z', end_date: '2015-05-01T05:59:59Z', is_last: false }
        '10': { id: '10', start_date: '2015-05-05T06:00:00Z', end_date: '2015-06-01T05:59:59Z', is_last: true }
      }
      @overrides = {
        studentOverrides: { '1': { '18': { student_ids: ['18'], due_at: '2015-04-15T06:00:00Z' } } }
        sectionOverrides: {}
      }
    teardown: ->

  test 'returns true if the assignment is only visible to overrides', ->
    assignments = { '1': { id: '1', has_overrides: true, due_at: null, only_visible_to_overrides: true } }
    self = @setupThis( assignments: assignments)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)
    deepEqual result, true

  test 'returns true if the assignment due_at is outside of the grading period', ->
    assignments = { '1': { id: '1', has_overrides: true, due_at: tz.parse('2015-05-15T06:00:00Z') } }
    self = @setupThis(assignments: assignments)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-05-15T06:00:00Z')
    deepEqual result, true

  test 'returns false if the assignment due_at is within the grading period', ->
    assignments = { '1': { id: '1', has_overrides: true, due_at: tz.parse('2015-04-15T06:00:00Z') } }
    self = @setupThis(assignments: assignments, dateIsInGradingPeriod: -> true)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-04-15T06:00:00Z')
    deepEqual result, false

  test 'returns true if the assignment due_at is null and the grading period is not the last', ->
    assignments = { '1': { id: '1', has_overrides: true, due_at: null } }
    self = @setupThis(assignments: assignments)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok dateIsInGradingPeriodSpy.called
    ok _.isNull(dateIsInGradingPeriodSpy.args[0][1])
    deepEqual result, true

  test 'returns false if the assignment due_at is null and the grading period is the last', ->
    assignments = { '1': { id: '1', has_overrides: true, due_at: null } }
    self = @setupThis(assignments: assignments, gradingPeriodToShow: '10', lastGradingPeriodAndDueAtNull: -> true)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, @overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, false

  module "Gradebook2#submissionOutsideOfGradingPeriod - assignment with two overrides that apply to the student",
    setupThis: (options, overrides) ->
      customOptions = options || {}
      assignments = { '1': { id: '1', has_overrides: true, due_at: tz.parse('2015-05-15T06:00:00Z'), overrides: overrides } }
      defaults =
        mgpEnabled: true
        assignments: assignments
        isAllGradingPeriods: -> false
        gradingPeriodToShow: '8'
        lastGradingPeriodAndDueAtNull: -> false
        dateIsInGradingPeriod: -> false

      _.defaults customOptions, defaults, gradebookStubs()

    generateOverrides: (date1, date2) ->
      [
        { student_ids: ['5'], due_at: date1 }
        { course_section_id: '101', assignment_id: '1', due_at: date2 }
      ]

    setup: ->
      @subOutsideOfPeriod = Gradebook.prototype.submissionOutsideOfGradingPeriod
      @submission = { assignment_id: '1' }
      @student = { id: '5', sections: ['101','102','103'] }
      @gradingPeriods = {
        '8': { id: '8', start_date: '2015-04-01T06:00:00Z', end_date: '2015-05-01T05:59:59Z', is_last: false }
        '10': { id: '10', start_date: '2015-05-05T06:00:00Z', end_date: '2015-06-01T05:59:59Z', is_last: true }
      }
    teardown: ->

  test 'returns false if the latest date of the two overrides falls within the grading period', ->
    overrides = @generateOverrides('2015-03-01T06:00:00Z', '2015-04-15T06:00:00Z')
    self = @setupThis({ dateIsInGradingPeriod: -> true }, overrides)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-04-15T06:00:00Z')
    deepEqual result, false

  test 'returns true if the latest date of the two overrides falls outside the grading period' +
  '(even if the earlier date falls within the grading period)', ->
    overrides = @generateOverrides('2015-04-15T06:00:00Z', '2015-05-15T06:00:00Z')
    self = @setupThis({}, overrides)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok +dateIsInGradingPeriodSpy.args[0][1] == +tz.parse('2015-05-15T06:00:00Z')
    deepEqual result, true

  test 'returns false if either date is null and the last grading period is selected', ->
    overrides = @generateOverrides(null, '2015-05-15T06:00:00Z')
    self = @setupThis({ gradingPeriodToShow: '10', lastGradingPeriodAndDueAtNull: -> true }, overrides)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    lastGradingPeriodAndDueAtNullSpy = @spy(self, 'lastGradingPeriodAndDueAtNull')
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok lastGradingPeriodAndDueAtNullSpy.called
    ok _.isNull(lastGradingPeriodAndDueAtNullSpy.args[0][1])
    deepEqual result, false

  test 'returns true if either date is null and the last grading period is not selected', ->
    overrides = @generateOverrides(null, '2015-05-15T06:00:00Z')
    self = @setupThis({}, overrides)
    isOutsidePeriod = @subOutsideOfPeriod.bind(self)
    dateIsInGradingPeriodSpy = @spy(self, 'dateIsInGradingPeriod')
    result = isOutsidePeriod(@submission, @student, @gradingPeriods, overrides)

    ok dateIsInGradingPeriodSpy.called
    ok _.isNull(dateIsInGradingPeriodSpy.args[0][1])
    deepEqual result, true

  module "Gradebook2#lastGradingPeriodAndDueAtNull",
    setup: ->
      @lastGradingPeriodAndDueAtNull = Gradebook.prototype.lastGradingPeriodAndDueAtNull
    teardown: ->

  test 'returns true if it is the last grading period and the due at is null', ->
    gradingPeriod = { is_last: true }
    dueAt = null
    ok @lastGradingPeriodAndDueAtNull(gradingPeriod, dueAt)

  test 'returns false if it is not the last grading period', ->
    gradingPeriod = { is_last: false }
    dueAt = null
    notOk @lastGradingPeriodAndDueAtNull(gradingPeriod, dueAt)

  test 'returns false if the dueAt is something other than null', ->
    gradingPeriod = { is_last: true }
    dueAt = tz.parse('2015-05-15T06:00:00Z')
    notOk @lastGradingPeriodAndDueAtNull(gradingPeriod, dueAt)

  module "Gradebook2#dateIsInGradingPeriod",
    setup: ->
      @dateIsInGradingPeriod = Gradebook.prototype.dateIsInGradingPeriod
      @gradingPeriod = { start_date: tz.parse('2015-04-01T06:00:00Z'), end_date: tz.parse('2015-05-01T06:00:00Z') }
    teardown: ->

  test 'returns false if the date is null', ->
    date = null
    notOk @dateIsInGradingPeriod(@gradingPeriod, date)

  test 'returns true if the date falls between the grading period start date and end date', ->
    date = tz.parse('2015-04-15T06:00:00Z')
    ok @dateIsInGradingPeriod(@gradingPeriod, date)

  test 'returns false if the date is before the grading period start date', ->
    date = tz.parse('2015-03-15T06:00:00Z')
    notOk @dateIsInGradingPeriod(@gradingPeriod, date)

  test 'returns false if the date is after the grading period end date', ->
    date = tz.parse('2015-05-15T06:00:00Z')
    notOk @dateIsInGradingPeriod(@gradingPeriod, date)

  test 'returns false if the date is the same as the grading period start date', ->
    date = tz.parse('2015-04-01T06:00:00Z')
    notOk @dateIsInGradingPeriod(@gradingPeriod, date)

  test 'returns true if the date is the same as the grading period end date', ->
    date = tz.parse('2015-05-01T06:00:00Z')
    ok @dateIsInGradingPeriod(@gradingPeriod, date)

  module "Gradebook2#hideAggregateColumns",
    setupThis: (options) ->
      customOptions = options || {}
      defaults =
        mgpEnabled: true
        getGradingPeriodToShow: -> '1'
        options:
          all_grading_periods_totals: false

      _.defaults customOptions, defaults, gradebookStubs()

    setup: ->
      @hideAggregateColumns = Gradebook.prototype.hideAggregateColumns
    teardown: ->

  test 'returns false if multiple grading periods is disabled', ->
    self = @setupThis(mgpEnabled: false, isAllGradingPeriods: -> false)
    notOk @hideAggregateColumns.call(self)

  test 'returns false if multiple grading periods is disabled, even if isAllGradingPeriods is true', ->
    self = @setupThis
      mgpEnabled: false
      getGradingPeriodToShow: -> '0'
      isAllGradingPeriods: -> true

    notOk @hideAggregateColumns.call(self)

  test 'returns false if "All Grading Periods" is not selected', ->
    self = @setupThis(isAllGradingPeriods: -> false)
    notOk @hideAggregateColumns.call(self)

  test 'returns true if "All Grading Periods" is selected', ->
    self = @setupThis
      getGradingPeriodToShow: -> '0'
      isAllGradingPeriods: -> true

    ok @hideAggregateColumns.call(self)

  test 'returns false if "All Grading Periods" is selected and the feature' +
  'flag is turned on for "Display Totals for All Grading Periods"', ->
    self = @setupThis
      getGradingPeriodToShow: -> '0'
      isAllGradingPeriods: -> true
      options:
        all_grading_periods_totals: true

    notOk @hideAggregateColumns.call(self)

  module 'Gradebook#getVisibleGradeGridColumns',
    setup: ->
      @getVisibleGradeGridColumns = Gradebook.prototype.getVisibleGradeGridColumns
      @makeColumnSortFn = Gradebook.prototype.makeColumnSortFn
      @compareAssignmentPositions = Gradebook.prototype.compareAssignmentPositions
      @compareAssignmentDueDates = Gradebook.prototype.compareAssignmentDueDates
      @wrapColumnSortFn = Gradebook.prototype.wrapColumnSortFn
      @getStoredSortOrder = Gradebook.prototype.getStoredSortOrder
      @defaultSortType = 'assignment_group'
      @allAssignmentColumns = [
          { object: { assignment_group: { position: 1 }, position: 1, name: "first" } },
          { object: { assignment_group: { position: 1 }, position: 2, name: "second" } },
          { object: { assignment_group: { position: 1 }, position: 3, name: "third" } }
        ]
      @aggregateColumns = []
      @parentColumns = []
      @customColumnDefinitions = -> []
      @spy(this, 'makeColumnSortFn')
    teardown: ->

  test 'It sorts columns when there is a valid sortType', ->
    @isInvalidCustomSort = -> false
    @columnOrderHasNotBeenSaved = -> false
    @gradebookColumnOrderSettings = { sortType: 'due_date' }
    @getVisibleGradeGridColumns()
    ok @makeColumnSortFn.calledWith { sortType: 'due_date' }

  test 'It falls back to the default sort type if the custom sort type does not have a customOrder property', ->
    @isInvalidCustomSort = -> true
    @gradebookColumnOrderSettings = { sortType: 'custom' }
    @makeCompareAssignmentCustomOrderFn = Gradebook.prototype.makeCompareAssignmentCustomOrderFn
    @getVisibleGradeGridColumns()
    ok @makeColumnSortFn.calledWith { sortType: 'assignment_group' }

  test 'It does not sort columns when gradebookColumnOrderSettings is undefined', ->
    @gradebookColumnOrderSettings = undefined
    @getVisibleGradeGridColumns()
    notOk @makeColumnSortFn.called

  module 'Gradebook#fieldsToExcludeFromAssignments',
    setup: ->
      @excludedFields = Gradebook.prototype.fieldsToExcludeFromAssignments

  test "includes 'description' in the response", ->
    ok _.contains(@excludedFields, 'description')

  test "includes 'needs_grading_count' in the response", ->
    ok _.contains(@excludedFields, 'needs_grading_count')

  module 'Gradebook#studentsUrl',
    setupThis:(options) ->
      options = options || {}
      defaults = {
        showConcludedEnrollments: false
        showInactiveEnrollments: false
      }
      _.defaults options, defaults

    setup: ->
      @studentsUrl = Gradebook.prototype.studentsUrl

  test 'enrollmentUrl returns "students_url"', ->
    equal @studentsUrl.call(@setupThis()), 'students_url'

  test 'when concluded only, enrollmentUrl returns "students_with_concluded_enrollments_url"', ->
    self = @setupThis(showConcludedEnrollments: true)
    equal @studentsUrl.call(self), 'students_with_concluded_enrollments_url'

  test 'when inactive only, enrollmentUrl returns "students_with_inactive_enrollments_url"', ->
    self = @setupThis(showInactiveEnrollments: true)
    equal @studentsUrl.call(self), 'students_with_inactive_enrollments_url'

  test 'when show concluded and hide inactive are true, enrollmentUrl returns "students_with_concluded_and_inactive_enrollments_url"', ->
    self = @setupThis(showConcludedEnrollments: true, showInactiveEnrollments: true)
    equal @studentsUrl.call(self), 'students_with_concluded_and_inactive_enrollments_url'

  module 'Gradebook#showNotesColumn',
    setup: ->
      @loadNotes = @stub(DataLoader, "getDataForColumn")

    setupShowNotesColumn: (opts) ->
      defaultOptions =
        options: {}
        toggleNotesColumn: ->
      self = _.defaults(opts || {}, defaultOptions)
      @showNotesColumn = Gradebook.prototype.showNotesColumn.bind(self)

  test 'loads the notes if they have not yet been loaded', ->
    @setupShowNotesColumn(teacherNotesNotYetLoaded: true)
    @showNotesColumn()
    ok @loadNotes.calledOnce

  test 'does not load the notes if they are already loaded', ->
    @setupShowNotesColumn(teacherNotesNotYetLoaded: false)
    @showNotesColumn()
    ok @loadNotes.notCalled
