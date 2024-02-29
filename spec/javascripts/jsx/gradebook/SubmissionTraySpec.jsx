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

import moxios from 'moxios'
import fakeENV from 'helpers/fakeENV'
import ReactDOM from 'react-dom'
import $ from 'jquery'
import 'jquery-migrate'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import GradebookApi from 'ui/features/gradebook/react/default_gradebook/apis/GradebookApi'
import {waitFor} from '../support/Waiters'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook#renderSubmissionTray', {
  setup() {
    fakeENV.setup()
    ENV.GRADEBOOK_OPTIONS = {
      proxy_submissions_allowed: false,
    }
    moxios.install()
    const url = '/api/v1/courses/1/assignments/2/submissions/3'
    moxios.stubRequest(url, {status: 200, response: {submission_comments: []}})
    this.mountPointId = 'StudentTray__Container'
    setFixtureHtml($fixtures)
    this.gradebook = createGradebook()
    this.gradebook.setAssignments({
      2301: {
        id: '2301',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: 'http://assignmentUrl',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    this.gradebook.setAssignmentGroups({9000: {group_weight: 100}})
    this.gradebook.students = {
      1101: {
        id: '1101',
        name: 'J&#x27;onn J&#x27;onzz',
        assignment_2301: {
          assignment_id: '2301',
          id: '2501',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
        enrollments: [
          {
            grades: {
              html_url: 'http://gradesUrl/',
            },
          },
        ],
        isConcluded: false,
      },
    }
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit() {},
        focus() {},
      },
      state: {
        getActiveLocation: () => ({region: 'body', cell: 0, row: 0}),
      },
      grid: {
        getColumns: () => [],
      },
    }
  },

  teardown() {
    const node = document.getElementById(this.mountPointId)
    ReactDOM.unmountComponentAtNode(node)
    $fixtures.innerHTML = ''
    moxios.uninstall()
  },
})

test('shows a submission tray on the page when rendering an open tray', async function () {
  this.gradebook.setSubmissionTrayState(true, '1101', '2301')
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'))
  await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))
  ok(document.querySelector('[aria-label="Submission tray"]'))
})

test('does not show a submission tray on the page when rendering a closed tray', function () {
  const clock = sinon.useFakeTimers()
  this.gradebook.setSubmissionTrayState(false, '1101', '2301')
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'))
  clock.tick(500) // wait for Tray transition to ensure it has not opened
  notOk(document.querySelector('[aria-label="Submission tray"]'))
  clock.restore()
})

test('shows a submission tray when the related submission has not loaded for the student', async function () {
  this.gradebook.setSubmissionTrayState(true, '1101', '2301')
  this.gradebook.student('1101').assignment_2301 = undefined
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'))
  await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))
  ok(document.querySelector('[aria-label="Submission tray"]'))
})

test('calls getSubmissionTrayProps with the student', async function () {
  sinon.spy(this.gradebook, 'getSubmissionTrayProps')
  this.gradebook.setSubmissionTrayState(true, '1101', '2301')
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'))
  await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))
  deepEqual(this.gradebook.getSubmissionTrayProps.firstCall.args, [this.gradebook.student('1101')])
})

QUnit.module('Gradebook#updateSubmissionAndRenderSubmissionTray', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit() {},
      },
    }
    this.gradebook.students = {1101: {id: '1101'}}
    this.promise = {
      then(thenFn) {
        this.thenFn = thenFn
        return this
      },

      catch(catchFn) {
        this.catchFn = catchFn
        return this
      },
    }
    this.submission = {assignmentId: '2301', latePolicyStatus: 'none', userId: '1101'}
    this.gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: 'A',
      entered_score: 9.5,
      excused: false,
      grade: 'B',
      score: 8.5,
      user_id: '1101',
    })

    sandbox.stub(GradebookApi, 'updateSubmission').returns(this.promise)
    this.gradebook.setSubmissionTrayState(true, '1101', '2301')
  },
})

