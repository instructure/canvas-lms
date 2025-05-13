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

import React from 'react'
import ReactDOM from 'react-dom'

import {createGradebook} from '../../../__tests__/GradebookSpecHelper'
import AssignmentColumnHeaderRenderer from '../AssignmentColumnHeaderRenderer'
import {getAssignmentColumnId} from '../../../Gradebook.utils'

describe('GradebookGrid AssignmentColumnHeaderRenderer', () => {
  let $container
  let gradebook
  let assignment
  let column
  let component
  let renderer
  let student
  let submission

  function renderComponent() {
    renderer.render(
      column,
      $container,
      {} /* gridSupport */,
      {
        ref(ref) {
          component = ref
        },
      },
    )
  }

  window.ENV.SETTINGS = {}

  beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function buildGradebook() {
    gradebook = createGradebook()
    gradebook.saveSettings = jest.fn()

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
      post_manually: false,
      published: true,
      submission_types: ['online_text_entry'],
      visible_to_everyone: true,
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

  describe('#render()', () => {
    beforeEach(() => {
      buildGradebook()
    })

    it('renders the AssignmentColumnHeader to the given container node', () => {
      renderComponent()
      expect($container.innerText).toContain('Math Assignment')
    })

    it('calls the "ref" callback option with the component reference', () => {
      renderComponent()
      expect(component.constructor.name).toBe('AssignmentColumnHeader')
    })

    it('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      buildGradebook()
      gradebook.keyboardNav.addGradebookElement = jest.fn()
      renderComponent()
      component.props.addGradebookElement()
      expect(gradebook.keyboardNav.addGradebookElement).toHaveBeenCalledTimes(1)
    })

    it('includes the assignment course id', () => {
      renderComponent()
      expect(component.props.assignment.courseId).toBe('1201')
    })

    it('includes the assignment html url', () => {
      renderComponent()
      expect(component.props.assignment.htmlUrl).toBe('/assignments/2301')
    })

    it('includes the assignment id', () => {
      renderComponent()
      expect(component.props.assignment.id).toBe('2301')
    })

    it('includes the assignment muted status when true', () => {
      buildGradebook()
      assignment.muted = true
      renderComponent()
      expect(component.props.assignment.muted).toBe(true)
    })

    it('includes the assignment muted status when false', () => {
      buildGradebook()
      assignment.muted = false
      renderComponent()
      expect(component.props.assignment.muted).toBe(false)
    })

    it('includes the assignment name', () => {
      renderComponent()
      expect(component.props.assignment.name).toBe('Math Assignment')
    })

    it('includes the assignment points possible', () => {
      buildGradebook()
      assignment.points_possible = 10
      renderComponent()
      expect(component.props.assignment.pointsPossible).toBe(10)
    })

    it('includes the assignment published status for a published assignment', () => {
      buildGradebook()
      assignment.published = true
      renderComponent()
      expect(component.props.assignment.published).toBe(true)
    })

    it('includes the assignment published status for an unpublished assignment', () => {
      buildGradebook()
      assignment.published = false
      renderComponent()
      expect(component.props.assignment.published).toBe(false)
    })

    it('includes the assignment submission types', () => {
      renderComponent()
      expect(component.props.assignment.submissionTypes).toEqual(['online_text_entry'])
    })

    it('includes the assignment post manually property', () => {
      buildGradebook()
      assignment.post_manually = true
      renderComponent()
      expect(component.props.assignment.postManually).toBe(true)
    })

    it('includes the curve grades action', () => {
      buildGradebook()
      gradebook.getCurveGradesAction = jest.fn().mockReturnValue('CurveAction')
      renderComponent()
      expect(component.props.curveGradesAction).toBe('CurveAction')
    })

    it('includes the download submissions action', () => {
      buildGradebook()
      gradebook.getDownloadSubmissionsAction = jest.fn().mockReturnValue('DownloadAction')
      renderComponent()
      expect(component.props.downloadSubmissionsAction).toBe('DownloadAction')
    })

    it('the anonymizeStudents prop is `true` when the assignment is anonymous', () => {
      buildGradebook()
      assignment.anonymize_students = true
      renderComponent()
      expect(component.props.assignment.anonymizeStudents).toBe(true)
    })

    it('the anonymizeStudents prop is `false` when the assignment is not anonymous', () => {
      buildGradebook()
      renderComponent()
      expect(component.props.assignment.anonymizeStudents).toBe(false)
    })

    it('shows the "enter grades as" setting for a "points" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'points'
      renderComponent()
      expect(component.props.enterGradesAsSetting.hidden).toBe(false)
    })

    it('shows the "enter grades as" setting for a "percent" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'percent'
      renderComponent()
      expect(component.props.enterGradesAsSetting.hidden).toBe(false)
    })

    it('shows the "enter grades as" setting for a "letter grade" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'letter_grade'
      renderComponent()
      expect(component.props.enterGradesAsSetting.hidden).toBe(false)
    })

    it('shows the "enter grades as" setting for a "GPA scale" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'gpa_scale'
      renderComponent()
      expect(component.props.enterGradesAsSetting.hidden).toBe(false)
    })

    it('hides the "enter grades as" setting for a "pass/fail" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'pass_fail'
      renderComponent()
      expect(component.props.enterGradesAsSetting.hidden).toBe(true)
    })

    it('hides the "enter grades as" setting for a "not graded" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'not_graded'
      renderComponent()
      expect(component.props.enterGradesAsSetting.hidden).toBe(true)
    })

    it('includes a callback for changing the "enter grades as" setting', () => {
      buildGradebook()
      gradebook.updateEnterGradesAsSetting = jest.fn()
      renderComponent()
      component.props.enterGradesAsSetting.onSelect('percent')
      expect(gradebook.updateEnterGradesAsSetting).toHaveBeenCalledTimes(1)
    })

    it('includes the assignment id when changing the "enter grades as" setting', () => {
      buildGradebook()
      gradebook.updateEnterGradesAsSetting = jest.fn()
      renderComponent()
      component.props.enterGradesAsSetting.onSelect('percent')
      const assignmentId =
        gradebook.updateEnterGradesAsSetting.mock.calls[
          gradebook.updateEnterGradesAsSetting.mock.calls.length - 1
        ][0]
      expect(assignmentId).toBe('2301')
    })

    it('includes the new setting when changing the "enter grades as" setting', () => {
      buildGradebook()
      gradebook.updateEnterGradesAsSetting = jest.fn()
      renderComponent()
      component.props.enterGradesAsSetting.onSelect('percent')
      const newSetting =
        gradebook.updateEnterGradesAsSetting.mock.calls[
          gradebook.updateEnterGradesAsSetting.mock.calls.length - 1
        ][1]
      expect(newSetting).toBe('percent')
    })

    it('uses the current "enter grades as" setting for the assignment', () => {
      buildGradebook()
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      renderComponent()
      expect(component.props.enterGradesAsSetting.selected).toBe('percent')
    })

    it('hides the "enter grades as" grading scheme option for a "points" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'points'
      renderComponent()
      expect(component.props.enterGradesAsSetting.showGradingSchemeOption).toBe(false)
    })

    it('hides the "enter grades as" grading scheme option for a "percent" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'percent'
      renderComponent()
      expect(component.props.enterGradesAsSetting.showGradingSchemeOption).toBe(false)
    })

    it('shows the "enter grades as" grading scheme option for a "letter grade" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'letter_grade'
      renderComponent()
      expect(component.props.enterGradesAsSetting.showGradingSchemeOption).toBe(true)
    })

    it('shows the "enter grades as" grading scheme option for a "GPA scale" assignment', () => {
      buildGradebook()
      assignment.grading_type = 'gpa_scale'
      renderComponent()
      expect(component.props.enterGradesAsSetting.showGradingSchemeOption).toBe(true)
    })

    describe('"Post grades" action', () => {
      beforeEach(() => {
        gradebook.postPolicies.showPostAssignmentGradesTray = jest.fn()
      })

      it('sets enabledForUser to true if the user can edit grades', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.enabledForUser).toBe(true)
      })

      it('sets enabledForUser to false if the user cannot edit grades', () => {
        gradebook.options.gradebook_is_editable = false
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.enabledForUser).toBe(false)
      })

      it('sets hasGradesOrPostableComments to true if at least one submission is graded', () => {
        submission.workflow_state = 'graded'
        submission.score = 1
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.hasGradesOrPostableComments).toBe(true)
      })

      it('sets hasGradesOrPostableComments to false if no submissions are graded', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.hasGradesOrPostableComments).toBe(false)
      })

      it('sets hasGradesOrCommentsToPost to true if at least one submission is graded and unposted', () => {
        submission.workflow_state = 'graded'
        submission.score = 1
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.hasGradesOrCommentsToPost).toBe(true)
      })

      it('sets hasGradesOrCommentsToPost to true if at least one submission has a postable comment and unposted', () => {
        submission.has_postable_comments = true
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.hasGradesOrCommentsToPost).toBe(true)
      })

      it('sets hasGradesOrCommentsToPost to false if all submissions have a posted_at date', () => {
        submission.posted_at = new Date('Wed Oct 1 1997')

        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.postGradesAction.hasGradesOrCommentsToPost).toBe(false)
      })

      it('includes a callback to show the "Post Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        component.props.postGradesAction.onSelect('callback')
        expect(gradebook.postPolicies.showPostAssignmentGradesTray).toHaveBeenCalledTimes(1)
      })

      it('includes the assignment id when showing the "Post Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        component.props.postGradesAction.onSelect('callback')
        const [{assignmentId}] =
          gradebook.postPolicies.showPostAssignmentGradesTray.mock.calls[
            gradebook.postPolicies.showPostAssignmentGradesTray.mock.calls.length - 1
          ]
        expect(assignmentId).toBe('2301')
      })

      it('includes the `onSelect` callback when showing the "Post Assignment Grades" tray', () => {
        const onSelectCallback = jest.fn()
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        component.props.postGradesAction.onSelect(onSelectCallback)
        const [{onExited}] =
          gradebook.postPolicies.showPostAssignmentGradesTray.mock.calls[
            gradebook.postPolicies.showPostAssignmentGradesTray.mock.calls.length - 1
          ]
        expect(onExited).toBe(onSelectCallback)
      })
    })

    describe('"Hide grades" action', () => {
      beforeEach(() => {
        gradebook.postPolicies.showHideAssignmentGradesTray = jest.fn()
      })

      it('sets hasGradesOrPostableComments to true if at least one submission is graded', () => {
        submission.workflow_state = 'graded'
        submission.score = 1
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.hideGradesAction.hasGradesOrPostableComments).toBe(true)
      })

      it('sets hasGradesOrPostableComments to true if at least one submission has postable comments', () => {
        submission.has_postable_comments = true
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.hideGradesAction.hasGradesOrPostableComments).toBe(true)
      })

      it('sets hasGradesOrPostableComments to false if no submissions are graded or have comments', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.hideGradesAction.hasGradesOrPostableComments).toBe(false)
      })

      it.skip('sets hasGradesOrCommentsToHide to true if at least one submission has a posted_at date', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.hideGradesAction.hasGradesOrCommentsToHide).toBe(true)
      })

      it('sets hasGradesOrCommentsToHide to false if no submission has a posted_at date', () => {
        submission.posted_at = null
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        expect(component.props.hideGradesAction.hasGradesOrCommentsToHide).toBe(false)
      })

      it('includes a callback to show the "Hide Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        component.props.hideGradesAction.onSelect('callback')
        expect(gradebook.postPolicies.showHideAssignmentGradesTray).toHaveBeenCalledTimes(1)
      })

      it('includes the assignment id when showing the "Hide Assignment Grades" tray', () => {
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        component.props.hideGradesAction.onSelect('callback')
        const [{assignmentId}] =
          gradebook.postPolicies.showHideAssignmentGradesTray.mock.calls[
            gradebook.postPolicies.showHideAssignmentGradesTray.mock.calls.length - 1
          ]
        expect(assignmentId).toBe('2301')
      })

      it('includes the `onSelect` callback when showing the "Hide Assignment Grades" tray', () => {
        const onSelectCallback = jest.fn()
        gradebook.gotChunkOfStudents([student])
        renderComponent()
        component.props.hideGradesAction.onSelect(onSelectCallback)
        const [{onExited}] =
          gradebook.postPolicies.showHideAssignmentGradesTray.mock.calls[
            gradebook.postPolicies.showHideAssignmentGradesTray.mock.calls.length - 1
          ]
        expect(onExited).toBe(onSelectCallback)
      })
    })

    describe('"Grade Posting Policy" action', () => {
      beforeEach(() => {
        gradebook.postPolicies.showAssignmentPostingPolicyTray = jest.fn()
      })

      it('includes a callback to show the "Grade Posting Policy" tray', () => {
        renderComponent()
        component.props.showGradePostingPolicyAction.onSelect('callback')
        expect(gradebook.postPolicies.showAssignmentPostingPolicyTray).toHaveBeenCalledTimes(1)
      })

      it('includes the assignment id when showing the "Grade Posting Policy" tray', () => {
        renderComponent()
        component.props.showGradePostingPolicyAction.onSelect('callback')
        const [{assignmentId}] =
          gradebook.postPolicies.showAssignmentPostingPolicyTray.mock.calls[
            gradebook.postPolicies.showAssignmentPostingPolicyTray.mock.calls.length - 1
          ]
        expect(assignmentId).toBe('2301')
      })

      it('includes the `onSelect` callback when showing the "Grade Posting Policy" tray', () => {
        const onSelectCallback = jest.fn()
        renderComponent()
        component.props.showGradePostingPolicyAction.onSelect(onSelectCallback)
        const [{onExited}] =
          gradebook.postPolicies.showAssignmentPostingPolicyTray.mock.calls[
            gradebook.postPolicies.showAssignmentPostingPolicyTray.mock.calls.length - 1
          ]
        expect(onExited).toBe(onSelectCallback)
      })
    })

    it('student submissions for the assignment include "excused"', () => {
      buildGradebook()
      submission.excused = true
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.excused).toBe(true)
    })

    it('"excused" is false if the student does not have a submission', () => {
      buildGradebook()
      submission.excused = true
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.excused).toBe(false)
    })

    it('student submissions for the assignment include "latePolicyStatus"', () => {
      buildGradebook()
      submission.late_policy_status = 'missing'
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.latePolicyStatus).toBe('missing')
    })

    it('"latePolicyStatus" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.late_policy_status = 'missing'
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.latePolicyStatus).toBeNull()
    })

    it('student submissions for the assignment include "score"', () => {
      buildGradebook()
      submission.score = 9
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.score).toBe(9)
    })

    it('"score" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.score = 9
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.score).toBeNull()
    })

    it('student submissions for the assignment include "submittedAt"', () => {
      buildGradebook()
      const submittedAt = new Date('Mon Nov 3 2016')
      submission.submitted_at = submittedAt
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.submittedAt).toBe(submittedAt)
    })

    it('"submittedAt" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.submitted_at = new Date('Mon Nov 3 2016')
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.submittedAt).toBeNull()
    })

    it('student submissions for the assignment include "postedAt"', () => {
      buildGradebook()
      const postedAt = new Date('Mon Nov 3 2016')
      submission.posted_at = postedAt
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.postedAt).toBe(postedAt)
    })

    it('"postedAt" is null if the student does not have a submission', () => {
      buildGradebook()
      submission.postedAt = new Date('Mon Nov 3 2016')
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.submission.postedAt).toBeNull()
    })

    it('"isTestStudent" is true if the student is enrolled via a StudentViewEnrollment', () => {
      buildGradebook()
      student.enrollments = [{type: 'StudentViewEnrollment'}]
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.isTestStudent).toBe(true)
    })

    it('"isTestStudent" is false if the student is not enrolled via a StudentViewEnrollment', () => {
      buildGradebook()
      student.enrollments = [{type: 'StudentEnrollment'}]
      gradebook.gotChunkOfStudents([student])
      renderComponent()
      const studentProp = component.props.allStudents.find(s => s.id === student.id)
      expect(studentProp.isTestStudent).toBe(false)
    })

    it.skip('getCurrentlyShownStudents() fetches students using visibleStudentsThatCanSeeAssignment', () => {
      buildGradebook()
      gradebook.visibleStudentsThatCanSeeAssignment = jest
        .fn()
        .mockReturnValue({[student.id]: student})

      renderComponent()
      const visibleStudents = component.props.getCurrentlyShownStudents()
      expect(Object.keys(visibleStudents)).toEqual([student.id])
    })

    it('includes a callback for keyDown events', () => {
      buildGradebook()
      gradebook.handleHeaderKeyDown = jest.fn()
      renderComponent()
      component.props.onHeaderKeyDown({})
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledTimes(1)
    })

    it.skip('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      buildGradebook()
      const exampleEvent = new Event('example')
      gradebook.handleHeaderKeyDown = jest.fn()
      renderComponent()
      component.props.onHeaderKeyDown(exampleEvent)
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledWith(exampleEvent)
    })

    it('calls Gradebook#handleHeaderKeyDown with the column id', () => {
      buildGradebook()
      gradebook.handleHeaderKeyDown = jest.fn()
      renderComponent()
      component.props.onHeaderKeyDown({})
      expect(gradebook.handleHeaderKeyDown).toHaveBeenCalledWith(expect.any(Object), column.id)
    })

    it.skip('includes a callback for closing the column header menu', () => {
      buildGradebook()
      gradebook.handleColumnHeaderMenuClose = jest.fn()
      renderComponent()
      component.props.onMenuDismiss()
      expect(gradebook.handleColumnHeaderMenuClose).toHaveBeenCalledTimes(1)
    })

    it('does not call the menu close handler synchronously', () => {
      // The React render lifecycle is not yet complete at this time.
      // The callback must begin after React finishes to avoid conflicts.
      jest.useFakeTimers()
      buildGradebook()
      gradebook.handleColumnHeaderMenuClose = jest.fn()
      renderComponent()
      component.props.onMenuDismiss()
      expect(gradebook.handleColumnHeaderMenuClose).not.toHaveBeenCalled()
      jest.runAllTimers()
      jest.useRealTimers()
    })

    it('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      buildGradebook()
      gradebook.keyboardNav.removeGradebookElement = jest.fn()
      renderComponent()
      component.props.removeGradebookElement()
      expect(gradebook.keyboardNav.removeGradebookElement).toHaveBeenCalledTimes(1)
    })

    it('includes the reupload submissions action', () => {
      buildGradebook()
      gradebook.getReuploadSubmissionsAction = jest.fn().mockReturnValue('ReuploadAction')
      renderComponent()
      expect(component.props.reuploadSubmissionsAction).toBe('ReuploadAction')
    })

    it('includes the set default grade action', () => {
      buildGradebook()
      gradebook.getSetDefaultGradeAction = jest.fn().mockReturnValue('SetDefaultGradeAction')
      renderComponent()
      expect(component.props.setDefaultGradeAction).toBe('SetDefaultGradeAction')
    })

    it('includes the "Sort by" direction setting', () => {
      buildGradebook()
      renderComponent()
      expect(component.props.sortBySetting.direction).toBe('ascending')
    })

    it('sets the "Sort by" disabled setting to true when assignments are not loaded', () => {
      buildGradebook()
      gradebook.contentLoadStates.assignmentsLoaded.all = false
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to true when anonymize_students is true', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      assignment.anonymize_students = true
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(false)
      gradebook.setSubmissionsLoaded(true)
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to true when submissions are not loaded', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(true)
    })

    it('sets the "Sort by" disabled setting to false when necessary data are loaded', () => {
      buildGradebook()
      gradebook.setAssignmentsLoaded()
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      renderComponent()
      expect(component.props.sortBySetting.disabled).toBe(false)
    })

    it('sets the "Sort by" isSortColumn setting to true when sorting by this column', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      expect(component.props.sortBySetting.isSortColumn).toBe(true)
    })

    it('sets the "Sort by" isSortColumn setting to false when not sorting by this column', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      renderComponent()
      expect(component.props.sortBySetting.isSortColumn).toBe(false)
    })

    it('includes the onSortByGradeAscending callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortByGradeAscending()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'grade'}
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortByGradeDescending callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortByGradeDescending()
      const expectedSetting = {columnId: column.id, direction: 'descending', settingKey: 'grade'}
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortByLate callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortByLate()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'late'}
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the onSortByMissing callback', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      component.props.sortBySetting.onSortByMissing()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'missing'}
      expect(gradebook.getSortRowsBySetting()).toEqual(expectedSetting)
    })

    it('includes the "Sort by" settingKey', () => {
      buildGradebook()
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      renderComponent()
      expect(component.props.sortBySetting.settingKey).toBe('grade')
    })

    it('sets showMessageStudentsWithObserversDialog to true if enabled in gradebook', () => {
      buildGradebook()
      gradebook.options.show_message_students_with_observers_dialog = true
      renderComponent()
      expect(component.props.showMessageStudentsWithObserversDialog).toBe(true)
    })

    it('sets showMessageStudentsWithObserversDialog to false if not enabled in gradebook', () => {
      buildGradebook()
      gradebook.options.show_message_students_with_observers_dialog = false
      renderComponent()
      expect(component.props.showMessageStudentsWithObserversDialog).toBe(false)
    })

    it('sends message when handleSendMessageStudentsWho is executed', () => {
      const recipientsIds = [1, 2, 3, 4]
      const subject = 'foo'
      const body = 'bar'
      const contextCode = '1'

      buildGradebook()
      gradebook.sendMessageStudentsWho = jest.fn()
      renderComponent()
      component.props.onSendMessageStudentsWho(recipientsIds, subject, body, contextCode)
      expect(gradebook.sendMessageStudentsWho).toHaveBeenCalledTimes(1)
    })
  })

  describe('#destroy()', () => {
    it('unmounts the component', () => {
      buildGradebook()
      renderComponent()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      expect(removed).toBe(false) // the component was already unmounted
    })
  })
})
