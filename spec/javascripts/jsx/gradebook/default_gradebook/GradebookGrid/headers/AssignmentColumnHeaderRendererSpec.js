/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'

import {createGradebook} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import AssignmentColumnHeaderRenderer from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/AssignmentColumnHeaderRenderer'
import {getAssignmentColumnId} from 'ui/features/gradebook/react/default_gradebook/Gradebook.utils'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid AssignmentColumnHeaderRenderer', suiteHooks => {
  let $container
  let gradebook
  let assignment
  let column
  let component
  let renderer
  let student
  let submission

  function render() {
    renderer.render(
      column,
      $container,
      {} /* gridSupport */,
      {
        ref(ref) {
          component = ref
        },
      }
    )
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  function buildGradebook() {
    gradebook = createGradebook()
    sinon.stub(gradebook, 'saveSettings')

    assignment = {
      id: '2301',
      anonymize_students: false,
      assignment_visibility: null,
      course_id: '1201',
      grading_type: 'points',
      html_url: '/assignments/2301',
      muted: false,
      name: 'Math Assignment',
      omit_from_final_grade: false,
      only_visible_to_overrides: false,
      post_manually: false,
      published: true,
      submission_types: ['online_text_entry'],
    }

    submission = {
      id: '93',
      assignment_id: '2301',
      excused: false,
      hasPostableComments: false,
      late_policy_status: null,
      posted_at: null,
      score: null,
      submitted_at: null,
      user_id: '441',
      workflow_state: 'unsubmitted',
    }

    student = {
      id: '441',
      assignment_2301: submission,
      isInactive: false,
      name: 'Guy B. Studying',
      enrollments: [{type: 'StudentEnrollment', user_id: '441', course_section_id: '1'}],
      sortable_name: 'Studying, Guy B.',
    }

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: [assignment]},
    ])

    column = {id: getAssignmentColumnId('2301'), assignmentId: '2301'}
    renderer = new AssignmentColumnHeaderRenderer(gradebook)
  }

  QUnit.module('#render()', () => {
    test('renders the AssignmentColumnHeader to the given container node', () => {
      buildGradebook()
      render()
      ok(
        $container.innerText.includes('Math Assignment'),
        'the "Math Assignment" header is rendered'
      )
    })

    test('calls the "ref" callback option with the component reference', () => {
      buildGradebook()
      render()
      equal(component.constructor.name, 'AssignmentColumnHeader')
    })

    test('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      buildGradebook()
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement')
      render()
      component.props.addGradebookElement()
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1)
    })

    test('includes the assignment course id', () => {
      buildGradebook()
      render()
      strictEqual(component.props.assignment.courseId, '1201')
    })

    test('includes the assignment html url', () => {
      buildGradebook()
      render()
      equal(component.props.assignment.htmlUrl, '/assignments/2301')
    })

    test('includes the assignment id', () => {
      buildGradebook()
      render()
      strictEqual(component.props.assignment.id, '2301')
    })

    test('includes the assignment muted status when true', () => {
      buildGradebook()
      assignment.muted = true
      render()
      strictEqual(component.props.assignment.muted, true)
    })

    test('includes the assignment muted status when false', () => {
      buildGradebook()
      assignment.muted = false
      render()
      strictEqual(component.props.assignment.muted, false)
    })

    test('includes the assignment name', () => {
      buildGradebook()
      render()
      equal(component.props.assignment.name, 'Math Assignment')
    })

    test('includes the assignment points possible', () => {
      buildGradebook()
      assignment.points_possible = 10
      render()
      strictEqual(component.props.assignment.pointsPossible, 10)
    })

    test('includes the assignment published status for a published assignment', () => {
      buildGradebook()
      assignment.published = true
      render()
      strictEqual(component.props.assignment.published, true)
    })

    test('includes the assignment published status for an unpublished assignment', () => {
      buildGradebook()
      assignment.published = false
      render()
      strictEqual(component.props.assignment.published, false)
    })

    test('includes the assignment submission types', () => {
      buildGradebook()
      render()
      deepEqual(component.props.assignment.submissionTypes, ['online_text_entry'])
    })

    test('includes the assignment post manually property', () => {
      buildGradebook()
      assignment.post_manually = true
      render()
      strictEqual(component.props.assignment.postManually, true)
    })

    test('includes the curve grades action', () => {
      buildGradebook()
      sinon.spy(gradebook, 'getCurveGradesAction')
      render()
      equal(component.props.curveGradesAction, gradebook.getCurveGradesAction.returnValues[0])
    })

    test('includes the download submissions action', () => {
      buildGradebook()
      sinon.spy(gradebook, 'getDownloadSubmissionsAction')
      render()
      equal(
        component.props.downloadSubmissionsAction,
        gradebook.getDownloadSubmissionsAction.returnValues[0]
      )
    })

    test('the anonymizeStudents prop is `true` when the assignment is anonymous', () => {
      buildGradebook()
      assignment.anonymize_students = true
      render()
      strictEqual(component.props.assignment.anonymizeStudents, true)
    })

    test('the anonymizeStudents prop is `false` when the assignment is not anonymous', () => {
      buildGradebook()
      render()
      strictEqual(component.props.assignment.anonymizeStudents, false)
    })

    test('shows the "enter grades as" setting for a "points" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'points'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('shows the "enter grades as" setting for a "percent" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'percent'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('shows the "enter grades as" setting for a "letter grade" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'letter_grade'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('shows the "enter grades as" setting for a "GPA scale" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'gpa_scale'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('hides the "enter grades as" setting for a "pass/fail" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'pass_fail'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, true)
    })

    test('hides the "enter grades as" setting for a "not graded" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'not_graded'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, true)
    })

    test('includes a callback for changing the "enter grades as" setting', () => {
      buildGradebook()
      sinon.stub(gradebook, 'updateEnterGradesAsSetting')
      render()
      component.props.enterGradesAsSetting.onSelect('percent')
      strictEqual(gradebook.updateEnterGradesAsSetting.callCount, 1)
    })

    test('includes the assignment id when changing the "enter grades as" setting', () => {
      buildGradebook()
      sinon.stub(gradebook, 'updateEnterGradesAsSetting')
      render()
      component.props.enterGradesAsSetting.onSelect('percent')
      const assignmentId = gradebook.updateEnterGradesAsSetting.lastCall.args[0]
      strictEqual(assignmentId, '2301')
    })

    test('includes the new setting when changing the "enter grades as" setting', () => {
      buildGradebook()
      sinon.stub(gradebook, 'updateEnterGradesAsSetting')
      render()
      component.props.enterGradesAsSetting.onSelect('percent')
      const assignmentId = gradebook.updateEnterGradesAsSetting.lastCall.args[1]
      equal(assignmentId, 'percent')
    })

    test('uses the current "enter grades as" setting for the assignment', () => {
      buildGradebook()
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      render()
      equal(component.props.enterGradesAsSetting.selected, 'percent')
    })

    test('hides the "enter grades as" grading scheme option for a "points" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'points'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, false)
    })

    test('hides the "enter grades as" grading scheme option for a "percent" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'percent'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, false)
    })

    test('shows the "enter grades as" grading scheme option for a "letter grade" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'letter_grade'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, true)
    })

    test('shows the "enter grades as" grading scheme option for a "GPA scale" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'gpa_scale'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, true)
    })

    QUnit.module('"Post grades" action', hooks => {
      let onSelectCallback

      hooks.beforeEach(() => {
        onSelectCallback = sinon.spy()
        buildGradebook()

        sinon.stub(gradebook.postPolicies, 'showPostAssignmentGradesTray')
      })

      test('sets enabledForUser to true if the user can edit grades', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.enabledForUser, true)
      })

      test('sets enabledForUser to false if the user cannnot edit grades', () => {
        gradebook.options.gradebook_is_editable = false
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.enabledForUser, false)
      })

      test('sets hasGradesOrPostableComments to true if at least one submission is graded', () => {
        submission.workflow_state = 'graded'
        submission.score = 1
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.hasGradesOrPostableComments, true)
      })

      test('sets hasGradesOrPostableComments to false if no submissions are graded', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.hasGradesOrPostableComments, false)
      })

      test('sets hasGradesOrCommentsToPost to true if at least one submission is graded and unposted', () => {
        submission.workflow_state = 'graded'
        submission.score = 1
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.hasGradesOrCommentsToPost, true)
      })

      test('sets hasGradesOrCommentsToPost to true if at least one submission has a postable comment and unposted', () => {
        submission.has_postable_comments = true
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.hasGradesOrCommentsToPost, true)
      })

      test('sets hasGradesOrCommentsToPost to false if all submissions have a posted_at date', () => {
        submission.posted_at = new Date('Wed Oct 1 1997')

        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.postGradesAction.hasGradesOrCommentsToPost, false)
      })

      test('includes a callback to show the "Post Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        component.props.postGradesAction.onSelect(onSelectCallback)
        strictEqual(gradebook.postPolicies.showPostAssignmentGradesTray.callCount, 1)
      })

      test('includes the assignment id when showing the "Post Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        component.props.postGradesAction.onSelect(onSelectCallback)
        const [{assignmentId}] = gradebook.postPolicies.showPostAssignmentGradesTray.lastCall.args
        strictEqual(assignmentId, '2301')
      })

      test('includes the `onSelect` callback when showing the "Post Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        component.props.postGradesAction.onSelect(onSelectCallback)
        const [{onExited}] = gradebook.postPolicies.showPostAssignmentGradesTray.lastCall.args
        strictEqual(onExited, onSelectCallback)
      })
    })

    QUnit.module('"Hide grades" action', hooks => {
      let onSelectCallback

      hooks.beforeEach(() => {
        onSelectCallback = sinon.spy()
        buildGradebook()
        submission.posted_at = new Date('Wed Oct 1 1997')

        sinon.stub(gradebook.postPolicies, 'showHideAssignmentGradesTray')
      })

      test('sets hasGradesOrPostableComments to true if at least one submission is graded', () => {
        submission.workflow_state = 'graded'
        submission.score = 1
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.hideGradesAction.hasGradesOrPostableComments, true)
      })

      test('sets hasGradesOrPostableComments to true if at least one submission has postable comments', () => {
        submission.has_postable_comments = true
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.hideGradesAction.hasGradesOrPostableComments, true)
      })

      test('sets hasGradesOrPostableComments to false if no submissions are graded or have comments', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.hideGradesAction.hasGradesOrPostableComments, false)
      })

      test('sets hasGradesOrCommentsToHide to true if at least one submission has a posted_at date', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.hideGradesAction.hasGradesOrCommentsToHide, true)
      })

      test('sets hasGradesOrCommentsToHide to false if no submission has a posted_at date', () => {
        submission.posted_at = null
        gradebook.gotChunkOfStudents([student])
        render()
        strictEqual(component.props.hideGradesAction.hasGradesOrCommentsToHide, false)
      })

      test('includes a callback to show the "Hide Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        component.props.hideGradesAction.onSelect(onSelectCallback)
        strictEqual(gradebook.postPolicies.showHideAssignmentGradesTray.callCount, 1)
      })

      test('includes the assignment id when showing the "Hide Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        component.props.hideGradesAction.onSelect(onSelectCallback)
        const [{assignmentId}] = gradebook.postPolicies.showHideAssignmentGradesTray.lastCall.args
        strictEqual(assignmentId, '2301')
      })

      test('includes the `onSelect` callback when showing the "Hide Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        render()
        component.props.hideGradesAction.onSelect(onSelectCallback)
        const [{onExited}] = gradebook.postPolicies.showHideAssignmentGradesTray.lastCall.args
        strictEqual(onExited, onSelectCallback)
      })
    })

    QUnit.module('"Grade Posting Policy" action', hooks => {
      let onSelectCallback

      hooks.beforeEach(() => {
        onSelectCallback = sinon.spy()
        buildGradebook()
        render()

        sinon.stub(gradebook.postPolicies, 'showAssignmentPostingPolicyTray')
      })

      test('includes a callback to show the "Grade Posting Policy" tray', () => {
        component.props.showGradePostingPolicyAction.onSelect(onSelectCallback)
        strictEqual(gradebook.postPolicies.showAssignmentPostingPolicyTray.callCount, 1)
      })

      test('includes the assignment id when showing the "Grade Posting Policy" tray', () => {
        component.props.showGradePostingPolicyAction.onSelect(onSelectCallback)
        const [{assignmentId}] =
          gradebook.postPolicies.showAssignmentPostingPolicyTray.lastCall.args
        strictEqual(assignmentId, '2301')
      })

      test('includes the `onSelect` callback when showing the "Grade Posting Policy" tray', () => {
        component.props.showGradePostingPolicyAction.onSelect(onSelectCallback)
        const [{onExited}] = gradebook.postPolicies.showAssignmentPostingPolicyTray.lastCall.args
        strictEqual(onExited, onSelectCallback)
      })
    })

    test('student submissions for the assignment include "excused"', () => {
      buildGradebook()
      submission.excused = true
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.excused, true)
    })

    test('"excused" is false if the student does not have a submission', () => {
      buildGradebook()
      submission.excused = true
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.excused, false)
    })

    test('student submissions for the assignment include "latePolicyStatus"', () => {
      buildGradebook()
      submission.late_policy_status = 'missing'
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.latePolicyStatus, 'missing')
    })

    test('"latePolicyStatus" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.late_policy_status = 'missing'
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.latePolicyStatus, null)
    })

    test('student submissions for the assignment include "score"', () => {
      buildGradebook()
      submission.score = 9
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.score, '9')
    })

    test('"score" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.score = 9
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.score, null)
    })

    test('student submissions for the assignment include "submittedAt"', () => {
      buildGradebook()
      const submittedAt = new Date('Mon Nov 3 2016')
      submission.submitted_at = submittedAt
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.submittedAt, submittedAt)
    })

    test('"submittedAt" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.submittedAt = new Date('Mon Nov 3 2016')
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.submittedAt, null)
    })

    test('student submissions for the assignment include "postedAt"', () => {
      buildGradebook()
      const postedAt = new Date('Mon Nov 3 2016')
      submission.posted_at = postedAt
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.postedAt, postedAt)
    })

    test('"postedAt" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.postedAt = new Date('Mon Nov 3 2016')
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.submission.postedAt, null)
    })

    test('"isTestStudent" is true if the student is enrolled via a StudentViewEnrollment', () => {
      buildGradebook()
      student.enrollments = [{type: 'StudentViewEnrollment'}]
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.isTestStudent, true)
    })

    test('"isTestStudent" is false if the student is not enrolled via a StudentViewEnrollment', () => {
      buildGradebook()
      student.enrollments = [{type: 'StudentEnrollment'}]
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      strictEqual(studentProp.isTestStudent, false)
    })

    test('getCurrentlyShownStudents() fetches students using visibleStudentsThatCanSeeAssignment', () => {
      buildGradebook()
      sinon.stub(gradebook, 'visibleStudentsThatCanSeeAssignment').returns({[student.id]: student})

      render()
      const visibleStudents = component.props.getCurrentlyShownStudents()
      deepEqual(
        visibleStudents.map(visibleStudent => visibleStudent.id),
        [student.id]
      )
    })

    test('includes a callback for keyDown events', () => {
      buildGradebook()
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      strictEqual(gradebook.handleHeaderKeyDown.callCount, 1)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      buildGradebook()
      const exampleEvent = new Event('example')
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown(exampleEvent)
      const event = gradebook.handleHeaderKeyDown.lastCall.args[0]
      equal(event, exampleEvent)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      buildGradebook()
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      const columnId = gradebook.handleHeaderKeyDown.lastCall.args[1]
      equal(columnId, column.id)
    })

    test('includes a callback for closing the column header menu', () => {
      buildGradebook()
      const clock = sinon.useFakeTimers()
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose')
      render()
      component.props.onMenuDismiss()
      clock.tick(0)
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 1)
      clock.restore()
    })

    test('does not call the menu close handler synchronously', () => {
      // The React render lifecycle is not yet complete at this time.
      // The callback must begin after React finishes to avoid conflicts.
      const clock = sinon.useFakeTimers()
      buildGradebook()
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose')
      render()
      component.props.onMenuDismiss()
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 0)
      clock.restore()
    })

    test('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      buildGradebook()
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement')
      render()
      component.props.removeGradebookElement()
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1)
    })

    test('includes the reupload submissions action', () => {
      buildGradebook()
      sinon.spy(gradebook, 'getReuploadSubmissionsAction')
      render()
      equal(
        component.props.reuploadSubmissionsAction,
        gradebook.getReuploadSubmissionsAction.returnValues[0]
      )
    })

    test('includes the set default grade action', () => {
      buildGradebook()
      sinon.spy(gradebook, 'getSetDefaultGradeAction')
      render()
      equal(
        component.props.setDefaultGradeAction,
        gradebook.getSetDefaultGradeAction.returnValues[0]
      )
    })

    test('includes the "Sort by" direction setting', () => {
      buildGradebook()
      render()
      equal(component.props.sortBySetting.direction, 'ascending')
    })

    QUnit.test(
      'sets the "Sort by" disabled setting to true when assignments are not loaded',
      () => {
        buildGradebook()
        gradebook.contentLoadStates.assignmentsLoaded.all = false
        gradebook.setStudentsLoaded(true)
        gradebook.setSubmissionsLoaded(true)
        render()
        strictEqual(component.props.sortBySetting.disabled, true)
      }
    )

    test('sets the "Sort by" disabled setting to true when anonymize_students is true', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      assignment.anonymize_students = true
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(false)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when submissions are not loaded', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to false when necessary data are loaded', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, false)
    })

    test('sets the "Sort by" isSortColumn setting to true when sorting by this column', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, true)
    })

    test('sets the "Sort by" isSortColumn setting to false when not sorting by this column', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, false)
    })

    test('includes the onSortByGradeAscending callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByGradeAscending()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'grade'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByGradeDescending callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByGradeDescending()
      const expectedSetting = {columnId: column.id, direction: 'descending', settingKey: 'grade'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByLate callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByLate()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'late'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByMissing callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByMissing()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'missing'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the "Sort by" settingKey', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      equal(component.props.sortBySetting.settingKey, 'grade')
    })

    test('sets showMessageStudentsWithObserversDialog to true if enabled in gradebook', () => {
      buildGradebook()
      gradebook.options.show_message_students_with_observers_dialog = true
      render()
      strictEqual(component.props.showMessageStudentsWithObserversDialog, true)
    })

    test('sets showMessageStudentsWithObserversDialog to false if not enabled in gradebook', () => {
      buildGradebook()
      gradebook.options.show_message_students_with_observers_dialog = false
      render()
      strictEqual(component.props.showMessageStudentsWithObserversDialog, false)
    })

    test('sends message when handleSendMessageStudentsWho is executed', () => {
      const recipientsIds = [1, 2, 3, 4]
      const subject = 'foo'
      const body = 'bar'
      const contextCode = '1'

      buildGradebook()
      sinon.stub(gradebook, 'sendMessageStudentsWho')
      render()
      component.props.onSendMessageStudentsWho(recipientsIds, subject, body, contextCode)
      strictEqual(gradebook.sendMessageStudentsWho.callCount, 1)
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the component', () => {
      buildGradebook()
      render()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      strictEqual(removed, false, 'the component was already unmounted')
    })
  })
})
/* eslint-enable qunit/no-identical-names */