test('stores the pending grade info before sending the request', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  strictEqual(this.gradebook.submissionIsUpdating(this.submission), true)
})

test('includes "grade" when storing the pending grade info', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  const pendingGradeInfo = this.gradebook.getPendingGradeInfo(this.submission)
  equal(pendingGradeInfo.grade, 'A')
})

test('includes "score" when storing the pending grade info', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  const pendingGradeInfo = this.gradebook.getPendingGradeInfo(this.submission)
  strictEqual(pendingGradeInfo.score, 9.5)
})

test('includes "excused" when storing the pending grade info', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  const pendingGradeInfo = this.gradebook.getPendingGradeInfo(this.submission)
  strictEqual(pendingGradeInfo.excused, false)
})

test('includes "valid" when storing the pending grade info', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  const pendingGradeInfo = this.gradebook.getPendingGradeInfo(this.submission)
  strictEqual(pendingGradeInfo.valid, true)
})

test('renders the tray before sending the request', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 1)
})

test('on success the pending grade info is removed', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  sandbox.stub(this.gradebook, 'updateSubmissionsFromExternal')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  this.promise.thenFn({data: {all_submissions: [{id: '293', ...this.submission}]}})
  strictEqual(this.gradebook.getPendingGradeInfo(this.submission), null)
})

test('on success the tray has been rendered a second time', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  sandbox.stub(this.gradebook, 'updateSubmissionsFromExternal')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  this.promise.thenFn({data: {all_submissions: [{id: '293', ...this.submission}]}})
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 2)
})

test('on failure the pending grade info is removed', function () {
  // without a retry strategy, clearing the request data is the only way to
  // revert to a stable state
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual(this.gradebook.getPendingGradeInfo(this.submission), null)
  })
})

test('on failure the student row is updated', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  sinon.spy(this.gradebook, 'updateRowCellsForStudentIds')
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual(this.gradebook.updateRowCellsForStudentIds.callCount, 1)
  })
})

test('includes the student id when updating its row on failure', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  sinon.spy(this.gradebook, 'updateRowCellsForStudentIds')
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    const [userIds] = this.gradebook.updateRowCellsForStudentIds.lastCall.args
    deepEqual(userIds, ['1101'])
  })
})

test('on failure the submission has been rendered a second time', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual(this.gradebook.renderSubmissionTray.callCount, 2)
  })
})

test('on failure a flash error is triggered', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray')
  sandbox.stub($, 'flashError')
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual($.flashError.callCount, 1)
  })
})

QUnit.module('Gradebook#updateRowAndRenderSubmissionTray', {
  setup() {
    this.gradebook = createGradebook()
    sandbox.stub(this.gradebook, 'updateRowCellsForStudentIds')
    sandbox.stub(this.gradebook, 'renderSubmissionTray')
  },
})

test('unloads comments for the submission', function () {
  sandbox.stub(this.gradebook, 'unloadSubmissionComments')
  this.gradebook.updateRowAndRenderSubmissionTray('1')

  strictEqual(this.gradebook.unloadSubmissionComments.callCount, 1)
})

test('updates the row cell for the given student id', function () {
  this.gradebook.updateRowAndRenderSubmissionTray('1')
  strictEqual(this.gradebook.updateRowCellsForStudentIds.callCount, 1)
  deepEqual(this.gradebook.updateRowCellsForStudentIds.getCall(0).args[0], ['1'])
})

test('renders the submission tray', function () {
  this.gradebook.updateRowAndRenderSubmissionTray('1')
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 1)
})

