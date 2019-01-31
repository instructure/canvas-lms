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
import {createGradebook, setFixtureHtml} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'
import AssignmentColumnHeaderRenderer from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/AssignmentColumnHeaderRenderer'

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
        }
      }
    )
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    setFixtureHtml($container)

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
      published: true,
      submission_types: ['online_text_entry']
    }

    submission = {
      id: '93',
      assignment_id: '2301',
      excused: false,
      late_policy_status: null,
      score: null,
      submitted_at: null,
      user_id: '441'
    }

    student = {
      id: '441',
      assignment_2301: submission,
      isInactive: false,
      name: 'Guy B. Studying',
      enrollments: [{type: 'StudentEnrollment', user_id: '441', course_section_id: '1'}]
    }

    gradebook.gotAllAssignmentGroups([
      {id: '2201', position: 1, name: 'Assignments', assignments: [assignment]}
    ])

    column = {id: gradebook.getAssignmentColumnId('2301'), assignmentId: '2301'}
    renderer = new AssignmentColumnHeaderRenderer(gradebook)
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  QUnit.module('#render()', () => {
    test('renders the AssignmentColumnHeader to the given container node', () => {
      render()
      ok(
        $container.innerText.includes('Math Assignment'),
        'the "Math Assignment" header is rendered'
      )
    })

    test('calls the "ref" callback option with the component reference', () => {
      render()
      equal(component.constructor.name, 'AssignmentColumnHeader')
    })

    test('includes a callback for adding elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement')
      render()
      component.props.addGradebookElement()
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1)
    })

    test('includes the assignment course id', () => {
      render()
      strictEqual(component.props.assignment.courseId, '1201')
    })

    test('includes the assignment html url', () => {
      render()
      equal(component.props.assignment.htmlUrl, '/assignments/2301')
    })

    test('includes the assignment id', () => {
      render()
      strictEqual(component.props.assignment.id, '2301')
    })

    test('includes the assignment muted status when true', () => {
      assignment.muted = true
      render()
      strictEqual(component.props.assignment.muted, true)
    })

    test('includes the assignment muted status when false', () => {
      assignment.muted = false
      render()
      strictEqual(component.props.assignment.muted, false)
    })

    test('includes the assignment name', () => {
      render()
      equal(component.props.assignment.name, 'Math Assignment')
    })

    test('includes the assignment points possible', () => {
      assignment.points_possible = 10
      render()
      strictEqual(component.props.assignment.pointsPossible, 10)
    })

    test('includes the assignment published status for a published assignment', () => {
      assignment.published = true
      render()
      strictEqual(component.props.assignment.published, true)
    })

    test('includes the assignment published status for an unpublished assignment', () => {
      assignment.published = false
      render()
      strictEqual(component.props.assignment.published, false)
    })

    test('includes the assignment submission types', () => {
      render()
      deepEqual(component.props.assignment.submissionTypes, ['online_text_entry'])
    })

    test('includes the curve grades action', () => {
      sinon.spy(gradebook, 'getCurveGradesAction')
      render()
      equal(component.props.curveGradesAction, gradebook.getCurveGradesAction.returnValues[0])
    })

    test('includes the download submissions action', () => {
      sinon.spy(gradebook, 'getDownloadSubmissionsAction')
      render()
      equal(
        component.props.downloadSubmissionsAction,
        gradebook.getDownloadSubmissionsAction.returnValues[0]
      )
    })

    test('the anonymizeStudents prop is `true` when the assignment is anonymous', () => {
      assignment.anonymize_students = true
      render()
      strictEqual(component.props.assignment.anonymizeStudents, true)
    })

    test('the anonymizeStudents prop is `false` when the assignment is not anonymous', () => {
      render()
      strictEqual(component.props.assignment.anonymizeStudents, false)
    })

    test('shows the "enter grades as" setting for a "points" assignment', () => {
      assignment.grading_type = 'points'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('shows the "enter grades as" setting for a "percent" assignment', () => {
      assignment.grading_type = 'percent'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('shows the "enter grades as" setting for a "letter grade" assignment', () => {
      assignment.grading_type = 'letter_grade'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('shows the "enter grades as" setting for a "GPA scale" assignment', () => {
      assignment.grading_type = 'gpa_scale'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, false)
    })

    test('hides the "enter grades as" setting for a "pass/fail" assignment', () => {
      assignment.grading_type = 'pass_fail'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, true)
    })

    test('hides the "enter grades as" setting for a "not graded" assignment', () => {
      assignment.grading_type = 'not_graded'
      render()
      strictEqual(component.props.enterGradesAsSetting.hidden, true)
    })

    test('includes a callback for changing the "enter grades as" setting', () => {
      sinon.stub(gradebook, 'updateEnterGradesAsSetting')
      render()
      component.props.enterGradesAsSetting.onSelect('percent')
      strictEqual(gradebook.updateEnterGradesAsSetting.callCount, 1)
    })

    test('includes the assignment id when changing the "enter grades as" setting', () => {
      sinon.stub(gradebook, 'updateEnterGradesAsSetting')
      render()
      component.props.enterGradesAsSetting.onSelect('percent')
      const assignmentId = gradebook.updateEnterGradesAsSetting.lastCall.args[0]
      strictEqual(assignmentId, '2301')
    })

    test('includes the new setting when changing the "enter grades as" setting', () => {
      sinon.stub(gradebook, 'updateEnterGradesAsSetting')
      render()
      component.props.enterGradesAsSetting.onSelect('percent')
      const assignmentId = gradebook.updateEnterGradesAsSetting.lastCall.args[1]
      equal(assignmentId, 'percent')
    })

    test('uses the current "enter grades as" setting for the assignment', () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      render()
      equal(component.props.enterGradesAsSetting.selected, 'percent')
    })

    test('hides the "enter grades as" grading scheme option for a "points" assignment', () => {
      assignment.grading_type = 'points'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, false)
    })

    test('hides the "enter grades as" grading scheme option for a "percent" assignment', () => {
      assignment.grading_type = 'percent'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, false)
    })

    test('shows the "enter grades as" grading scheme option for a "letter grade" assignment', () => {
      assignment.grading_type = 'letter_grade'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, true)
    })

    test('shows the "enter grades as" grading scheme option for a "GPA scale" assignment', () => {
      assignment.grading_type = 'gpa_scale'
      render()
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, true)
    })

    test('includes the mute assignment action', () => {
      sinon.spy(gradebook, 'getMuteAssignmentAction')
      render()
      equal(component.props.muteAssignmentAction, gradebook.getMuteAssignmentAction.returnValues[0])
    })

    test('student submissions for the assignment include "excused"', () => {
      submission.excused = true
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.excused, true)
    })

    test('"excused" is false if the student does not have a submission', () => {
      submission.excused = true
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.excused, false)
    })

    test('student submissions for the assignment include "latePolicyStatus"', () => {
      submission.late_policy_status = 'missing'
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.latePolicyStatus, 'missing')
    })

    test('"latePolicyStatus" is null if the student does not have a submission', () => {
      submission.late_policy_status = 'missing'
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.latePolicyStatus, null)
    })

    test('student submissions for the assignment include "score"', () => {
      submission.score = 9
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.score, 9)
    })

    test('"score" is null if the student does not have a submission', () => {
      submission.score = 9
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.score, null)
    })

    test('student submissions for the assignment include "submittedAt"', () => {
      const submittedAt = new Date('Mon Nov 3 2016')
      submission.submitted_at = submittedAt
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.submittedAt, submittedAt)
    })

    test('"submittedAt" is null if the student does not have a submission', () => {
      submission.submittedAt = new Date('Mon Nov 3 2016')
      delete student.assignment_2301
      gradebook.gotChunkOfStudents([student])
      render()
      const studentProp = component.props.students.find(s => s.id === student.id)
      strictEqual(studentProp.submission.submittedAt, null)
    })

    test('includes a callback for keyDown events', () => {
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      strictEqual(gradebook.handleHeaderKeyDown.callCount, 1)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      const exampleEvent = new Event('example')
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown(exampleEvent)
      const event = gradebook.handleHeaderKeyDown.lastCall.args[0]
      equal(event, exampleEvent)
    })

    test('calls Gradebook#handleHeaderKeyDown with a given event', () => {
      sinon.stub(gradebook, 'handleHeaderKeyDown')
      render()
      component.props.onHeaderKeyDown({})
      const columnId = gradebook.handleHeaderKeyDown.lastCall.args[1]
      equal(columnId, column.id)
    })

    test('includes a callback for closing the column header menu', () => {
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
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose')
      render()
      component.props.onMenuDismiss()
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 0)
      clock.restore()
    })

    test('includes a callback for removing elements to the Gradebook KeyboardNav', () => {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement')
      render()
      component.props.removeGradebookElement()
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1)
    })

    test('includes the reupload submissions action', () => {
      sinon.spy(gradebook, 'getReuploadSubmissionsAction')
      render()
      equal(
        component.props.reuploadSubmissionsAction,
        gradebook.getReuploadSubmissionsAction.returnValues[0]
      )
    })

    test('includes the set default grade action', () => {
      sinon.spy(gradebook, 'getSetDefaultGradeAction')
      render()
      equal(
        component.props.setDefaultGradeAction,
        gradebook.getSetDefaultGradeAction.returnValues[0]
      )
    })

    test('shows the "unposted" menu setting when "new gradebook development" is enabled', () => {
      gradebook.options.new_gradebook_development_enabled = true
      render()
      strictEqual(component.props.showUnpostedMenuItem, true)
    })

    test('does not show the "unposted" menu setting when "new gradebook development" is disabled', () => {
      gradebook.options.new_gradebook_development_enabled = false
      render()
      strictEqual(component.props.showUnpostedMenuItem, false)
    })

    test('includes the "Sort by" direction setting', () => {
      render()
      equal(component.props.sortBySetting.direction, 'ascending')
    })

    test('sets the "Sort by" disabled setting to true when assignments are not loaded', () => {
      gradebook.setAssignmentsLoaded(false)
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when anonymize_students is true', () => {
      gradebook.setAssignmentsLoaded(true)
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      assignment.anonymize_students = true
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when students are not loaded', () => {
      gradebook.setAssignmentsLoaded(true)
      gradebook.setStudentsLoaded(false)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to true when submissions are not loaded', () => {
      gradebook.setAssignmentsLoaded(true)
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(false)
      render()
      strictEqual(component.props.sortBySetting.disabled, true)
    })

    test('sets the "Sort by" disabled setting to false when necessary data are loaded', () => {
      gradebook.setAssignmentsLoaded(true)
      gradebook.setStudentsLoaded(true)
      gradebook.setSubmissionsLoaded(true)
      render()
      strictEqual(component.props.sortBySetting.disabled, false)
    })

    test('sets the "Sort by" isSortColumn setting to true when sorting by this column', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, true)
    })

    test('sets the "Sort by" isSortColumn setting to false when not sorting by this column', () => {
      gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending')
      render()
      strictEqual(component.props.sortBySetting.isSortColumn, false)
    })

    test('includes the onSortByGradeAscending callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByGradeAscending()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'grade'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByGradeDescending callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByGradeDescending()
      const expectedSetting = {columnId: column.id, direction: 'descending', settingKey: 'grade'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByLate callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByLate()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'late'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByMissing callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByMissing()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'missing'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the onSortByUnposted callback', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      component.props.sortBySetting.onSortByUnposted()
      const expectedSetting = {columnId: column.id, direction: 'ascending', settingKey: 'unposted'}
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting)
    })

    test('includes the "Sort by" settingKey', () => {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending')
      render()
      equal(component.props.sortBySetting.settingKey, 'grade')
    })
  })

  QUnit.module('#destroy()', () => {
    test('unmounts the component', () => {
      render()
      renderer.destroy({}, $container)
      const removed = ReactDOM.unmountComponentAtNode($container)
      strictEqual(removed, false, 'the component was already unmounted')
    })
  })
})
/* eslint-enable qunit/no-identical-names */
