define [
  'compiled/gradezilla/Gradebook'
  'jsx/gradezilla/DataLoader'
  'underscore'
  'timezone'
  'compiled/SubmissionDetailsDialog'
  'compiled/util/natcompare'
], (Gradebook, DataLoader, _, tz, SubmissionDetailsDialog, natcompare) ->
  QUnit.module "Gradebook#localeSort"

  test "delegates to natcompare.strings", ->
    natCompareSpy = @spy(natcompare, 'strings')
    Gradebook.prototype.localeSort('a', 'b')
    ok natCompareSpy.calledWith('a', 'b')

  test "substitutes falsy args with empty string", ->
    natCompareSpy = @spy(natcompare, 'strings')
    Gradebook.prototype.localeSort(0, false)
    ok natCompareSpy.calledWith('', '')

  QUnit.module "Gradebook#gradeSort"

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

  QUnit.module "Gradebook#hideAggregateColumns",
    gradebookStubs: ->
      indexedOverrides: Gradebook.prototype.indexedOverrides
      indexedGradingPeriods: _.indexBy(@gradingPeriods, 'id')

    setupThis: (options) ->
      customOptions = options || {}
      defaults =
        gradingPeriodsEnabled: true
        getGradingPeriodToShow: -> '1'
        options:
          all_grading_periods_totals: false

      _.defaults customOptions, defaults, @gradebookStubs()

    setup: ->
      @hideAggregateColumns = Gradebook.prototype.hideAggregateColumns
    teardown: ->

  test 'returns false if multiple grading periods is disabled', ->
    self = @setupThis(gradingPeriodsEnabled: false, isAllGradingPeriods: -> false)
    notOk @hideAggregateColumns.call(self)

  test 'returns false if multiple grading periods is disabled, even if isAllGradingPeriods is true', ->
    self = @setupThis
      gradingPeriodsEnabled: false
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

  QUnit.module 'Gradebook#getVisibleGradeGridColumns',
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

  QUnit.module 'Gradebook#fieldsToExcludeFromAssignments',
    setup: ->
      @excludedFields = Gradebook.prototype.fieldsToExcludeFromAssignments

  test "includes 'description' in the response", ->
    ok _.contains(@excludedFields, 'description')

  test "includes 'needs_grading_count' in the response", ->
    ok _.contains(@excludedFields, 'needs_grading_count')

  QUnit.module "Gradebook#submissionsForStudent",
    setupThis: (options = {}) ->
      effectiveDueDates = {
        1: { 1: { grading_period_id: "1" } },
        2: { 1: { grading_period_id: "2" } }
      }

      defaults = {
        gradingPeriodsEnabled: false,
        gradingPeriodToShow: null,
        isAllGradingPeriods: -> false,
        effectiveDueDates
      }
      _.defaults options, defaults

    setup: ->
      @student =
        id: "1"
        assignment_1: { assignment_id: "1", user_id: "1", name: "yolo" }
        assignment_2: { assignment_id: "2", user_id: "1", name: "froyo" }
      @submissionsForStudent = Gradebook.prototype.submissionsForStudent

  test "returns all submissions for the student (multiple grading periods disabled)", ->
    self = @setupThis()
    submissions = @submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, "assignment_id"), ["1", "2"]

  test "returns all submissions if 'All Grading Periods' is selected", ->
    self = @setupThis(
      gradingPeriodsEnabled: true,
      gradingPeriodToShow: "0",
      isAllGradingPeriods: -> true
    )
    submissions = @submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, "assignment_id"), ["1", "2"]

  test "only returns submissions due for the student in the selected grading period", ->
    self = @setupThis(
      gradingPeriodsEnabled: true,
      gradingPeriodToShow: "2"
    )
    submissions = @submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, "assignment_id"), ["2"]

  QUnit.module 'Gradebook#studentsUrl',
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

  QUnit.module 'Gradebook#showNotesColumn',
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

  QUnit.module 'Gradebook#cellCommentClickHandler',
    setup: ->
      @cellCommentClickHandler = Gradebook.prototype.cellCommentClickHandler
      @assignments = {
        '61890000000013319': { name: 'Assignment #1' }
      }
      @student = @stub().returns({})
      @options = {}

      @fixture = document.createElement('div')
      @fixture.className = 'editable'
      @fixture.setAttribute('data-assignment-id', '61890000000013319')
      @fixture.setAttribute('data-user-id', '61890000000013319')

      @fixtureParent = document.getElementById('fixtures')
      @fixtureParent.appendChild(@fixture)

      @submissionDialogArgs = undefined

      @fakeSubmissionDetailsDialog = @stub SubmissionDetailsDialog, 'open', =>
        @submissionDialogArgs = arguments

      @event = {
        preventDefault: @stub(),
        currentTarget: @fixture
      }
      @grid = {
        getActiveCellNode: @stub().returns(@fixture)
      }

    teardown: ->
      @fixtureParent.innerHTML = ""
      @fixture = undefined
      @fakeSubmissionDetailsDialog.restore()

  test 'when not editable, returns false if the active cell node has the "cannot_edit" class', ->
    @fixture.className = 'cannot_edit'

    result = @cellCommentClickHandler(@event)

    equal result, false
    ok @event.preventDefault.called

  test 'when editable, removes the "editable" class from the active cell', ->
    @cellCommentClickHandler(@event)

    equal '', @fixture.className
    ok @event.preventDefault.called

  test 'when editable, calls @student with the user id as a string', ->
    @cellCommentClickHandler(@event)

    ok @student.calledWith('61890000000013319')

  test 'when editable, calls SubmissionDetailsDialog', ->
    @cellCommentClickHandler(@event)

    expectedArguments = {
      0: { name: 'Assignment #1' },
      1: {},
      2: {}
    }

    ok @fakeSubmissionDetailsDialog.called
    deepEqual expectedArguments, @submissionDialogArgs

  test 'ViewOptionsMenu is rendered on init', ->
    fixtures = document.getElementById("fixtures")
    fixtures.innerHTML = '<span data-component="ViewOptionsMenu"></span>'
    Gradebook.prototype.initViewOptionsMenu.call()
    buttonText = document.querySelector('[data-component="ViewOptionsMenu"] Button').innerText.trim()
    equal(buttonText, 'View')
    document.getElementById("fixtures").innerHTML = ""
