/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {createCourseGradesWithGradingPeriods as createGrades} from '@canvas/grading/GradeCalculatorSpecHelper'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

const $fixtures = document.getElementById('fixtures')

QUnit.module('setupGrading', {
  setup() {
    this.gradebook = createGradebook()
    this.students = [{id: '1101'}, {id: '1102'}]
    sandbox.stub(this.gradebook, 'setAssignmentVisibility')
    sandbox.stub(this.gradebook, 'invalidateRowsForStudentIds')
  },
})

test('sets assignment visibility for the given students', function () {
  this.gradebook.setupGrading(this.students)
  strictEqual(
    this.gradebook.setAssignmentVisibility.callCount,
    1,
    'setAssignmentVisibility was called once'
  )
  const [studentIds] = this.gradebook.setAssignmentVisibility.lastCall.args
  deepEqual(studentIds, ['1101', '1102'], 'both students were updated')
})

test('returns student IDs for the given students', function () {
  const studentIds = this.gradebook.setupGrading(this.students)
  deepEqual(studentIds, ['1101', '1102'])
})

QUnit.module('resetGrading')

test('initializes a new submission state map', () => {
  const gradebook = createGradebook()
  const originalMap = gradebook.submissionStateMap
  gradebook.resetGrading()
  strictEqual(gradebook.submissionStateMap.constructor, SubmissionStateMap)
  notEqual(originalMap, gradebook.submissionStateMap)
})

test('calls setupGrading', () => {
  const gradebook = createGradebook()
  sinon.spy(gradebook, 'setupGrading')
  gradebook.resetGrading()
  strictEqual(gradebook.setupGrading.callCount, 1)
})

test('sends all students when calling setupGrading', () => {
  const allStudents = [{id: '1101', assignment_201: {}, assignment_202: {}}]
  const gradebook = createGradebook()
  sandbox.stub(gradebook.courseContent.students, 'listStudents').returns(allStudents)
  sinon.spy(gradebook, 'setupGrading')
  gradebook.resetGrading()
  const [students] = gradebook.setupGrading.lastCall.args
  strictEqual(students, allStudents)
})

QUnit.module('Gradebook Grading Schemes', suiteHooks => {
  const defaultGradingScheme = [
    ['A', 0.9],
    ['B', 0.8],
    ['C', 0.7],
    ['D', 0.6],
    ['E', 0.5],
  ]
  const gradingScheme = {
    id: '2801',
    data: [
      ['😂', 0.9],
      ['🙂', 0.8],
      ['😐', 0.7],
      ['😢', 0.6],
      ['💩', 0],
    ],
    title: 'Emoji Grades',
  }

  let gradebook

  function createInitializedGradebook(options) {
    gradebook = createGradebook({
      default_grading_standard: defaultGradingScheme,
      grading_schemes: [gradingScheme],
      grading_standard: gradingScheme.data,
      ...options,
    })
    gradebook.setAssignments({
      2301: {
        grading_standard_id: '2801',
        grading_type: 'points',
        id: '2301',
        name: 'Math Assignment',
        published: true,
      },
      2302: {
        grading_standard_id: null,
        grading_type: 'points',
        id: '2302',
        name: 'English Assignment',
        published: false,
      },
    })
  }

  suiteHooks.beforeEach(() => {
    setFixtureHtml($fixtures)
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $fixtures.innerHTML = ''
  })

  QUnit.module('#getCourseGradingScheme', () => {
    test('returns the course grading scheme when present', () => {
      createInitializedGradebook()
      deepEqual(gradebook.getCourseGradingScheme().data, gradingScheme.data)
    })

    test('returns null when course is not using a grading scheme', () => {
      createInitializedGradebook({grading_standard: undefined})
      strictEqual(gradebook.getCourseGradingScheme(), null)
    })
  })

  QUnit.module('#getDefaultGradingScheme', () => {
    test('returns the default grading scheme when present', () => {
      createInitializedGradebook()
      deepEqual(gradebook.getDefaultGradingScheme().data, defaultGradingScheme)
    })

    test('returns null when the default grading scheme is not present', () => {
      createInitializedGradebook({default_grading_standard: undefined})
      strictEqual(gradebook.getDefaultGradingScheme(), null)
    })
  })

  QUnit.module('#getGradingScheme', () => {
    test('returns the grading scheme matching the given id', () => {
      createInitializedGradebook()
      deepEqual(gradebook.getGradingScheme('2801'), gradingScheme)
    })

    test('returns undefined when no grading scheme exists with the given id', () => {
      createInitializedGradebook()
      strictEqual(gradebook.getGradingScheme('2802'), undefined)
    })
  })

  QUnit.module('#getAssignmentGradingScheme', () => {
    test('returns the grading scheme associated with the assignment', () => {
      createInitializedGradebook()
      deepEqual(gradebook.getAssignmentGradingScheme('2301'), gradingScheme)
    })

    test('returns the default grading scheme when the assignment does not use a specific scheme', () => {
      createInitializedGradebook()
      deepEqual(gradebook.getAssignmentGradingScheme('2302').data, defaultGradingScheme)
    })
  })
})

