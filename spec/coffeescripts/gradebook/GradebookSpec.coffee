#
# Copyright (C) 2014 - 2017 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'spec/jsx/gradebook/GradeCalculatorSpecHelper'
  'compiled/gradebook/Gradebook'
  'jsx/gradebook/DataLoader'
  'underscore'
  'timezone'
  'compiled/util/natcompare'
  'compiled/SubmissionDetailsDialog'
  'jsx/gradebook/CourseGradeCalculator'
], (
  GradeCalculatorSpecHelper, Gradebook, DataLoader, _, tz, natcompare, SubmissionDetailsDialog, CourseGradeCalculator
) ->
  exampleGradebookOptions =
    settings:
      show_concluded_enrollments: 'true'
      show_inactive_enrollments: 'true'
    sections: []

  createExampleGrades = GradeCalculatorSpecHelper.createCourseGradesWithGradingPeriods

  QUnit.module 'Gradebook'

  test 'normalizes the grading period set from the env', ->
    options = _.extend {}, exampleGradebookOptions,
      grading_period_set:
        id: '1501'
        grading_periods: [{ id: '701', weight: 50 }, { id: '702', weight: 50 }]
        weighted: true
    gradingPeriodSet = new Gradebook(options).gradingPeriodSet
    deepEqual(gradingPeriodSet.id, '1501')
    equal(gradingPeriodSet.gradingPeriods.length, 2)
    deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])

  test 'sets grading period set to null when not defined in the env', ->
    gradingPeriodSet = new Gradebook(exampleGradebookOptions).gradingPeriodSet
    deepEqual(gradingPeriodSet, null)

  QUnit.module 'Gradebook#calculateStudentGrade',
    setupThis:(options = {}) ->
      assignments = [{ id: 201, points_possible: 10, omit_from_final_grade: false }]
      submissions = [{ assignment_id: 201, score: 10 }]
      defaults = {
        gradingPeriodToShow: '0'
        isAllGradingPeriods: Gradebook.prototype.isAllGradingPeriods
        assignmentGroups: [{ id: 301, group_weight: 60, rules: {}, assignments }]
        options: { group_weighting_scheme: 'points' }
        gradingPeriods: [{ id: 701, weight: 50 }, { id: 702, weight: 50 }]
        gradingPeriodSet:
          id: '1501'
          gradingPeriods: [{ id: '701', weight: 50 }, { id: '702', weight: 50 }]
          weighted: true
        effectiveDueDates: { 201: { 101: { grading_period_id: '701' } } }
        submissionsForStudent: () ->
          submissions
        addDroppedClass: () ->
      }
      _.defaults options, defaults

    setup: ->
      @calculate = Gradebook.prototype.calculateStudentGrade

  test 'calculates grades using properties from the gradebook', ->
    self = @setupThis()
    @stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
    @calculate.call(self, id: '101', loaded: true, initialized: true)
    args = CourseGradeCalculator.calculate.getCall(0).args
    equal(args[0], self.submissionsForStudent())
    equal(args[1], self.assignmentGroups)
    equal(args[2], self.options.group_weighting_scheme)
    equal(args[3], self.gradingPeriodSet)

  test 'scopes effective due dates to the user', ->
    self = @setupThis()
    @stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
    @calculate.call(self, id: '101', loaded: true, initialized: true)
    dueDates = CourseGradeCalculator.calculate.getCall(0).args[4]
    deepEqual(dueDates, 201: { grading_period_id: '701' })

  test 'calculates grades without grading period data when grading period set is null', ->
    self = @setupThis(gradingPeriodSet: null)
    @stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
    @calculate.call(self, id: '101', loaded: true, initialized: true)
    args = CourseGradeCalculator.calculate.getCall(0).args
    equal(args[0], self.submissionsForStudent())
    equal(args[1], self.assignmentGroups)
    equal(args[2], self.options.group_weighting_scheme)
    equal(typeof args[3], 'undefined')
    equal(typeof args[4], 'undefined')

  test 'calculates grades without grading period data when effective due dates are not defined', ->
    self = @setupThis(effectiveDueDates: null)
    @stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
    @calculate.call(self, id: '101', loaded: true, initialized: true)
    args = CourseGradeCalculator.calculate.getCall(0).args
    equal(args[0], self.submissionsForStudent())
    equal(args[1], self.assignmentGroups)
    equal(args[2], self.options.group_weighting_scheme)
    equal(typeof args[3], 'undefined')
    equal(typeof args[4], 'undefined')

  test 'stores the current grade on the student when not including ungraded assignments', ->
    exampleGrades = createExampleGrades()
    self = @setupThis(include_ungraded_assignments: false)
    @stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
    student = { id: '101', loaded: true, initialized: true }
    @calculate.call(self, student)
    equal(student.total_grade, exampleGrades.current)

  test 'stores the final grade on the student when including ungraded assignments', ->
    exampleGrades = createExampleGrades()
    self = @setupThis(include_ungraded_assignments: true)
    @stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
    student = { id: '101', loaded: true, initialized: true }
    @calculate.call(self, student)
    equal(student.total_grade, exampleGrades.final)

  test 'stores the current grade from the selected grading period when not including ungraded assignments', ->
    exampleGrades = createExampleGrades()
    self = @setupThis(gradingPeriodToShow: 701, include_ungraded_assignments: false)
    @stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
    student = { id: '101', loaded: true, initialized: true }
    @calculate.call(self, student)
    equal(student.total_grade, exampleGrades.gradingPeriods[701].current)

  test 'stores the final grade from the selected grading period when including ungraded assignments', ->
    exampleGrades = createExampleGrades()
    self = @setupThis(gradingPeriodToShow: 701, include_ungraded_assignments: true)
    @stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
    student = { id: '101', loaded: true, initialized: true }
    @calculate.call(self, student)
    equal(student.total_grade, exampleGrades.gradingPeriods[701].final)

  test 'does not calculate when the student is not loaded', ->
    self = @setupThis()
    @stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
    @calculate.call(self, id: '101', loaded: false, initialized: true)
    notOk(CourseGradeCalculator.calculate.called)

  test 'does not calculate when the student is not initialized', ->
    self = @setupThis()
    @stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
    @calculate.call(self, id: '101', loaded: true, initialized: false)
    notOk(CourseGradeCalculator.calculate.called)

  QUnit.module "Gradebook#localeSort"

  test "delegates to natcompare.strings", ->
    natCompareSpy = @spy(natcompare, 'strings')
    Gradebook.prototype.localeSort('a', 'b')
    ok natCompareSpy.calledWith('a', 'b')

  test "substitutes falsy args with empty string", ->
    natCompareSpy = @spy(natcompare, 'strings')
    Gradebook.prototype.localeSort(0, false)
    ok natCompareSpy.calledWith('', '')

  QUnit.module 'Gradebook#gradeSort'

  test 'gradeSort - total_grade', ->
    gradeSort = (showTotalGradeAsPoints, a, b, field, asc) ->
      asc = true unless asc?

      Gradebook.prototype.gradeSort.call options:
        show_total_grade_as_points: showTotalGradeAsPoints
      , a, b, field, asc

    ok gradeSort(false
    , {total_grade: {score: 10, possible: 20}}
    , {total_grade: {score: 5, possible: 10}}
    , 'total_grade') == 0
    , 'total_grade sorts by percent (normally)'

    ok gradeSort(true
    , {total_grade: {score: 10, possible: 20}}
    , {total_grade: {score: 5, possible: 10}}
    , 'total_grade') > 0
    , 'total_grade sorts by score when if show_total_grade_as_points'

    ok gradeSort(true
    , {assignment_group_1: {score: 10, possible: 20}}
    , {assignment_group_1: {score: 5, possible: 10}}
    , 'assignment_group_1') == 0
    , 'assignment groups are always sorted by percent'

    ok gradeSort(false
    , {assignment1: {score: 5, possible: 10}}
    , {assignment1: {score: 10, possible: 20}}
    , 'assignment1') < 0
    , 'other fields are sorted by score'

  QUnit.module 'Gradebook#hideAggregateColumns',
    gradebookStubs: ->
      indexedOverrides: Gradebook.prototype.indexedOverrides
      indexedGradingPeriods: _.indexBy(@gradingPeriods, 'id')

    setupThis: (options) ->
      customOptions = options || {}
      defaults =
        gradingPeriodSet: { id: '1' }
        getGradingPeriodToShow: -> '1'
        options:
          all_grading_periods_totals: false

      _.defaults customOptions, defaults, @gradebookStubs()

    setup: ->
      @hideAggregateColumns = Gradebook.prototype.hideAggregateColumns
    teardown: ->

  test 'returns false if there are no grading periods', ->
    self = @setupThis(gradingPeriodSet: null, isAllGradingPeriods: -> false)
    notOk @hideAggregateColumns.call(self)

  test 'returns false if there are no grading periods, even if isAllGradingPeriods is true', ->
    self = @setupThis
      gradingPeriodSet: null
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

  test 'returns false if "All Grading Periods" is selected and "Display Totals ' +
  'for All Grading Periods option" is not checked on the grading period set', ->
    self = @setupThis
      getGradingPeriodToShow: -> '0'
      isAllGradingPeriods: -> true
      gradingPeriodSet:
        displayTotalsForAllGradingPeriods: true

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
          { object: { assignment_group: { position: 1 }, position: 1, name: 'first' } },
          { object: { assignment_group: { position: 1 }, position: 2, name: 'second' } },
          { object: { assignment_group: { position: 1 }, position: 3, name: 'third' } }
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

  test 'includes "description" in the response', ->
    ok _.contains(@excludedFields, 'description')

  test 'includes "needs_grading_count" in the response', ->
    ok _.contains(@excludedFields, 'needs_grading_count')

  QUnit.module 'Gradebook#submissionsForStudent',
    setupThis: (options = {}) ->
      effectiveDueDates = {
        1: { 1: { grading_period_id: '1' } },
        2: { 1: { grading_period_id: '2' } }
      }

      defaults = {
        gradingPeriodSet: null,
        gradingPeriodToShow: null,
        isAllGradingPeriods: -> false,
        effectiveDueDates
      }
      _.defaults options, defaults

    setup: ->
      @student =
        id: '1'
        assignment_1: { assignment_id: '1', user_id: '1', name: 'yolo' }
        assignment_2: { assignment_id: '2', user_id: '1', name: 'froyo' }
      @submissionsForStudent = Gradebook.prototype.submissionsForStudent

  test 'returns all submissions for the student when there are no grading periods', ->
    self = @setupThis()
    submissions = @submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, 'assignment_id'), ['1', '2']

  test 'returns all submissions if "All Grading Periods" is selected', ->
    self = @setupThis(
      gradingPeriodSet: { id: '1' },
      gradingPeriodToShow: '0',
      isAllGradingPeriods: -> true
    )
    submissions = @submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, 'assignment_id'), ['1', '2']

  test 'only returns submissions due for the student in the selected grading period', ->
    self = @setupThis(
      gradingPeriodSet: { id: '1' },
      gradingPeriodToShow: '2'
    )
    submissions = @submissionsForStudent.call(self, @student)
    propEqual _.pluck(submissions, 'assignment_id'), ['2']

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

  QUnit.module 'Gradebook#weightedGroups',
    setup: ->
      @weightedGroups = Gradebook.prototype.weightedGroups

  test 'returns true when group_weighting_scheme is "percent"', ->
    equal @weightedGroups.call(options: { group_weighting_scheme: 'percent' }), true

  test 'returns false when group_weighting_scheme is not "percent"', ->
    equal @weightedGroups.call(options: { group_weighting_scheme: 'points' }), false
    equal @weightedGroups.call(options: { group_weighting_scheme: null }), false

  QUnit.module 'Gradebook#weightedGrades',
    setupThis:(group_weighting_scheme, gradingPeriodSet) ->
      { options: { group_weighting_scheme }, gradingPeriodSet }
    setup: ->
      @weightedGrades = Gradebook.prototype.weightedGrades

  test 'returns true when group_weighting_scheme is "percent"', ->
    self = @setupThis('percent', { weighted: false })
    equal @weightedGrades.call(self), true

  test 'returns true when the gradingPeriodSet is weighted', ->
    self = @setupThis('points', { weighted: true })
    equal @weightedGrades.call(self), true

  test 'returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not weighted', ->
    self = @setupThis('points', { weighted: false })
    equal @weightedGrades.call(self), false

  test 'returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not defined', ->
    self = @setupThis('points', null)
    equal @weightedGrades.call(self), false

  QUnit.module 'Gradebook#displayPointTotals',
    setupThis:(show_total_grade_as_points, weightedGrades) ->
      options: { show_total_grade_as_points }
      weightedGrades: () -> weightedGrades
    setup: ->
      @displayPointTotals = Gradebook.prototype.displayPointTotals

  test 'returns true when grades are not weighted and show_total_grade_as_points is true', ->
    self = @setupThis(true, false)
    equal @displayPointTotals.call(self), true

  test 'returns false when grades are weighted', ->
    self = @setupThis(true, true)
    equal @displayPointTotals.call(self), false

  test 'returns false when show_total_grade_as_points is false', ->
    self = @setupThis(false, false)
    equal @displayPointTotals.call(self), false

  QUnit.module 'Gradebook#showNotesColumn',
    setup: ->
      @loadNotes = @stub(DataLoader, 'getDataForColumn')

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

      @stub(SubmissionDetailsDialog, 'open').callsFake =>
        @submissionDialogArgs = arguments

      @event = {
        preventDefault: @stub(),
        currentTarget: @fixture
      }
      @grid = {
        getActiveCellNode: @stub().returns(@fixture)
      }

    teardown: ->
      @fixtureParent.innerHTML = ''
      @fixture = undefined

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

    equal SubmissionDetailsDialog.open.callCount, 1
    deepEqual expectedArguments, @submissionDialogArgs
