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

import ReactDOM from 'react-dom';
import { createGradebook, setFixtureHtml } from '../../GradebookSpecHelper';
import AssignmentColumnHeaderRenderer
from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/AssignmentColumnHeaderRenderer'

QUnit.module('AssignmentColumnHeaderRenderer', function (suiteHooks) {
  let $container;
  let gradebook;
  let assignment;
  let column;
  let component;
  let renderer;
  let student;
  let submission;

  function render () {
    renderer.render(column, $container, {} /* gridSupport */, { ref (ref) { component = ref } });
  }

  suiteHooks.beforeEach(function () {
    $container = document.createElement('div');
    document.body.appendChild($container);
    setFixtureHtml($container);

    gradebook = createGradebook();
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
    };

    submission =  {
      id: '93',
      assignment_id: '2301',
      excused: false,
      late_policy_status: null,
      score: null,
      submitted_at: null,
      user_id: '441'
    };

    student = {
      id: '441',
      assignment_2301: submission,
      isInactive: false,
      name: 'Guy B. Studying',
      enrollments: [{ type: 'StudentEnrollment', user_id: '441', course_section_id: '1' }]
    };

    gradebook.gotAllAssignmentGroups([
      { id: '2201', position: 1, name: 'Assignments', assignments: [assignment] }
    ]);

    column = { id: gradebook.getAssignmentColumnId('2301'), assignmentId: '2301' };
    renderer = new AssignmentColumnHeaderRenderer(gradebook);
  });

  suiteHooks.afterEach(function() {
    $container.remove();
  });

  QUnit.module('#render', function () {
    test('renders the AssignmentColumnHeader to the given container node', function () {
      render();
      ok($container.innerText.includes('Math Assignment'), 'the "Math Assignment" header is rendered');
    });

    test('calls the "ref" callback option with the component reference', function () {
      render();
      equal(component.constructor.name, 'AssignmentColumnHeader');
    });

    test('includes a callback for adding elements to the Gradebook KeyboardNav', function () {
      sinon.stub(gradebook.keyboardNav, 'addGradebookElement');
      render();
      component.props.addGradebookElement();
      strictEqual(gradebook.keyboardNav.addGradebookElement.callCount, 1);
    });

    test('includes the assignment course id', function () {
      render();
      strictEqual(component.props.assignment.courseId, '1201');
    });

    test('includes the assignment html url', function () {
      render();
      equal(component.props.assignment.htmlUrl, '/assignments/2301');
    });

    test('includes the assignment id', function () {
      render();
      strictEqual(component.props.assignment.id, '2301');
    });

    test('includes the assignment muted status when true', function () {
      assignment.muted = true;
      render();
      strictEqual(component.props.assignment.muted, true);
    });

    test('includes the assignment muted status when false', function () {
      assignment.muted = false;
      render();
      strictEqual(component.props.assignment.muted, false);
    });

    test('includes the assignment name', function () {
      render();
      equal(component.props.assignment.name, 'Math Assignment');
    });

    test('includes the assignment points possible', function () {
      assignment.points_possible = 10;
      render();
      strictEqual(component.props.assignment.pointsPossible, 10);
    });

    test('includes the assignment published status for a published assignment', function () {
      assignment.published = true;
      render();
      strictEqual(component.props.assignment.published, true);
    });

    test('includes the assignment published status for an unpublished assignment', function () {
      assignment.published = false;
      render();
      strictEqual(component.props.assignment.published, false);
    });

    test('includes the assignment submission types', function () {
      render();
      deepEqual(component.props.assignment.submissionTypes, ['online_text_entry']);
    });

    test('includes the curve grades action', function () {
      sinon.spy(gradebook, 'getCurveGradesAction');
      render();
      equal(component.props.curveGradesAction, gradebook.getCurveGradesAction.returnValues[0]);
    });

    test('includes the download submissions action', function () {
      sinon.spy(gradebook, 'getDownloadSubmissionsAction');
      render();
      equal(component.props.downloadSubmissionsAction, gradebook.getDownloadSubmissionsAction.returnValues[0]);
    });

    test('the anonymizeStudents prop is `true` when the assignment is anonymous', function () {
      assignment.anonymize_students = true
      render()
      strictEqual(component.props.assignment.anonymizeStudents, true)
    })

    test('the anonymizeStudents prop is `false` when the assignment is not anonymous', function () {
      render()
      strictEqual(component.props.assignment.anonymizeStudents, false)
    })

    test('shows the "enter grades as" setting for a "points" assignment', function () {
      assignment.grading_type = 'points';
      render();
      strictEqual(component.props.enterGradesAsSetting.hidden, false);
    });

    test('shows the "enter grades as" setting for a "percent" assignment', function () {
      assignment.grading_type = 'percent';
      render();
      strictEqual(component.props.enterGradesAsSetting.hidden, false);
    });

    test('shows the "enter grades as" setting for a "letter grade" assignment', function () {
      assignment.grading_type = 'letter_grade';
      render();
      strictEqual(component.props.enterGradesAsSetting.hidden, false);
    });

    test('shows the "enter grades as" setting for a "GPA scale" assignment', function () {
      assignment.grading_type = 'gpa_scale';
      render();
      strictEqual(component.props.enterGradesAsSetting.hidden, false);
    });

    test('hides the "enter grades as" setting for a "pass/fail" assignment', function () {
      assignment.grading_type = 'pass_fail';
      render();
      strictEqual(component.props.enterGradesAsSetting.hidden, true);
    });

    test('hides the "enter grades as" setting for a "not graded" assignment', function () {
      assignment.grading_type = 'not_graded';
      render();
      strictEqual(component.props.enterGradesAsSetting.hidden, true);
    });

    test('includes a callback for changing the "enter grades as" setting', function () {
      sinon.stub(gradebook, 'updateEnterGradesAsSetting');
      render();
      component.props.enterGradesAsSetting.onSelect('percent');
      strictEqual(gradebook.updateEnterGradesAsSetting.callCount, 1);
    });

    test('includes the assignment id when changing the "enter grades as" setting', function () {
      sinon.stub(gradebook, 'updateEnterGradesAsSetting');
      render();
      component.props.enterGradesAsSetting.onSelect('percent');
      const assignmentId = gradebook.updateEnterGradesAsSetting.lastCall.args[0];
      strictEqual(assignmentId, '2301');
    });

    test('includes the new setting when changing the "enter grades as" setting', function () {
      sinon.stub(gradebook, 'updateEnterGradesAsSetting');
      render();
      component.props.enterGradesAsSetting.onSelect('percent');
      const assignmentId = gradebook.updateEnterGradesAsSetting.lastCall.args[1];
      equal(assignmentId, 'percent');
    });

    test('uses the current "enter grades as" setting for the assignment', function () {
      gradebook.setEnterGradesAsSetting('2301', 'percent');
      render();
      equal(component.props.enterGradesAsSetting.selected, 'percent');
    });

    test('hides the "enter grades as" grading scheme option for a "points" assignment', function () {
      assignment.grading_type = 'points';
      render();
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, false);
    });

    test('hides the "enter grades as" grading scheme option for a "percent" assignment', function () {
      assignment.grading_type = 'percent';
      render();
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, false);
    });

    test('shows the "enter grades as" grading scheme option for a "letter grade" assignment', function () {
      assignment.grading_type = 'letter_grade';
      render();
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, true);
    });

    test('shows the "enter grades as" grading scheme option for a "GPA scale" assignment', function () {
      assignment.grading_type = 'gpa_scale';
      render();
      strictEqual(component.props.enterGradesAsSetting.showGradingSchemeOption, true);
    });

    test('includes the mute assignment action', function () {
      sinon.spy(gradebook, 'getMuteAssignmentAction');
      render();
      equal(component.props.muteAssignmentAction, gradebook.getMuteAssignmentAction.returnValues[0]);
    });

    test('student submissions for the assignment include "excused"', function () {
      submission.excused = true;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.excused, true);
    });

    test('"excused" is false if the student does not have a submission', function () {
      submission.excused = true;
      delete student.assignment_2301;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.excused, false);
    });

    test('student submissions for the assignment include "latePolicyStatus"', function () {
      submission.late_policy_status = 'missing';
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.latePolicyStatus, 'missing');
    });

    test('"latePolicyStatus" is null if the student does not have a submission', function () {
      submission.late_policy_status = 'missing';
      delete student.assignment_2301;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.latePolicyStatus, null);
    });

    test('student submissions for the assignment include "score"', function () {
      submission.score = 9;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.score, 9);
    });

    test('"score" is null if the student does not have a submission', function () {
      submission.score = 9;
      delete student.assignment_2301;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.score, null);
    });

    test('student submissions for the assignment include "submittedAt"', function () {
      const submittedAt = new Date("Mon Nov 3 2016");
      submission.submitted_at = submittedAt;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.submittedAt, submittedAt);
    });

    test('"submittedAt" is null if the student does not have a submission', function () {
      submission.submittedAt = new Date("Mon Nov 3 2016");
      delete student.assignment_2301;
      gradebook.gotChunkOfStudents([student]);
      render();
      const studentProp = component.props.students.find(s => s.id === student.id);
      strictEqual(studentProp.submission.submittedAt, null);
    });

    test('includes a callback for keyDown events', function () {
      sinon.stub(gradebook, 'handleHeaderKeyDown');
      render();
      component.props.onHeaderKeyDown({});
      strictEqual(gradebook.handleHeaderKeyDown.callCount, 1);
    });

    test('calls Gradebook#handleHeaderKeyDown with a given event', function () {
      const exampleEvent = new Event('example');
      sinon.stub(gradebook, 'handleHeaderKeyDown');
      render();
      component.props.onHeaderKeyDown(exampleEvent);
      const event = gradebook.handleHeaderKeyDown.lastCall.args[0];
      equal(event, exampleEvent);
    });

    test('calls Gradebook#handleHeaderKeyDown with a given event', function () {
      sinon.stub(gradebook, 'handleHeaderKeyDown');
      render();
      component.props.onHeaderKeyDown({});
      const columnId = gradebook.handleHeaderKeyDown.lastCall.args[1];
      equal(columnId, column.id);
    });

    test('includes a callback for closing the column header menu', function () {
      sinon.stub(gradebook, 'handleColumnHeaderMenuClose');
      render();
      component.props.onMenuDismiss();
      strictEqual(gradebook.handleColumnHeaderMenuClose.callCount, 1);
    });

    test('includes a callback for removing elements to the Gradebook KeyboardNav', function () {
      sinon.stub(gradebook.keyboardNav, 'removeGradebookElement');
      render();
      component.props.removeGradebookElement();
      strictEqual(gradebook.keyboardNav.removeGradebookElement.callCount, 1);
    });

    test('includes the reupload submissions action', function () {
      sinon.spy(gradebook, 'getReuploadSubmissionsAction');
      render();
      equal(component.props.reuploadSubmissionsAction, gradebook.getReuploadSubmissionsAction.returnValues[0]);
    });

    test('includes the set default grade action', function () {
      sinon.spy(gradebook, 'getSetDefaultGradeAction');
      render();
      equal(component.props.setDefaultGradeAction, gradebook.getSetDefaultGradeAction.returnValues[0]);
    });

    test('shows the "unposted" menu setting when "new gradebook development" is enabled', function () {
      gradebook.options.new_gradebook_development_enabled = true;
      render();
      strictEqual(component.props.showUnpostedMenuItem, true);
    });

    test('does not show the "unposted" menu setting when "new gradebook development" is disabled', function () {
      gradebook.options.new_gradebook_development_enabled = false;
      render();
      strictEqual(component.props.showUnpostedMenuItem, false);
    });

    test('includes the "Sort by" direction setting', function () {
      render();
      equal(component.props.sortBySetting.direction, 'ascending');
    });

    test('sets the "Sort by" disabled setting to true when assignments are not loaded', function () {
      gradebook.setAssignmentsLoaded(false);
      gradebook.setStudentsLoaded(true);
      gradebook.setSubmissionsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to true when students are not loaded', function () {
      gradebook.setAssignmentsLoaded(true);
      gradebook.setStudentsLoaded(false);
      gradebook.setSubmissionsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to true when submissions are not loaded', function () {
      gradebook.setAssignmentsLoaded(true);
      gradebook.setStudentsLoaded(true);
      gradebook.setSubmissionsLoaded(false);
      render();
      strictEqual(component.props.sortBySetting.disabled, true);
    });

    test('sets the "Sort by" disabled setting to false when necessary data are loaded', function () {
      gradebook.setAssignmentsLoaded(true);
      gradebook.setStudentsLoaded(true);
      gradebook.setSubmissionsLoaded(true);
      render();
      strictEqual(component.props.sortBySetting.disabled, false);
    });

    test('sets the "Sort by" isSortColumn setting to true when sorting by this column', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      strictEqual(component.props.sortBySetting.isSortColumn, true);
    });

    test('sets the "Sort by" isSortColumn setting to false when not sorting by this column', function () {
      gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending');
      render();
      strictEqual(component.props.sortBySetting.isSortColumn, false);
    });

    test('includes the onSortByGradeAscending callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByGradeAscending();
      const expectedSetting = { columnId: column.id, direction: 'ascending', settingKey: 'grade' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the onSortByGradeDescending callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByGradeDescending();
      const expectedSetting = { columnId: column.id, direction: 'descending', settingKey: 'grade' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the onSortByLate callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByLate();
      const expectedSetting = { columnId: column.id, direction: 'ascending', settingKey: 'late' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the onSortByMissing callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByMissing();
      const expectedSetting = { columnId: column.id, direction: 'ascending', settingKey: 'missing' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the onSortByUnposted callback', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      component.props.sortBySetting.onSortByUnposted();
      const expectedSetting = { columnId: column.id, direction: 'ascending', settingKey: 'unposted' };
      deepEqual(gradebook.getSortRowsBySetting(), expectedSetting);
    });

    test('includes the "Sort by" settingKey', function () {
      gradebook.setSortRowsBySetting('assignment_2301', 'grade', 'ascending');
      render();
      equal(component.props.sortBySetting.settingKey, 'grade');
    });
  });

  QUnit.module('#destroy', function () {
    test('unmounts the component', function () {
      render();
      renderer.destroy({}, $container);
      const removed = ReactDOM.unmountComponentAtNode($container);
      strictEqual(removed, false, 'the component was already unmounted');
    });
  });
});