QUnit.module('Gradebook#weightedGrades', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('returns true when group_weighting_scheme is "percent"', function () {
  this.gradebook.options.group_weighting_scheme = 'percent'
  this.gradebook.gradingPeriodSet = {weighted: false}
  equal(this.gradebook.weightedGrades(), true)
})

test('returns true when the gradingPeriodSet is weighted', function () {
  this.gradebook.options.group_weighting_scheme = 'points'
  this.gradebook.gradingPeriodSet = {weighted: true}
  equal(this.gradebook.weightedGrades(), true)
})

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not weighted', function () {
  this.gradebook.options.group_weighting_scheme = 'points'
  this.gradebook.gradingPeriodSet = {weighted: false}
  equal(this.gradebook.weightedGrades(), false)
})

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not defined', function () {
  this.gradebook.options.group_weighting_scheme = 'points'
  this.gradebook.gradingPeriodSet = {weighted: null}
  equal(this.gradebook.weightedGrades(), false)
})

QUnit.module('Gradebook#weightedGroups', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('returns true when group_weighting_scheme is "percent"', function () {
  this.gradebook.options.group_weighting_scheme = 'percent'
  equal(this.gradebook.weightedGroups(), true)
})

test('returns false when group_weighting_scheme is not "percent"', function () {
  this.gradebook.options.group_weighting_scheme = 'points'
  equal(this.gradebook.weightedGroups(), false)
  this.gradebook.options.group_weighting_scheme = null
  equal(this.gradebook.weightedGroups(), false)
})

QUnit.module('Gradebook#calculateStudentGrade', {
  createGradebook(options = {}) {
    const gradebook = createGradebook({
      group_weighting_scheme: 'points',
    })
    const assignments = [{id: '201', points_possible: 10, omit_from_final_grade: false}]
    Object.assign(gradebook, {
      assignmentGroups: [{id: '301', group_weight: 60, rules: {}, assignments}],
      gradingPeriods: [
        {id: '701', weight: 50},
        {id: '702', weight: 50},
      ],
      gradingPeriodSet: {
        id: '1501',
        gradingPeriods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      },
      effectiveDueDates: {
        201: {
          101: {grading_period_id: '701'},
        },
      },
      submissionsForStudent: () => this.submissions,
      ...options,
    })
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    return gradebook
  },

  setup() {
    this.exampleGrades = createGrades()
    this.submissions = [{assignment_id: 201, score: 10}]
  },
})

test('calculates grades using properties from the gradebook', function () {
  const gradebook = this.createGradebook()
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades())
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true,
  })
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], this.submissions)
  equal(args[1], gradebook.assignmentGroups)
  equal(args[2], gradebook.options.group_weighting_scheme)
  equal(args[4], gradebook.gradingPeriodSet)
})

test('scopes effective due dates to the user', function () {
  const gradebook = this.createGradebook()
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades())
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true,
  })
  const dueDates = CourseGradeCalculator.calculate.getCall(0).args[5]
  deepEqual(dueDates, {
    201: {
      grading_period_id: '701',
    },
  })
})

test('calculates grades without grading period data when grading period set is null', function () {
  const gradebook = this.createGradebook({
    gradingPeriodSet: null,
  })
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades())
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true,
  })
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], this.submissions)
  equal(args[1], gradebook.assignmentGroups)
  equal(args[2], gradebook.options.group_weighting_scheme)
  equal(typeof args[3], 'undefined')
  equal(typeof args[4], 'undefined')
})

test('calculates grades without grading period data when effective due dates are not defined', function () {
  const gradebook = this.createGradebook({
    effectiveDueDates: null,
  })
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades())
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true,
  })
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], this.submissions)
  equal(args[1], gradebook.assignmentGroups)
  equal(args[2], gradebook.options.group_weighting_scheme)
  equal(typeof args[4], 'undefined')
  equal(typeof args[5], 'undefined')
})

test('stores the current grade on the student if not viewing ungraded as zero', function () {
  const gradebook = this.createGradebook()
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades)
  const student = {
    id: '101',
    loaded: true,
    initialized: true,
  }
  gradebook.calculateStudentGrade(student)
  equal(student.total_grade, this.exampleGrades.current)
})

test('stores the final grade on the student if viewing ungraded as zero', function () {
  const gradebook = this.createGradebook()
  gradebook.courseFeatures.allowViewUngradedAsZero = true
  gradebook.gridDisplaySettings.viewUngradedAsZero = true
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades)
  const student = {
    id: '101',
    loaded: true,
    initialized: true,
  }
  gradebook.calculateStudentGrade(student)
  equal(student.total_grade, this.exampleGrades.final)
})

