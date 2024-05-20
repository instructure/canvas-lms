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

import $ from 'jquery'
import 'jquery-migrate'
import React from 'react'
import ReactDOM from 'react-dom'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import SubmissionStateMap from '@canvas/grading/SubmissionStateMap'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {createCourseGradesWithGradingPeriods as createGrades} from './GradeCalculatorSpecHelper'
import MessageStudentsWhoHelper from '@canvas/grading/messageStudentsWhoHelper'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import fakeENV from 'helpers/fakeENV'

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

QUnit.module('Gradebook Grading', () => {
  let gradebook

  QUnit.module('#isGradeEditable()', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.students = {1101: {id: '1101', isConcluded: false}}
      sinon
        .stub(gradebook.submissionStateMap, 'getSubmissionState')
        .returns({hideGrade: false, locked: false})
    })

    hooks.afterEach(() => {
      gradebook.submissionStateMap.getSubmissionState.restore()
    })

    test('returns true when the submission state is not locked', () => {
      strictEqual(gradebook.isGradeEditable('1101', '2301'), true)
    })

    test('returns false when the submission state is locked', () => {
      gradebook.submissionStateMap.getSubmissionState.returns({hideGrade: false, locked: true})
      strictEqual(gradebook.isGradeEditable('1101', '2301'), false)
    })

    test('returns false when the submission state is not defined', () => {
      gradebook.submissionStateMap.getSubmissionState.returns(undefined)
      strictEqual(gradebook.isGradeEditable('1101', '2301'), false)
    })

    test('uses the given assignment id when retrieving submission state', () => {
      gradebook.isGradeEditable('1101', '2301')
      const submission = gradebook.submissionStateMap.getSubmissionState.lastCall.args[0]
      strictEqual(submission.assignment_id, '2301')
    })

    test('uses the given student id when retrieving submission state', () => {
      gradebook.isGradeEditable('1101', '2301')
      const submission = gradebook.submissionStateMap.getSubmissionState.lastCall.args[0]
      strictEqual(submission.user_id, '1101')
    })

    test('returns false when the student enrollment is concluded', () => {
      gradebook.students[1101].isConcluded = true
      strictEqual(gradebook.isGradeEditable('1101', '2301'), false)
    })

    test('returns false when the student is not loaded', () => {
      delete gradebook.students[1101]
      strictEqual(gradebook.isGradeEditable('1101', '2301'), false)
    })
  })

  QUnit.module('#isGradeVisible()', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      sinon
        .stub(gradebook.submissionStateMap, 'getSubmissionState')
        .returns({hideGrade: false, locked: true})
    })

    hooks.afterEach(() => {
      gradebook.submissionStateMap.getSubmissionState.restore()
    })

    test('returns true when the submission state is not hiding the grade', () => {
      strictEqual(gradebook.isGradeVisible('1101', '2301'), true)
    })

    test('returns false when the submission state is hiding the grade', () => {
      gradebook.submissionStateMap.getSubmissionState.returns({hideGrade: true, locked: true})
      strictEqual(gradebook.isGradeVisible('1101', '2301'), false)
    })

    test('returns false when the submission state is not defined', () => {
      gradebook.submissionStateMap.getSubmissionState.returns(undefined)
      strictEqual(gradebook.isGradeVisible('1101', '2301'), false)
    })

    test('uses the given assignment id when retrieving submission state', () => {
      gradebook.isGradeVisible('1101', '2301')
      const submission = gradebook.submissionStateMap.getSubmissionState.lastCall.args[0]
      strictEqual(submission.assignment_id, '2301')
    })

    test('uses the given student id when retrieving submission state', () => {
      gradebook.isGradeVisible('1101', '2301')
      const submission = gradebook.submissionStateMap.getSubmissionState.lastCall.args[0]
      strictEqual(submission.user_id, '1101')
    })
  })

  QUnit.module('#addPendingGradeInfo()', hooks => {
    let pendingGradeInfo
    let submission

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      pendingGradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      submission = {assignmentId: '2301', userId: '1101'}
    })

    test('stores the pending grade info', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      deepEqual(gradebook.getPendingGradeInfo(submission), {
        ...pendingGradeInfo,
        assignmentId: '2301',
        userId: '1101',
      })
    })

    test('replaces existing pending grade info', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      gradebook.addPendingGradeInfo(submission, {...pendingGradeInfo, score: 9.9})
      strictEqual(gradebook.getPendingGradeInfo(submission).score, 9.9)
    })

    test('does not affect other submissions for the same assignment', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.getPendingGradeInfo({assignmentId: '2301', userId: '1102'}), null)
    })

    test('does not affect other submissions for the same user', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.getPendingGradeInfo({assignmentId: '2302', userId: '1101'}), null)
    })
  })

  QUnit.module('#getPendingGradeInfo()', hooks => {
    let pendingGradeInfo
    let submission

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      pendingGradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      submission = {assignmentId: '2301', userId: '1101'}
    })

    test('returns null when the submission has no pending grade info', () => {
      strictEqual(gradebook.getPendingGradeInfo(submission), null)
    })

    test('does not match other submissions for the same assignment', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.getPendingGradeInfo({assignmentId: '2301', userId: '1102'}), null)
    })

    test('does not match other submissions for the same user', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.getPendingGradeInfo({assignmentId: '2302', userId: '1101'}), null)
    })
  })

  QUnit.module('#removePendingGradeInfo()', hooks => {
    let pendingGradeInfo
    let submission

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      pendingGradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      submission = {assignmentId: '2301', userId: '1101'}
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
    })

    test('removes pending grade info for the submission', () => {
      gradebook.removePendingGradeInfo(submission)
      strictEqual(gradebook.getPendingGradeInfo(submission), null)
    })

    test('does not affect other submissions for the same assignment', () => {
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1102'}, pendingGradeInfo)
      gradebook.removePendingGradeInfo(submission)
      deepEqual(gradebook.getPendingGradeInfo({assignmentId: '2301', userId: '1102'}), {
        ...pendingGradeInfo,
        assignmentId: '2301',
        userId: '1102',
      })
    })

    test('does not affect other submissions for the same user', () => {
      gradebook.addPendingGradeInfo({assignmentId: '2302', userId: '1101'}, pendingGradeInfo)
      gradebook.removePendingGradeInfo(submission)
      deepEqual(gradebook.getPendingGradeInfo({assignmentId: '2302', userId: '1101'}), {
        ...pendingGradeInfo,
        assignmentId: '2302',
        userId: '1101',
      })
    })
  })

  QUnit.module('#submissionIsUpdating()', hooks => {
    let pendingGradeInfo
    let submission

    hooks.beforeEach(() => {
      gradebook = createGradebook()
      pendingGradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      submission = {assignmentId: '2301', userId: '1101'}
    })

    test('returns true when the submission has valid pending grade info', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.submissionIsUpdating(submission), true)
    })

    test('returns false when the submission has invalid pending grade info', () => {
      Object.assign(pendingGradeInfo, {grade: 'invalid', valid: false})
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.submissionIsUpdating(submission), false)
    })

    test('returns false when the submission has no pending grade info', () => {
      strictEqual(gradebook.submissionIsUpdating(submission), false)
    })

    test('does not match other submissions for the same assignment', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.submissionIsUpdating({assignmentId: '2301', userId: '1102'}), false)
    })

    test('does not match other submissions for the same user', () => {
      gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
      strictEqual(gradebook.submissionIsUpdating({assignmentId: '2302', userId: '1101'}), false)
    })
  })

  QUnit.module('#gradeSubmission()', hooks => {
    let apiPromise
    let submission
    let gradeInfo
    let response
    let renderSubmissionTrayStub

    hooks.beforeEach(() => {
      fakeENV.setup({
        GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
      })
      const defaultGradingScheme = [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['E', 0.5],
      ]
      gradebook = createGradebook({default_grading_standard: defaultGradingScheme})
      gradebook.setAssignments({
        2301: {
          grading_type: 'letter_grade',
          id: '2301',
          name: 'Math Assignment',
          points_possible: 10,
          published: true,
        },
        2302: {
          grading_type: 'letter_grade',
          id: '2302',
          name: 'English Assignment',
          points_possible: 5,
          published: false,
        },
      })
      submission = {
        assignmentId: '2301',
        enteredScore: 9,
        enteredGrade: 'B',
        excused: false,
        id: '2501',
        userId: '1101',
      }
      gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      response = {
        data: {score: 10},
      }
      sinon.stub(gradebook, 'apiUpdateSubmission').callsFake(() => {
        apiPromise = Promise.resolve(response)
        return apiPromise
      })
      sinon.stub($, 'flashWarning')
      renderSubmissionTrayStub = sinon.stub(gradebook, 'renderSubmissionTray')
    })

    hooks.afterEach(() => {
      $.flashWarning.restore()
      renderSubmissionTrayStub.restore()
      fakeENV.teardown()
    })

    test('updates the submission via Gradebook.apiUpdateSubmission', () => {
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        strictEqual(gradebook.apiUpdateSubmission.callCount, 1)
      })
    })

    test('sets "submission.excuse" to true when the submission is excused', () => {
      gradeInfo = {enteredAs: 'excused', excused: true, grade: null, score: null, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.excuse, true)
      })
    })

    test('sets "submission.late_policy_status" to "missing" when the submission is missing', () => {
      gradeInfo = {
        enteredAs: 'missing',
        late_policy_status: 'missing',
        excused: false,
        grade: null,
        score: null,
        valid: true,
      }
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.late_policy_status, 'missing')
      })
    })

    test('does not set "submission.excuse" when the submission is not excused', () => {
      gradeInfo.excused = false
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        notOk('excuse' in submissionData, 'does not set "excuse"')
      })
    })

    test('sets "submission.posted_grade" to the entered grade when the submission is not excused', () => {
      gradeInfo.excused = false
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        equal(submissionData.posted_grade, 10)
      })
    })

    test('does not set "submission.posted_grade" when the submission is excused', () => {
      gradeInfo = {enteredAs: 'excused', excused: true, grade: null, score: null, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        notOk('posted_grade' in submissionData, 'does not set "excuse"')
      })
    })

    test('uses the score from the grading data when the grade was entered as points', () => {
      gradeInfo = {enteredAs: 'points', excused: false, grade: '78%', score: 7.8, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.posted_grade, 7.8)
      })
    })

    test('uses the score from the grading data when the grade was entered as a percent', () => {
      gradeInfo = {enteredAs: 'percent', excused: false, grade: '78%', score: 7.8, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.posted_grade, 7.8)
      })
    })

    test('uses the grade from the grading data when the grade was entered as a grading scheme key', () => {
      gradeInfo = {enteredAs: 'gradingScheme', excused: false, grade: 'A', score: 7.8, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.posted_grade, 'A')
      })
    })

    test('uses the grade from the grading data when the grade was entered as a pass/fail key', () => {
      gradeInfo = {
        enteredAs: 'gradingScheme',
        excused: false,
        grade: 'complete',
        score: 10,
        valid: true,
      }
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.posted_grade, 'complete')
      })
    })

    test('uses an empty string "" when the grade is cleared', () => {
      gradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [submissionData] = gradebook.apiUpdateSubmission.firstCall.args
        strictEqual(submissionData.posted_grade, '')
      })
    })

    test('includes gradeInfo as the second parameter', () => {
      gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 9.5, valid: true}
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        const [, givenInfo] = gradebook.apiUpdateSubmission.firstCall.args
        deepEqual(givenInfo, gradeInfo)
      })
    })

    test('warns about unusually high grades', () => {
      response.data.score = 15
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        strictEqual($.flashWarning.callCount, 1)
      })
    })

    test('does not warn about slightly high grades', () => {
      response.data.score = 14.99
      gradebook.gradeSubmission(submission, gradeInfo)
      return apiPromise.then(() => {
        strictEqual($.flashWarning.callCount, 0)
      })
    })

    test('does not warn about the given grade when the update fails', () => {
      gradeInfo.grade = '1000'
      apiPromise = Promise.reject(new Error('FAIL'))
      gradebook.apiUpdateSubmission.returns(apiPromise)
      return gradebook.gradeSubmission(submission, gradeInfo).catch(() => {
        strictEqual($.flashWarning.callCount, 0)
      })
    })

    QUnit.module('when the grade is unchanged', contextHooks => {
      contextHooks.beforeEach(() => {
        const invalidGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: 'invalid',
          score: null,
          valid: false,
        }
        gradebook.addPendingGradeInfo(submission, invalidGradeInfo)
        Object.assign(gradeInfo, {enteredAs: 'points', grade: 'B', score: 9})
      })

      test('removes an existing pending grade info for the submission', () => {
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.getPendingGradeInfo(submission), null)
      })

      test('does not update the grade via the api', () => {
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.apiUpdateSubmission.callCount, 0)
      })

      test('updates cells in the student row', () => {
        sinon.stub(gradebook, 'updateRowCellsForStudentIds')
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.updateRowCellsForStudentIds.callCount, 1)
      })

      test('uses the id of the student when updating the row cells', () => {
        sinon.stub(gradebook, 'updateRowCellsForStudentIds')
        gradebook.gradeSubmission(submission, gradeInfo)
        const [userIds] = gradebook.updateRowCellsForStudentIds.lastCall.args
        deepEqual(userIds, ['1101'])
      })

      test('re-renders the submission tray if it is open', () => {
        sinon.stub(gradebook, 'getSubmissionTrayState').callsFake(() => ({open: true}))

        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 1)

        gradebook.getSubmissionTrayState.restore()
      })

      test('does not attempt to re-render the submission tray if it is not open', () => {
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 0)
      })
    })

    QUnit.module('when the grade info is invalid', contextHooks => {
      contextHooks.beforeEach(() => {
        gradeInfo = {
          enteredAs: null,
          excused: false,
          grade: 'invalid',
          score: null,
          valid: false,
        }
        // return to ensure that any changes cause the hook to wait for the
        // potential promise from the api
        sinon.stub(FlashAlert, 'showFlashAlert')
        return gradebook.gradeSubmission(submission, gradeInfo)
      })

      contextHooks.afterEach(() => {
        FlashAlert.showFlashAlert.restore()
      })

      test('adds the pending grade info for the submission', () => {
        deepEqual(gradebook.getPendingGradeInfo({assignmentId: '2301', userId: '1101'}), {
          ...gradeInfo,
          assignmentId: '2301',
          userId: '1101',
        })
      })

      test('does not update the grade via the api', () => {
        strictEqual(gradebook.apiUpdateSubmission.callCount, 0)
      })

      test('shows a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "error" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })

      test('mentions the invalid grade in the flash alert', () => {
        const [{message}] = FlashAlert.showFlashAlert.lastCall.args
        ok(message.includes('invalid grade'))
      })

      test('updates cells in the student row', () => {
        sinon.stub(gradebook, 'updateRowCellsForStudentIds')
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.updateRowCellsForStudentIds.callCount, 1)
      })

      test('uses the id of the student when updating the row cells', () => {
        sinon.stub(gradebook, 'updateRowCellsForStudentIds')
        gradebook.gradeSubmission(submission, gradeInfo)
        const [userIds] = gradebook.updateRowCellsForStudentIds.lastCall.args
        deepEqual(userIds, ['1101'])
      })

      test('re-renders the submission tray if it is open', () => {
        sinon.stub(gradebook, 'getSubmissionTrayState').callsFake(() => ({open: true}))
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 1)
        gradebook.getSubmissionTrayState.restore()
      })

      test('does not attempt to re-render the submission tray if it is not open', () => {
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 0)
      })
    })
  })
})

