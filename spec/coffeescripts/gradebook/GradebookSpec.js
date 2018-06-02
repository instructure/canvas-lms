/*
 * Copyright (C) 2014 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import GradeCalculatorSpecHelper from 'spec/jsx/gradebook/GradeCalculatorSpecHelper'
import Gradebook from 'compiled/gradebook/Gradebook'
import DataLoader from 'jsx/gradebook/DataLoader'
import _ from 'underscore'
import tz from 'timezone'
import natcompare from 'compiled/util/natcompare'
import SubmissionDetailsDialog from 'compiled/SubmissionDetailsDialog'
import CourseGradeCalculator from 'jsx/gradebook/CourseGradeCalculator'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'

const createGradebook = () =>
  new Gradebook({
    settings: {
      show_concluded_enrollments: false,
      show_inactive_enrollments: false
    },
    sections: {}
  })

const exampleGradebookOptions = {
  settings: {
    show_concluded_enrollments: 'true',
    show_inactive_enrollments: 'true'
  },
  sections: []
}

const createExampleGrades = GradeCalculatorSpecHelper.createCourseGradesWithGradingPeriods

QUnit.module('Gradebook')

test('normalizes the grading period set from the env', function() {
  const options = _.extend({}, exampleGradebookOptions, {
    grading_period_set: {
      id: '1501',
      grading_periods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
      weighted: true
    }
  })
  const {gradingPeriodSet} = new Gradebook(options)
  deepEqual(gradingPeriodSet.id, '1501')
  equal(gradingPeriodSet.gradingPeriods.length, 2)
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
})

test('sets grading period set to null when not defined in the env', function() {
  const {gradingPeriodSet} = new Gradebook(exampleGradebookOptions)
  deepEqual(gradingPeriodSet, null)
})

QUnit.module('Gradebook#calculateStudentGrade', {
  setupThis(options = {}) {
    const assignments = [{id: 201, points_possible: 10, omit_from_final_grade: false}]
    const submissions = [{assignment_id: 201, score: 10}]
    const defaults = {
      gradingPeriodToShow: '0',
      isAllGradingPeriods: Gradebook.prototype.isAllGradingPeriods,
      assignmentGroups: [{id: 301, group_weight: 60, rules: {}, assignments}],
      options: {group_weighting_scheme: 'points'},
      gradingPeriods: [{id: 701, weight: 50}, {id: 702, weight: 50}],
      gradingPeriodSet: {
        id: '1501',
        gradingPeriods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
        weighted: true
      },
      effectiveDueDates: {201: {101: {grading_period_id: '701'}}},
      submissionsForStudent() {
        return submissions
      },
      addDroppedClass() {}
    }
    return _.defaults(options, defaults)
  },

  setup() {
    this.calculate = Gradebook.prototype.calculateStudentGrade
  }
})

test('calculates grades using properties from the gradebook', function() {
  const self = this.setupThis()
  this.stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
  this.calculate.call(self, {id: '101', loaded: true, initialized: true})
  const {args} = CourseGradeCalculator.calculate.getCall(0)
  equal(args[0], self.submissionsForStudent())
  equal(args[1], self.assignmentGroups)
  equal(args[2], self.options.group_weighting_scheme)
  equal(args[3], self.gradingPeriodSet)
})

test('scopes effective due dates to the user', function() {
  const self = this.setupThis()
  this.stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
  this.calculate.call(self, {id: '101', loaded: true, initialized: true})
  const dueDates = CourseGradeCalculator.calculate.getCall(0).args[4]
  return deepEqual(dueDates, {201: {grading_period_id: '701'}})
})

test('calculates grades without grading period data when grading period set is null', function() {
  const self = this.setupThis({gradingPeriodSet: null})
  this.stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
  this.calculate.call(self, {id: '101', loaded: true, initialized: true})
  const {args} = CourseGradeCalculator.calculate.getCall(0)
  equal(args[0], self.submissionsForStudent())
  equal(args[1], self.assignmentGroups)
  equal(args[2], self.options.group_weighting_scheme)
  equal(typeof args[3], 'undefined')
  equal(typeof args[4], 'undefined')
})

test('calculates grades without grading period data when effective due dates are not defined', function() {
  const self = this.setupThis({effectiveDueDates: null})
  this.stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
  this.calculate.call(self, {id: '101', loaded: true, initialized: true})
  const {args} = CourseGradeCalculator.calculate.getCall(0)
  equal(args[0], self.submissionsForStudent())
  equal(args[1], self.assignmentGroups)
  equal(args[2], self.options.group_weighting_scheme)
  equal(typeof args[3], 'undefined')
  equal(typeof args[4], 'undefined')
})

test('stores the current grade on the student when not including ungraded assignments', function() {
  const exampleGrades = createExampleGrades()
  const self = this.setupThis({include_ungraded_assignments: false})
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
  const student = {id: '101', loaded: true, initialized: true}
  this.calculate.call(self, student)
  equal(student.total_grade, exampleGrades.current)
})

test('stores the final grade on the student when including ungraded assignments', function() {
  const exampleGrades = createExampleGrades()
  const self = this.setupThis({include_ungraded_assignments: true})
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
  const student = {id: '101', loaded: true, initialized: true}
  this.calculate.call(self, student)
  equal(student.total_grade, exampleGrades.final)
})

test('stores the current grade from the selected grading period when not including ungraded assignments', function() {
  const exampleGrades = createExampleGrades()
  const self = this.setupThis({gradingPeriodToShow: 701, include_ungraded_assignments: false})
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
  const student = {id: '101', loaded: true, initialized: true}
  this.calculate.call(self, student)
  equal(student.total_grade, exampleGrades.gradingPeriods[701].current)
})

test('stores the final grade from the selected grading period when including ungraded assignments', function() {
  const exampleGrades = createExampleGrades()
  const self = this.setupThis({gradingPeriodToShow: 701, include_ungraded_assignments: true})
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
  const student = {id: '101', loaded: true, initialized: true}
  this.calculate.call(self, student)
  equal(student.total_grade, exampleGrades.gradingPeriods[701].final)
})

test('does not calculate when the student is not loaded', function() {
  const self = this.setupThis()
  this.stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
  this.calculate.call(self, {id: '101', loaded: false, initialized: true})
  notOk(CourseGradeCalculator.calculate.called)
})

test('does not calculate when the student is not initialized', function() {
  const self = this.setupThis()
  this.stub(CourseGradeCalculator, 'calculate').returns(createExampleGrades())
  this.calculate.call(self, {id: '101', loaded: true, initialized: false})
  notOk(CourseGradeCalculator.calculate.called)
})

QUnit.module('Gradebook#localeSort')

test('delegates to natcompare.strings', function() {
  const natCompareSpy = this.spy(natcompare, 'strings')
  Gradebook.prototype.localeSort('a', 'b')
  ok(natCompareSpy.calledWith('a', 'b'))
})

test('substitutes falsy args with empty string', function() {
  const natCompareSpy = this.spy(natcompare, 'strings')
  Gradebook.prototype.localeSort(0, false)
  ok(natCompareSpy.calledWith('', ''))
})

QUnit.module('Gradebook#gradeSort')

test('gradeSort - total_grade', function() {
  const gradeSort = function(showTotalGradeAsPoints, a, b, field, asc = true) {
    return Gradebook.prototype.gradeSort.call(
      {
        options: {
          show_total_grade_as_points: showTotalGradeAsPoints
        }
      },
      a,
      b,
      field,
      asc
    )
  }

  ok(
    gradeSort(
      false,
      {total_grade: {score: 10, possible: 20}},
      {total_grade: {score: 5, possible: 10}},
      'total_grade'
    ) === 0,
    'total_grade sorts by percent (normally)'
  )

  ok(
    gradeSort(
      true,
      {total_grade: {score: 10, possible: 20}},
      {total_grade: {score: 5, possible: 10}},
      'total_grade'
    ) > 0,
    'total_grade sorts by score when if show_total_grade_as_points'
  )

  ok(
    gradeSort(
      true,
      {assignment_group_1: {score: 10, possible: 20}},
      {assignment_group_1: {score: 5, possible: 10}},
      'assignment_group_1'
    ) === 0,
    'assignment groups are always sorted by percent'
  )

  ok(
    gradeSort(
      false,
      {assignment1: {score: 5, possible: 10}},
      {assignment1: {score: 10, possible: 20}},
      'assignment1'
    ) < 0,
    'other fields are sorted by score'
  )
})

QUnit.module('Gradebook#hideAggregateColumns', {
  gradebookStubs() {
    return {
      indexedOverrides: Gradebook.prototype.indexedOverrides,
      indexedGradingPeriods: _.indexBy(this.gradingPeriods, 'id')
    }
  },

  setupThis(options) {
    const customOptions = options || {}
    const defaults = {
      gradingPeriodSet: {id: '1'},
      getGradingPeriodToShow() {
        return '1'
      },
      options: {
        all_grading_periods_totals: false
      }
    }

    return _.defaults(customOptions, defaults, this.gradebookStubs())
  },

  setup() {
    this.hideAggregateColumns = Gradebook.prototype.hideAggregateColumns
  },
  teardown() {}
})

test('returns false if there are no grading periods', function() {
  const self = this.setupThis({
    gradingPeriodSet: null,
    isAllGradingPeriods() {
      return false
    }
  })
  notOk(this.hideAggregateColumns.call(self))
})

test('returns false if there are no grading periods, even if isAllGradingPeriods is true', function() {
  const self = this.setupThis({
    gradingPeriodSet: null,
    getGradingPeriodToShow() {
      return '0'
    },
    isAllGradingPeriods() {
      return true
    }
  })

  notOk(this.hideAggregateColumns.call(self))
})

test('returns false if "All Grading Periods" is not selected', function() {
  const self = this.setupThis({
    isAllGradingPeriods() {
      return false
    }
  })
  notOk(this.hideAggregateColumns.call(self))
})

test('returns true if "All Grading Periods" is selected', function() {
  const self = this.setupThis({
    getGradingPeriodToShow() {
      return '0'
    },
    isAllGradingPeriods() {
      return true
    }
  })

  ok(this.hideAggregateColumns.call(self))
})

test(
  'returns false if "All Grading Periods" is selected and "Display Totals ' +
    'for All Grading Periods option" is not checked on the grading period set',
  function() {
    const self = this.setupThis({
      getGradingPeriodToShow() {
        return '0'
      },
      isAllGradingPeriods() {
        return true
      },
      gradingPeriodSet: {
        displayTotalsForAllGradingPeriods: true
      }
    })

    notOk(this.hideAggregateColumns.call(self))
  }
)

QUnit.module('Gradebook#getVisibleGradeGridColumns', {
  setup() {
    this.getVisibleGradeGridColumns = Gradebook.prototype.getVisibleGradeGridColumns
    this.makeColumnSortFn = Gradebook.prototype.makeColumnSortFn
    this.compareAssignmentPositions = Gradebook.prototype.compareAssignmentPositions
    this.compareAssignmentDueDates = Gradebook.prototype.compareAssignmentDueDates
    this.wrapColumnSortFn = Gradebook.prototype.wrapColumnSortFn
    this.getStoredSortOrder = Gradebook.prototype.getStoredSortOrder
    this.defaultSortType = 'assignment_group'
    this.allAssignmentColumns = [
      {object: {assignment_group: {position: 1}, position: 1, name: 'first'}},
      {object: {assignment_group: {position: 1}, position: 2, name: 'second'}},
      {object: {assignment_group: {position: 1}, position: 3, name: 'third'}},
      {object: {assignment_group: {position: 1}, position: 4, name: 'moderated', moderation_in_progress: true}}
    ]
    this.aggregateColumns = []
    this.parentColumns = []
    this.customColumnDefinitions = () => []
    this.spy(this, 'makeColumnSortFn')
  },
  teardown() {}
})

test('It sorts columns when there is a valid sortType', function() {
  this.isInvalidCustomSort = () => false
  this.columnOrderHasNotBeenSaved = () => false
  this.gradebookColumnOrderSettings = {sortType: 'due_date'}
  this.getVisibleGradeGridColumns()
  ok(this.makeColumnSortFn.calledWith({sortType: 'due_date'}))
})

test('It falls back to the default sort type if the custom sort type does not have a customOrder property', function() {
  this.isInvalidCustomSort = () => true
  this.gradebookColumnOrderSettings = {sortType: 'custom'}
  this.makeCompareAssignmentCustomOrderFn = Gradebook.prototype.makeCompareAssignmentCustomOrderFn
  this.getVisibleGradeGridColumns()
  ok(this.makeColumnSortFn.calledWith({sortType: 'assignment_group'}))
})

test('It does not sort columns when gradebookColumnOrderSettings is undefined', function() {
  this.gradebookColumnOrderSettings = undefined
  this.getVisibleGradeGridColumns()
  notOk(this.makeColumnSortFn.called)
})

test('sets cannot_edit if moderation_in_progress is true on the column object', function() {
  const moderatedColumn = _.find(this.allAssignmentColumns, (column) => column.object.moderation_in_progress)
  this.getVisibleGradeGridColumns()
  strictEqual(moderatedColumn.cssClass, 'cannot_edit')
})

test('does not set cannot_edit if moderation_in_progress is not true on the column object', function() {
  const unmoderatedColumn = this.allAssignmentColumns[0]
  this.getVisibleGradeGridColumns()
  notStrictEqual(unmoderatedColumn.cssClass, 'cannot_edit')
})

QUnit.module('Gradebook#customColumnDefinitions', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.customColumns = [
      { id: '1', teacher_notes: false, hidden: false, title: 'Read Only', read_only: true },
      { id: '2', teacher_notes: false, hidden: false, title: 'Not Read Only', read_only: false }
    ]
  }
})

test('includes the cannot_edit class for read_only columns', function () {
  columns = this.gradebook.customColumnDefinitions()
  equal(columns[0].cssClass, "meta-cell custom_column cannot_edit")
  equal(columns[1].cssClass, "meta-cell custom_column")
})

QUnit.module('Gradebook#fieldsToExcludeFromAssignments', {
  setup() {
    return (this.excludedFields = Gradebook.prototype.fieldsToExcludeFromAssignments)
  }
})

test('includes "description" in the response', function() {
  ok(_.contains(this.excludedFields, 'description'))
})

test('includes "needs_grading_count" in the response', function() {
  ok(_.contains(this.excludedFields, 'needs_grading_count'))
})

QUnit.module('Gradebook#submissionsForStudent', {
  setupThis(options = {}) {
    const effectiveDueDates = {
      1: {1: {grading_period_id: '1'}},
      2: {1: {grading_period_id: '2'}}
    }

    const defaults = {
      gradingPeriodSet: null,
      gradingPeriodToShow: null,
      isAllGradingPeriods() {
        return false
      },
      effectiveDueDates
    }
    return _.defaults(options, defaults)
  },

  setup() {
    this.student = {
      id: '1',
      assignment_1: {assignment_id: '1', user_id: '1', name: 'yolo'},
      assignment_2: {assignment_id: '2', user_id: '1', name: 'froyo'}
    }
    return (this.submissionsForStudent = Gradebook.prototype.submissionsForStudent)
  }
})

test('returns all submissions for the student when there are no grading periods', function() {
  const self = this.setupThis()
  const submissions = this.submissionsForStudent.call(self, this.student)
  propEqual(_.pluck(submissions, 'assignment_id'), ['1', '2'])
})

test('returns all submissions if "All Grading Periods" is selected', function() {
  const self = this.setupThis({
    gradingPeriodSet: {id: '1'},
    gradingPeriodToShow: '0',
    isAllGradingPeriods() {
      return true
    }
  })
  const submissions = this.submissionsForStudent.call(self, this.student)
  propEqual(_.pluck(submissions, 'assignment_id'), ['1', '2'])
})

test('only returns submissions due for the student in the selected grading period', function() {
  const self = this.setupThis({
    gradingPeriodSet: {id: '1'},
    gradingPeriodToShow: '2'
  })
  const submissions = this.submissionsForStudent.call(self, this.student)
  propEqual(_.pluck(submissions, 'assignment_id'), ['2'])
})

QUnit.module('Gradebook#studentsUrl', {
  setupThis(options) {
    options = options || {}
    const defaults = {
      showConcludedEnrollments: false,
      showInactiveEnrollments: false
    }
    return _.defaults(options, defaults)
  },

  setup() {
    return (this.studentsUrl = Gradebook.prototype.studentsUrl)
  }
})

test('enrollmentUrl returns "students_url"', function() {
  equal(this.studentsUrl.call(this.setupThis()), 'students_url')
})

test('when concluded only, enrollmentUrl returns "students_with_concluded_enrollments_url"', function() {
  const self = this.setupThis({showConcludedEnrollments: true})
  equal(this.studentsUrl.call(self), 'students_with_concluded_enrollments_url')
})

test('when inactive only, enrollmentUrl returns "students_with_inactive_enrollments_url"', function() {
  const self = this.setupThis({showInactiveEnrollments: true})
  equal(this.studentsUrl.call(self), 'students_with_inactive_enrollments_url')
})

test('when show concluded and hide inactive are true, enrollmentUrl returns "students_with_concluded_and_inactive_enrollments_url"', function() {
  const self = this.setupThis({showConcludedEnrollments: true, showInactiveEnrollments: true})
  equal(this.studentsUrl.call(self), 'students_with_concluded_and_inactive_enrollments_url')
})

QUnit.module('Gradebook#weightedGroups', {
  setup() {
    this.weightedGroups = Gradebook.prototype.weightedGroups
  }
})

test('returns true when group_weighting_scheme is "percent"', function() {
  equal(this.weightedGroups.call({options: {group_weighting_scheme: 'percent'}}), true)
})

test('returns false when group_weighting_scheme is not "percent"', function() {
  equal(this.weightedGroups.call({options: {group_weighting_scheme: 'points'}}), false)
  equal(this.weightedGroups.call({options: {group_weighting_scheme: null}}), false)
})

QUnit.module('Gradebook#weightedGrades', {
  setupThis(group_weighting_scheme, gradingPeriodSet) {
    return {options: {group_weighting_scheme}, gradingPeriodSet}
  },
  setup() {
    this.weightedGrades = Gradebook.prototype.weightedGrades
  }
})

test('returns true when group_weighting_scheme is "percent"', function() {
  const self = this.setupThis('percent', {weighted: false})
  equal(this.weightedGrades.call(self), true)
})

test('returns true when the gradingPeriodSet is weighted', function() {
  const self = this.setupThis('points', {weighted: true})
  equal(this.weightedGrades.call(self), true)
})

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not weighted', function() {
  const self = this.setupThis('points', {weighted: false})
  equal(this.weightedGrades.call(self), false)
})

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not defined', function() {
  const self = this.setupThis('points', null)
  equal(this.weightedGrades.call(self), false)
})

QUnit.module('Gradebook#showNotesColumn', {
  setup() {
    this.loadNotes = this.stub(DataLoader, 'getDataForColumn')
  },

  setupShowNotesColumn(opts) {
    const defaultOptions = {
      options: {},
      toggleNotesColumn() {}
    }
    const self = _.defaults(opts || {}, defaultOptions)
    return (this.showNotesColumn = Gradebook.prototype.showNotesColumn.bind(self))
  }
})

test('loads the notes if they have not yet been loaded', function() {
  this.setupShowNotesColumn({teacherNotesNotYetLoaded: true})
  this.showNotesColumn()
  ok(this.loadNotes.calledOnce)
})

test('does not load the notes if they are already loaded', function() {
  this.setupShowNotesColumn({teacherNotesNotYetLoaded: false})
  this.showNotesColumn()
  ok(this.loadNotes.notCalled)
})

QUnit.module('Gradebook#cellCommentClickHandler', {
  setup() {
    this.cellCommentClickHandler = Gradebook.prototype.cellCommentClickHandler
    this.assignments = {
      '61890000000013319': {name: 'Assignment #1'}
    }
    this.student = this.stub().returns({
      name: 'Some Student'
    })
    this.options = {}

    this.fixture = document.createElement('div')
    this.fixture.className = 'editable'
    this.fixture.setAttribute('data-assignment-id', '61890000000013319')
    this.fixture.setAttribute('data-user-id', '61890000000013319')

    this.fixtureParent = document.getElementById('fixtures')
    this.fixtureParent.appendChild(this.fixture)

    this.submissionDialogArgs = undefined

    this.stub(SubmissionDetailsDialog, 'open').callsFake(
      function() {
        return (this.submissionDialogArgs = arguments)
      }.bind(this)
    )

    this.event = {
      preventDefault: this.stub(),
      currentTarget: this.fixture
    }
    this.$grid = {
      find: () => ({
        hasClass: () => false
      })
    }
    this.grid = {
      getActiveCellNode: this.stub().returns(this.fixture)
    }
  },

  teardown() {
    this.fixtureParent.innerHTML = ''
    this.fixture = undefined
  }
})

test('when not editable, returns false if the active cell node has the "cannot_edit" class', function() {
  this.fixture.className = 'cannot_edit'

  const result = this.cellCommentClickHandler(this.event)

  equal(result, false)
  ok(this.event.preventDefault.called)
})

test('when editable, removes the "editable" class from the active cell', function() {
  this.cellCommentClickHandler(this.event)

  equal('', this.fixture.className)
  ok(this.event.preventDefault.called)
})

test('when editable, calls @student with the user id as a string', function() {
  this.cellCommentClickHandler(this.event)

  ok(this.student.calledWith('61890000000013319'))
})

test('when editable, calls SubmissionDetailsDialog', function() {
  this.cellCommentClickHandler(this.event)

  const expectedArguments = {
    0: {name: 'Assignment #1'},
    1: {name: 'Some Student'},
    2: {anonymous: false}
  }

  equal(SubmissionDetailsDialog.open.callCount, 1)
  deepEqual(expectedArguments, this.submissionDialogArgs)
})

test('when editable, calls SubmissionDetailsDialog', function() {
  this.$grid = {
    find: () => ({
      hasClass: () => true
    })
  }
  this.cellCommentClickHandler(this.event)

  const expectedArguments = {
    0: {name: 'Assignment #1'},
    1: {name: 'Student'},
    2: {anonymous: true}
  }

  equal(SubmissionDetailsDialog.open.callCount, 1)
  deepEqual(expectedArguments, this.submissionDialogArgs)
})

QUnit.module('Gradebook#updateSubmission', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.students = {1101: {id: '1101'}}
    this.submission = {
      assignment_id: '201',
      grade: '123.45',
      gradingType: 'percent',
      submitted_at: '2015-05-04T12:00:00Z',
      user_id: '1101'
    }
  }
})

test('formats the grade for the submission', function() {
  this.spy(GradeFormatHelper, 'formatGrade')
  this.gradebook.updateSubmission(this.submission)
  equal(GradeFormatHelper.formatGrade.callCount, 1)
})

test('includes submission attributes when formatting the grade', function() {
  this.spy(GradeFormatHelper, 'formatGrade')
  this.gradebook.updateSubmission(this.submission)
  const [grade, options] = Array.from(GradeFormatHelper.formatGrade.getCall(0).args)
  equal(grade, '123.45', 'parameter 1 is the submission grade')
  equal(options.gradingType, 'percent', 'options.gradingType is the submission gradingType')
  strictEqual(options.delocalize, false, 'submission grades from the server are not localized')
})

test('sets the formatted grade on submission', function() {
  this.stub(GradeFormatHelper, 'formatGrade').returns('123.45%')
  this.gradebook.updateSubmission(this.submission)
  equal(this.submission.grade, '123.45%')
})

test('sets the raw grade on submission', function() {
  this.stub(GradeFormatHelper, 'formatGrade').returns('123.45%')
  this.gradebook.updateSubmission(this.submission)
  equal(this.submission.rawGrade, '123.45')
})

QUnit.module('Gradebook#gotSubmissionsChunk', function(hooks) {
  let $fixtures = null
  let studentSubmissions = null
  let gradebook = null

  hooks.beforeEach(function(hooks) {
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    $fixtures.innerHTML = `\
<div id="application"> \
<div id="wrapper"> \
<div id="StudentTray__Container"></div> \
<span data-component="GridColor"></span> \
<div id="gradebook_grid"></div> \
</div> \
</div>\
`

    gradebook = createGradebook()
    gradebook.customColumns = []
    sinon.stub(gradebook, 'getFrozenColumnCount').returns(1)
    sinon.stub(gradebook, 'updateSubmission')
    sinon.stub(gradebook, 'setupGrading')

    const students = [
      {
        id: '1101',
        name: 'Adam Jones',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}]
      },
      {
        id: '1102',
        name: 'Betty Ford',
        enrollments: [{type: 'StudentEnrollment', grades: {html_url: 'http://example.url/'}}]
      }
    ]
    gradebook.gotChunkOfStudents(students)

    studentSubmissions = [
      {
        submissions: [
          {
            assignment_id: '201',
            assignment_visible: true,
            cached_due_date: '2015-02-01T12:00:00Z',
            score: 10,
            user_id: '1101'
          },
          {
            assignment_id: '202',
            assignment_visible: true,
            cached_due_date: '2015-02-02T12:00:00Z',
            score: 9,
            user_id: '1101'
          }
        ],
        user_id: '1101'
      },
      {
        submissions: [
          {
            assignment_id: '201',
            assignment_visible: true,
            cached_due_date: '2015-02-03T12:00:00Z',
            score: 8,
            user_id: '1102'
          }
        ],
        user_id: '1102'
      }
    ]
  })

  hooks.afterEach(() => $fixtures.remove())

  test('updates effectiveDueDates with the submissions', function() {
    gradebook.gotSubmissionsChunk(studentSubmissions)
    return gradebook.gridReady.resolve().then(() => {
      deepEqual(Object.keys(gradebook.effectiveDueDates), ['201', '202'])
      deepEqual(Object.keys(gradebook.effectiveDueDates[201]), ['1101', '1102'])
      deepEqual(Object.keys(gradebook.effectiveDueDates[202]), ['1101'])
    })
  })

  test('waits for gridReady to resolve', function() {
    deepEqual(Object.keys(gradebook.effectiveDueDates), [])
    gradebook.gotSubmissionsChunk(studentSubmissions)
    return gradebook.gridReady.resolve().then(() => {
      deepEqual(Object.keys(gradebook.effectiveDueDates), ['201', '202'])
    })
  })

  test('updates effectiveDueDates on related assignments', function() {
    gradebook.assignments = {
      201: {id: '201', name: 'Math Assignment', published: true},
      202: {id: '202', name: 'English Assignment', published: false}
    }
    gradebook.gotSubmissionsChunk(studentSubmissions)
    return gradebook.gridReady.resolve().then(() => {
      deepEqual(Object.keys(gradebook.assignments[201].effectiveDueDates), ['1101', '1102'])
      deepEqual(Object.keys(gradebook.assignments[202].effectiveDueDates), ['1101'])
    })
  })

  test('updates inClosedGradingPeriod on related assignments', function() {
    gradebook.assignments = {
      201: {id: '201', name: 'Math Assignment', published: true},
      202: {id: '202', name: 'English Assignment', published: false}
    }
    gradebook.gotSubmissionsChunk(studentSubmissions)
    return gradebook.gridReady.resolve().then(() => {
      deepEqual(Object.keys(gradebook.assignments[201].effectiveDueDates), ['1101', '1102'])
      deepEqual(Object.keys(gradebook.assignments[202].effectiveDueDates), ['1101'])
    })
  })

  test('sets up grading for the related students', function() {
    gradebook.gotSubmissionsChunk(studentSubmissions)
    return gradebook.gridReady.resolve().then(() => {
      const [students] = Array.from(gradebook.setupGrading.lastCall.args)
      deepEqual(students.map(student => student.id), ['1101', '1102'])
    })
  })
})

QUnit.module('Gradebook#gotAllAssignmentGroups', suiteHooks => {
  let studentSubmissions = null
  let gradebook = null

  let unmoderatedAssignment
  let moderatedUnpublishedAssignment
  let moderatedPublishedAssignment
  let anonymousUnmoderatedAssignment
  let anonymousModeratedAssignment
  let assignmentGroups

  suiteHooks.beforeEach(() => {
    unmoderatedAssignment = {
      id: 1,
      name: 'test',
      published: true,
      anonymous_grading: false,
      moderated_grading: false
    }
    moderatedUnpublishedAssignment = {
      id: 2,
      name: 'test',
      published: true,
      anonymous_grading: false,
      moderated_grading: true,
      grades_published: false
    }
    moderatedPublishedAssignment = {
      id: 3,
      name: 'test',
      published: true,
      anonymous_grading: false,
      moderated_grading: true,
      grades_published: true
    }
    anonymousUnmoderatedAssignment = {
      id: 4,
      name: 'test',
      published: true,
      anonymous_grading: true,
      moderated_grading: false,
      grades_published: true
    }
    anonymousModeratedAssignment = {
      id: 5,
      name: 'test',
      published: true,
      anonymous_grading: true,
      moderated_grading: true,
      grades_published: true
    }

    assignmentGroups = [{
      id: 1,
      assignments: [
        unmoderatedAssignment,
        moderatedUnpublishedAssignment,
        moderatedPublishedAssignment,
        anonymousUnmoderatedAssignment,
        anonymousModeratedAssignment
      ]
    }]

    gradebook = createGradebook()
    sinon.stub(gradebook, 'updateAssignmentEffectiveDueDates')
  })

  suiteHooks.afterEach(() => {
    gradebook.updateAssignmentEffectiveDueDates.restore()

    // gotAllAssignmentGroups creates an AssignmentGroupWeightsDialog
    // on the page; remove it as part of cleaning up
    $('#assignment_group_weights_dialog').remove()
  })

  QUnit.module('when Anonymous Moderated Marking is enabled', hooks => {
    hooks.beforeEach(() => {
      gradebook.options.anonymous_moderated_marking_enabled = true
    })

    test('sets moderation_in_progress to true for a moderated assignment whose grades are not published', () => {
      gradebook.gotAllAssignmentGroups(assignmentGroups)
      strictEqual(moderatedUnpublishedAssignment.moderation_in_progress, true) })

    test('sets moderation_in_progress to false for a moderated assignment whose grades are published', () => {
      gradebook.gotAllAssignmentGroups(assignmentGroups)
      strictEqual(moderatedPublishedAssignment.moderation_in_progress, false)
    })

    test('sets moderation_in_progress to false for an unmoderated assignment', () => {
      gradebook.gotAllAssignmentGroups(assignmentGroups)
      strictEqual(unmoderatedAssignment.moderation_in_progress, false)
    })

    test('sets hide_grades_when_muted to true for an anonymous assignment', () => {
      gradebook.gotAllAssignmentGroups(assignmentGroups)
      strictEqual(anonymousUnmoderatedAssignment.hide_grades_when_muted, true)
    })

    test('sets hide_grades_when_muted to false for a non-anonymous assignment', () => {
      gradebook.gotAllAssignmentGroups(assignmentGroups)
      strictEqual(unmoderatedAssignment.hide_grades_when_muted, false)
    })
  })

  test('does not set moderation_in_progress when anonymous moderated marking is off', () => {
    gradebook.gotAllAssignmentGroups(assignmentGroups)
    strictEqual(moderatedUnpublishedAssignment.moderation_in_progress, undefined)
  })

  test('does not set hide_grades_when_muted when anonymous moderated marking is off', () => {
    gradebook.gotAllAssignmentGroups(assignmentGroups)
    strictEqual(moderatedUnpublishedAssignment.hide_grades_when_muted, undefined)
  })
})