test('stores the current grade from the selected grading period if not viewing ungraded as zero', function () {
  const gradebook = this.createGradebook()
  gradebook.gradingPeriodId = '701'
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades)
  const student = {
    id: '101',
    loaded: true,
    initialized: true,
  }
  gradebook.calculateStudentGrade(student)
  equal(student.total_grade, this.exampleGrades.gradingPeriods[701].current)
})

test('stores the final grade from the selected grading period if viewing ungraded as zero', function () {
  const gradebook = this.createGradebook()
  gradebook.gradingPeriodId = '701'
  gradebook.courseFeatures.allowViewUngradedAsZero = true
  gradebook.gridDisplaySettings.viewUngradedAsZero = true
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades)
  const student = {
    id: '101',
    loaded: true,
    initialized: true,
  }
  gradebook.calculateStudentGrade(student)
  equal(student.total_grade, this.exampleGrades.gradingPeriods[701].final)
})

test('does not repeat the calculation if cached and preferCachedGrades is true', function () {
  const gradebook = this.createGradebook()
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades)
  const student = {
    id: '101',
    loaded: true,
    initialized: true,
  }

  gradebook.calculateStudentGrade(student)
  gradebook.calculateStudentGrade(student, true)

  strictEqual(CourseGradeCalculator.calculate.callCount, 1)
})

test('does perform the calculation if preferCachedGrades is true and no cached value exists', function () {
  const gradebook = this.createGradebook()
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades)
  const student = {
    id: '101',
    loaded: true,
    initialized: true,
  }

  gradebook.calculateStudentGrade(student, true)
  strictEqual(CourseGradeCalculator.calculate.callCount, 1)
})

test('does not calculate when the student is not loaded', function () {
  const gradebook = this.createGradebook()
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades())
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: false,
    initialized: true,
  })
  notOk(CourseGradeCalculator.calculate.called)
})

test('does not calculate when the student is not initialized', function () {
  const gradebook = this.createGradebook()
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades())
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: false,
  })
  notOk(CourseGradeCalculator.calculate.called)
})

QUnit.module('Gradebook#allowApplyScoreToUngraded', () => {
  test('returns true if the allow_apply_score_to_ungraded option is true', () => {
    const gradebook = createGradebook({allow_apply_score_to_ungraded: true})
    ok(gradebook.allowApplyScoreToUngraded())
  })

  test('returns false if the allow_apply_score_to_ungraded option is false', () => {
    const gradebook = createGradebook({allow_apply_score_to_ungraded: false})
    notOk(gradebook.allowApplyScoreToUngraded())
  })
})

QUnit.module('Gradebook#onApplyScoreToUngradedRequested', hooks => {
  let gradebook
  let mountPoint

  hooks.beforeEach(() => {
    mountPoint = document.body.appendChild(document.createElement('div'))
    sandbox.stub(ReactDOM, 'render')
    sandbox.stub(React, 'createElement')
  })

  hooks.afterEach(() => {
    ReactDOM.render.restore()
    React.createElement.restore()
    mountPoint.remove()
  })

  test('does not render the modal if the allow_apply_score_to_ungraded option is false', () => {
    gradebook = createGradebook({
      applyScoreToUngradedModalNode: mountPoint,
    })
    gradebook.onApplyScoreToUngradedRequested()
    ok(ReactDOM.render.notCalled)
  })

  test('renders the modal when the mount point is present and allow_apply_score_to_ungraded is true', () => {
    gradebook = createGradebook({
      allow_apply_score_to_ungraded: true,
      applyScoreToUngradedModalNode: mountPoint,
    })
    gradebook.onApplyScoreToUngradedRequested()

    strictEqual(ReactDOM.render.callCount, 1)
    strictEqual(ReactDOM.render.firstCall.args[1], mountPoint)
  })

  test('passes the supplied assignmentGroup to the render if present', () => {
    gradebook = createGradebook({
      allow_apply_score_to_ungraded: true,
      applyScoreToUngradedModalNode: mountPoint,
    })

    gradebook.onApplyScoreToUngradedRequested({id: '100', name: 'group'})

    strictEqual(React.createElement.callCount, 1)
    deepEqual(React.createElement.firstCall.args[1].assignmentGroup, {id: '100', name: 'group'})
  })
})