QUnit.module('Gradebook#toggleViewUngradedAsZero', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook({
      grid: {
        getColumns: () => [],
        updateCell: sinon.stub(),
      },
      settings: {
        allow_view_ungraded_as_zero: 'true',
      },
    })

    sandbox.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
  })

  test('toggles viewUngradedAsZero to true when false', () => {
    gradebook.gridDisplaySettings.viewUngradedAsZero = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleViewUngradedAsZero()

    strictEqual(gradebook.gridDisplaySettings.viewUngradedAsZero, true)
  })

  test('toggles viewUngradedAsZero to false when true', () => {
    gradebook.gridDisplaySettings.viewUngradedAsZero = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    gradebook.toggleViewUngradedAsZero()

    strictEqual(gradebook.gridDisplaySettings.viewUngradedAsZero, false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', () => {
    gradebook.gridDisplaySettings.viewUngradedAsZero = true
    const stubFn = sandbox
      .stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      .callsFake(() => {
        strictEqual(gradebook.gridDisplaySettings.viewUngradedAsZero, false)
      })
    gradebook.toggleViewUngradedAsZero()

    strictEqual(stubFn.callCount, 1)
  })

  test('calls saveSettings with the new value of the setting', () => {
    gradebook.gridDisplaySettings.viewUngradedAsZero = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')

    gradebook.toggleViewUngradedAsZero()

    deepEqual(gradebook.saveSettings.firstCall.args[0], {
      viewUngradedAsZero: true,
    })
  })

  test('calls calculateStudentGrade once for each student', () => {
    const allStudents = [
      {id: '1101', assignment_201: {}, assignment_202: {}},
      {id: '1102', assignment_201: {}},
    ]
    sandbox.stub(gradebook.courseContent.students, 'listStudents').returns(allStudents)

    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox.stub(gradebook, 'calculateStudentGrade')
    gradebook.toggleViewUngradedAsZero()

    strictEqual(gradebook.calculateStudentGrade.callCount, 2)
  })

  test('calls updateAllTotalColumns', () => {
    gradebook.students = {
      1101: {id: '1101', assignment_201: {}, assignment_202: {}},
      1102: {id: '1102', assignment_201: {}},
    }

    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox.stub(gradebook, 'updateAllTotalColumns')
    gradebook.toggleViewUngradedAsZero()

    strictEqual(gradebook.updateAllTotalColumns.callCount, 1)
  })
})