QUnit.module('Gradebook#getSubmissionTrayProps', suiteHooks => {
  const url = '/api/v1/courses/1/assignments/2/submissions/3'
  const mountPointId = 'StudentTray__Container'
  const defaultGradingScheme = [
    ['A', 0.9],
    ['B', 0.8],
    ['C', 0.7],
    ['D', 0.6],
    ['E', 0.5],
  ]
  let gradebook

  suiteHooks.beforeEach(() => {
    moxios.install()
    moxios.stubRequest(url, {status: 200, response: {submission_comments: []}})
    setFixtureHtml($fixtures)
    gradebook = createGradebook({
      default_grading_standard: defaultGradingScheme,
    })
    gradebook.setAssignmentGroups({9000: {group_weight: 100}})
    gradebook.setAssignments({
      2301: {
        id: '2301',
        assignment_group_id: '9000',
        points_posible: 10,
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: 'http://assignmentUrl',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    gradebook.students = {
      1101: {
        id: '1101',
        name: 'J&#x27;onn J&#x27;onzz',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
        enrollments: [
          {
            grades: {
              html_url: 'http://gradesUrl/',
            },
          },
        ],
        isConcluded: false,
      },
    }
    gradebook.initSubmissionStateMap()
    gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit() {},
        focus() {},
      },
      state: {
        getActiveLocation: () => ({region: 'body', cell: 0, row: 0}),
      },
      grid: {
        getColumns: () => [],
      },
    }
  })

  suiteHooks.afterEach(() => {
    const node = document.getElementById(mountPointId)
    ReactDOM.unmountComponentAtNode(node)
    $fixtures.innerHTML = ''
    moxios.uninstall()
  })

  test('gradingDisabled is true when the submission state is locked', () => {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({locked: true})
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.gradingDisabled, true)
  })

  test('gradingDisabled is false when the submission state is not locked', () => {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({locked: false})
    gradebook.student('1101').isConcluded = false
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.gradingDisabled, false)
  })

  test('gradingDisabled is false when the submission state is undefined', () => {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns(undefined)
    gradebook.student('1101').isConcluded = false
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.gradingDisabled, false)
  })

  test('gradingDisabled is true when the student enrollment is concluded', () => {
    gradebook.student('1101').isConcluded = true
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.gradingDisabled, true)
  })

  test('gradingDisabled is false when the student enrollment is not concluded', () => {
    gradebook.student('1101').isConcluded = false
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.gradingDisabled, false)
  })

  test('onGradeSubmission is the Gradebook "gradeSubmission" method', () => {
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    equal(props.onGradeSubmission, gradebook.gradeSubmission)
  })

  test('student has valid gradesUrl', () => {
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.student.gradesUrl, 'http://gradesUrl/#tab-assignments')
  })

  test('student has html decoded name', () => {
    gradebook.students[1101].name = 'J&#x27;onn J&#x27;onzz'
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.student.name, "J'onn J'onzz")
  })

  test('student has isConcluded property', () => {
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.student.isConcluded, false)
  })

  test('isInOtherGradingPeriod is true when the SubmissionStateMap returns true', () => {
    sinon
      .stub(gradebook.submissionStateMap, 'getSubmissionState')
      .returns({inOtherGradingPeriod: true})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInOtherGradingPeriod, true)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInOtherGradingPeriod is false when the SubmissionStateMap returns false', () => {
    sinon
      .stub(gradebook.submissionStateMap, 'getSubmissionState')
      .returns({inOtherGradingPeriod: false})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInOtherGradingPeriod, false)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInOtherGradingPeriod is false when the SubmissionStateMap returns undefined', () => {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInOtherGradingPeriod, false)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInClosedGradingPeriod is true when the SubmissionStateMap returns true', () => {
    sinon
      .stub(gradebook.submissionStateMap, 'getSubmissionState')
      .returns({inClosedGradingPeriod: true})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInClosedGradingPeriod, true)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInClosedGradingPeriod is false when the SubmissionStateMap returns false', () => {
    sinon
      .stub(gradebook.submissionStateMap, 'getSubmissionState')
      .returns({inClosedGradingPeriod: false})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInClosedGradingPeriod, false)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInClosedGradingPeriod is false when the SubmissionStateMap returns undefined', () => {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInClosedGradingPeriod, false)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInNoGradingPeriod is true when the SubmissionStateMap returns true', () => {
    sinon
      .stub(gradebook.submissionStateMap, 'getSubmissionState')
      .returns({inNoGradingPeriod: true})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInNoGradingPeriod, true)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInNoGradingPeriod is false when the SubmissionStateMap returns false', () => {
    sinon
      .stub(gradebook.submissionStateMap, 'getSubmissionState')
      .returns({inNoGradingPeriod: false})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInNoGradingPeriod, false)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('isInNoGradingPeriod is false when the SubmissionStateMap returns undefined', () => {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({})

    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(props.isInNoGradingPeriod, false)

    gradebook.submissionStateMap.getSubmissionState.restore()
  })

  test('gradingScheme is the grading scheme for the assignment', () => {
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    deepEqual(props.gradingScheme, defaultGradingScheme)
  })

  test('enterGradesAs is the "enter grades as" setting for the assignment', () => {
    sinon.spy(gradebook, 'getEnterGradesAsSetting')
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))

    strictEqual(gradebook.getEnterGradesAsSetting.withArgs('2301').callCount, 1)
    strictEqual(props.enterGradesAs, 'points')
  })

  test('sets isNotCountedForScore to false when the assignment is counted toward final grade', () => {
    gradebook.assignments[2301].omit_from_final_grade = false
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.isNotCountedForScore, false)
  })

  test('sets isNotCountedForScore to true when the assignment is not counted toward final grade', () => {
    gradebook.assignments[2301].omit_from_final_grade = true
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.isNotCountedForScore, true)
  })

  test('sets isNotCountedForScore to false when the assignment group weight is not zero', () => {
    gradebook.assignmentGroups[9000].group_weight = 100
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.isNotCountedForScore, false)
  })

  test('sets isNotCountedForScore to true when the assignment group weight is zero and weighting scheme is percent', () => {
    gradebook.assignmentGroups[9000].group_weight = 0
    gradebook.options.group_weighting_scheme = 'percent'
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.isNotCountedForScore, true)
  })

  test('sets isNotCountedForScore to false when the assignment group weight is not zero and weighting scheme is percent', () => {
    gradebook.assignmentGroups[9000].group_weight = 100
    gradebook.options.group_weighting_scheme = 'percent'
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.isNotCountedForScore, false)
  })

  test('sets isNotCountedForScore to false when assignment group weight is zero and weighting scheme is not percent', () => {
    gradebook.assignmentGroups[9000].group_weight = 0
    gradebook.options.group_weighting_scheme = 'equals'
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    strictEqual(props.isNotCountedForScore, false)
  })

  test('sets pendingGradeInfo when a pending grade exists for the current student/assignment', () => {
    const pendingGradeInfo = {
      enteredAs: null,
      excused: false,
      grade: null,
      score: null,
      valid: true,
    }
    const submission = {assignmentId: '2301', userId: '1101'}

    gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
    gradebook.setSubmissionTrayState(true, '1101', '2301')

    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    deepEqual(props.pendingGradeInfo, {...pendingGradeInfo, assignmentId: '2301', userId: '1101'})
  })

  test('sets pendingGradeInfo to null when no pending grade exists for the current student/assignment', () => {
    const pendingGradeInfo = {
      enteredAs: null,
      excused: false,
      grade: null,
      score: null,
      valid: true,
    }
    const submission = {assignmentId: '2302', userId: '1101'}

    gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
    gradebook.setSubmissionTrayState(true, '1101', '2301')

    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    notOk(props.pendingGradeInfo)
  })

  QUnit.module('requireStudentGroupForSpeedGrader', requireStudentGroupHooks => {
    requireStudentGroupHooks.beforeEach(() => {
      const studentGroups = [
        {
          groups: [
            {id: '1', name: 'First Group Set 1'},
            {id: '2', name: 'First Group Set 2'},
          ],
          id: '1',
          name: 'First Group Set',
        },
        {
          groups: [
            {id: '3', name: 'Second Group Set 1'},
            {id: '4', name: 'Second Group Set 2'},
          ],
          id: '2',
          name: 'Second Group Set',
        },
      ]

      gradebook.setStudentGroups(studentGroups)
    })

    QUnit.module(
      'when filter_speed_grader_by_student_group is enabled and no group is selected',
      noGroupSelectedHooks => {
        noGroupSelectedHooks.beforeEach(() => {
          gradebook.options.course_settings.filter_speed_grader_by_student_group = true
          gradebook.setSubmissionTrayState(true, '1101', '2301')
        })

        test('is true when the current assignment is not a group assignment', () => {
          const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
          strictEqual(props.requireStudentGroupForSpeedGrader, true)
        })

        test('is true when the current assignment is a group assignment and grades students individually', () => {
          gradebook.getAssignment('2301').group_category_id = '1'
          gradebook.getAssignment('2301').grade_group_students_individually = true
          const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
          strictEqual(props.requireStudentGroupForSpeedGrader, true)
        })

        test('is false when the current assignment is a group assignment but does not grade individually', () => {
          gradebook.getAssignment('2301').group_category_id = '1'
          const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
          strictEqual(props.requireStudentGroupForSpeedGrader, false)
        })
      }
    )

    test('is false when filter_speed_grader_by_student_group is enabled and a group is selected', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = true
      gradebook.setFilterRowsBySetting('studentGroupId', '4')
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      strictEqual(props.requireStudentGroupForSpeedGrader, false)
    })

    test('is false when filter_speed_grader_by_student_group is not enabled', () => {
      gradebook.options.course_settings.filter_speed_grader_by_student_group = false
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
      strictEqual(props.requireStudentGroupForSpeedGrader, false)
    })
  })
})

