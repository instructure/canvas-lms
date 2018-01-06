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

import { createGradebook, setFixtureHtml } from 'spec/jsx/gradezilla/default_gradebook/GradebookSpecHelper';
import AssignmentCellFormatter from 'jsx/gradezilla/default_gradebook/slick-grid/formatters/AssignmentCellFormatter';

QUnit.module('AssignmentCellFormatter', function (hooks) {
  let $fixture;
  let gradebook;
  let formatter;
  let student;
  let submission;
  let submissionState;

  hooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);
    setFixtureHtml($fixture);

    gradebook = createGradebook();
    formatter = new AssignmentCellFormatter(gradebook);
    gradebook.setAssignments({
      2301: { id: '2301', name: 'Algebra 1', grading_type: 'points', points_possible: 10 }
    });

    student = { id: '1101', loaded: true, initialized: true };
    submission = {
      assignment_id: '2301',
      grade: '8',
      id: '2501',
      score: 8,
      submission_type: 'online_text_entry',
      user_id: '1101',
      workflow_state: 'active'
    };
    submissionState = { hideGrade: false };

    const getSubmissionState = gradebook.submissionStateMap.getSubmissionState.bind(gradebook.submissionStateMap);
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').callsFake(getSubmissionState);
    gradebook.submissionStateMap.getSubmissionState.withArgs(submission).returns(submissionState);
  });

  hooks.afterEach(function () {
    gradebook.submissionStateMap.getSubmissionState.restore();
    $fixture.remove();
  });

  function renderCell () {
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      submission, // value
      null, // column definition
      student // dataContext
    );
    return $fixture.querySelector('.gradebook-cell');
  }

  function excuseSubmission () {
    submission.grade = null;
    submission.score = null;
    submission.excused = true;
  }

  QUnit.module('#render');

  test('includes the "dropped" style when the submission is dropped', function () {
    submission.drop = true;
    ok(renderCell().classList.contains('dropped'));
  });

  test('includes the "excused" style when the submission is excused', function () {
    excuseSubmission();
    ok(renderCell().classList.contains('excused'));
  });

  test('includes the "resubmitted" style when the current grade does not match the submission grade', function () {
    submission.grade_matches_current_submission = false;
    ok(renderCell().classList.contains('resubmitted'));
  });

  test('includes the "missing" style when the submission is missing', function () {
    submission.missing = true;
    ok(renderCell().classList.contains('missing'));
  });

  test('excludes the "missing" style when the submission is both dropped and missing', function () {
    submission.drop = true;
    submission.missing = true;
    notOk(renderCell().classList.contains('missing'));
  });

  test('excludes the "missing" style when the submission is both excused and missing', function () {
    excuseSubmission();
    submission.missing = true;
    notOk(renderCell().classList.contains('missing'));
  });

  test('excludes the "missing" style when the submission is both resubmitted and missing', function () {
    submission.grade_matches_current_submission = false;
    submission.missing = true;
    notOk(renderCell().classList.contains('missing'));
  });

  test('includes the "late" style when the submission is late', function () {
    submission.late = true;
    ok(renderCell().classList.contains('late'));
  });

  test('excludes the "late" style when the submission is both dropped and late', function () {
    submission.drop = true;
    submission.late = true;
    notOk(renderCell().classList.contains('late'));
  });

  test('excludes the "late" style when the submission is both excused and late', function () {
    excuseSubmission();
    submission.late = true;
    notOk(renderCell().classList.contains('late'));
  });

  test('excludes the "late" style when the submission is both resubmitted and late', function () {
    submission.grade_matches_current_submission = false;
    submission.late = true;
    notOk(renderCell().classList.contains('late'));
  });

  test('excludes the "late" style when the submission is both missing and late', function () {
    submission.missing = true;
    submission.late = true;
    notOk(renderCell().classList.contains('late'));
  });

  test('renders an empty cell when the student is not loaded', function () {
    student.loaded = false;
    strictEqual(renderCell().innerHTML, '');
  });

  test('renders an empty cell when the student is not initialized', function () {
    student.initialized = false;
    strictEqual(renderCell().innerHTML, '');
  });

  test('renders an empty cell when the submission is not defined', function () {
    submission = undefined;
    strictEqual(renderCell().innerHTML, '');
  });

  test('renders an empty cell when the submission state is not defined', function () {
    gradebook.submissionStateMap.getSubmissionState.withArgs(submission).returns(undefined);
    strictEqual(renderCell().innerHTML, '');
  });

  test('renders an empty cell when the submission has a hidden grade', function () {
    submissionState.hideGrade = true;
    strictEqual(renderCell().innerHTML, '');
  });

  test('renders a grayed-out cell when the student enrollment is inactive', function () {
    student.isInactive = true;
    const $cell = renderCell();
    ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"');
  });

  test('renders an uneditable cell when the student enrollment is concluded', function () {
    student.isConcluded = true;
    const $cell = renderCell();
    ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"');
  });

  test('renders an uneditable cell when the submission has a hidden grade', function () {
    submissionState.hideGrade = true;
    const $cell = renderCell();
    ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"');
  });

  test('renders an uneditable cell when the submission cannot be graded', function () {
    submissionState.locked = true;
    const $cell = renderCell();
    ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"');
  });

  test('includes the "turnitin" class when the submission has Turnitin data', function () {
    submission.turnitin_data = { submission_2501: { state: 'acceptable' } };
    ok(renderCell().classList.contains('turnitin'));
  });

  test('renders the turnitin score when the submission has Turnitin data', function () {
    submission.turnitin_data = { submission_2501: { state: 'acceptable' } };
    strictEqual(renderCell().querySelectorAll('.gradebook-cell-turnitin.acceptable-score').length, 1);
  });

  test('includes the "turnitin" class when the submission has Vericite data', function () {
    submission.vericite_data = { submission_2501: { state: 'acceptable' } };
    ok(renderCell().classList.contains('turnitin'));
  });

  test('renders the turnitin score when the submission has Turnitin data', function () {
    submission.turnitin_data = { submission_2501: { state: 'acceptable' } };
    strictEqual(renderCell().querySelectorAll('.gradebook-cell-turnitin.acceptable-score').length, 1);
  });

  test('includes the "ungraded" class when the assignment is not graded', function () {
    gradebook.getAssignment('2301').submission_types = ['not_graded'];
    ok(renderCell().classList.contains('ungraded'));
  });

  test('includes the "muted" class when the assignment is muted', function () {
    gradebook.getAssignment('2301').muted = true;
    ok(renderCell().classList.contains('muted'));
  });

  QUnit.module('#render with a "points" assignment submission', {
    setup () {
      gradebook.getAssignment('2301').grading_type = 'points';
    }
  });

  test('renders the score converted to a points string', function () {
    strictEqual(renderCell().innerHTML.trim(), '8');
  });

  test('renders the "needs grading" icon when the submission was graded and cleared', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'graded';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission was resubmitted', function () {
    submission.workflow_state = 'submitted';
    submission.grade_matches_current_submission = false;
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission is ungraded and pending review', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders "Excused" when the submission is excused', function () {
    excuseSubmission();
    strictEqual(renderCell().innerHTML.trim(), 'Excused');
  });

  QUnit.module('#render with a "percent" assignment submission', {
    setup () {
      gradebook.getAssignment('2301').grading_type = 'percent';
    }
  });

  test('renders the score converted to a percentage', function () {
    strictEqual(renderCell().innerHTML.trim(), '80%');
  });

  test('renders the "needs grading" icon when the submission was graded and cleared', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'graded';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission was resubmitted', function () {
    submission.workflow_state = 'submitted';
    submission.grade_matches_current_submission = false;
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission is ungraded and pending review', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders "Excused" when the submission is excused', function () {
    excuseSubmission();
    strictEqual(renderCell().innerHTML.trim(), 'Excused');
  });

  QUnit.module('#render with a "letter grade" assignment submission', {
    setup () {
      gradebook.getAssignment('2301').grading_type = 'letter_grade';
      submission.score = 9;
    }
  });

  test('renders the score converted to a letter grade', function () {
    strictEqual(renderCell().firstChild.wholeText.trim(), 'A');
  });

  test('renders the grade when the assignment has no points possible', function () {
    gradebook.getAssignment('2301').points_possible = 0;
    submission.grade = 'A';
    submission.score = 0;
    strictEqual(renderCell().firstChild.wholeText.trim(), 'A');
  });

  test('renders the "needs grading" icon when the submission was graded and cleared', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'graded';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission was resubmitted', function () {
    submission.workflow_state = 'submitted';
    submission.grade_matches_current_submission = false;
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission is ungraded and pending review', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders "Excused" when the submission is excused', function () {
    excuseSubmission();
    strictEqual(renderCell().innerHTML.trim(), 'Excused');
  });

  QUnit.module('#render with a "complete/incomplete" assignment submission', {
    setup () {
      gradebook.getAssignment('2301').grading_type = 'pass_fail';
      submission.grade = 'Complete (i18n)';
      submission.rawGrade = 'complete';
      submission.score = 10;
    }
  });

  test('renders a checkmark when the grade is "complete"', function () {
    strictEqual(renderCell().querySelectorAll('button i.icon-check').length, 1);
  });

  test('renders a checkmark when the grade is "incomplete"', function () {
    submission.grade = 'Incomplete (i18n)';
    submission.rawGrade = 'incomplete';
    submission.score = 0;
    strictEqual(renderCell().querySelectorAll('button i.icon-x').length, 1);
  });

  test('renders an emdash "–" when the submission is unsubmitted', function () {
    submission.grade = null;
    submission.rawGrade = null;
    submission.score = null;
    submission.submission_type = null;
    equal(renderCell().firstChild.wholeText.trim(), '–');
  });

  test('renders the "needs grading" icon when the submission was graded and cleared', function () {
    submission.grade = null;
    submission.rawGrade = null;
    submission.score = null;
    submission.workflow_state = 'graded';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission was resubmitted', function () {
    submission.workflow_state = 'submitted';
    submission.grade_matches_current_submission = false;
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission is pending review', function () {
    submission.grade = null;
    submission.rawGrade = null;
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders "Excused" when the submission is excused', function () {
    excuseSubmission();
    equal(renderCell().innerHTML.trim(), 'Excused');
  });

  QUnit.module('#render with a "GPA Scale" assignment submission', {
    setup () {
      gradebook.getAssignment('2301').grading_type = 'gpa_scale';
      submission.score = 9;
    }
  });

  test('renders the score converted to a letter grade', function () {
    strictEqual(renderCell().innerHTML.trim(), 'A');
  });

  test('renders the "needs grading" icon when the submission was graded and cleared', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'graded';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission was resubmitted', function () {
    submission.workflow_state = 'submitted';
    submission.grade_matches_current_submission = false;
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission is pending review', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders "Excused" when the submission is excused', function () {
    excuseSubmission();
    strictEqual(renderCell().innerHTML.trim(), 'Excused');
  });

  QUnit.module('#render with a quiz submission', {
    setup () {
      gradebook.getAssignment('2301').grading_type = 'points';
      submission.submission_type = 'online_quiz';
    }
  });

  test('renders the score converted to a points string', function () {
    strictEqual(renderCell().innerHTML.trim(), '8');
  });

  test('renders the "needs grading" icon when the submission was graded and cleared', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'graded';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the "needs grading" icon when the submission was resubmitted', function () {
    submission.workflow_state = 'submitted';
    submission.grade_matches_current_submission = false;
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the quiz icon when the submission is ungraded and pending review', function () {
    submission.grade = null;
    submission.score = null;
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders the quiz icon when the submission is partially graded and pending review', function () {
    submission.workflow_state = 'pending_review';
    strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1);
  });

  test('renders "Excused" when the submission is excused', function () {
    excuseSubmission();
    strictEqual(renderCell().innerHTML.trim(), 'Excused');
  });
});