QUnit.module('Gradebook#executeApplyScoreToUngraded', hooks => {
  let gradebook
  let startProcessStub

  hooks.beforeEach(() => {
    gradebook = createGradebook({
      allow_apply_score_to_ungraded: true,
      context_id: '1234',
    })

    gradebook.gridData.rows = [
      {id: '3', sortable_name: 'Z'},
      {id: '4', sortable_name: 'A'},
      {id: '1', sortable_name: 'C'},
    ]

    gradebook.gridData.columns.scrollable = [
      'assignment_3',
      'custom_col_8',
      'assignment_2',
      'assignment_group_1',
      'assignment_7',
      'total_grade',
    ]

    const assignments = [
      {id: '3', assignment_group_id: '10'},
      {id: '2', assignment_group_id: '10'},
      {id: '7'},
    ]
    gradebook.gotAllAssignmentGroups([{id: '10', position: 1, name: 'Assignments', assignments}])

    startProcessStub = sandbox.stub(gradebook.scoreToUngradedManager, 'startProcess')
    startProcessStub.resolves({})

    sandbox.stub(FlashAlert, 'showFlashSuccess')
    sandbox.stub(FlashAlert, 'showFlashError')
  })

  hooks.afterEach(() => {
    startProcessStub.restore()

    FlashAlert.showFlashSuccess.restore()
    FlashAlert.showFlashError.restore()
  })

  test('updates total and assignment group columns', async () => {
    gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders = sinon.stub()
    await gradebook.executeApplyScoreToUngraded({value: 50.0})
    ok(
      gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.calledWith([
        'assignment_group_10',
        'total_grade',
      ])
    )
  })

  test('only updates total column when assignment groups are hidden', async () => {
    gradebook.gridDisplaySettings.hideAssignmentGroupTotals = true
    gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders = sinon.stub()
    await gradebook.executeApplyScoreToUngraded({value: 50.0})
    ok(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.calledWith(['total_grade']))
  })

  test('only updates assignment group columns when the total column is hidden', async () => {
    gradebook.gridDisplaySettings.hideTotal = true
    gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders = sinon.stub()
    await gradebook.executeApplyScoreToUngraded({value: 50.0})
    ok(
      gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.calledWith([
        'assignment_group_10',
      ])
    )
  })

  test('calls the startProcess method with the course ID as the first argument', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 50.0})

    strictEqual(startProcessStub.firstCall.args[0], '1234')
  })

  test('calls the startProcess method with the "percent" parameter when given a percentage value', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 50.0})

    strictEqual(startProcessStub.firstCall.args[1].percent, 50.0)
  })

  test('calls the startProcess method with the "excused" parameter when given a value of "excused"', async () => {
    await gradebook.executeApplyScoreToUngraded({value: 'excused'})
    strictEqual(startProcessStub.firstCall.args[1].excused, true)
  })

  test('passes any additional arguments to the endpoint', async () => {
    await gradebook.executeApplyScoreToUngraded({
      assignmentGroupId: '10',
      onlyPastDue: true,
      markAsMissing: true,
      value: 40.0,
    })

    const passedArgs = startProcessStub.firstCall.args[1]
    strictEqual(passedArgs.assignmentGroupId, '10', 'assignmentGroupId not passed')
    strictEqual(passedArgs.onlyPastDue, true, 'onlyPastDue not passed')
    strictEqual(passedArgs.markAsMissing, true, 'markAsMissing not passed')
    deepEqual(passedArgs.assignment_ids, ['3', '2'], 'assignment ids not passed')
    deepEqual(passedArgs.student_ids, ['3', '4', '1'], 'student ids not passed')
  })

  test('passes all assignments when assignmentGroupId is not specified', async () => {
    await gradebook.executeApplyScoreToUngraded({
      onlyPastDue: true,
      markAsMissing: true,
      value: 40.0,
    })

    const passedArgs = startProcessStub.firstCall.args[1]
    strictEqual(passedArgs.assignmentGroupId, undefined, 'assignmentGroupId not passed')
    strictEqual(passedArgs.onlyPastDue, true, 'onlyPastDue not passed')
    strictEqual(passedArgs.markAsMissing, true, 'markAsMissing not passed')
    deepEqual(passedArgs.assignment_ids, ['3', '2', '7'], 'assignment ids not passed')
    deepEqual(passedArgs.student_ids, ['3', '4', '1'], 'student ids not passed')
  })

  test('shows an initial flash alert when the process starts', async () => {
    const message =
      'Request successfully sent. Note that applying scores may take a while and changes will not appear until you reload the page.'
    await gradebook.executeApplyScoreToUngraded({value: 10.0})
    strictEqual(FlashAlert.showFlashSuccess.firstCall.args[0], message)
  })

  test('shows a success flash alert when the process succeeds', async () => {
    const message = 'Score to ungraded process finished successfully'
    await gradebook.executeApplyScoreToUngraded({value: 10.0})
    strictEqual(FlashAlert.showFlashSuccess.secondCall.args[0], message)
  })

  test('shows an error flash alert when the process fails', async () => {
    startProcessStub.rejects(new Error(':-/'))

    await gradebook.executeApplyScoreToUngraded({value: 10.0})
    strictEqual(FlashAlert.showFlashError.callCount, 1)
  })
})