QUnit.module('Gradebook#renderSubmissionTray - Student Carousel', hooks => {
  let gradebook
  let mountPointId
  let clock

  hooks.beforeEach(() => {
    mountPointId = 'StudentTray__Container'
    setFixtureHtml($fixtures)
    moxios.install()
    const url = '/api/v1/courses/1/assignments/2301/submissions/1101?include=submission_comments'
    moxios.stubRequest(url, {status: 200, response: {submission_comments: []}})
    gradebook = createGradebook()
    gradebook.setAssignments({
      2301: {
        id: '2301',
        assignment_group_id: '9000',
        course_id: '1',
        grading_type: 'points',
        name: 'Assignment 1',
        assignment_visibility: [],
        only_visible_to_overrides: false,
        html_url: 'http://assignmentUrl',
        muted: false,
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry'],
      },
    })
    gradebook.setAssignmentGroups({9000: {group_weight: 100}})

    gradebook.students = {
      1100: {
        id: '1100',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
        enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
        isConcluded: false,
      },
      1101: {
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
        enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
        isConcluded: false,
      },
      1102: {
        id: '1100',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
        },
        enrollments: [{grades: {html_url: 'http://gradesUrl/'}}],
        isConcluded: false,
      },
    }
    sinon.stub(gradebook, 'listRows').returns([1100, 1101, 1102].map(id => gradebook.students[id]))
    gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit() {},
        focus() {},
      },
      state: {
        getActiveLocation: () => ({region: 'body', cell: 0, row: 0}),
      },
      grid: {
        getColumns: () => [],
      },
    }
    clock = sinon.useFakeTimers()
  })

  hooks.afterEach(() => {
    if (clock) {
      clock.restore()
    }
    const node = document.getElementById(mountPointId)
    ReactDOM.unmountComponentAtNode(node)
    moxios.uninstall()
    $fixtures.innerHTML = ''
  })

  test('does not show the previous student arrow for the first student', async () => {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
      region: 'body',
      cell: 0,
      row: 0,
    })
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))

    strictEqual(
      document.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      0
    )
  })

  test('shows the next student arrow for the first student', async () => {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
      region: 'body',
      cell: 0,
      row: 0,
    })
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))

    strictEqual(
      document.querySelectorAll('#student-carousel .right-arrow-button-container button').length,
      1
    )
  })

  test('does not show the next student arrow for the last student', async () => {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
      region: 'body',
      cell: 0,
      row: 2,
    })
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))

    strictEqual(
      document.querySelectorAll('#student-carousel .right-arrow-button-container button').length,
      0
    )
  })

  test('shows the previous student arrow for the last student', async () => {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
      region: 'body',
      cell: 0,
      row: 2,
    })
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))

    strictEqual(
      document.querySelectorAll('#student-carousel .left-arrow-button-container button').length,
      1
    )
  })

  test('clicking the next student arrow calls loadTrayStudent with "next"', async () => {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
      region: 'body',
      cell: 0,
      row: 1,
    })
    sinon.stub(gradebook, 'loadTrayStudent')
    sinon.stub(gradebook, 'getCommentsUpdating').returns(false)
    sinon.stub(gradebook, 'getSubmissionCommentsLoaded').returns(true)
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))

    const nextStudentButton = document.querySelector(
      '#student-carousel .right-arrow-button-container button'
    )
    nextStudentButton.click()
    strictEqual(gradebook.loadTrayStudent.callCount, 1)
    deepEqual(gradebook.loadTrayStudent.getCall(0).args, ['next'])
  })

  test('clicking the previous student arrow calls loadTrayStudent with "previous"', async () => {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({
      region: 'body',
      cell: 0,
      row: 1,
    })
    sinon.stub(gradebook, 'loadTrayStudent')
    sinon.stub(gradebook, 'getCommentsUpdating').returns(false)
    sinon.stub(gradebook, 'getSubmissionCommentsLoaded').returns(true)
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    await waitFor(() => document.querySelector('[aria-label="Submission tray"]'))

    const nextStudentButton = document.querySelector(
      '#student-carousel .left-arrow-button-container button'
    )
    nextStudentButton.click()
    strictEqual(gradebook.loadTrayStudent.callCount, 1)
    deepEqual(gradebook.loadTrayStudent.getCall(0).args, ['previous'])
  })

  test('calls loadSubmissionComments', () => {
    const loadSubmissionCommentsStub = sinon.stub(gradebook, 'loadSubmissionComments')
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    strictEqual(loadSubmissionCommentsStub.callCount, 1)
  })

  test('does not call loadSubmissionComments if not open', () => {
    const loadSubmissionCommentsStub = sinon.stub(gradebook, 'loadSubmissionComments')
    gradebook.setSubmissionTrayState(false, '1101', '2301')
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    strictEqual(loadSubmissionCommentsStub.callCount, 0)
  })

  test('does not call loadSubmissionComments if loaded', () => {
    const loadSubmissionCommentsStub = sinon.stub(gradebook, 'loadSubmissionComments')
    gradebook.setSubmissionTrayState(true, '1101', '2301')
    gradebook.setSubmissionCommentsLoaded(true)
    gradebook.renderSubmissionTray(gradebook.student('1101'))
    strictEqual(loadSubmissionCommentsStub.callCount, 0)
  })
})