QUnit.module('Gradebook#sendMessageStudentsWho', hooks => {
  let gradebook
  let apiRequestStub

  const recipientsIds = [1, 2, 3, 4]
  const subject = 'subject'
  const body = 'body'

  hooks.beforeEach(() => {
    gradebook = createGradebook({
      context_id: '1234',
      show_message_students_with_observers_dialog: true,
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

    sandbox.stub(FlashAlert, 'showFlashSuccess')
    sandbox.stub(FlashAlert, 'showFlashError')

    apiRequestStub = sinon.stub(MessageStudentsWhoHelper, 'sendMessageStudentsWho').resolves()
  })

  hooks.afterEach(() => {
    apiRequestStub.restore()
    FlashAlert.showFlashSuccess.restore()
    FlashAlert.showFlashError.restore()
  })

  test('sends the messages via Gradebook.sendMessageStudentsWho', async () => {
    await gradebook.sendMessageStudentsWho({
      recipientsIds,
      subject,
      body,
    })

    strictEqual(apiRequestStub.callCount, 1)
  })

  test('includes recipientsIds as the first parameter', async () => {
    await gradebook.sendMessageStudentsWho({
      recipientsIds,
      subject,
      body,
    })

    strictEqual(apiRequestStub.firstCall.args[0], recipientsIds)
  })

  test('includes subject as the second parameter', async () => {
    await gradebook.sendMessageStudentsWho({
      recipientsIds,
      subject,
      body,
    })

    strictEqual(apiRequestStub.firstCall.args[1], subject)
  })

  test('includes body as the third parameter', async () => {
    await gradebook.sendMessageStudentsWho({
      recipientsIds,
      subject,
      body,
    })

    strictEqual(apiRequestStub.firstCall.args[2], body)
  })

  test('if provided, includes mediaFile as the fifth parameter', async () => {
    const mediaFile = {id: '1959', type: 'video'}
    await gradebook.sendMessageStudentsWho({
      body,
      mediaFile,
      recipientsIds,
      subject,
    })

    deepEqual(apiRequestStub.firstCall.args[4], mediaFile)
  })

  test('if provided, includes attachmentIds as the sixth parameter', async () => {
    const attachmentIds = ['4', '82']
    await gradebook.sendMessageStudentsWho({
      attachmentIds,
      body,
      recipientsIds,
      subject,
    })

    deepEqual(apiRequestStub.firstCall.args[5], attachmentIds)
  })

  test('shows a success flash alert when the process succeeds', async () => {
    const message = 'Message sent successfully'
    await gradebook.sendMessageStudentsWho({
      recipientsIds,
      subject,
      body,
    })
    strictEqual(FlashAlert.showFlashSuccess.firstCall.args[0], message)
  })

  test('shows an error flash alert when the process fails', async () => {
    let errorThrown = false
    apiRequestStub.rejects(new Error(':-/'))
    try {
      await gradebook.sendMessageStudentsWho({
        recipientsIds,
        subject,
        body,
      })
    } catch (_error) {
      errorThrown = true
    }
    strictEqual(errorThrown, true)
    strictEqual(FlashAlert.showFlashError.callCount, 1)
  })
})