QUnit.module('Gradebook#toggleSubmissionTrayOpen', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit() {},
        focus() {},
      },
    }
    sandbox.stub(this.gradebook, 'updateRowAndRenderSubmissionTray')
  },
})

test('sets the tray state to open if it was closed', function () {
  const openState = {before: this.gradebook.getSubmissionTrayState().open}
  this.gradebook.toggleSubmissionTrayOpen('1', '2')
  openState.after = this.gradebook.getSubmissionTrayState().open
  deepEqual(openState, {before: false, after: true})
})

test('sets the tray state to closed if it was open', function () {
  this.gradebook.setSubmissionTrayState(true, '1', '2')
  const openState = {before: this.gradebook.getSubmissionTrayState().open}
  this.gradebook.toggleSubmissionTrayOpen('1', '2')
  openState.after = this.gradebook.getSubmissionTrayState().open
  deepEqual(openState, {before: true, after: false})
})

test('sets the studentId and assignmentId state for the tray', function () {
  this.gradebook.toggleSubmissionTrayOpen('1', '2')
  const {studentId, assignmentId} = this.gradebook.getSubmissionTrayState()
  deepEqual({studentId, assignmentId}, {studentId: '1', assignmentId: '2'})
})

QUnit.module('Gradebook#closeSubmissionTray', {
  setup() {
    this.gradebook = createGradebook()
    this.activeStudentId = '1101'
    this.gradebook.gridData.rows = [{id: this.activeStudentId}]
    this.gradebook.gradebookGrid.grid = {
      getActiveCell() {
        return {row: 0}
      },
    }
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit() {},
        focus() {},
        beginEdit() {},
      },
    }
    this.gradebook.setSubmissionTrayState(true, '1101', '2')
    sandbox.stub(this.gradebook, 'updateRowAndRenderSubmissionTray')
  },
})

test('sets the state of the tray to closed', function () {
  const openState = {before: this.gradebook.getSubmissionTrayState().open}
  this.gradebook.closeSubmissionTray()
  openState.after = this.gradebook.getSubmissionTrayState().open
  deepEqual(openState, {before: true, after: false})
})

test('calls updateRowAndRenderSubmissionTray with the student id for the active row', function () {
  this.gradebook.closeSubmissionTray()
  strictEqual(this.gradebook.updateRowAndRenderSubmissionTray.callCount, 1)
  strictEqual(
    this.gradebook.updateRowAndRenderSubmissionTray.getCall(0).args[0],
    this.activeStudentId
  )
})

test('puts the active grid cell back into "editing" mode', function () {
  sandbox.stub(this.gradebook.gradebookGrid.gridSupport.helper, 'beginEdit')
  this.gradebook.closeSubmissionTray()
  strictEqual(this.gradebook.gradebookGrid.gridSupport.helper.beginEdit.callCount, 1)
})

QUnit.module('Gradebook#setSubmissionTrayState', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit: sinon.stub(),
        focus: sinon.stub(),
      },
    }
  },
})

test('sets the state of the submission tray', function () {
  this.gradebook.setSubmissionTrayState(true, '1', '2')
  const expected = {
    open: true,
    studentId: '1',
    assignmentId: '2',
    commentsLoaded: false,
    comments: [],
    commentsUpdating: false,
    editedCommentId: null,
  }

  deepEqual(this.gradebook.gridDisplaySettings.submissionTray, expected)
})

test('puts cell in view mode when tray is opened', function () {
  this.gradebook.setSubmissionTrayState(true, '1', '2')
  strictEqual(this.gradebook.gradebookGrid.gridSupport.helper.commitCurrentEdit.callCount, 1)
})

test('does not put cell in view mode when tray is closed', function () {
  this.gradebook.setSubmissionTrayState(false, '1', '2')
  strictEqual(this.gradebook.gradebookGrid.gridSupport.helper.commitCurrentEdit.callCount, 0)
})

QUnit.module('Gradebook#getSubmissionTrayState', {
  setup() {
    this.gradebook = createGradebook()
  },
})

test('returns the state of the submission tray', function () {
  const expected = {
    open: false,
    studentId: '',
    assignmentId: '',
    commentsLoaded: false,
    comments: [],
    commentsUpdating: false,
    editedCommentId: null,
  }

  deepEqual(this.gradebook.getSubmissionTrayState(), expected)
})

test('returns the state of the submission tray when accessed directly', function () {
  this.gradebook.gridDisplaySettings.submissionTray.open = true
  this.gradebook.gridDisplaySettings.submissionTray.studentId = '1'
  this.gradebook.gridDisplaySettings.submissionTray.assignmentId = '2'
  const expected = {
    open: true,
    studentId: '1',
    assignmentId: '2',
    commentsLoaded: false,
    comments: [],
    commentsUpdating: false,
    editedCommentId: null,
  }

  deepEqual(this.gradebook.getSubmissionTrayState(), expected)
})
