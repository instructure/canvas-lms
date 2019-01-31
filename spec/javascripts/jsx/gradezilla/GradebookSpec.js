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

import $ from 'jquery';
import _ from 'underscore';
import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';
import moxios from 'moxios';
import qs from 'qs';
import fakeENV from 'helpers/fakeENV';
import UserSettings from 'compiled/userSettings';
import natcompare from 'compiled/util/natcompare';
import round from 'compiled/util/round';
import * as FlashAlert from 'jsx/shared/FlashAlert';
import ActionMenu from 'jsx/gradezilla/default_gradebook/components/ActionMenu';
import CourseGradeCalculator from 'jsx/gradebook/CourseGradeCalculator';
import DataLoader from 'jsx/gradezilla/DataLoader';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import AnonymousSpeedGraderAlert from 'jsx/gradezilla/default_gradebook/components/AnonymousSpeedGraderAlert'
import GradebookApi from 'jsx/gradezilla/default_gradebook/apis/GradebookApi';
import LatePolicyApplicator from 'jsx/grading/LatePolicyApplicator';
import SubmissionStateMap from 'jsx/gradezilla/SubmissionStateMap';
import studentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/studentRowHeaderConstants';
import { darken, statusColors, defaultColors } from 'jsx/gradezilla/default_gradebook/constants/colors';
import ViewOptionsMenu from 'jsx/gradezilla/default_gradebook/components/ViewOptionsMenu';

import { createGradebook, stubDataLoader } from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper';
import { createCourseGradesWithGradingPeriods as createGrades } from '../gradebook/GradeCalculatorSpecHelper';

const $fixtures = document.getElementById('fixtures');

QUnit.module('Gradebook');

test('normalizes the grading period set from the env', function () {
  const options = {
    grading_period_set: {
      id: '1501',
      grading_periods: [
        { id: '701', weight: 50 },
        { id: '702', weight: 50 }
      ],
      weighted: true
    }
  };
  const gradingPeriodSet = createGradebook(options).gradingPeriodSet;
  deepEqual(gradingPeriodSet.id, '1501');
  equal(gradingPeriodSet.gradingPeriods.length, 2);
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702']);
});

test('sets grading period set to null when not defined in the env', function () {
  const gradingPeriodSet = createGradebook().gradingPeriodSet;
  deepEqual(gradingPeriodSet, null);
});

test('when sections are loaded and there is no secondary info configured, set it to "section"', function () {
  const sections = [
    { id: 1, name: 'Section 1' },
    { id: 2, name: 'Section 2' },
  ];
  const gradebook = createGradebook({ sections });

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'section');
});

test('when one section is loaded and there is no secondary info configured, set it to "none"', function () {
  const sections = [
    { id: 1, name: 'Section 1' },
  ];
  const gradebook = createGradebook({ sections });

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'none');
});

test('when zero sections are loaded and there is no secondary info configured, set it to "none"', function () {
  const sections = [];
  const gradebook = createGradebook({ sections });

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'none');
});

test('when sections are loaded and there is secondary info configured, do not change it', function () {
  const sections = [
    { id: 1, name: 'Section 1' },
    { id: 2, name: 'Section 2' },
  ];
  const settings = {
    student_column_secondary_info: 'login_id'
  }
  const gradebook = createGradebook({ sections, settings });

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'login_id');
});

test('when one section is loaded and there is secondary info configured, do not change it', function () {
  const sections = [
    { id: 1, name: 'Section 1' },
  ];
  const settings = {
    student_column_secondary_info: 'login_id'
  }
  const gradebook = createGradebook({ sections, settings });

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'login_id');
});

test('when zero sections are loaded and there is secondary info configured, do not change it', function () {
  const sections = [];
  const settings = {
    student_column_secondary_info: 'login_id'
  }
  const gradebook = createGradebook({ sections, settings });

  strictEqual(gradebook.getSelectedSecondaryInfo(), 'login_id');
});

test('initializes content load state for context modules to false', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.contentLoadStates.contextModulesLoaded, false);
});

test('initializes a submission state map', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.submissionStateMap.constructor, SubmissionStateMap);
});

test('sets the submission state map .hasGradingPeriods to true when a grading period set exists', function () {
  const gradebook = createGradebook({
    grading_period_set: { id: '1501', grading_periods: [{ id: '701' }, { id: '702' }] }
  });
  strictEqual(gradebook.submissionStateMap.hasGradingPeriods, true);
});

test('sets the submission state map .selectedGradingPeriodID to the "grading period to show"', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.submissionStateMap.selectedGradingPeriodID, gradebook.getGradingPeriodToShow());
});

test('adds teacher notes to custom columns when provided', function () {
  const teacherNotes = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false };
  const gradebook = createGradebook({ teacher_notes: teacherNotes });
  deepEqual(gradebook.gradebookContent.customColumns, [teacherNotes]);
});

test('custom columns remain empty when teacher notes are not provided', function () {
  const gradebook = createGradebook();
  deepEqual(gradebook.gradebookContent.customColumns, []);
});

QUnit.module('Gradebook#gotCustomColumnDataChunk', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.students = {
      1101: { id: '1101', assignment_201: {}, assignment_202: {} },
      1102: { id: '1102', assignment_201: {} }
    };
    sandbox.stub(this.gradebook, 'invalidateRowsForStudentIds')
  }
});

test('updates students with custom column data', function () {
  const data = [{ user_id: '1101', content: 'example' }, { user_id: '1102', content: 'sample' }];
  this.gradebook.gotCustomColumnDataChunk('2401', data);
  equal(this.gradebook.students[1101].custom_col_2401, 'example');
  equal(this.gradebook.students[1102].custom_col_2401, 'sample');
});

test('invalidates rows for related students', function () {
  const data = [{ user_id: '1101', content: 'example' }, { user_id: '1102', content: 'sample' }];
  this.gradebook.gotCustomColumnDataChunk('2401', data);
  strictEqual(this.gradebook.invalidateRowsForStudentIds.callCount, 1);
  const [studentIds] = this.gradebook.invalidateRowsForStudentIds.lastCall.args;
  deepEqual(studentIds, ['1101', '1102'], 'both students had custom column data');
});

test('ignores students without custom column data', function () {
  const data = [{ user_id: '1102', content: 'sample' }];
  this.gradebook.gotCustomColumnDataChunk('2401', data);
  const [studentIds] = this.gradebook.invalidateRowsForStudentIds.lastCall.args;
  deepEqual(studentIds, ['1102'], 'only the student 1102 had custom column data');
});

test('invalidates rows after updating students', function () {
  const data = [{ user_id: '1101', content: 'example' }, { user_id: '1102', content: 'sample' }];
  this.gradebook.invalidateRowsForStudentIds.callsFake(() => {
    equal(this.gradebook.students[1101].custom_col_2401, 'example');
    equal(this.gradebook.students[1102].custom_col_2401, 'sample');
  });
  this.gradebook.gotCustomColumnDataChunk('2401', data);
});

QUnit.module('Gradebook - initial .gridDisplaySettings');

test('sets .filterColumnsBy.assignmentGroupId to the value from the given settings', function () {
  const gradebook = createGradebook({ settings: { filter_columns_by: { assignment_group_id: '2201' } } });
  strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2201');
});

test('sets .filterColumnsBy.contextModuleId to the value from the given settings', function () {
  const gradebook = createGradebook({ settings: { filter_columns_by: { context_module_id: '2601' } } });
  strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), '2601');
});

test('sets .filterColumnsBy.gradingPeriodId to the value from the given settings', function () {
  const gradebook = createGradebook({ settings: { filter_columns_by: { grading_period_id: '1401' } } });
  strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1401');
});

test('sets .filterColumnsBy.sectionId to the value from the given settings', function () {
  const gradebook = createGradebook({ settings: { filter_columns_by: { section_id: '2001' } } });
  strictEqual(gradebook.getFilterColumnsBySetting('sectionId'), '2001');
});

test('defaults .filterColumnsBy.assignmentGroupId to null when not present in the given settings', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), null);
});

test('defaults .filterColumnsBy.contextModuleId to null when not present in the given settings', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), null);
});

test('defaults .filterColumnsBy.gradingPeriodId to null when not present in the given settings', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), null);
});

test('defaults .filterRowsBy.sectionId to null when not present in the given settings', function () {
  const gradebook = createGradebook();
  strictEqual(gradebook.getFilterRowsBySetting('sectionId'), null);
});

test('updates partial .filterColumnsBy settings with the default values', function () {
  const gradebook = createGradebook({ settings: { filter_columns_by: { assignment_group_id: '2201' } } });
  strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2201');
  strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), null);
  strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), null);
});

QUnit.module('Gradebook#initialize', {
  setup () {
    stubDataLoader()
    $fixtures.innerHTML = `
      <div id="search-filter-container">
        <input type="text" />
      </div>
    `;
  },

  createInitializedGradebook (options) {
    const gradebook = createGradebook(options);
    gradebook.initialize();
    return gradebook;
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('stores the late policy with camelized keys, if one exists', function () {
  const gradebook = this.createInitializedGradebook({ late_policy: { late_submission_interval: 'hour' } });
  deepEqual(gradebook.courseContent.latePolicy, { lateSubmissionInterval: 'hour' });
});

test('stores the late policy as undefined if the late_policy option is null', function () {
  const gradebook = this.createInitializedGradebook({ late_policy: null });
  strictEqual(gradebook.courseContent.latePolicy, undefined);
});

test('sets assignmentGroupsLoaded to false', function () {
  const gradebook = this.createInitializedGradebook()
  strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, false)
})

QUnit.module('Gradebook#gotChunkOfStudents', {
  setup () {
    const placeholderStudent = { id: '1101' };
    this.gradebook = createGradebook();
    this.gradebook.courseContent.students.addUserStudents([placeholderStudent]);
    this.gradebook.gridData.rows.push(placeholderStudent);
    sandbox.stub(this.gradebook.gradebookGrid, 'render');
    this.students = [
      {
        id: '1101',
        name: 'Adam Jones',
        enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }]
      },
      {
        id: '1102',
        name: 'Betty Ford',
        enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }]
      },
      {
        id: '1199',
        name: 'Test Student',
        enrollments: [{ type: 'StudentViewEnrollment', grades: { html_url: 'http://example.url/' } }]
      }
    ];
  }
});

test('updates the student map with each student', function () {
  this.gradebook.gotChunkOfStudents(this.students);
  ok(this.gradebook.students[1101], 'student map includes Adam Jones');
  ok(this.gradebook.students[1102], 'student map includes Betty Ford');
});

test('replaces matching students in the student map', function () {
  this.gradebook.gotChunkOfStudents(this.students);
  equal(this.gradebook.students[1101].name, 'Adam Jones');
});

test('updates the test student map with each test student', function () {
  this.gradebook.gotChunkOfStudents(this.students);
  ok(this.gradebook.studentViewStudents[1199], 'test student map includes Test Student');
});

test('replaces matching students in the test student map', function () {
  this.gradebook.courseContent.students.addTestStudents([{ id: '1199' }]);
  this.gradebook.gotChunkOfStudents(this.students);
  equal(this.gradebook.studentViewStudents[1199].name, 'Test Student');
});

test('updates attributes of each student', function () {
  this.gradebook.gotChunkOfStudents(this.students);
  strictEqual(this.gradebook.students[1101].isConcluded, false, 'isConcluded is set to false');
  strictEqual(this.gradebook.students[1101].isInactive, false, 'isInactive is set to false');
});

test('updates the row for each student', function () {
  this.gradebook.gotChunkOfStudents(this.students);
  strictEqual(this.gradebook.gridData.rows[0], this.students[0]);
});

test('builds rows when filtering with search', function () {
  this.gradebook.userFilterTerm = 'searching';
  sandbox.stub(this.gradebook, 'buildRows');
  this.gradebook.gotChunkOfStudents(this.students);
  strictEqual(this.gradebook.buildRows.callCount, 1);
});

test('does not build rows when not filtering with search', function () {
  sandbox.stub(this.gradebook, 'buildRows');
  this.gradebook.gotChunkOfStudents(this.students);
  strictEqual(this.gradebook.buildRows.callCount, 0);
});

test('renders the grid when not filtering with search', function () {
  this.gradebook.gotChunkOfStudents(this.students);
  strictEqual(this.gradebook.gradebookGrid.render.callCount, 1);
});

QUnit.module('Gradebook#calculateStudentGrade', {
  createGradebook (options = {}) {
    const gradebook = createGradebook({
      group_weighting_scheme: 'points'
    });
    const assignments = [
      { id: '201', points_possible: 10, omit_from_final_grade: false }
    ];
    Object.assign(gradebook, {
      assignmentGroups: [
        { id: '301', group_weight: 60, rules: {}, assignments }
      ],
      gradingPeriods: [
        { id: '701', weight: 50 },
        { id: '702', weight: 50 }
      ],
      gradingPeriodSet: {
        id: '1501',
        gradingPeriods: [
          { id: '701', weight: 50 },
          { id: '702', weight: 50 }
        ],
        weighted: true
      },
      effectiveDueDates: {
        201: {
          101: { grading_period_id: '701' }
        }
      },
      submissionsForStudent: () => this.submissions,
      ...options
    });
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
    return gradebook;
  },

  setup () {
    this.exampleGrades = createGrades();
    this.submissions = [{ assignment_id: 201, score: 10 }];
  }
});

test('calculates grades using properties from the gradebook', function () {
  const gradebook = this.createGradebook();
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true
  });
  const args = CourseGradeCalculator.calculate.getCall(0).args;
  equal(args[0], this.submissions);
  equal(args[1], gradebook.assignmentGroups);
  equal(args[2], gradebook.options.group_weighting_scheme);
  equal(args[3], gradebook.gradingPeriodSet);
});

test('scopes effective due dates to the user', function () {
  const gradebook = this.createGradebook();
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true
  });
  const dueDates = CourseGradeCalculator.calculate.getCall(0).args[4];
  deepEqual(dueDates, {
    201: {
      grading_period_id: '701'
    }
  });
});

test('calculates grades without grading period data when grading period set is null', function () {
  const gradebook = this.createGradebook({
    gradingPeriodSet: null
  });
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true
  });
  const args = CourseGradeCalculator.calculate.getCall(0).args;
  equal(args[0], this.submissions);
  equal(args[1], gradebook.assignmentGroups);
  equal(args[2], gradebook.options.group_weighting_scheme);
  equal(typeof args[3], 'undefined');
  equal(typeof args[4], 'undefined');
});

test('calculates grades without grading period data when effective due dates are not defined', function () {
  const gradebook = this.createGradebook({
    effectiveDueDates: null
  });
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: true
  });
  const args = CourseGradeCalculator.calculate.getCall(0).args;
  equal(args[0], this.submissions);
  equal(args[1], gradebook.assignmentGroups);
  equal(args[2], gradebook.options.group_weighting_scheme);
  equal(typeof args[3], 'undefined');
  equal(typeof args[4], 'undefined');
});

test('stores the current grade on the student when not including ungraded assignments', function () {
  const gradebook = this.createGradebook({
    include_ungraded_assignments: false
  });
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  gradebook.calculateStudentGrade(student);
  equal(student.total_grade, this.exampleGrades.current);
});

test('stores the final grade on the student when including ungraded assignments', function () {
  const gradebook = this.createGradebook({
    include_ungraded_assignments: true
  });
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  gradebook.calculateStudentGrade(student);
  equal(student.total_grade, this.exampleGrades.final);
});

test('stores the current grade from the selected grading period when not including ungraded assignments', function () {
  const gradebook = this.createGradebook({
    include_ungraded_assignments: false
  });
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701');
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  gradebook.calculateStudentGrade(student);
  equal(student.total_grade, this.exampleGrades.gradingPeriods[701].current);
});

test('stores the final grade from the selected grading period when including ungraded assignments', function () {
  const gradebook = this.createGradebook({
    include_ungraded_assignments: true
  });
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701');
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(this.exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  gradebook.calculateStudentGrade(student);
  equal(student.total_grade, this.exampleGrades.gradingPeriods[701].final);
});

test('does not calculate when the student is not loaded', function () {
  const gradebook = this.createGradebook();
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: false,
    initialized: true
  });
  notOk(CourseGradeCalculator.calculate.called);
});

test('does not calculate when the student is not initialized', function () {
  const gradebook = this.createGradebook();
  sandbox.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  gradebook.calculateStudentGrade({
    id: '101',
    loaded: true,
    initialized: false
  });
  notOk(CourseGradeCalculator.calculate.called);
});

QUnit.module('Gradebook#getStudentGradeForColumn');

test('returns the grade stored on the student for the column id', function () {
  const student = { total_grade: { score: 5, possible: 10 } };
  const grade = createGradebook().getStudentGradeForColumn(student, 'total_grade');
  equal(grade, student.total_grade);
});

test('returns an empty grade when the student has no grade for the column id', function () {
  const student = { total_grade: undefined };
  const grade = createGradebook().getStudentGradeForColumn(student, 'total_grade');
  strictEqual(grade.score, null, 'grade has a null score');
  strictEqual(grade.possible, 0, 'grade has no points possible');
});

QUnit.module('Gradebook#getGradeAsPercent');

test('returns a percent for a grade with points possible', function () {
  const percent = createGradebook().getGradeAsPercent({ score: 5, possible: 10 });
  equal(percent, 0.5);
});

test('returns null for a grade with no points possible', function () {
  const percent = createGradebook().getGradeAsPercent({ score: 5, possible: 0 });
  strictEqual(percent, null);
});

test('returns 0 for a grade with a null score', function () {
  const percent = createGradebook().getGradeAsPercent({ score: null, possible: 10 });
  strictEqual(percent, 0);
});

test('returns 0 for a grade with an undefined score', function () {
  const percent = createGradebook().getGradeAsPercent({ score: undefined, possible: 10 });
  strictEqual(percent, 0);
});

QUnit.module('Gradebook#localeSort');

test('delegates to natcompare.strings', function () {
  sandbox.spy(natcompare, 'strings');
  const gradebook = createGradebook();
  gradebook.localeSort('a', 'b');
  equal(natcompare.strings.callCount, 1);
  deepEqual(natcompare.strings.getCall(0).args, ['a', 'b']);
});

test('substitutes falsy args with empty string', function () {
  sandbox.spy(natcompare, 'strings');
  const gradebook = createGradebook();
  gradebook.localeSort(0, false);
  equal(natcompare.strings.callCount, 1);
  deepEqual(natcompare.strings.getCall(0).args, ['', '']);
});

QUnit.module('Gradebook#gradeSort by an assignment', {
  setup () {
    this.studentA = { id: '1', sortable_name: 'A, Student', assignment_201: { score: 10, possible: 20 } };
    this.studentB = { id: '2', sortable_name: 'B, Student', assignment_201: { score: 6, possible: 10 } };
    this.gradebook = createGradebook();
  }
});

test('sorts by score', function () {
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true);
  // a positive value indicates reversing the order of inputs
  strictEqual(comparison, 4, 'studentA with the higher score is ordered second');
});

test('optionally sorts in descending order', function () {
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false);
  // a negative value indicates preserving the order of inputs
  equal(comparison, -4, 'studentA with the higher score is ordered first');
});

test('returns -1 when sorted by sortable name where scores are the same', function () {
  const score = 10;
  this.studentA.assignment_201.score = score;
  this.studentB.assignment_201.score = score;
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true);
  strictEqual(comparison, -1);
});

test('returns 1 when sorted by sortable name descending where scores are the same and sorting by descending', function () {
  const score = 10;
  this.studentA.assignment_201.score = score;
  this.studentB.assignment_201.score = score;
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false);
  strictEqual(comparison, 1);
});

test('returns -1 when sorted by id where scores and sortable names are the same', function () {
  const score = 10;
  this.studentA.assignment_201.score = score;
  this.studentB.assignment_201.score = score;
  const name = 'Same Name';
  this.studentA.sortable_name = name;
  this.studentB.sortable_name = name;
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true);
  strictEqual(comparison, -1);
});

test('returns 1 when descending sorted by id where where scores and sortable names are the same and sorting by descending', function () {
  const score = 10;
  this.studentA.assignment_201.score = score;
  this.studentB.assignment_201.score = score;
  const name = 'Same Name';
  this.studentA.sortable_name = name;
  this.studentB.sortable_name = name;
  const comparison = this.gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false);
  strictEqual(comparison, 1);
});

QUnit.module('Gradebook#gradeSort by an assignment group', {
  setup () {
    this.studentA = { assignment_group_301: { score: 10, possible: 20 } };
    this.studentB = { assignment_group_301: { score: 6, possible: 10 } };
  }
});

test('always sorts by percent', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: false });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_group_301', true);
  // a negative value indicates preserving the order of inputs
  equal(round(comparison, 1), -0.1, 'studentB with the higher percent is ordered second');
});

test('optionally sorts in descending order', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: true });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_group_301', false);
  // a positive value indicates reversing the order of inputs
  equal(round(comparison, 1), 0.1, 'studentB with the higher percent is ordered first');
});

test('sorts grades with no points possible at lowest priority', function () {
  this.studentA.assignment_group_301.possible = 0;
  const gradebook = createGradebook({ show_total_grade_as_points: false });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_group_301', true);
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second');
});

test('sorts grades with no points possible at lowest priority in descending order', function () {
  this.studentA.assignment_group_301.possible = 0;
  const gradebook = createGradebook({ show_total_grade_as_points: false });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_group_301', false);
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second');
});

QUnit.module('Gradebook#gradeSort by "total_grade"', {
  setup () {
    this.studentA = { total_grade: { score: 10, possible: 20 } };
    this.studentB = { total_grade: { score: 6, possible: 10 } };
  }
});

test('sorts by percent when not showing total grade as points', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: false });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', true);
  // a negative value indicates preserving the order of inputs
  equal(round(comparison, 1), -0.1, 'studentB with the higher percent is ordered second');
});

test('sorts percent grades with no points possible at lowest priority', function () {
  this.studentA.total_grade.possible = 0;
  const gradebook = createGradebook({ show_total_grade_as_points: false });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', true);
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second');
});

test('sorts percent grades with no points possible at lowest priority in descending order', function () {
  this.studentA.total_grade.possible = 0;
  const gradebook = createGradebook({ show_total_grade_as_points: false });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', false);
  // a value of 1 indicates reversing the order of inputs
  equal(comparison, 1, 'studentA with no points possible is ordered second');
});

test('sorts by score when showing total grade as points', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: true });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', true);
  // a positive value indicates reversing the order of inputs
  equal(comparison, 4, 'studentA with the higher score is ordered second');
});

test('optionally sorts in descending order', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: true });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'total_grade', false);
  // a negative value indicates preserving the order of inputs
  equal(comparison, -4, 'studentA with the higher score is ordered first');
});

QUnit.module('Gradebook#hideAggregateColumns', {
  createGradebook () {
    const gradebook = createGradebook({
      all_grading_periods_totals: false
    });
    gradebook.gradingPeriodSet = { id: '1', gradingPeriods: [{ id: '701' }, { id: '702' }] };
    return gradebook;
  }
});

test('returns false if there are no grading periods', function () {
  const gradebook = this.createGradebook();
  gradebook.gradingPeriodSet = null;
  notOk(gradebook.hideAggregateColumns());
});

test('returns false if there are no grading periods, even if isAllGradingPeriods is true', function () {
  const gradebook = this.createGradebook();
  gradebook.gradingPeriodSet = null;
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
  notOk(gradebook.hideAggregateColumns());
});

test('returns false if "All Grading Periods" is not selected', function () {
  const gradebook = this.createGradebook();
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701');
  notOk(gradebook.hideAggregateColumns());
});

test('returns true if "All Grading Periods" is selected', function () {
  const gradebook = this.createGradebook();
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
  ok(gradebook.hideAggregateColumns());
});

test('returns false if "All Grading Periods" is selected and the grading period set has' +
  '"Display Totals for All Grading Periods option" enabled', function () {
  const gradebook = this.createGradebook();
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
  gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true;
  notOk(gradebook.hideAggregateColumns());
});

QUnit.module('Gradebook#makeColumnSortFn', {
  sortOrder (sortType, direction) {
    return {
      sortType,
      direction
    }
  },

  setup () {
    this.gradebook = createGradebook();
    sandbox.stub(this.gradebook, 'wrapColumnSortFn');
    sandbox.stub(this.gradebook, 'compareAssignmentPositions');
    sandbox.stub(this.gradebook, 'compareAssignmentDueDates');
    sandbox.stub(this.gradebook, 'compareAssignmentNames');
    sandbox.stub(this.gradebook, 'compareAssignmentPointsPossible');
    sandbox.stub(this.gradebook, 'compareAssignmentModulePositions');
  }
});

test('wraps compareAssignmentPositions when called with a sortType of assignment_group', function () {
  this.gradebook.makeColumnSortFn(this.sortOrder('assignment_group', 'ascending'));
  const expectedArgs = [this.gradebook.compareAssignmentPositions, 'ascending'];

  strictEqual(this.gradebook.wrapColumnSortFn.callCount, 1);
  deepEqual(this.gradebook.wrapColumnSortFn.firstCall.args, expectedArgs);
});

test('wraps compareAssignmentPositions when called with a sortType of alpha', function () {
  this.gradebook.makeColumnSortFn(this.sortOrder('alpha', 'descending'));
  const expectedArgs = [this.gradebook.compareAssignmentPositions, 'descending'];

  strictEqual(this.gradebook.wrapColumnSortFn.callCount, 1);
  deepEqual(this.gradebook.wrapColumnSortFn.firstCall.args, expectedArgs);
});

test('wraps compareAssignmentNames when called with a sortType of name', function () {
  this.gradebook.makeColumnSortFn(this.sortOrder('name', 'ascending'));
  const expectedArgs = [this.gradebook.compareAssignmentNames, 'ascending'];

  strictEqual(this.gradebook.wrapColumnSortFn.callCount, 1);
  deepEqual(this.gradebook.wrapColumnSortFn.firstCall.args, expectedArgs);
});

test('wraps compareAssignmentDueDates when called with a sortType of due_date', function () {
  this.gradebook.makeColumnSortFn(this.sortOrder('due_date', 'descending'));
  const expectedArgs = [this.gradebook.compareAssignmentDueDates, 'descending'];

  strictEqual(this.gradebook.wrapColumnSortFn.callCount, 1);
  deepEqual(this.gradebook.wrapColumnSortFn.firstCall.args, expectedArgs);
});

test('wraps compareAssignmentPointsPossible when called with a sortType of points', function () {
  this.gradebook.makeColumnSortFn(this.sortOrder('points', 'ascending'));
  const expectedArgs = [this.gradebook.compareAssignmentPointsPossible, 'ascending'];

  strictEqual(this.gradebook.wrapColumnSortFn.callCount, 1);
  deepEqual(this.gradebook.wrapColumnSortFn.firstCall.args, expectedArgs);
});

test('wraps compareAssignmentModulePositions when called with a sortType of module_position', function () {
  this.gradebook.makeColumnSortFn(this.sortOrder('module_position', 'ascending'));
  const expectedArgs = [this.gradebook.compareAssignmentModulePositions, 'ascending'];

  strictEqual(this.gradebook.wrapColumnSortFn.callCount, 1);
  deepEqual(this.gradebook.wrapColumnSortFn.firstCall.args, expectedArgs);
});

QUnit.module('Gradebook#wrapColumnSortFn');

test('returns -1 if second argument is of type total_grade', function () {
  const sortFn = createGradebook().wrapColumnSortFn(sinon.stub());
  equal(sortFn({}, { type: 'total_grade' }), -1);
});

test('returns 1 if first argument is of type total_grade', function () {
  const sortFn = createGradebook().wrapColumnSortFn(sinon.stub());
  equal(sortFn({ type: 'total_grade' }, {}), 1);
});

test('returns -1 if second argument is an assignment_group and the first is not', function () {
  const sortFn = createGradebook().wrapColumnSortFn(sinon.stub());
  equal(sortFn({}, { type: 'assignment_group' }), -1);
});

test('returns 1 if first arg is an assignment_group and second arg is not', function () {
  const sortFn = createGradebook().wrapColumnSortFn(sinon.stub());
  equal(sortFn({type: 'assignment_group'}, {}), 1);
});

test('returns difference in object.positions if both args are assignement_groups', function () {
  const sortFn = createGradebook().wrapColumnSortFn(sinon.stub());
  const a = { type: 'assignment_group', object: { position: 10 }};
  const b = { type: 'assignment_group', object: { position: 5 }};

  equal(sortFn(a, b), 5);
});

test('calls wrapped function when either column is not total_grade nor assignment_group', function () {
  const wrappedFn = sinon.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn);
  sortFn({}, {});
  ok(wrappedFn.called);
});

test('calls wrapped function with arguments in given order when no direction is given', function () {
  const wrappedFn = sinon.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn);
  const first = { field: 1 };
  const second = { field: 2 };
  const expectedArgs = [first, second];

  sortFn(first, second);

  strictEqual(wrappedFn.callCount, 1);
  deepEqual(wrappedFn.firstCall.args, expectedArgs);
});

test('calls wrapped function with arguments in given order when direction is ascending', function () {
  const wrappedFn = sinon.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn, 'ascending');
  const first = { field: 1 };
  const second = { field: 2 };
  const expectedArgs = [first, second];

  sortFn(first, second);

  strictEqual(wrappedFn.callCount, 1);
  deepEqual(wrappedFn.firstCall.args, expectedArgs);
});

test('calls wrapped function with arguments in reverse order when direction is descending', function () {
  const wrappedFn = sinon.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn, 'descending');
  const first = { field: 1 };
  const second = { field: 2 };
  const expectedArgs = [second, first];

  sortFn(first, second);

  strictEqual(wrappedFn.callCount, 1);
  deepEqual(wrappedFn.firstCall.args, expectedArgs);
});

QUnit.module('Gradebook#rowFilter', {
  setup () {
    this.gradebook = createGradebook();
    this.student = {
      login_id: 'charlie.xi@example.com',
      name: 'Charlie Xi',
      short_name: 'Chuck Xi',
      sortable_name: 'Xi, Charlie',
      sis_user_id: '123456789'
    };
  }
});

test('returns true when search term matches the student name', function () {
  this.gradebook.userFilterTerm = 'charlie Xi';
  strictEqual(this.gradebook.rowFilter(this.student), true);
});

test('returns true when search term matches the student login id', function () {
  this.gradebook.userFilterTerm = 'example.com';
  strictEqual(this.gradebook.rowFilter(this.student), true);
});

test('returns true when search term matches the student short name', function () {
  this.gradebook.userFilterTerm = 'chuck';
  strictEqual(this.gradebook.rowFilter(this.student), true);
});

test('returns true when search term matches the student sortable name', function () {
  this.gradebook.userFilterTerm = 'Xi, Charlie';
  strictEqual(this.gradebook.rowFilter(this.student), true);
});


test('returns true when search term matches the student sis id', function () {
  this.gradebook.userFilterTerm = '123456789';
  strictEqual(this.gradebook.rowFilter(this.student), true);
});

test('returns false when search term does not match', function () {
  this.gradebook.userFilterTerm = 'Betty';
  strictEqual(this.gradebook.rowFilter(this.student), false);
});

test('returns true when not filtering by a search term', function () {
  this.gradebook.userFilterTerm = '';
  strictEqual(this.gradebook.rowFilter(this.student), true);
});

test('returns true when search term is not defined', function () {
  this.gradebook.userFilterTerm = null;
  strictEqual(this.gradebook.rowFilter(this.student), true);
});

QUnit.module('Gradebook#makeCompareAssignmentCustomOrderFn');

test('returns position difference if both are defined in the index', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  sandbox.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'foo' };
  const b = { id: 'bar' };
  equal(sortFn(a, b), -1);
});

test('returns -1 if the first arg is in the order and the second one is not', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  sandbox.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'foo' };
  const b = { id: 'NO' };
  equal(sortFn(a, b), -1);
});

test('returns 1 if the second arg is in the order and the first one is not', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  sandbox.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'NO' };
  const b = { id: 'bar' };
  equal(sortFn(a, b), 1);
});

test('calls wrapped compareAssignmentPositions otherwise', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  sandbox.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'taco' };
  const b = { id: 'cat' };
  sortFn(a, b);
  ok(gradeBook.compareAssignmentPositions.called);
});

test('falls back to object id for the indexes if field is not in the map', function () {
  const sortOrder = { customOrder: ['5', '11'] };
  const gradeBook = createGradebook();
  sandbox.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'NO', object: { id: 5 }};
  const b = { id: 'NOPE', object: { id: 11 }};
  equal(sortFn(a, b), -1);
});

QUnit.module('Gradebook#compareAssignmentNames', {
  getRecord (name) {
    return {
      object: {
        name
      }
    };
  },

  setup () {
    this.gradebook = createGradebook();

    this.firstRecord = this.getRecord('alpha');
    this.secondRecord = this.getRecord('omega');
  }
});

test('returns -1 if the name field comes first alphabetically in the first record', function () {
  strictEqual(this.gradebook.compareAssignmentNames(this.firstRecord, this.secondRecord), -1);
});

test('returns 0 if the name field is the same in both records', function () {
  strictEqual(this.gradebook.compareAssignmentNames(this.firstRecord, this.firstRecord), 0);
});

test('returns 1 if the name field comes later alphabetically in the first record', function () {
  strictEqual(this.gradebook.compareAssignmentNames(this.secondRecord, this.firstRecord), 1);
});

test('comparison is case-sensitive between alpha and Alpha', function () {
  const thirdRecord = this.getRecord('Alpha');

  strictEqual(this.gradebook.compareAssignmentNames(thirdRecord, this.firstRecord), 1);
});

test('comparison does not group uppercase letters together', function () {
  const thirdRecord = this.getRecord('Omega');

  strictEqual(this.gradebook.compareAssignmentNames(thirdRecord, this.secondRecord), 1);
});

QUnit.module('Gradebook#compareAssignmentPointsPossible', {
  setup () {
    this.gradebook = createGradebook();
    this.firstRecord = { object: { points_possible: 1 } };
    this.secondRecord = { object: { points_possible: 2 } };
  }
});

test('returns a negative number if the points_possible field is smaller in the first record', function () {
  strictEqual(this.gradebook.compareAssignmentPointsPossible(this.firstRecord, this.secondRecord), -1);
});

test('returns 0 if the points_possible field is the same in both records', function () {
  strictEqual(this.gradebook.compareAssignmentPointsPossible(this.firstRecord, this.firstRecord), 0);
});

test('returns a positive number if the points_possible field is greater in the first record', function () {
  strictEqual(this.gradebook.compareAssignmentPointsPossible(this.secondRecord, this.firstRecord), 1);
});

QUnit.module('Gradebook#compareAssignmentModulePositions - when both records have module info', {
  createRecord (moduleId, positionInModule) {
    return {
      object: {
        module_ids: [moduleId],
        module_positions: [positionInModule],
      }
    };
  },

  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setContextModules([
      { id: '1', name: 'Module 1', position: 1 },
      { id: '2', name: 'Another Module', position: 2 },
      { id: '3', name: 'Module 2', position: 3 },
    ]);
  }
});

test("returns a negative number if the position of the first record's module comes first", function () {
  const firstRecord = this.createRecord('1', 1);
  const secondRecord = this.createRecord('2', 1);

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) < 0);
});

test("returns a positive number if the position of the first record's module comes later", function () {
  const firstRecord = this.createRecord('2', 1);
  const secondRecord = this.createRecord('1', 1);

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) > 0);
});

test('returns a negative number if within the same module the position of the first record comes first', function () {
  const firstRecord = this.createRecord('1', 1);
  const secondRecord = this.createRecord('1', 2);

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) < 0);
});

test('returns a positive number if within the same module the position of the first record comes later', function () {
  const firstRecord = this.createRecord('1', 2);
  const secondRecord = this.createRecord('1', 1);

  ok(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord) > 0);
});

test('returns a zero if both records are in the same module at the same position', function () {
  const firstRecord = this.createRecord('1', 1);
  const secondRecord = this.createRecord('1', 1);

  strictEqual(this.gradebook.compareAssignmentModulePositions(firstRecord, secondRecord), 0);
});

QUnit.module('Gradebook#compareAssignmentModulePositions - when only one record has module info', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setContextModules([
      { id: '1', name: 'Module 1', position: 1 },
    ]);
    this.firstRecord = {
      object: {
        module_ids: ['1'],
        module_positions: [1],
      }
    };
    this.secondRecord = {
      object: {
        module_ids: [],
        module_positions: [],
      }
    };
  }
});

test('returns a negative number when the first record has module information but the second does not', function () {
  ok(this.gradebook.compareAssignmentModulePositions(this.firstRecord, this.secondRecord) < 0);
});

test('returns a positive number when the first record has no module information but the second does', function () {
  ok(this.gradebook.compareAssignmentModulePositions(this.secondRecord, this.firstRecord) > 0);
});

QUnit.module('Gradebook#compareAssignmentModulePositions - when neither record has module info', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setContextModules([
      { id: '1', name: 'Module 1', position: 1 },
    ]);
    sinon.spy(this.gradebook, 'compareAssignmentPositions');

    this.firstRecord = {
      object: {
        module_ids: [],
        module_positions: [],
        assignment_group: {
          position: 1,
        },
        position: 1
      }
    };
    this.secondRecord = {
      object: {
        module_ids: [],
        module_positions: [],
        assignment_group: {
          position: 1,
        },
        position: 2
      },
    };

    this.comparisonResult = this.gradebook.compareAssignmentModulePositions(this.firstRecord, this.secondRecord);
  }
});

test('calls compareAssignmentPositions', function () {
  strictEqual(this.gradebook.compareAssignmentPositions.callCount, 1);
  deepEqual(this.gradebook.compareAssignmentPositions.getCall(0).args[0], this.firstRecord);
  deepEqual(this.gradebook.compareAssignmentPositions.getCall(0).args[1], this.secondRecord);
});

test('returns the result of compareAssignmentPositions', function () {
  strictEqual(this.comparisonResult, -1);
});

QUnit.module('Gradebook Column Order', (suiteHooks) => {
  let gradebook;

  function createWithSettings (settings) {
    gradebook = createGradebook({ gradebook_column_order_settings: settings });
    gradebook.setContextModules([
      { id: '2601', name: 'Algebra', position: 1 },
    ]);
  }

  suiteHooks.afterEach(() => {
    gradebook.destroy();
  });

  QUnit.module('initialization', () => {
    test('sets column sort direction to "ascending" when the settings are invalid', () => {
      createWithSettings({
        direction: 'descending', freezeTotalGrade: 'false', sortType: 'due_date'
      });
      equal(gradebook.getColumnOrder().direction, 'descending');
    });

    test('sets column sort type to "assignment_group" when the settings are invalid', () => {
      createWithSettings({
        direction: 'descending', freezeTotalGrade: 'false', sortType: 'due_date'
      });
      equal(gradebook.getColumnOrder().sortType, 'due_date');
    });

    test('freezes the total grade column when the setting is "true"', () => {
      createWithSettings({
        direction: 'descending', freezeTotalGrade: 'true', sortType: 'due_date'
      });
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, true);
    });

    test('does not freeze the total grade column when the setting is "false"', () => {
      createWithSettings({
        direction: 'descending', freezeTotalGrade: 'false', sortType: 'due_date'
      });
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
    });

    test('does not freeze the total grade column when the setting is not set', () => {
      createWithSettings({
        direction: 'descending', sortType: 'due_date'
      });
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
    });
  });

  QUnit.module('#setColumnOrder', (hooks) => {
    hooks.beforeEach(() => {
      createWithSettings({ direction: 'descending', sortType: 'module_position' });
    });

    test('updates "direction"', () => {
      gradebook.setColumnOrder({ direction: 'ascending', sortType: 'due_date' });
      equal(gradebook.getColumnOrder().direction, 'ascending');
    });

    test('updates "sortType"', () => {
      gradebook.setColumnOrder({ direction: 'ascending', sortType: 'due_date' });
      equal(gradebook.getColumnOrder().sortType, 'due_date');
    });

    test('does not update "direction" when not included', () => {
      gradebook.setColumnOrder({ direction: undefined, sortType: 'due_date' });
      equal(gradebook.getColumnOrder().direction, 'descending');
    });

    test('does not update "sortType" when "direction" is not included', () => {
      gradebook.setColumnOrder({ direction: undefined, sortType: 'due_date' });
      equal(gradebook.getColumnOrder().sortType, 'module_position');
    });

    test('does not update "sortType" when not included', () => {
      gradebook.setColumnOrder({ direction: 'ascending', sortType: undefined });
      equal(gradebook.getColumnOrder().sortType, 'module_position');
    });

    test('does not update "direction" when "sortType" is not included', () => {
      gradebook.setColumnOrder({ direction: 'ascending', sortType: undefined });
      equal(gradebook.getColumnOrder().direction, 'descending');
    });

    test('updates a "sortType" of "custom"', () => {
      const originalOrder = ['assignment_2301', 'total_grade'];
      gradebook.setColumnOrder({ customOrder: originalOrder, sortType: 'custom' });
      equal(gradebook.getColumnOrder().sortType, 'custom');
    });

    test('updates "customOrder" with a "sortType" of "custom"', () => {
      const customOrder = ['assignment_2301', 'total_grade'];
      gradebook.setColumnOrder({ customOrder, sortType: 'custom' });
      equal(gradebook.getColumnOrder().customOrder, customOrder);
    });

    test('does not update "sortType" of "custom" when "customOrder" is not included', () => {
      gradebook.setColumnOrder({ customOrder: undefined, sortType: 'custom' });
      equal(gradebook.getColumnOrder().sortType, 'module_position');
    });

    test('does not update "customOrder" when "sortType" is not included', () => {
      gradebook.setColumnOrder({ customOrder: ['assignment_2301', 'total_grade'], sortType: undefined });
      strictEqual(typeof gradebook.getColumnOrder().customOrder, 'undefined');
    });

    test('does not update "customOrder" when "sortType" is not "custom"', () => {
      const originalOrder = ['assignment_2301', 'total_grade'];
      gradebook.setColumnOrder({ customOrder: originalOrder, sortType: 'custom' });
      gradebook.setColumnOrder({ customOrder: ['total_grade', 'assignment_2301'], sortType: 'due_date' });
      equal(gradebook.getColumnOrder().customOrder, originalOrder);
    });

    test('updates "freezeTotalGrade"', () => {
      gradebook.setColumnOrder({ freezeTotalGrade: true });
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, true);
    });

    test('does not update "freezeTotalGrade" when not included', () => {
      gradebook.setColumnOrder({ freezeTotalGrade: undefined });
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
    });
  });

  QUnit.module('#getColumnOrder', () => {
    test('sets column sort direction to "ascending" when the settings are invalid', () => {
      createWithSettings({ sortType: 'custom' });
      equal(gradebook.getColumnOrder().direction, 'ascending');
    });

    test('sets column sort type to "assignment_group" when the settings are invalid', () => {
      createWithSettings({ sortType: 'custom' });
      equal(gradebook.getColumnOrder().sortType, 'assignment_group');
    });

    test('does not freeze the total grade column when the settings are invalid', () => {
      createWithSettings({ sortType: 'custom' });
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
    });

    test('sets column sort direction to "ascending" when the settings are not defined', () => {
      createWithSettings(undefined);
      equal(gradebook.getColumnOrder().direction, 'ascending');
    });

    test('sets column sort type to "assignment_group" when the settings are not defined', () => {
      createWithSettings(undefined);
      equal(gradebook.getColumnOrder().sortType, 'assignment_group');
    });

    test('does not freeze the total grade column when the settings are not defined', () => {
      createWithSettings(undefined);
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
    });
  });

  QUnit.module('#getColumnOrder when sorting by module position', (hooks) => {
    hooks.beforeEach(() => {
      createWithSettings({ direction: 'descending', sortType: 'module_position' });
    });

    test('includes the stored column sort direction', () => {
      equal(gradebook.getColumnOrder().direction, 'descending');
    });

    test('includes "module_position" as the stored column sort type', () => {
      equal(gradebook.getColumnOrder().sortType, 'module_position');
    });

    test('sets the column direction to "ascending" when the course has no modules', () => {
      gradebook.setContextModules([]);
      equal(gradebook.getColumnOrder().direction, 'ascending');
    });

    test('sets the column sort type to "assignment_group" when the course has no modules', () => {
      gradebook.setContextModules([]);
      equal(gradebook.getColumnOrder().sortType, 'assignment_group');
    });
  });

  QUnit.module('#saveColumnOrder', (hooks) => {
    let server;

    hooks.beforeEach(() => {
      gradebook = createGradebook();
      gradebook.setColumnOrder({ sortType: 'name', direction: 'ascending' });
      server = sinon.fakeServer.create({ respondImmediately: true });
    });

    hooks.afterEach(() => {
      server.restore();
    });

    test('sends a request to the "gradebook custom order settings" url', () => {
      gradebook.saveColumnOrder();
      const requests = server.requests.filter(request => (
        request.url === 'http://example.com/gradebook_column_order_settings_url'
      ));
      strictEqual(requests.length, 1);
    });

    test('sends a POST request', () => {
      gradebook.saveColumnOrder();
      const saveRequest = server.requests.find(request => (
        request.url === 'http://example.com/gradebook_column_order_settings_url'
      ));
      equal(saveRequest.method, 'POST');
    });

    test('includes the column order', () => {
      gradebook.saveColumnOrder();
      const saveRequest = server.requests.find(request => (
        request.url === 'http://example.com/gradebook_column_order_settings_url'
      ));
      const requestBody = qs.parse(saveRequest.requestBody);
      deepEqual(qs.stringify(requestBody.column_order), qs.stringify(gradebook.getColumnOrder()));
    });

    test('does not send a request when the order setting is invalid', () => {
      gradebook.gradebookColumnOrderSettings = { sortType: 'custom' };
      gradebook.saveColumnOrder();
      const requests = server.requests.filter(request => (
        request.url === 'http://example.com/gradebook_column_order_settings_url'
      ));
      strictEqual(requests.length, 0);
    });
  });

  QUnit.module('#saveCustomColumnOrder', (hooks) => {
    hooks.beforeEach(() => {
      gradebook = createGradebook();
      const columns = [
        { id: 'student' },
        { id: 'custom_col_2401' },
        { id: 'assignment_2301' },
        { id: 'assignment_2302' },
        { id: 'assignment_group_2201' },
        { id: 'total_grade' }
      ];
      columns.forEach((column) => {
        gradebook.gridData.columns.definitions[column.id] = column;
      });
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id);
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id);

      gradebook.setColumnOrder({ sortType: 'name', direction: 'ascending' });
      sinon.stub(gradebook, 'saveColumnOrder');
    });

    test('includes the "sortType" when storing the order', () => {
      gradebook.saveCustomColumnOrder();
      equal(gradebook.getColumnOrder().sortType, 'custom');
    });

    test('includes the column order when storing the order', () => {
      gradebook.saveCustomColumnOrder();
      const expectedOrder = ['assignment_2301', 'assignment_2302', 'assignment_group_2201', 'total_grade'];
      deepEqual(gradebook.getColumnOrder().customOrder, expectedOrder);
    });

    test('saves the column order', () => {
      gradebook.saveCustomColumnOrder();
      strictEqual(gradebook.saveColumnOrder.callCount, 1);
    });

    test('saves the column order after setting the new settings', () => {
      gradebook.saveColumnOrder.callsFake(() => {
        equal(gradebook.getColumnOrder().sortType, 'custom');
      });
      gradebook.saveCustomColumnOrder();
    });
  });

  QUnit.module('#freezeTotalGradeColumn', (hooks) => {
    let server
    let options

    hooks.beforeEach(() => {
      server = sinon.fakeServer.create({ respondImmediately: true })
      options = { gradebook_column_order_settings_url: 'gradebook_column_order_setting_url' }
      server.respondWith('POST', options.gradebook_column_order_settings_url, [
        200, { 'Content-Type': 'application/json' }, '{}'
      ])
      gradebook = createGradebook(options);
      gradebook.setColumnOrder({ freezeTotalGrade: false });
      sinon.stub(gradebook, 'saveColumnOrder');
      sinon.stub(gradebook, 'updateGrid');
      sinon.stub(gradebook, 'updateColumnHeaders');
    })

    hooks.afterEach(() => {
      server.restore()
    })

    test('sets the total grade column as frozen', () => {
      gradebook.freezeTotalGradeColumn();
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, true);
    });

    test('saves column order', () => {
      gradebook.freezeTotalGradeColumn();
      strictEqual(gradebook.saveColumnOrder.callCount, 1);
    });

    test('saves column order after setting the total grade column as frozen', () => {
      gradebook.saveColumnOrder.callsFake(() => {
        strictEqual(gradebook.getColumnOrder().freezeTotalGrade, true);
      });
      gradebook.freezeTotalGradeColumn();
    });

    test('updates the grid', () => {
      gradebook.freezeTotalGradeColumn();
      strictEqual(gradebook.updateGrid.callCount, 1);
    });

    test('updates column headers', () => {
      gradebook.freezeTotalGradeColumn();
      strictEqual(gradebook.updateColumnHeaders.callCount, 1);
    });

    test('calls scrollToStart', () => {
      const scrollToStartStub = sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'scrollToStart')
      gradebook.freezeTotalGradeColumn()
      strictEqual(scrollToStartStub.callCount, 1)
    })
  });

  QUnit.module('#moveTotalGradeColumnToEnd', (hooks) => {
    hooks.beforeEach(() => {
      gradebook = createGradebook();
      gradebook.setColumnOrder({ freezeTotalGrade: true });
      sinon.stub(gradebook, 'saveColumnOrder');
      sinon.stub(gradebook, 'saveCustomColumnOrder');
      sinon.stub(gradebook, 'updateGrid');
      sinon.stub(gradebook, 'updateColumnHeaders');
    });

    test('sets the total grade column as not frozen', () => {
      gradebook.moveTotalGradeColumnToEnd();
      strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
    });

    test('saves column order when not using a custom order', () => {
      gradebook.moveTotalGradeColumnToEnd();
      strictEqual(gradebook.saveColumnOrder.callCount, 1);
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 0);
    });

    test('saves custom column order when using a custom order', () => {
      gradebook.setColumnOrder({ customOrder: ['assignment_2301', 'total_grade'], sortType: 'custom' });
      gradebook.moveTotalGradeColumnToEnd();
      strictEqual(gradebook.saveColumnOrder.callCount, 0);
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 1);
    });

    test('saves column order after setting the total grade column as not frozen', () => {
      gradebook.saveColumnOrder.callsFake(() => {
        strictEqual(gradebook.getColumnOrder().freezeTotalGrade, false);
      });
      gradebook.moveTotalGradeColumnToEnd();
    });

    test('updates the grid', () => {
      gradebook.moveTotalGradeColumnToEnd();
      strictEqual(gradebook.updateGrid.callCount, 1);
    });

    test('updates column headers', () => {
      gradebook.moveTotalGradeColumnToEnd();
      strictEqual(gradebook.updateColumnHeaders.callCount, 1);
    });

    test('calls scrollToEnd', () => {
      const scrollToEndStub = sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'scrollToEnd')
      gradebook.moveTotalGradeColumnToEnd()
      strictEqual(scrollToEndStub.callCount, 1)
    })
  });
});

QUnit.module('Gradebook#isDefaultSortOrder', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('returns false if called with due_date', function () {
  strictEqual(this.gradebook.isDefaultSortOrder('due_date'), false);
});

test('returns false if called with name', function () {
  strictEqual(this.gradebook.isDefaultSortOrder('name'), false);
});

test('returns false if called with points', function () {
  strictEqual(this.gradebook.isDefaultSortOrder('points'), false);
});

test('returns false if called with points', function () {
  strictEqual(this.gradebook.isDefaultSortOrder('custom'), false);
});

test('returns false if called with module_position', function () {
  strictEqual(this.gradebook.isDefaultSortOrder('module_position'), false);
});

test('returns true if called with anything else', function () {
  strictEqual(this.gradebook.isDefaultSortOrder('alpha'), true);
  strictEqual(this.gradebook.isDefaultSortOrder('assignment_group'), true);
});

QUnit.module('Gradebook#isInvalidSort', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('returns false if sorting by any valid criterion', function () {
  this.gradebook.setColumnOrder({ sortType: 'name', direction: 'ascending' });

  strictEqual(this.gradebook.isInvalidSort(), false);
});

test('returns true if sorting by module position but there are no modules in the course any more', function () {
  this.gradebook.setColumnOrder({ sortType: 'module_position', direction: 'ascending' });
  this.gradebook.courseContent.contextModules = [];

  strictEqual(this.gradebook.isInvalidSort(), true);
});

test('returns false if sorting by module position and there are modules in the course', function () {
  this.gradebook.setColumnOrder({ sortType: 'module_position', direction: 'ascending' });
  this.gradebook.courseContent.contextModules = [
    { id: '1', name: 'Module 1', position: 1 }
  ];

  strictEqual(this.gradebook.isInvalidSort(), false);
});

test('returns true if sorting by custom but there is no custom column order stored', function () {
  this.gradebook.gradebookColumnOrderSettings = { sortType: 'custom' };

  strictEqual(this.gradebook.isInvalidSort(), true);
});

test('returns false if sorting by custom and there is a custom column order stored', function () {
  this.gradebook.gradebookColumnOrderSettings = { sortType: 'custom', customOrder: [1, 2, 3] };

  strictEqual(this.gradebook.isInvalidSort(), false);
});

QUnit.module('Gradebook#renderSearchFilter', {
  setup () {
    $fixtures.innerHTML = `
      <div id="search-filter-container">
        <input type="text" />
      </div>
    `;
    this.gradebook = createGradebook();
    this.gradebook.setStudentsLoaded(true);
    this.gradebook.setSubmissionsLoaded(true);
    this.gradebook.renderSearchFilter();
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('binds an InputFilterView to the search filter markup', function () {
  equal(this.gradebook.userFilter.constructor.name, 'InputFilterView');
});

test('does not create a new InputFilterView when already bound', function () {
  const userFilter = this.gradebook.userFilter;
  this.gradebook.renderSearchFilter();
  strictEqual(this.gradebook.userFilter, userFilter);
});

test('enables the input when students and submissions are loaded', function () {
  const input = document.querySelector('#search-filter-container input');
  strictEqual(input.disabled, false, 'input is not disabled');
  strictEqual(input.getAttribute('aria-disabled'), 'false', 'input is not aria-disabled');
});

test('disables the input when students are not loaded', function () {
  this.gradebook.setStudentsLoaded(false);
  this.gradebook.renderSearchFilter();
  const input = document.querySelector('#search-filter-container input');
  strictEqual(input.disabled, true, 'input is disabled');
  strictEqual(input.getAttribute('aria-disabled'), 'true', 'input is aria-disabled');
});

test('disables the input when submissions are not loaded', function () {
  this.gradebook.setSubmissionsLoaded(false);
  this.gradebook.renderSearchFilter();
  const input = document.querySelector('#search-filter-container input');
  strictEqual(input.disabled, true, 'input is disabled');
  strictEqual(input.getAttribute('aria-disabled'), 'true', 'input is aria-disabled');
});

QUnit.module('Gradebook#submissionsForStudent', {
  setup () {
    this.student = {
      id: '1',
      assignment_1: {
        assignment_id: '1',
        user_id: '1',
        name: 'yolo'
      },
      assignment_2: {
        assignment_id: '2',
        user_id: '1',
        name: 'froyo'
      }
    };
    this.gradebook = createGradebook();
    this.gradebook.effectiveDueDates = {
      1: {
        1: { grading_period_id: '1' }
      },
      2: {
        1: { grading_period_id: '2' }
      }
    };
  }
});

test('returns all submissions for the student when there are no grading periods', function () {
  const submissions = this.gradebook.submissionsForStudent(this.student);
  propEqual(_.pluck(submissions, 'assignment_id'), ['1', '2']);
});

test('returns all submissions if "All Grading Periods" is selected', function () {
  this.gradebook.gradingPeriodSet = { id: '1', gradingPeriods: [{ id: '1' }, { id: '2' }] };
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0'); // value indicates "All Grading Periods"
  const submissions = this.gradebook.submissionsForStudent(this.student);
  propEqual(_.pluck(submissions, 'assignment_id'), ['1', '2']);
});

test('only returns submissions due for the student in the selected grading period', function () {
  this.gradebook.gradingPeriodSet = { id: '1', gradingPeriods: [{ id: '1' }, { id: '2' }] };
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '2');
  const submissions = this.gradebook.submissionsForStudent(this.student);
  propEqual(_.pluck(submissions, 'assignment_id'), ['2']);
});

QUnit.module('Gradebook#studentsParams', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('enrollment_state includes "completed" when concluded filter is on', function () {
  sandbox.stub(this.gradebook, 'getEnrollmentFilters').returns({ concluded: true, inactive: false });
  ok(this.gradebook.studentsParams().enrollment_state.includes('completed'));
});

test('enrollment_state excludes "completed" when concluded filter is off', function () {
  sandbox.stub(this.gradebook, 'getEnrollmentFilters').returns({ concluded: false, inactive: false });
  notOk(this.gradebook.studentsParams().enrollment_state.includes('completed'));
});

test('enrollment_state includes "inactive" when inactive filter is on', function () {
  sandbox.stub(this.gradebook, 'getEnrollmentFilters').returns({ concluded: false, inactive: true });
  ok(this.gradebook.studentsParams().enrollment_state.includes('inactive'));
});

test('enrollment_state excludes "inactive" when inactive filter is off', function () {
  sandbox.stub(this.gradebook, 'getEnrollmentFilters').returns({ concluded: false, inactive: false });
  notOk(this.gradebook.studentsParams().enrollment_state.includes('inactive'));
});

test('enrollment_state includes "active" and "invited" by default', function () {
  sandbox.stub(this.gradebook, 'getEnrollmentFilters').returns({ concluded: false, inactive: false });
  ok(this.gradebook.studentsParams().enrollment_state.includes('active'));
  ok(this.gradebook.studentsParams().enrollment_state.includes('invited'));
});

QUnit.module('Gradebook#weightedGroups', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('returns true when group_weighting_scheme is "percent"', function () {
  this.gradebook.options.group_weighting_scheme = 'percent';
  equal(this.gradebook.weightedGroups(), true);
});

test('returns false when group_weighting_scheme is not "percent"', function () {
  this.gradebook.options.group_weighting_scheme = 'points';
  equal(this.gradebook.weightedGroups(), false);
  this.gradebook.options.group_weighting_scheme = null;
  equal(this.gradebook.weightedGroups(), false);
});

QUnit.module('Gradebook#weightedGrades', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('returns true when group_weighting_scheme is "percent"', function () {
  this.gradebook.options.group_weighting_scheme = 'percent';
  this.gradebook.gradingPeriodSet = { weighted: false };
  equal(this.gradebook.weightedGrades(), true);
});

test('returns true when the gradingPeriodSet is weighted', function () {
  this.gradebook.options.group_weighting_scheme = 'points';
  this.gradebook.gradingPeriodSet = { weighted: true };
  equal(this.gradebook.weightedGrades(), true);
});

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not weighted', function () {
  this.gradebook.options.group_weighting_scheme = 'points';
  this.gradebook.gradingPeriodSet = { weighted: false };
  equal(this.gradebook.weightedGrades(), false);
});

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not defined', function () {
  this.gradebook.options.group_weighting_scheme = 'points';
  this.gradebook.gradingPeriodSet = { weighted: null };
  equal(this.gradebook.weightedGrades(), false);
});

QUnit.module('Gradebook', () => {
  let gradebook

  QUnit.module('#switchTotalDisplay()', hooks => {
    hooks.beforeEach(() => {
      // Stub this here so the AJAX calls in Dataloader don't get stubbed too
      sandbox.stub($, 'ajaxJSON')

      createAndStubGradebook()
    })

    hooks.afterEach(() => {
      UserSettings.contextRemove('warned_about_totals_display')
      gradebook.destroy()
    })

    function createAndStubGradebook() {
      gradebook = createGradebook({
        show_total_grade_as_points: true,
        setting_update_url: 'http://settingUpdateUrl'
      })

      gradebook.gradebookGrid.gridSupport = {
        columns: {
          updateColumnHeaders: sinon.stub()
        }
      }

      sandbox.stub(gradebook.gradebookGrid, 'invalidate')
    }

    test('sets the warned_about_totals_display setting when called with true', () => {
      notOk(UserSettings.contextGet('warned_about_totals_display'))
      gradebook.switchTotalDisplay({dontWarnAgain: true})
      strictEqual(UserSettings.contextGet('warned_about_totals_display'), true)
    })

    test('disables "Show Total Grade as Points" when previously enabled', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      strictEqual(gradebook.options.show_total_grade_as_points, false)
    })

    test('enables "Show Total Grade as Points" when previously disabled', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      strictEqual(gradebook.options.show_total_grade_as_points, true)
    })

    test('updates the total display preferences for the current user', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})

      strictEqual($.ajaxJSON.callCount, 1)
      equal($.ajaxJSON.getCall(0).args[0], 'http://settingUpdateUrl')
      equal($.ajaxJSON.getCall(0).args[1], 'PUT')
      strictEqual($.ajaxJSON.getCall(0).args[2].show_total_grade_as_points, false)
    })

    test('invalidates the grid so it re-renders it', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1)
    })

    test('updates column headers', () => {
      gradebook.switchTotalDisplay({dontWarnAgain: false})
      strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
    })

    QUnit.module('when the "total grade override" column is used', () => {
      test('includes both "total grade" column ids when updating column headers', () => {
        gradebook.setShowFinalGradeOverrides(true)
        gradebook.switchTotalDisplay({dontWarnAgain: false})
        const [
          columnIds
        ] = gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
        deepEqual(columnIds, ['total_grade', 'total_grade_override'])
      })
    })

    QUnit.module('when the "total grade override" column is not used', () => {
      test('includes only the "total grade" column id when updating column headers', () => {
        gradebook.setShowFinalGradeOverrides(false)
        gradebook.switchTotalDisplay({dontWarnAgain: false})
        const [
          columnIds
        ] = gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
        deepEqual(columnIds, ['total_grade'])
      })
    })
  })
})

QUnit.module('Gradebook#togglePointsOrPercentTotals', {
  setup () {
    this.gradebook = createGradebook({
      show_total_grade_as_points: true,
      setting_update_url: 'http://settingUpdateUrl'
    });
    sandbox.stub(this.gradebook, 'switchTotalDisplay');

    // Stub this here so the AJAX calls in Dataloader don't get stubbed too
    sandbox.stub($, 'ajaxJSON');
  },

  teardown () {
    UserSettings.contextRemove('warned_about_totals_display');
    $(".ui-dialog").remove();
  }
});

test('when user is ignoring warnings, immediately toggles the total grade display', function () {
  UserSettings.contextSet('warned_about_totals_display', true);

  this.gradebook.togglePointsOrPercentTotals();

  equal(this.gradebook.switchTotalDisplay.callCount, 1, 'toggles the total grade display');
});

test('when user is ignoring warnings and a callback is given, immediately invokes callback', function () {
  const callback = sinon.stub();
  UserSettings.contextSet('warned_about_totals_display', true);

  this.gradebook.togglePointsOrPercentTotals(callback);

  equal(callback.callCount, 1);
});

test('when user is not ignoring warnings, return a dialog', function () {
  UserSettings.contextSet('warned_about_totals_display', false);

  const dialog = this.gradebook.togglePointsOrPercentTotals();

  equal(dialog.constructor.name, 'GradeDisplayWarningDialog', 'returns a grade display warning dialog');

  dialog.cancel();
});

test('when user is not ignoring warnings, the dialog has a save property which is the switchTotalDisplay function', function () {
  sandbox.stub(UserSettings, 'contextGet').withArgs('warned_about_totals_display').returns(false);
  const dialog = this.gradebook.togglePointsOrPercentTotals();

  equal(dialog.options.save, this.gradebook.switchTotalDisplay);

  dialog.cancel();
});

test('when user is not ignoring warnings, the dialog has a onClose property which is the callback function', function () {
  const callback = sinon.stub();
  sandbox.stub(UserSettings, 'contextGet').withArgs('warned_about_totals_display').returns(false);
  const dialog = this.gradebook.togglePointsOrPercentTotals(callback);

  equal(dialog.options.onClose, callback);

  dialog.cancel();
});

QUnit.module('Gradebook#showNotesColumn', {
  setup () {
    sandbox.stub(DataLoader, 'getDataForColumn');
    const teacherNotes = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true };
    this.gradebook = createGradebook({ teacher_notes: teacherNotes });
    sandbox.stub(this.gradebook, 'toggleNotesColumn');
  }
});

test('loads the notes if they have not yet been loaded', function () {
  this.gradebook.teacherNotesNotYetLoaded = true;
  this.gradebook.showNotesColumn();
  equal(DataLoader.getDataForColumn.callCount, 1);
});

test('loads the notes using the teacher notes column id', function () {
  this.gradebook.teacherNotesNotYetLoaded = true;
  this.gradebook.showNotesColumn();
  const [columnId] = DataLoader.getDataForColumn.lastCall.args;
  strictEqual(columnId, '2401');
});

test('does not load the notes if they are already loaded', function () {
  this.gradebook.teacherNotesNotYetLoaded = false;
  this.gradebook.showNotesColumn();
  equal(DataLoader.getDataForColumn.callCount, 0);
});

QUnit.module('Gradebook#getTeacherNotesViewOptionsMenuProps');

test('includes teacherNotes', function () {
  const gradebook = createGradebook();
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(typeof props.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.onSelect, 'function', 'props include "onSelect"');
  equal(typeof props.selected, 'boolean', 'props include "selected"');
});

test('disabled defaults to true', function () {
  const gradebook = createGradebook();
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, true);
});

test('disabled is false when the grid is ready', function () {
  const gradebook = createGradebook();
  sinon.stub(gradebook.gridReady, 'state').returns('resolved');
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, false);
});

test('disabled is true if the teacher notes column is updating', function () {
  const gradebook = createGradebook();
  sinon.stub(gradebook.gridReady, 'state').returns('resolved');
  gradebook.setTeacherNotesColumnUpdating(true);
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, true);
});

test('disabled is false if the teacher notes column is not updating', function () {
  const gradebook = createGradebook();
  sinon.stub(gradebook.gridReady, 'state').returns('resolved');
  gradebook.setTeacherNotesColumnUpdating(false);
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, false);
});

test('onSelect calls createTeacherNotes if there are no teacher notes', function () {
  const gradebook = createGradebook({ teacher_notes: null });
  sandbox.stub(gradebook, 'createTeacherNotes');
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  props.onSelect();
  equal(gradebook.createTeacherNotes.callCount, 1);
});

test('onSelect calls setTeacherNotesHidden with false if teacher notes are visible', function () {
  const teacherNotes = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true };
  const gradebook = createGradebook({ teacher_notes: teacherNotes });
  sandbox.stub(gradebook, 'setTeacherNotesHidden');
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  props.onSelect();
  equal(gradebook.setTeacherNotesHidden.callCount, 1);
  equal(gradebook.setTeacherNotesHidden.getCall(0).args[0], false)
});

test('onSelect calls setTeacherNotesHidden with true if teacher notes are hidden', function () {
  const teacherNotes = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false };
  const gradebook = createGradebook({ teacher_notes: teacherNotes });
  sandbox.stub(gradebook, 'setTeacherNotesHidden');
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  props.onSelect();
  equal(gradebook.setTeacherNotesHidden.callCount, 1);
  equal(gradebook.setTeacherNotesHidden.getCall(0).args[0], true)
});

test('selected is false if there are no teacher notes', function () {
  const gradebook = createGradebook({ teacher_notes: null });
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.selected, false);
});

test('selected is false if teacher notes are hidden', function () {
  const teacherNotes = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true };
  const gradebook = createGradebook({ teacher_notes: teacherNotes });
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.selected, false);
});

test('selected is true if teacher notes are visible', function () {
  const teacherNotes = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false };
  const gradebook = createGradebook({ teacher_notes: teacherNotes });
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.selected, true);
});

QUnit.module('Gradebook#getColumnSortSettingsViewOptionsMenuProps', {
  getProps (sortType = 'due_date', direction = 'ascending') {
    this.gradebook.setColumnOrder({ direction, sortType });
    return this.gradebook.getColumnSortSettingsViewOptionsMenuProps();
  },

  expectedArgs (sortType, direction) {
    return [
      { sortType, direction },
      false
    ];
  },

  setup () {
    this.gradebook = createGradebook();
    sandbox.stub(this.gradebook, 'arrangeColumnsBy');
  }
});

test('includes all required properties', function () {
  const props = this.getProps();

  equal(typeof props.criterion, 'string', 'props include "criterion"');
  equal(typeof props.direction, 'string', 'props include "direction"');
  equal(typeof props.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.onSortByDefault, 'function', 'props include "onSortByDefault"');
  equal(typeof props.onSortByNameAscending, 'function', 'props include "onSortByNameAscending"');
  equal(typeof props.onSortByNameDescending, 'function', 'props include "onSortByNameDescending"');
  equal(typeof props.onSortByDueDateAscending, 'function', 'props include "onSortByDueDateAscending"');
  equal(typeof props.onSortByDueDateDescending, 'function', 'props include "onSortByDueDateDescending"');
  equal(typeof props.onSortByPointsAscending, 'function', 'props include "onSortByPointsAscending"');
  equal(typeof props.onSortByPointsDescending, 'function', 'props include "onSortByPointsDescending"');
});

test('sets criterion to the sort field', function () {
  strictEqual(this.getProps().criterion, 'due_date');
  strictEqual(this.getProps('name').criterion, 'name');
});

test('sets criterion to "default" when isDefaultSortOrder returns true', function () {
  strictEqual(this.getProps('assignment_group').criterion, 'default');
});

test('sets the direction', function () {
  strictEqual(this.getProps(undefined, 'ascending').direction, 'ascending');
  strictEqual(this.getProps(undefined, 'descending').direction, 'descending');
});

test('sets disabled to true when assignments have not been loaded yet', function () {
  this.gradebook.setAssignmentsLoaded(false);

  strictEqual(this.getProps().disabled, true);
});

test('sets disabled to false when assignments have been loaded', function () {
  this.gradebook.setAssignmentsLoaded(true);

  strictEqual(this.getProps().disabled, false);
});

test('sets modulesEnabled to true when there are modules in the current course', function () {
  this.gradebook.setContextModules([
    { id: '1', name: 'Module 1', position: 1 },
  ]);

  strictEqual(this.getProps().modulesEnabled, true);
});

test('sets modulesEnabled to false when there are no modules in the current course', function () {
  this.gradebook.setContextModules([]);

  strictEqual(this.getProps().modulesEnabled, false);
});

test('sets onSortByNameAscending to a function that sorts columns by name ascending', function () {
  this.getProps().onSortByNameAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('name', 'ascending'));
});

test('sets onSortByNameDescending to a function that sorts columns by name descending', function () {
  this.getProps().onSortByNameDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('name', 'descending'));
});

test('sets onSortByDueDateAscending to a function that sorts columns by due date ascending', function () {
  this.getProps().onSortByDueDateAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('due_date', 'ascending'));
});

test('sets onSortByDueDateDescending to a function that sorts columns by due date descending', function () {
  this.getProps().onSortByDueDateDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('due_date', 'descending'));
});

test('sets onSortByPointsAscending to a function that sorts columns by points ascending', function () {
  this.getProps().onSortByPointsAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('points', 'ascending'));
});

test('sets onSortByPointsDescending to a function that sorts columns by points descending', function () {
  this.getProps().onSortByPointsDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('points', 'descending'));
});

test('sets onSortByModuleAscending to a function that sorts columns by module position ascending', function () {
  this.getProps().onSortByModuleAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('module_position', 'ascending'));
});

test('sets onSortByModuleDescending to a function that sorts columns by module position descending', function () {
  this.getProps().onSortByModuleDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('module_position', 'descending'));
});

QUnit.module('Gradebook#getFilterSettingsViewOptionsMenuProps', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setAssignmentGroups({
      301: { name: 'Assignments', group_weight: 40 },
      302: { name: 'Homework', group_weight: 60 }
    });
    this.gradebook.gradingPeriodSet = { id: '1501' };
    this.gradebook.setContextModules([{ id: '2601' }, { id: '2602' }]);
    this.gradebook.sections_enabled = true;
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu');
    sandbox.stub(this.gradebook, 'renderFilters');
    sandbox.stub(this.gradebook, 'saveSettings');
  }
});

test('includes available filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.available, ['assignmentGroups', 'gradingPeriods', 'modules', 'sections']);
});

test('available filters exclude assignment groups when only one exists', function () {
  this.gradebook.setAssignmentGroups({ 301: { name: 'Assignments' } });
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.available, ['gradingPeriods', 'modules', 'sections']);
});

test('available filters exclude assignment groups when not loaded', function () {
  this.gradebook.setAssignmentGroups(undefined);
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.available, ['gradingPeriods', 'modules', 'sections']);
});

test('available filters exclude grading periods when no grading period set exists', function () {
  this.gradebook.gradingPeriodSet = null;
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.available, ['assignmentGroups', 'modules', 'sections']);
});

test('available filters exclude modules when none exist', function () {
  this.gradebook.setContextModules([]);
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.available, ['assignmentGroups', 'gradingPeriods', 'sections']);
});

test('available filters exclude sections when only one exists', function () {
  this.gradebook.sections_enabled = false;
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.available, ['assignmentGroups', 'gradingPeriods', 'modules']);
});

test('includes selected filters', function () {
  this.gradebook.setSelectedViewOptionsFilters(['gradingPeriods', 'modules']);
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  deepEqual(props.selected, ['gradingPeriods', 'modules']);
});

test('onSelect sets the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  props.onSelect(['gradingPeriods', 'sections']);
  deepEqual(this.gradebook.listSelectedViewOptionsFilters(), ['gradingPeriods', 'sections']);
});

test('onSelect renders the view options menu after setting the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    strictEqual(this.gradebook.listSelectedViewOptionsFilters().length, 2, 'filters were updated');
  });
  props.onSelect(['gradingPeriods', 'sections']);
});

test('onSelect renders the filters after setting the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  this.gradebook.renderFilters.callsFake(() => {
    strictEqual(this.gradebook.listSelectedViewOptionsFilters().length, 2, 'filters were updated');
  });
  props.onSelect(['gradingPeriods', 'sections']);
});

test('onSelect saves settings after setting the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps();
  this.gradebook.saveSettings.callsFake(() => {
    strictEqual(this.gradebook.listSelectedViewOptionsFilters().length, 2, 'filters were updated');
  });
  props.onSelect(['gradingPeriods', 'sections']);
});

QUnit.module('Gradebook#getViewOptionsMenuProps', () => {
  test('includes exactly the required ViewOptionsMenu overrides props require', () => {
    const props = createGradebook().getViewOptionsMenuProps()
    const consoleSpy = sinon.spy(console, 'error')
    PropTypes.checkPropTypes(ViewOptionsMenu.propTypes, props, 'prop', 'ViewOptionsMenu')
    strictEqual(consoleSpy.called, false)
    consoleSpy.restore()
  })

  test('finalGradeOverrideEnabled is false', () => {
    const {finalGradeOverrideEnabled} = createGradebook().getViewOptionsMenuProps()
    strictEqual(finalGradeOverrideEnabled, false)
  })

  test('finalGradeOverrideEnabled is set via final_grade_override_enabled', () => {
    const {finalGradeOverrideEnabled} = createGradebook({final_grade_override_enabled: true}).getViewOptionsMenuProps()
    strictEqual(finalGradeOverrideEnabled, true)
  })

  test('showUnpublishedAssignments is true', () => {
    const {showUnpublishedAssignments} = createGradebook().getViewOptionsMenuProps()
    strictEqual(showUnpublishedAssignments, true)
  })

  test('showUnpublishedAssignments is set via settings.show_unpublished_assignments', () => {
    const settings = {show_unpublished_assignments: false}
    const {showUnpublishedAssignments} = createGradebook({settings}).getViewOptionsMenuProps()
    strictEqual(showUnpublishedAssignments, false)
  })
})

QUnit.module('Gradebook#createTeacherNotes', {
  setup () {
    this.promise = {
      then (thenFn) {
        this.thenFn = thenFn;
        return this;
      },

      catch (catchFn) {
        this.catchFn = catchFn;
        return this;
      }
    };
    sandbox.stub(GradebookApi, 'createTeacherNotesColumn').returns(this.promise);
    this.gradebook = createGradebook({ context_id: '1201' });
    sandbox.stub(this.gradebook, 'showNotesColumn');
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu');
  }
});

test('sets teacherNotesUpdating to true before sending the api request', function () {
  this.gradebook.createTeacherNotes();
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true);
});

test('re-renders the view options menu after setting teacherNotesUpdating', function () {
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true);
  });
  this.gradebook.createTeacherNotes();
});

test('calls GradebookApi.createTeacherNotesColumn', function () {
  this.gradebook.createTeacherNotes();
  equal(GradebookApi.createTeacherNotesColumn.callCount, 1);
  const [courseId] = GradebookApi.createTeacherNotesColumn.getCall(0).args;
  equal(courseId, '1201', 'the only parameter is the course id');
});

test('updates teacher notes with response data after request resolves', function () {
  const column = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false };
  this.gradebook.createTeacherNotes();
  this.promise.thenFn({ data: column });
  equal(this.gradebook.getTeacherNotesColumn(), column);
});

test('updates custom columns with response data after request resolves', function () {
  const column = { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false };
  this.gradebook.createTeacherNotes();
  this.promise.thenFn({ data: column });
  deepEqual(this.gradebook.gradebookContent.customColumns, [column]);
});

test('shows the notes column after request resolves', function () {
  this.gradebook.createTeacherNotes();
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.getTeacherNotesColumn().hidden, false);
});

test('sets teacherNotesUpdating to false after request resolves', function () {
  this.gradebook.createTeacherNotes();
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('re-renders the view options menu after request resolves', function () {
  this.gradebook.createTeacherNotes();
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('displays a flash error after request rejects', function () {
  sandbox.stub($, 'flashError');
  this.gradebook.createTeacherNotes();
  this.promise.catchFn(new Error('FAIL'));
  equal($.flashError.callCount, 1);
});

test('sets teacherNotesUpdating to false after request rejects', function () {
  this.gradebook.createTeacherNotes();
  this.promise.catchFn(new Error('FAIL'));
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('re-renders the view options menu after request rejects', function () {
  this.gradebook.createTeacherNotes();
  this.promise.catchFn(new Error('FAIL'));
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

QUnit.module('Gradebook#setTeacherNotesHidden - showing teacher notes', {
  setup () {
    this.promise = {
      then (thenFn) {
        this.thenFn = thenFn;
        return this;
      },

      catch (catchFn) {
        this.catchFn = catchFn;
        return this;
      }
    };
    sandbox.stub(GradebookApi, 'updateTeacherNotesColumn').returns(this.promise);
    this.gradebook = createGradebook({ context_id: '1201' });
    this.gradebook.gradebookContent.customColumns = [
      { id: '2401', teacher_notes: true, hidden: true, title: 'Notes' },
      { id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes' }
    ];
    this.gradebook.gradebookGrid.grid = {
      getColumns () {
        return [];
      },
      getOptions () {
        return {
          numberOfColumnsToFreeze: 0
        };
      },
      invalidate () {},
      setColumns () {},
      setNumberOfColumnsToFreeze () {}
    };
    sandbox.stub(DataLoader, 'getDataForColumn');
    sandbox.stub(this.gradebook, 'reorderCustomColumns');
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu');
  }
});

test('sets teacherNotesUpdating to true before sending the api request', function () {
  this.gradebook.setTeacherNotesHidden(false);
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true);
});

test('re-renders the view options menu after setting teacherNotesUpdating', function () {
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true);
  });
  this.gradebook.setTeacherNotesHidden(false);
});

test('calls GradebookApi.updateTeacherNotesColumn', function () {
  this.gradebook.setTeacherNotesHidden(false);
  equal(GradebookApi.updateTeacherNotesColumn.callCount, 1);
  const [courseId, columnId, attr] = GradebookApi.updateTeacherNotesColumn.getCall(0).args;
  equal(courseId, '1201', 'parameter 1 is the course id');
  equal(columnId, '2401', 'parameter 2 is the column id');
  equal(attr.hidden, false, 'attr.hidden is true');
});

test('shows the notes column after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false);
  equal(this.gradebook.getTeacherNotesColumn().hidden, true);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.getTeacherNotesColumn().hidden, false);
});

test('reorders custom columns after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false);
  equal(this.gradebook.reorderCustomColumns.callCount, 0);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.reorderCustomColumns.callCount, 1);
});

test('reorders custom columns using the column ids', function () {
  this.gradebook.setTeacherNotesHidden(false);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  const [columnIds] = this.gradebook.reorderCustomColumns.getCall(0).args;
  deepEqual(columnIds, ['2401', '2402']);
});

test('sets teacherNotesUpdating to false after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('re-renders the view options menu after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('displays a flash message after request rejects', function () {
  sandbox.stub($, 'flashError');
  this.gradebook.setTeacherNotesHidden(false);
  this.promise.catchFn(new Error('FAIL'));
  equal($.flashError.callCount, 1);
});

test('sets teacherNotesUpdating to false after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(false);
  this.promise.catchFn(new Error('FAIL'));
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('re-renders the view options menu after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(false);
  this.promise.catchFn(new Error('FAIL'));
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

QUnit.module('Gradebook#setTeacherNotesHidden - hiding teacher notes', {
  setup () {
    this.promise = {
      then (thenFn) {
        this.thenFn = thenFn;
        return this;
      },

      catch (catchFn) {
        this.catchFn = catchFn;
        return this;
      }
    };
    sandbox.stub(GradebookApi, 'updateTeacherNotesColumn').returns(this.promise);
    this.gradebook = createGradebook({
      context_id: '1201',
      teacher_notes: { id: '2401', teacher_notes: true, hidden: false }
    });
    this.gradebook.gradebookGrid.grid = {
      getColumns () {
        return [];
      },
      getOptions () {
        return {
          numberOfColumnsToFreeze: 0
        };
      },
      invalidate () {},
      setColumns () {},
      setNumberOfColumnsToFreeze () {}
    };
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu');
  }
});

test('sets teacherNotesUpdating to true before sending the api request', function () {
  this.gradebook.setTeacherNotesHidden(true);
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true);
});

test('re-renders the view options menu after setting teacherNotesUpdating', function () {
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, true);
  });
  this.gradebook.setTeacherNotesHidden(true);
});

test('calls GradebookApi.updateTeacherNotesColumn', function () {
  this.gradebook.setTeacherNotesHidden(true);
  equal(GradebookApi.updateTeacherNotesColumn.callCount, 1);
  const [courseId, columnId, attr] = GradebookApi.updateTeacherNotesColumn.getCall(0).args;
  equal(courseId, '1201', 'parameter 1 is the course id');
  equal(columnId, '2401', 'parameter 2 is the column id');
  equal(attr.hidden, true, 'attr.hidden is true');
});

test('hides the notes column after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true);
  equal(this.gradebook.getTeacherNotesColumn().hidden, false);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true } });
  equal(this.gradebook.getTeacherNotesColumn().hidden, true);
});

test('sets teacherNotesUpdating to false after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true } });
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('re-renders the view options menu after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true } });
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('displays a flash message after request rejects', function () {
  sandbox.stub($, 'flashError');
  this.gradebook.setTeacherNotesHidden(true);
  this.promise.catchFn(new Error('FAIL'));
  equal($.flashError.callCount, 1);
});

test('sets teacherNotesUpdating to false after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(true);
  this.promise.catchFn(new Error('FAIL'));
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

test('re-renders the view options menu after request rejects', function () {
  this.gradebook.setTeacherNotesHidden(true);
  this.promise.catchFn(new Error('FAIL'));
  equal(this.gradebook.contentLoadStates.teacherNotesColumnUpdating, false);
});

QUnit.module('Gradebook#updateSectionFilterVisibility', {
  setup () {
    const sectionsFilterContainerSelector = 'sections-filter-container';
    $fixtures.innerHTML = `<div id="${sectionsFilterContainerSelector}"></div>`;
    this.container = $fixtures.querySelector(`#${sectionsFilterContainerSelector}`);
    const sections = [
      { id: '2001', name: 'Freshmen / First-Year' },
      { id: '2002', name: 'Sophomores' }
    ];
    this.gradebook = createGradebook({ sections });
    this.gradebook.sections_enabled = true;
    this.gradebook.setSelectedViewOptionsFilters(['sections']);
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('renders the section select when not already rendered', function () {
  this.gradebook.updateSectionFilterVisibility();
  ok(this.container.children.length > 0, 'section menu was rendered');
});

test('stores a reference to the section select when it is rendered', function () {
  this.gradebook.updateSectionFilterVisibility();
  ok(this.gradebook.sectionFilterMenu, 'section menu reference has been stored');
});

test('does not render when only one section exists', function () {
  this.gradebook.sections_enabled = false;
  this.gradebook.updateSectionFilterVisibility();
  notOk(this.gradebook.sectionFilterMenu, 'section menu reference has not been stored');
  strictEqual(this.container.children.length, 0, 'nothing was rendered');
});

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups']);
  this.gradebook.updateSectionFilterVisibility();
  notOk(this.gradebook.sectionFilterMenu, 'section menu reference has been removed');
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed');
});

test('renders the section select with a list of sections', function () {
  this.gradebook.updateSectionFilterVisibility();
  const sections = this.gradebook.sectionFilterMenu.props.items;
  strictEqual(sections.length, 2, 'includes the "nothing selected" option plus the two sections');
  deepEqual(sections.map(section => section.id), ['2001', '2002']);
});

test('unescapes section names', function () {
  this.gradebook.updateSectionFilterVisibility();
  const sections = this.gradebook.sectionFilterMenu.props.items;
  deepEqual(sections.map(section => section.name), ['Freshmen / First-Year', 'Sophomores']);
});

test('sets the section select to show the saved "filter rows by" setting', function () {
  this.gradebook.setFilterRowsBySetting('sectionId', '2002');
  this.gradebook.updateSectionFilterVisibility();
  strictEqual(this.gradebook.sectionFilterMenu.props.selectedItemId, '2002');
});

test('sets the section select as disabled when students are not loaded', function () {
  this.gradebook.updateSectionFilterVisibility();
  strictEqual(this.gradebook.sectionFilterMenu.props.disabled, true);
});

test('sets the section select as not disabled when students are loaded', function () {
  this.gradebook.setStudentsLoaded(true);
  this.gradebook.updateSectionFilterVisibility();
  strictEqual(this.gradebook.sectionFilterMenu.props.disabled, false);
});

test('updates the disabled state of the rendered section select', function () {
  this.gradebook.updateSectionFilterVisibility();
  this.gradebook.setStudentsLoaded(true);
  this.gradebook.updateSectionFilterVisibility();
  strictEqual(this.gradebook.sectionFilterMenu.props.disabled, false);
});

test('renders only one section select when updated', function () {
  this.gradebook.updateSectionFilterVisibility();
  this.gradebook.updateSectionFilterVisibility();
  ok(this.gradebook.sectionFilterMenu, 'section menu reference has been stored');
  strictEqual(this.container.children.length, 1, 'only one section select is rendered');
});

test('removes the section select when filter is deselected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups']);
  this.gradebook.updateSectionFilterVisibility();
  notOk(this.gradebook.sectionFilterMenu, 'section menu reference has been stored');
  strictEqual(this.container.children.length, 0, 'nothing was rendered');
});

QUnit.module('Gradebook#updateCurrentSection', {
  setup () {
    this.server = sinon.createFakeServer({ respondImmediately: true })
    this.server.respondWith([200, {}, ''])

    this.gradebook = createGradebook({ settings_update_url: '/settingUrl' })
    this.gradebook.postGradesStore = {
      setSelectedSection: sinon.stub()
    };
    sandbox.stub(this.gradebook, 'reloadStudentData');
    sinon.spy(this.gradebook, 'saveSettings')
    sandbox.stub(this.gradebook, 'updateSectionFilterVisibility');
  },

  teardown () {
    this.server.restore()
  }
})

test('updates the filter setting with the given section id', function () {
  this.gradebook.updateCurrentSection('2001');
  strictEqual(this.gradebook.getFilterRowsBySetting('sectionId'), '2001');
});

test('sets the selected section on the post grades store', function () {
  this.gradebook.updateCurrentSection('2001');
  strictEqual(this.gradebook.postGradesStore.setSelectedSection.callCount, 1);
});

test('includes the selected section when updating the post grades store', function () {
  this.gradebook.updateCurrentSection('2001');
  const [sectionId] = this.gradebook.postGradesStore.setSelectedSection.firstCall.args;
  strictEqual(sectionId, '2001');
});

test('re-renders the section filter', function () {
  this.gradebook.updateCurrentSection('2001');
  strictEqual(this.gradebook.updateSectionFilterVisibility.callCount, 1);
});

test('re-renders the section filter after setting the selected section', function () {
  this.gradebook.updateSectionFilterVisibility.callsFake(() => {
    strictEqual(this.gradebook.getFilterRowsBySetting('sectionId'), '2001', 'section was already updated');
  });
  this.gradebook.updateCurrentSection('2001');
});

test('saves settings', function () {
  this.gradebook.updateCurrentSection('2001');
  strictEqual(this.gradebook.saveSettings.callCount, 1);
});

test('saves settings after updating the filter setting', function () {
  this.gradebook.updateCurrentSection('2001')
  strictEqual(this.gradebook.getFilterRowsBySetting('sectionId'), '2001', 'section was already updated');
});

test('has no effect when the section has not changed', function () {
  this.gradebook.setFilterRowsBySetting('sectionId', '2001');
  this.gradebook.updateCurrentSection('2001');
  strictEqual(this.gradebook.saveSettings.callCount, 0, 'saveSettings was not called');
  strictEqual(this.gradebook.updateSectionFilterVisibility.callCount, 0,
    'updateSectionFilterVisibility was not called');
});

test('reloads student data after saving settings', function () {
  this.gradebook.updateCurrentSection('2001')
  strictEqual(this.gradebook.reloadStudentData.callCount, 1);
});

QUnit.module('Gradebook#updateGradingPeriodFilterVisibility', {
  setup () {
    const sectionsFilterContainerSelector = 'grading-periods-filter-container';
    $fixtures.innerHTML = `<div id="${sectionsFilterContainerSelector}"></div>`;
    this.container = $fixtures.querySelector(`#${sectionsFilterContainerSelector}`);
    this.gradebook = createGradebook({
      grading_period_set: {
        id: '1501',
        grading_periods: [
          { id: '701', title: 'Grading Period 1', startDate: new Date(1) },
          { id: '702', title: 'Grading Period 2', startDate: new Date(2) }
        ]
      }
    });
    this.gradebook.setSelectedViewOptionsFilters(['gradingPeriods']);
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('renders the grading period select when not already rendered', function () {
  this.gradebook.updateGradingPeriodFilterVisibility();
  ok(this.container.children.length > 0, 'grading period menu was rendered');
});

test('stores a reference to the grading period select when it is rendered', function () {
  this.gradebook.updateGradingPeriodFilterVisibility();
  ok(this.gradebook.gradingPeriodFilterMenu, 'grading period menu reference has been stored');
});

test('does not render when a grading period set does not exist', function () {
  this.gradebook.gradingPeriodSet = null;
  this.gradebook.updateGradingPeriodFilterVisibility();
  notOk(this.gradebook.gradingPeriodFilterMenu, 'grading period menu reference has not been stored');
  strictEqual(this.container.children.length, 0, 'nothing was rendered');
});

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups']);
  this.gradebook.updateGradingPeriodFilterVisibility();
  notOk(this.gradebook.gradingPeriodFilterMenu, 'grading period menu reference has been removed');
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed');
});

test('renders the grading period select with a list of grading periods', function () {
  this.gradebook.updateGradingPeriodFilterVisibility();
  const periods = this.gradebook.gradingPeriodFilterMenu.props.items;
  strictEqual(periods.length, 2, 'includes the "nothing selected" option plus the two grading periods');
  deepEqual(periods.map(gradingPeriod => gradingPeriod.id), ['701', '702']);
});

test('sets the grading period select to show the selected grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '702');
  this.gradebook.updateGradingPeriodFilterVisibility();
  strictEqual(this.gradebook.gradingPeriodFilterMenu.props.selectedItemId, '702');
});

test('renders only one grading period select when updated', function () {
  this.gradebook.updateGradingPeriodFilterVisibility();
  this.gradebook.updateGradingPeriodFilterVisibility();
  ok(this.gradebook.gradingPeriodFilterMenu, 'grading period menu reference has been stored');
  strictEqual(this.container.children.length, 1, 'only one grading period select is rendered');
});

test('removes the grading period select when filter is deselected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups']);
  this.gradebook.updateGradingPeriodFilterVisibility();
  notOk(this.gradebook.gradingPeriodFilterMenu, 'grading period menu reference has been stored');
  strictEqual(this.container.children.length, 0, 'nothing was rendered');
});

QUnit.module('Gradebook#updateModulesFilterVisibility', {
  setup () {
    const modulesFilterContainerSelector = 'modules-filter-container';
    $fixtures.innerHTML = `<div id="${modulesFilterContainerSelector}"></div>`;
    this.container = $fixtures.querySelector(`#${modulesFilterContainerSelector}`);
    this.gradebook = createGradebook();
    this.gradebook.setContextModules([
      { id: '1', name: 'Module 1', position: 1 },
      { id: '2', name: 'Module 2', position: 2 }
    ]);
    this.gradebook.setSelectedViewOptionsFilters(['modules']);
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('renders the module select when not already rendered', function () {
  this.gradebook.updateModulesFilterVisibility();
  ok(this.container.children.length > 0, 'something was rendered');
});

test('stores a reference to the module select when it is rendered', function () {
  this.gradebook.updateModulesFilterVisibility();
  ok(this.gradebook.moduleFilterMenu);
});

test('does not render when modules do not exist', function () {
  this.gradebook.setContextModules(undefined);
  this.gradebook.updateModulesFilterVisibility();
  notOk(this.gradebook.moduleFilterMenu, 'module filter menu reference has not been stored');
  strictEqual(this.container.children.length, 0, 'nothing was rendered');
});

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups']);
  this.gradebook.updateModulesFilterVisibility();
  notOk(this.gradebook.moduleFilterMenu, 'grading period menu reference has been removed');
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed');
});

QUnit.module('Gradebook#updateAssignmentGroupFilterVisibility', {
  setup () {
    const agfContainer = 'assignment-group-filter-container';
    $fixtures.innerHTML = `<div id="${agfContainer}"></div>`;
    this.container = $fixtures.querySelector(`#${agfContainer}`);
    this.gradebook = createGradebook();
    this.gradebook.setAssignmentGroups([
      { id: '1', name: 'Assignments', position: 1 },
      { id: '2', name: 'Other', position: 2 }
    ]);
    this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups']);
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('renders the assignment group select when not already rendered', function () {
  const countBefore = this.container.children.length;
  this.gradebook.updateAssignmentGroupFilterVisibility();
  ok(this.container.children.length > countBefore, 'something was rendered');
});

test('stores a reference to the assignment group select when it is rendered', function () {
  this.gradebook.updateAssignmentGroupFilterVisibility();
  ok(this.gradebook.assignmentGroupFilterMenu);
});

test('does not render when there is only one assignment group', function () {
  this.gradebook.setAssignmentGroups([
    { id: '1', name: 'Assignments', position: 1 }
  ]);
  this.gradebook.updateAssignmentGroupFilterVisibility();
  notOk(this.gradebook.assignmentGroupFilterMenu, 'assignment group filter menu reference has not been stored');
  strictEqual(this.container.children.length, 0, 'nothing was rendered');
});

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['modules']);
  this.gradebook.updateAssignmentGroupFilterVisibility();
  notOk(this.gradebook.assignmentGroupFilterMenu, 'assignment group menu reference has been removed');
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed');
});

QUnit.module('Menus', {
  setup () {
    this.gradebook = createGradebook({
      context_allows_gradebook_uploads: true,
      export_gradebook_csv_url: 'http://someUrl',
      gradebook_import_url: 'http://someUrl',
      navigate () {}
    });
    this.gradebook.postGradesLtis = [];
    this.gradebook.postGradesStore = {};
    $fixtures.innerHTML = `
      <div id="application"></div>
      <span data-component="ViewOptionsMenu"></span>
      <span data-component="ActionMenu"></span>
      <span data-component="GradebookMenu" data-variant="DefaultGradebook"></span>
      <span data-component="StatusesModal" />
    `;
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('ViewOptionsMenu is rendered on renderViewOptionsMenu', function () {
  this.gradebook.renderViewOptionsMenu();
  const buttonText = document.querySelector('[data-component="ViewOptionsMenu"] Button').innerText.trim();
  equal(buttonText, 'View');
});

test('ActionMenu is rendered on renderActionMenu', function () {
  this.gradebook.renderActionMenu();
  const buttonText = document.querySelector('[data-component="ActionMenu"] Button').innerText.trim();
  equal(buttonText, 'Actions');
});

test('GradebookMenu is rendered on renderGradebookMenu', function () {
  this.gradebook.options.assignmentOrOutcome = 'assignment';
  this.gradebook.renderGradebookMenu();
  const buttonText = document.querySelector('[data-component="GradebookMenu"] Button').innerText.trim();
  equal(buttonText, 'Gradebook');
});

test('StatusesModal is mounted on renderStatusesModal', function () {
  const clock = sinon.useFakeTimers();
  const statusModal = this.gradebook.renderStatusesModal();
  statusModal.open();
  clock.tick(500); // wait for Modal to transition open

  const header = document.querySelector('[aria-label="Statuses"][role="dialog"] h2');
  equal(header.innerText, 'Statuses');

  const statusesModalMountPoint = document.querySelector("[data-component='StatusesModal']");
  ReactDOM.unmountComponentAtNode(statusesModalMountPoint);
  clock.restore();
});

QUnit.module('setupGrading', {
  setup () {
    this.gradebook = createGradebook();
    this.students = [{ id: '1101' }, { id: '1102' }];
    sandbox.stub(this.gradebook, 'setAssignmentVisibility');
    sandbox.stub(this.gradebook, 'invalidateRowsForStudentIds');
  }
});

test('sets assignment visibility for the given students', function () {
  this.gradebook.setupGrading(this.students);
  strictEqual(this.gradebook.setAssignmentVisibility.callCount, 1, 'setAssignmentVisibility was called once');
  const [studentIds] = this.gradebook.setAssignmentVisibility.lastCall.args;
  deepEqual(studentIds, ['1101', '1102'], 'both students were updated');
});

test('invalidates student rows for the given students', function () {
  this.gradebook.setupGrading(this.students);
  strictEqual(this.gradebook.invalidateRowsForStudentIds.callCount, 1, 'invalidateRowsForStudentIds was called once');
  const [studentIds] = this.gradebook.invalidateRowsForStudentIds.lastCall.args;
  deepEqual(studentIds, ['1101', '1102'], 'both students were updated');
});

test('invalidates student rows after setting assignment visibility', function () {
  this.gradebook.invalidateRowsForStudentIds.callsFake(() => {
    strictEqual(this.gradebook.setAssignmentVisibility.callCount, 1, 'setAssignmentVisibility was already called');
  });
  this.gradebook.setupGrading(this.students);
});

QUnit.module('resetGrading');

test('initializes a new submission state map', function () {
  const gradebook = createGradebook();
  const originalMap = gradebook.submissionStateMap;
  gradebook.resetGrading();
  strictEqual(gradebook.submissionStateMap.constructor, SubmissionStateMap);
  notEqual(originalMap, gradebook.submissionStateMap);
});

test('calls setupGrading', function () {
  const gradebook = createGradebook();
  sinon.spy(gradebook, 'setupGrading');
  gradebook.resetGrading();
  strictEqual(gradebook.setupGrading.callCount, 1);
});

test('sends all students when calling setupGrading', function () {
  const allStudents = [{ id: '1101', assignment_201: {}, assignment_202: {} }];
  const gradebook = createGradebook();
  sandbox.stub(gradebook.courseContent.students, 'listStudents').returns(allStudents);
  sinon.spy(gradebook, 'setupGrading');
  gradebook.resetGrading();
  const [students] = gradebook.setupGrading.lastCall.args;
  strictEqual(students, allStudents);
});

QUnit.module('Gradebook#updateStudentAttributes', {
  setup () {
    this.gradebook = createGradebook();
    this.student = { id: '1101', enrollments: [{ grades: { html_url: 'http://example.url/' } }] };
  }
});

test('sets .computed_current_score to 0', function () {
  this.gradebook.updateStudentAttributes(this.student);
  strictEqual(this.student.computed_current_score, 0);
});

test('sets .computed_final_score to 0', function () {
  this.gradebook.updateStudentAttributes(this.student);
  strictEqual(this.student.computed_final_score, 0);
});

test('sets .isConcluded to true when all enrollments are "completed"', function () {
  this.student.enrollments[0].enrollment_state = 'completed';
  this.student.enrollments.push({ enrollment_state: 'completed', grades: { html_url: 'http://example.url/' } });
  this.gradebook.updateStudentAttributes(this.student);
  strictEqual(this.student.isConcluded, true);
});

test('sets .isConcluded to false when any enrollments are not "completed"', function () {
  this.student.enrollments.push({ enrollment_state: 'completed', grades: { html_url: 'http://example.url/' } });
  this.gradebook.updateStudentAttributes(this.student);
  strictEqual(this.student.isConcluded, false);
});

test('sets .isInactive to true when all enrollments are "inactive"', function () {
  this.student.enrollments[0].enrollment_state = 'inactive';
  this.student.enrollments.push({ enrollment_state: 'inactive', grades: { html_url: 'http://example.url/' } });
  this.gradebook.updateStudentAttributes(this.student);
  strictEqual(this.student.isInactive, true);
});

test('sets .isInactive to false when any enrollments are not "inactive"', function () {
  this.student.enrollments.push({ enrollment_state: 'inactive', grades: { html_url: 'http://example.url/' } });
  this.gradebook.updateStudentAttributes(this.student);
  strictEqual(this.student.isInactive, false);
});

test('sets .cssClass using the id of the student', function () {
  this.gradebook.updateStudentAttributes(this.student);
  equal(this.student.cssClass, 'student_1101');
});

QUnit.module('Gradebook#updateStudentRow', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [{ id: '1101' }, { id: '1102' }, { id: '1103' }];
    sandbox.stub(this.gradebook.gradebookGrid, 'invalidateRow');
  }
});

test('updates the associated row with the given student', function () {
  const student = { id: '1102', name: 'Adam Jones' };
  this.gradebook.updateStudentRow(student);
  strictEqual(this.gradebook.gridData.rows[1], student);
});

test('invalidates the associated grid row', function () {
  this.gradebook.updateStudentRow({ id: '1102', name: 'Adam Jones' });
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 1);
});

test('includes the row index when invalidating the grid row', function () {
  this.gradebook.updateStudentRow({ id: '1102', name: 'Adam Jones' });
  const [row] = this.gradebook.gradebookGrid.invalidateRow.lastCall.args;
  strictEqual(row, 1);
});

test('does not update rows when the given student is not already included', function () {
  this.gradebook.updateStudentRow({ id: '1104', name: 'Dana Smith' });
  equal(typeof this.gradebook.gridData.rows[-1], 'undefined');
  deepEqual(this.gradebook.gridData.rows.map(row => row.id), ['1101', '1102', '1103']);
});

test('does not invalidate rows when the given student is not already included', function () {
  this.gradebook.updateStudentRow({ id: '1104', name: 'Dana Smith' });
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 0);
});

QUnit.module('sortByStudentColumn', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'Z' },
    { id: '4', sortable_name: 'A' }
  ];
  this.gradebook.sortByStudentColumn('sortable_name', 'ascending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.id, '4');
  strictEqual(secondRow.id, '3');
});

test('sorts the gradebook rows descending', function () {
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'A' },
    { id: '4', sortable_name: 'Z' }
  ];
  this.gradebook.sortByStudentColumn('sortable_name', 'descending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.id, '4');
  strictEqual(secondRow.id, '3');
});

test('sort gradebook rows by id when sortable names are the same', function () {
  this.gradebook.gridData.rows = [
    { id: '4', sortable_name: 'Same Name' },
    { id: '3', sortable_name: 'Same Name' }
  ];
  this.gradebook.sortByStudentColumn('sortable_name', 'ascending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.id, '3');
  strictEqual(secondRow.id, '4');
});

test('descending sort gradebook rows by id sortable names are the same and direction is descending', function () {
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'Same Name' },
    { id: '4', sortable_name: 'Same Name' }
  ];
  this.gradebook.sortByStudentColumn('someProperty', 'descending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.id, '4');
  strictEqual(secondRow.id, '3');
});

QUnit.module('sortByCustomColumn', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.gridData.rows = [
    { id: '3', custom_col_501: 'Z' },
    { id: '4', custom_col_501: 'A' }
  ];
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.custom_col_501, 'A');
  strictEqual(secondRow.custom_col_501, 'Z');
});

test('sorts the gradebook rows descending', function () {
  this.gradebook.gridData.rows = [
    { id: '4', custom_col_501: 'A' },
    { id: '3', custom_col_501: 'Z' }
  ];
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.custom_col_501, 'Z');
  strictEqual(secondRow.custom_col_501, 'A');
});

test('sort gradebook rows by sortable_name when setting key is the same', function () {
  this.gradebook.gridData.rows = [
    { id: '4', sortable_name: 'Jones, Adam', custom_col_501: '42' },
    { id: '3', sortable_name: 'Ford, Betty', custom_col_501: '42' }
  ];
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.sortable_name, 'Ford, Betty');
  strictEqual(secondRow.sortable_name, 'Jones, Adam');
});

test('descending sort gradebook rows by sortable_name when setting key is the same and direction is descending', function () {
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'Ford, Betty', custom_col_501: '42' },
    { id: '4', sortable_name: 'Jones, Adam', custom_col_501: '42' }
  ];
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.sortable_name, 'Jones, Adam');
  strictEqual(secondRow.sortable_name, 'Ford, Betty');
});

test('sort gradebook rows by id when setting key and sortable name are the same', function () {
  this.gradebook.gridData.rows = [
    { id: '4', sortable_name: 'Same Name', custom_col_501: '42' },
    { id: '3', sortable_name: 'Same Name', custom_col_501: '42' }
  ];
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.id, '3');
  strictEqual(secondRow.id, '4');
});

test('descending sort gradebook rows by id when setting key and sortable name are the same and direction is descending', function () {
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'Same Name', custom_col_501: '42' },
    { id: '4', sortable_name: 'Same Name', custom_col_501: '42' }
  ];
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  strictEqual(firstRow.id, '4');
  strictEqual(secondRow.id, '3');
});

QUnit.module('sortByAssignmentColumn', {
  setup () {
    this.gradebook = createGradebook();
    this.studentA = { name: 'Adam Jones' };
    this.studentB = { name: 'Betty Ford' };
    sandbox.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    sandbox.stub(this.gradebook, 'gradeSort');
    sandbox.stub(this.gradebook, 'missingSort');
    sandbox.stub(this.gradebook, 'lateSort');
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending');
  equal(this.gradebook.sortRowsBy.callCount, 1);
});

test('sorts using gradeSort when the settingKey is "grade"', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending');
  equal(this.gradebook.gradeSort.callCount, 1);
});

test('sorts by grade using the columnId', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending');
  const field = this.gradebook.gradeSort.getCall(0).args[2];
  equal(field, 'assignment_201');
});

test('optionally sorts by grade in ascending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'ascending');
  const [studentA, studentB, /* field */, ascending] = this.gradebook.gradeSort.getCall(0).args;
  equal(studentA, this.studentA, 'student A is in first position');
  equal(studentB, this.studentB, 'student B is in second position');
  equal(ascending, true, 'ascending is explicitly true');
});

test('optionally sorts by grade in descending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'grade', 'descending');
  const [studentA, studentB, /* field */, ascending] = this.gradebook.gradeSort.getCall(0).args;
  equal(studentA, this.studentA, 'student A is in first position');
  equal(studentB, this.studentB, 'student B is in second position');
  equal(ascending, false, 'ascending is explicitly false');
});

test('optionally sorts by missing in ascending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'missing', 'ascending');
  const columnId = this.gradebook.missingSort.getCall(0).args;
  equal(columnId, 'assignment_201');
});

test('optionally sorts by late in ascending order', function () {
  this.gradebook.sortByAssignmentColumn('assignment_201', 'late', 'ascending');
  const columnId = this.gradebook.lateSort.getCall(0).args;
  equal(columnId, 'assignment_201');
});

QUnit.module('sortByAssignmentGroupColumn', {
  setup () {
    this.gradebook = createGradebook();
    this.studentA = { name: 'Adam Jones' };
    this.studentB = { name: 'Betty Ford' };
    sandbox.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    sandbox.stub(this.gradebook, 'gradeSort');
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending');
  equal(this.gradebook.sortRowsBy.callCount, 1);
});

test('sorts by grade using gradeSort', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending');
  equal(this.gradebook.gradeSort.callCount, 1);
});

test('sorts by grade using the columnId', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending');
  const field = this.gradebook.gradeSort.getCall(0).args[2];
  equal(field, 'assignment_group_301');
});

test('optionally sorts by grade in ascending order', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'ascending');
  const [studentA, studentB, /* field */, ascending] = this.gradebook.gradeSort.getCall(0).args;
  equal(studentA, this.studentA, 'student A is in first position');
  equal(studentB, this.studentB, 'student B is in second position');
  equal(ascending, true, 'ascending is explicitly true');
});

test('optionally sorts by grade in descending order', function () {
  this.gradebook.sortByAssignmentGroupColumn('assignment_group_301', 'grade', 'descending');
  const [studentA, studentB, /* field */, ascending] = this.gradebook.gradeSort.getCall(0).args;
  equal(studentA, this.studentA, 'student A is in first position');
  equal(studentB, this.studentB, 'student B is in second position');
  equal(ascending, false, 'ascending is explicitly false');
});

QUnit.module('sortByTotalGradeColumn', {
  setup () {
    this.gradebook = createGradebook();
    this.studentA = { name: 'Adam Jones' };
    this.studentB = { name: 'Betty Ford' };
    sandbox.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    sandbox.stub(this.gradebook, 'gradeSort');
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.sortByTotalGradeColumn('ascending');
  equal(this.gradebook.sortRowsBy.callCount, 1);
});

test('sorts by grade using gradeSort', function () {
  this.gradebook.sortByTotalGradeColumn('ascending');
  equal(this.gradebook.gradeSort.callCount, 1);
});

test('sorts by "total_grade"', function () {
  this.gradebook.sortByTotalGradeColumn('ascending');
  const field = this.gradebook.gradeSort.getCall(0).args[2];
  equal(field, 'total_grade');
});

test('optionally sorts by grade in ascending order', function () {
  this.gradebook.sortByTotalGradeColumn('ascending');
  const [studentA, studentB, /* field */, ascending] = this.gradebook.gradeSort.getCall(0).args;
  equal(studentA, this.studentA, 'student A is in first position');
  equal(studentB, this.studentB, 'student B is in second position');
  equal(ascending, true, 'ascending is explicitly true');
});

test('optionally sorts by grade in descending order', function () {
  this.gradebook.sortByTotalGradeColumn('descending');
  const [studentA, studentB, /* field */, ascending] = this.gradebook.gradeSort.getCall(0).args;
  equal(studentA, this.studentA, 'student A is in first position');
  equal(studentB, this.studentB, 'student B is in second position');
  equal(ascending, false, 'ascending is explicitly false');
});

QUnit.module('Gradebook#sortGridRows', {
  setup () {
    this.gradebook = createGradebook();
    this.server = sinon.fakeServer.create({ respondImmediately: true });
    const options = { settings_update_url: '/course/1/gradebook_settings' };
    this.server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ]);
  },

  teardown () {
    this.server.restore()
  }
});

test('sorts by the student column by default', function () {
  sandbox.stub(this.gradebook, 'sortByStudentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByStudentColumn.callCount, 1);
});

test('uses the saved sort setting for student column sorting', function () {
  this.gradebook.setSortRowsBySetting('student_name', 'sortable_name', 'ascending');
  sandbox.stub(this.gradebook, 'sortByStudentColumn');
  this.gradebook.sortGridRows();

  const [settingKey, direction] = this.gradebook.sortByStudentColumn.getCall(0).args;
  equal(settingKey, 'sortable_name', 'parameter 1 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 2 is the sort direction');
});

test('optionally sorts by a custom column', function () {
  this.gradebook.setSortRowsBySetting('custom_col_501', null, 'ascending');
  sandbox.stub(this.gradebook, 'sortByCustomColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByCustomColumn.callCount, 1);
});

test('uses the saved sort setting for custom column sorting', function () {
  this.gradebook.setSortRowsBySetting('custom_col_501', null, 'ascending');
  sandbox.stub(this.gradebook, 'sortByCustomColumn');
  this.gradebook.sortGridRows();

  const [columnId, direction] = this.gradebook.sortByCustomColumn.getCall(0).args;
  equal(columnId, 'custom_col_501', 'parameter 1 is the sort columnId');
  equal(direction, 'ascending', 'parameter 2 is the sort direction');
});

test('optionally sorts by an assignment column', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'grade', 'ascending');
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1);
});

test('uses the saved sort setting for assignment sorting', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'grade', 'ascending');
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();

  const [columnId, settingKey, direction] = this.gradebook.sortByAssignmentColumn.getCall(0).args;
  equal(columnId, 'assignment_201', 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('optionally sorts by an assignment group column', function () {
  this.gradebook.setSortRowsBySetting('assignment_group_301', 'grade', 'ascending');
  sandbox.stub(this.gradebook, 'sortByAssignmentGroupColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentGroupColumn.callCount, 1);
});

test('uses the saved sort setting for assignment group sorting', function () {
  this.gradebook.setSortRowsBySetting('assignment_group_301', 'grade', 'ascending');
  sandbox.stub(this.gradebook, 'sortByAssignmentGroupColumn');
  this.gradebook.sortGridRows();

  const [columnId, settingKey, direction] = this.gradebook.sortByAssignmentGroupColumn.getCall(0).args;
  equal(columnId, 'assignment_group_301', 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('optionally sorts by the total grade column', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  sandbox.stub(this.gradebook, 'sortByTotalGradeColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByTotalGradeColumn.callCount, 1);
});

test('uses the saved sort setting for total grade sorting', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  sandbox.stub(this.gradebook, 'sortByTotalGradeColumn');
  this.gradebook.sortGridRows();

  const [direction] = this.gradebook.sortByTotalGradeColumn.getCall(0).args;
  equal(direction, 'ascending', 'the only parameter is the sort direction');
});

test('optionally sorts by missing', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'missing', 'ascending');
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1);
});

test('optionally sorts by late', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'late', 'ascending');
  sandbox.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1);
});

test('updates the column headers after sorting', function () {
  sandbox.stub(this.gradebook, 'sortByStudentColumn');
  sandbox.stub(this.gradebook, 'updateColumnHeaders').callsFake(() => {
    equal(this.gradebook.sortByStudentColumn.callCount, 1, 'sorting method was called first');
  });
  this.gradebook.sortGridRows();
})

QUnit.module('Gradebook#filterAssignments', {
  setup () {
    this.assignments = [
      {
        assignment_group: { position: 1 },
        id: '2301',
        position: 1,
        name: 'published graded',
        published: true,
        submission_types: ['online_text_entry'],
        assignment_group_id: '1',
        module_ids: ['2']
      }, {
        assignment_group: { position: 2 },
        id: '2302',
        position: 2,
        name: 'unpublished',
        published: false,
        submission_types: ['online_text_entry'],
        assignment_group_id: '2',
        module_ids: ['1']
      }, {
        assignment_group: { position: 2 },
        id: '2303',
        position: 3,
        name: 'not graded',
        published: true,
        submission_types: ['not_graded'],
        assignment_group_id: '2',
        module_ids: ['2']
      }, {
        assignment_group: { position: 1 },
        id: '2304',
        position: 4,
        name: 'attendance',
        published: true,
        submission_types: ['attendance'],
        assignment_group_id: '1',
        module_ids: ['1']
      }
    ];
    this.gradebook = createGradebook();
    this.gradebook.setAssignmentGroups([
      { id: '1', name: 'Assignments', position: 1 },
      { id: '2', name: 'Homework', position: 2 }
    ]);
    this.gradebook.courseContent.gradingPeriodAssignments = {
      1401: ['2301', '2303'],
      1402: ['2302', '2304']
    };
    this.gradebook.gradingPeriodSet = { id: '1501', gradingPeriods: [{ id: '1401' }, { id: '1402' }] };
    this.gradebook.gridDisplaySettings.showUnpublishedAssignments = true;
    this.gradebook.show_attendance = true;
  }
});

test('excludes "not_graded" assignments', function () {
  const assignments = this.gradebook.filterAssignments(this.assignments);
  strictEqual(assignments.findIndex(assignment => assignment.id === '2303'), -1);
});

test('excludes "unpublished" assignments when "showUnpublishedAssignments" is false', function () {
  this.gradebook.gridDisplaySettings.showUnpublishedAssignments = false;
  const assignments = this.gradebook.filterAssignments(this.assignments);
  strictEqual(assignments.findIndex(assignment => assignment.id === '2302'), -1);
});

test('includes "unpublished" assignments when "showUnpublishedAssignments" is true', function () {
  this.gradebook.gridDisplaySettings.showUnpublishedAssignments = true;
  const assignments = this.gradebook.filterAssignments(this.assignments);
  notEqual(assignments.findIndex(assignment => assignment.id === '2302'), -1);
});

test('excludes "attendance" assignments when "show_attendance" is false', function () {
  this.gradebook.show_attendance = false;
  const assignments = this.gradebook.filterAssignments(this.assignments);
  strictEqual(assignments.findIndex(assignment => assignment.id === '2304'), -1);
});

test('includes "attendance" assignments when "show_attendance" is true', function () {
  this.gradebook.show_attendance = true;
  const assignments = this.gradebook.filterAssignments(this.assignments);
  notEqual(assignments.findIndex(assignment => assignment.id === '2304'), -1);
});

test('includes assignments from all grading periods when not filtering by grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0'); // value indicates "All Grading Periods"
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2301', '2302', '2304']);
});

test('excludes assignments from other grading periods when filtering by a grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401');
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2301']);
});

test('includes assignments from all grading periods grading period set has not been assigned', function () {
  this.gradebook.gradingPeriodSet = null;
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401');
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2301', '2302', '2304']);
});

test('includes assignments from all modules when not filtering by module', function () {
  this.gradebook.setFilterColumnsBySetting('contextModuleId', '0'); // All Modules
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2301', '2302', '2304']);
});

test('excludes assignments from other modules when filtering by a module', function () {
  this.gradebook.setFilterColumnsBySetting('contextModuleId', '2');
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2301']);
});

test('includes assignments from all assignment groups when not filtering by assignment group', function () {
  this.gradebook.setFilterColumnsBySetting('assignmentGroupId', '0'); // All Modules
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2301', '2302', '2304']);
});

test('excludes assignments from other assignment groups when filtering by an assignment group', function () {
  this.gradebook.setFilterColumnsBySetting('assignmentGroupId', '2');
  const assignments = this.gradebook.filterAssignments(this.assignments);
  deepEqual(_.map(assignments, 'id'), ['2302']);
});

QUnit.module('Gradebook Grid Events', function (suiteHooks) {
  suiteHooks.beforeEach(function () {
    $fixtures.innerHTML = `
      <div id="application">
        <span data-component="GridColor"></span>
        <div id="gradebook_grid"></div>
        <div id="example-gradebook-cell">
          <a class="student-grades-link" href="#">Student Name</a>
        </div>
      </div>
    `;

    this.studentColumnHeader = {
      focusAtEnd: sinon.spy(),
      focusAtStart: sinon.spy(),
      handleKeyDown: sinon.stub()
    };

    this.gradebook = createGradebook();
    sinon.stub(this.gradebook, 'setVisibleGridColumns');
    sinon.stub(this.gradebook, 'onGridInit');

    this.gradebook.createGrid();
    this.gradebook.setHeaderComponentRef('student', this.studentColumnHeader);
  });

  suiteHooks.afterEach(function () {
    this.gradebook.destroy();
  });

  this.triggerEvent = function (eventName, event, location) {
    return this.gradebook.gradebookGrid.gridSupport.events[eventName].trigger(event, location);
  };

  QUnit.module('onActiveLocationChanged', {
    setup () {
      this.$studentGradesLink = $fixtures.querySelector('.student-grades-link');
    }
  });

  test('sets focus on the student grades link when a "student" body cell becomes active', function () {
    const clock = sinon.useFakeTimers();
    sandbox.stub(this.gradebook.gradebookGrid.gridSupport.state, 'getActiveNode')
      .returns($fixtures.querySelector('#example-gradebook-cell'));
    this.triggerEvent('onActiveLocationChanged', {}, { columnId: 'student', region: 'body' });
    clock.tick(0);
    strictEqual(document.activeElement, this.$studentGradesLink);
    clock.restore();
  });

  test('does nothing when a "student" body cell without a student grades link becomes active', function () {
    const clock = sinon.useFakeTimers();
    const previousActiveElement = document.activeElement;
    $fixtures.querySelector('#example-gradebook-cell').innerHTML = 'Student Name';
    sandbox.stub(this.gradebook.gradebookGrid.gridSupport.state, 'getActiveNode')
      .returns($fixtures.querySelector('#example-gradebook-cell'));
    this.triggerEvent('onActiveLocationChanged', {}, { columnId: 'student', region: 'body' });
    clock.tick(0);
    strictEqual(document.activeElement, previousActiveElement);
    clock.restore();
  });

  test('does not change focus when a "student" header cell becomes active', function () {
    const clock = sinon.useFakeTimers();
    this.triggerEvent('onActiveLocationChanged', {}, { columnId: 'student', region: 'header' });
    clock.tick(0);
    notEqual(document.activeElement, this.$studentGradesLink);
    clock.restore();
  });

  test('does not change focus when body cells of other columns become active', function () {
    const clock = sinon.useFakeTimers();
    this.triggerEvent('onActiveLocationChanged', {}, { columnId: 'total_grade', region: 'body' });
    clock.tick(0);
    notEqual(document.activeElement, this.$studentGradesLink);
    clock.restore();
  });

  QUnit.module('onKeyDown');

  test('calls handleKeyDown on the column header component associated with the event location', function () {
    this.triggerEvent('onKeyDown', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.handleKeyDown.callCount, 1);
  });

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onKeyDown', {}, { columnId: 'student', region: 'body' });
    strictEqual(this.studentColumnHeader.handleKeyDown.callCount, 0);
  });

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student');
    this.triggerEvent('onKeyDown', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.handleKeyDown.callCount, 0);
  });

  test('includes the event when calling handleKeyDown', function () {
    const event = {};
    this.triggerEvent('onKeyDown', event, { columnId: 'student', region: 'header' });
    const { args } = this.studentColumnHeader.handleKeyDown.lastCall;
    equal(args[0], event);
  });

  test('returns the return value of the handled event', function () {
    this.studentColumnHeader.handleKeyDown.returns(false);
    const returnValue = this.triggerEvent('onKeyDown', {}, { columnId: 'student', region: 'header' });
    strictEqual(returnValue, false);
  });

  QUnit.module('onNavigatePrev');

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigatePrev', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1);
  });

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigatePrev', {}, { columnId: 'student', region: 'body' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student');
    this.triggerEvent('onNavigatePrev', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  QUnit.module('onNavigateNext');

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigateNext', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1);
  });

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigateNext', {}, { columnId: 'student', region: 'body' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student');
    this.triggerEvent('onNavigateNext', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  QUnit.module('onNavigateLeft');

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigateLeft', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1);
  });

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigateLeft', {}, { columnId: 'student', region: 'body' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student');
    this.triggerEvent('onNavigateLeft', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  QUnit.module('onNavigateRight');

  test('calls focusAtStart on the column header component associated with the event location', function () {
    this.triggerEvent('onNavigateRight', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1);
  });

  test('does nothing when the location region is not "header"', function () {
    this.triggerEvent('onNavigateRight', {}, { columnId: 'student', region: 'body' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  test('does nothing when no component is referenced for the given column', function () {
    this.gradebook.removeHeaderComponentRef('student');
    this.triggerEvent('onNavigateRight', {}, { columnId: 'student', region: 'header' });
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
  });

  QUnit.module('onNavigateUp');

  test('calls focusAtStart on the column header component associated with the event location', function () {
    const clock = sinon.useFakeTimers();
    this.triggerEvent('onNavigateUp', {}, { columnId: 'student', region: 'header' });
    clock.tick(0);
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 1);
    clock.restore();
  });

  test('does nothing when the location region is not "header"', function () {
    const clock = sinon.useFakeTimers();
    this.triggerEvent('onNavigateUp', {}, { columnId: 'student', region: 'body' });
    clock.tick(0);
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
    clock.restore();
  });

  test('does nothing when no component is referenced for the given column', function () {
    const clock = sinon.useFakeTimers();
    this.gradebook.removeHeaderComponentRef('student');
    this.triggerEvent('onNavigateUp', {}, { columnId: 'student', region: 'header' });
    clock.tick(0);
    strictEqual(this.studentColumnHeader.focusAtStart.callCount, 0);
    clock.restore();
  });

  QUnit.module('onColumnsReordered', (hooks) => {
    let gradebook;
    let allColumns;
    let columns;

    hooks.beforeEach(() => {
      gradebook = createGradebook();
      allColumns = [
        { id: 'student', type: 'student' },
        { id: 'custom_col_2401', type: 'custom_column', customColumnId: '2401' },
        { id: 'custom_col_2402', type: 'custom_column', customColumnId: '2402' },
        { id: 'assignment_2301', type: 'assignment' },
        { id: 'assignment_2302', type: 'assignment' },
        { id: 'assignment_group_2201', type: 'assignment_group' },
        { id: 'assignment_group_2202', type: 'assignment_group' },
        { id: 'total_grade', type: 'total_grade' }
      ];
      columns = {
        frozen: allColumns.slice(0, 3),
        scrollable: allColumns.slice(3)
      };

      gradebook.gridData.columns.definitions = allColumns.reduce((map, column) => (
        { ...map, [column.id]: column }
      ), {});
      gradebook.gridData.columns.frozen = columns.frozen.map(column => column.id);
      gradebook.gridData.columns.scrollable = columns.scrollable.map(column => column.id);

      sinon.stub(gradebook, 'reorderCustomColumns').returns(Promise.resolve());
      sinon.stub(gradebook, 'renderViewOptionsMenu');
      sinon.stub(gradebook, 'updateColumnHeaders');
      sinon.stub(gradebook, 'saveCustomColumnOrder');
    });

    test('reorders custom columns when frozen columns were reordered', () => {
      columns.frozen = [allColumns[0], allColumns[2], allColumns[1]];
      columns.scrollable = allColumns.slice(3, 8);
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns);
      strictEqual(gradebook.reorderCustomColumns.callCount, 1);
    });

    test('does not reorder custom columns when custom column order was not affected', () => {
      columns.frozen = [allColumns[1], allColumns[0], allColumns[2]];
      columns.scrollable = allColumns.slice(3, 8);
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns);
      strictEqual(gradebook.reorderCustomColumns.callCount, 0);
    });

    test('stores custom column order when scrollable columns were reordered', () => {
      columns.frozen = allColumns.slice(0, 3);
      columns.scrollable = [allColumns[7], ...allColumns.slice(3, 7)];
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns);
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 1);
    });

    test('re-renders the View options menu', () => {
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns);
      strictEqual(gradebook.renderViewOptionsMenu.callCount, 1);
    });

    test('re-renders all column headers', () => {
      gradebook.gradebookGrid.events.onColumnsReordered.trigger(null, columns);
      strictEqual(gradebook.updateColumnHeaders.callCount, 1);
    });
  });
});

QUnit.module('Gradebook#onGridKeyDown', {
  setup () {
    const columns = [
      { id: 'student', type: 'student' },
      { id: 'assignment_2301', type: 'assignment' }
    ];
    this.gradebook = createGradebook();
    this.grid = {
      getColumns () { return columns }
    };
  }
});

test('skips SlickGrid default behavior when pressing "enter" on a "student" cell', function () {
  const event = { which: 13, originalEvent: {} };
  this.gradebook.onGridKeyDown(event, { grid: this.grid, cell: 0, row: 0 }); // 0 is the index of the 'student' column
  strictEqual(event.originalEvent.skipSlickGridDefaults, true);
});

test('does not skip SlickGrid default behavior when pressing other keys on a "student" cell', function () {
  const event = { which: 27, originalEvent: {} };
  this.gradebook.onGridKeyDown(event, { grid: this.grid, cell: 0, row: 0 }); // 0 is the index of the 'student' column
  notOk('skipSlickGridDefaults' in event.originalEvent, 'skipSlickGridDefaults is not applied');
});

test('does not skip SlickGrid default behavior when pressing "enter" on other cells', function () {
  const event = { which: 27, originalEvent: {} };
  this.gradebook.onGridKeyDown(event, { grid: this.grid, cell: 1, row: 0 }); // 1 is the index of the 'assignment' column
  notOk('skipSlickGridDefaults' in event.originalEvent, 'skipSlickGridDefaults is not applied');
});

test('does not skip SlickGrid default behavior when pressing "enter" off the grid', function () {
  const event = { which: 27, originalEvent: {} };
  this.gradebook.onGridKeyDown(event, { grid: this.grid, cell: undefined, row: undefined });
  notOk('skipSlickGridDefaults' in event.originalEvent, 'skipSlickGridDefaults is not applied');
});

QUnit.module('Gradebook Grid Events', () => {
  QUnit.module('#onBeforeEditCell', (hooks) => {
    let gradebook;
    let eventObject;

    hooks.beforeEach(() => {
      gradebook = createGradebook();
      gradebook.initSubmissionStateMap();
      gradebook.gradebookContent.customColumns = [
        { id: '1', teacher_notes: false, hidden: false, title: 'Read Only', read_only: true },
        { id: '2', teacher_notes: false, hidden: false, title: 'Not Read Only', read_only: false }
      ];
      gradebook.students = { 1101: { id: '1101', isConcluded: false } };
      eventObject = {
        column: { assignmentId: '2301', type: 'assignment' },
        item: { id: '1101' }
      };
      sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ locked: false });
    });

    test('returns true to allow editing the cell', () => {
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), true);
    });

    test('returns false when the student does not exist', () => {
      delete gradebook.students[1101];
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), false);
    });

    test('returns true when the cell is not in an assignment column', () => {
      eventObject.column = { type: 'custom_column' };
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), true);
    });

    test('returns false when the cell is read_only', () => {
      eventObject.column = { type: 'custom_column', customColumnId: '1' };
      strictEqual(gradebook.onBeforeEditCell(null, eventObject), false);
    });
  });

  QUnit.module('onColumnsResized', (hooks) => {
    let gradebook;
    let columns;

    hooks.beforeEach(() => {
      gradebook = createGradebook();
      columns = [
        { id: 'student', width: 120 },
        { id: 'assignment_2301', width: 140 },
        { id: 'total_grade', width: 100 }
      ];
      sinon.stub(gradebook, 'saveColumnWidthPreference');
    });

    test('saves the column width preference', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns.slice(0, 1));
      strictEqual(gradebook.saveColumnWidthPreference.callCount, 1);
    });

    test('saves the column width preference for multiple columns', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns);
      strictEqual(gradebook.saveColumnWidthPreference.callCount, 3);
    });

    test('includes the column id when saving the column width preference', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns);
      const ids = gradebook.saveColumnWidthPreference.getCalls().map(call => call.args[0]);
      deepEqual(ids, ['student', 'assignment_2301', 'total_grade']);
    });

    test('includes the column width when saving the column width preference', () => {
      gradebook.gradebookGrid.events.onColumnsResized.trigger(null, columns);
      const widths = gradebook.saveColumnWidthPreference.getCalls().map(call => call.args[1]);
      deepEqual(widths, [120, 140, 100]);
    });
  });
});

QUnit.module('Gradebook#getCustomColumnId');

test('returns a unique key for the custom column', function () {
  const gradebook = createGradebook();
  equal(gradebook.getCustomColumnId('2401'), 'custom_col_2401');
});

QUnit.module('Gradebook#getAssignmentColumnId');

test('returns a unique key for the assignment column', function () {
  const gradebook = createGradebook();
  equal(gradebook.getAssignmentColumnId('201'), 'assignment_201');
});

QUnit.module('Gradebook#getAssignmentGroupColumnId');

test('returns a unique key for the assignment group column', function () {
  const gradebook = createGradebook();
  equal(gradebook.getAssignmentGroupColumnId('301'), 'assignment_group_301');
});

QUnit.module('Gradebook#updateColumnHeaders', {
  setup () {
    const columns = [
      { type: 'assignment_group', assignmentGroupId: '2201' },
      { type: 'assignment', assignmentId: '2301' },
      { type: 'custom_column', customColumnId: '2401' },
      { type: 'total_grade' }
    ];
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub()
      }
    };
    this.gradebook.gradebookGrid.grid = {
      getColumns () {
        return columns;
      }
    };
  }
});

test('uses Grid Support to update the column headers', function () {
  this.gradebook.updateColumnHeaders();
  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
});

QUnit.module('Gradebook#listRowIndicesForStudentIds');

test('returns a row index for each student id', function () {
  const gradebook = createGradebook();
  gradebook.gridData.rows = [
    { id: '1101' },
    { id: '1102' },
    { id: '1103' },
    { id: '1104' }
  ];
  deepEqual(gradebook.listRowIndicesForStudentIds(['1102', '1104']), [1, 3]);
});

QUnit.module('Gradebook#updateRowCellsForStudentIds', {
  setup () {
    const columns = [
      { id: 'student', type: 'student' },
      { id: 'assignment_232', type: 'assignment' },
      { id: 'total_grade', type: 'total_grade' },
      { id: 'assignment_group_12', type: 'assignment' }
    ];
    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [
      { id: '1101' },
      { id: '1102' }
    ];
    this.gradebook.gradebookGrid.grid = {
      updateCell: sinon.stub(),
      getColumns () { return columns },
    };
  }
});

test('updates cells for each column', function () {
  this.gradebook.updateRowCellsForStudentIds(['1101']);
  strictEqual(this.gradebook.gradebookGrid.grid.updateCell.callCount, 4, 'called once per column');
});

test('includes the row index of the student when updating', function () {
  this.gradebook.updateRowCellsForStudentIds(['1102']);
  const rows = _.map(this.gradebook.gradebookGrid.grid.updateCell.args, args => args[0]); // get the first arg of each call
  deepEqual(rows, [1, 1, 1, 1], 'each call specified row 1 (student 1102)');
});

test('includes the index of each column when updating', function () {
  this.gradebook.updateRowCellsForStudentIds(['1101', '1102']);
  const rows = _.map(this.gradebook.gradebookGrid.grid.updateCell.args, args => args[1]); // get the first arg of each call
  deepEqual(rows, [0, 1, 2, 3, 0, 1, 2, 3]);
});

test('updates row cells for each student', function () {
  this.gradebook.updateRowCellsForStudentIds(['1101', '1102']);
  strictEqual(this.gradebook.gradebookGrid.grid.updateCell.callCount, 8, 'called once per student, per column');
});

test('has no effect when the grid has not been initialized', function () {
  this.gradebook.gradebookGrid.grid = null;
  this.gradebook.updateRowCellsForStudentIds(['1101']);
  ok(true, 'no error was thrown');
});

QUnit.module('Gradebook#invalidateRowsForStudentIds', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [
      { id: '1101' },
      { id: '1102' }
    ];
    sandbox.stub(this.gradebook.gradebookGrid, 'invalidateRow');
    sandbox.stub(this.gradebook.gradebookGrid, 'render');
  }
});

test('invalidates each student row', function () {
  this.gradebook.invalidateRowsForStudentIds(['1101', '1102']);
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 2, 'called once per student row');
});

test('includes the row index of the student when invalidating', function () {
  this.gradebook.invalidateRowsForStudentIds(['1101', '1102']);
  const rows = _.map(this.gradebook.gradebookGrid.invalidateRow.args, args => args[0]); // get the first arg of each call
  deepEqual(rows, [0, 1]);
});

test('re-renders the grid after invalidating', function () {
  this.gradebook.gradebookGrid.render.callsFake(() => {
    strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 2, 'both rows have already been validated');
  });
  this.gradebook.invalidateRowsForStudentIds(['1101', '1102']);
});

test('does not invalidate rows for students not included', function () {
  this.gradebook.invalidateRowsForStudentIds(['1102']);
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.callCount, 1, 'called once');
  strictEqual(this.gradebook.gradebookGrid.invalidateRow.lastCall.args[0], 1, 'called for the row (1) of student 1102');
});

test('has no effect when the grid has not been initialized', function () {
  this.gradebook.gradebookGrid.grid = null;
  this.gradebook.invalidateRowsForStudentIds(['1101']);
  ok(true, 'no error was thrown');
});

QUnit.module('Gradebook Rows', function () {
  QUnit.module('#buildRows', function () {
    test('invalidates the grid', function () {
      const gradebook = createGradebook();
      sinon.spy(gradebook.gradebookGrid, 'invalidate');
      gradebook.buildRows();
      strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1);
      gradebook.destroy();
    });
  });
});

QUnit.module('Gradebook#gotSubmissionsChunk', function (hooks) {
  let studentSubmissions;

  hooks.beforeEach(function () {
    $fixtures.innerHTML = `
      <div id="application">
        <div id="wrapper">
          <div id="StudentTray__Container"></div>
          <span data-component="GridColor"></span>
          <div id="gradebook_grid"></div>
        </div>
      </div>
    `;

    this.gradebook = createGradebook();
    this.gradebook.initGrid();

    const students = [{
      id: '1101',
      name: 'Adam Jones',
      enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }]
    }, {
      id: '1102',
      name: 'Betty Ford',
      enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }]
    }];
    this.gradebook.gotChunkOfStudents(students);
    sinon.stub(this.gradebook, 'updateSubmission');
    sinon.spy(this.gradebook, 'setupGrading');

    studentSubmissions = [{
      submissions: [{
        assignment_id: '201',
        assignment_visible: true,
        cached_due_date: '2015-02-01T12:00:00Z',
        score: 10,
        user_id: '1101'
      }, {
        assignment_id: '202',
        assignment_visible: true,
        cached_due_date: '2015-02-02T12:00:00Z',
        score: 9,
        user_id: '1101'
      }],
      user_id: '1101'
    }, {
      submissions: [{
        assignment_id: '201',
        assignment_visible: true,
        cached_due_date: '2015-02-03T12:00:00Z',
        score: 8,
        user_id: '1102'
      }],
      user_id: '1102'
    }];
    this.gradebook.setAssignmentGroups({
      9000: { group_weight: 100 }
    })
    this.gradebook.setAssignments({
      201: { id: '201', assignment_group_id: '9000', name: 'Math Assignment', published: true },
      202: { id: '202', assignment_group_id: '9000', name: 'English Assignment', published: false }
    })
  });

  hooks.afterEach(function () {
    this.gradebook.destroy();
    $fixtures.innerHTML = '';
  });

  test('updates effectiveDueDates with the submissions', function () {
    this.gradebook.gotSubmissionsChunk(studentSubmissions);
    deepEqual(Object.keys(this.gradebook.effectiveDueDates), ['201', '202']);
    deepEqual(Object.keys(this.gradebook.effectiveDueDates[201]), ['1101', '1102']);
    deepEqual(Object.keys(this.gradebook.effectiveDueDates[202]), ['1101']);
  });

  test('updates effectiveDueDates on related assignments', function () {
    this.gradebook.gotSubmissionsChunk(studentSubmissions);
    deepEqual(Object.keys(this.gradebook.getAssignment('201').effectiveDueDates), ['1101', '1102']);
    deepEqual(Object.keys(this.gradebook.getAssignment('202').effectiveDueDates), ['1101']);
  });

  test('updates inClosedGradingPeriod on related assignments', function () {
    this.gradebook.gotSubmissionsChunk(studentSubmissions);
    strictEqual(this.gradebook.getAssignment('201').inClosedGradingPeriod, false);
    strictEqual(this.gradebook.getAssignment('202').inClosedGradingPeriod, false);
  });

  test('sets up grading for the related students', function () {
    this.gradebook.gotSubmissionsChunk(studentSubmissions);
    const [students] = this.gradebook.setupGrading.lastCall.args;
    deepEqual(students.map(student => student.id), ['1101', '1102']);
  });
});

QUnit.module('Gradebook Assignment Student Visibility', function (moduleHooks) {
  let gradebook;
  let allStudents;
  let assignments;

  moduleHooks.beforeEach(function () {
    gradebook = createGradebook();

    allStudents = [{
      id: '1101',
      name: 'Adam Jones',
      enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }]
    }, {
      id: '1102',
      name: 'Betty Ford',
      enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }]
    }];

    assignments = [{
      id: '2301',
      assignment_visibility: null,
      only_visible_to_overrides: false
    }, {
      id: '2302',
      assignment_visibility: ['1102'],
      only_visible_to_overrides: true
    }];

    gradebook.gotAllAssignmentGroups([
      { id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1) },
      { id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2) }
    ]);
  });

  QUnit.module('#studentsThatCanSeeAssignment', function (hooks) {
    let saveSettingsStub

    hooks.beforeEach(() => {
      saveSettingsStub = sinon.stub(gradebook, 'saveSettings')
    })

    hooks.afterEach(() => {
      saveSettingsStub.restore()
    })

    test('returns all students when the assignment is visible to everyone', function () {
      gradebook.gotChunkOfStudents(allStudents);
      const students = gradebook.studentsThatCanSeeAssignment('2301');
      deepEqual(Object.keys(students).sort(), ['1101', '1102']);
    });

    test('returns only students with visibility when the assignment is not visible to everyone', function () {
      gradebook.gotChunkOfStudents(allStudents);
      const students = gradebook.studentsThatCanSeeAssignment('2302');
      deepEqual(Object.keys(students), ['1102']);
    });

    test('returns an empty collection when related students are not loaded', function () {
      gradebook.gotChunkOfStudents(allStudents.slice(0, 1));
      const students = gradebook.studentsThatCanSeeAssignment('2302');
      deepEqual(Object.keys(students), []);
    });

    test('returns an up-to-date collection when student data has changed', function () {
      // this ensures cached visibility data is invalidated when student data changes
      gradebook.gotChunkOfStudents(allStudents.slice(0, 1));
      let students = gradebook.studentsThatCanSeeAssignment('2302'); // first cache
      gradebook.gotChunkOfStudents(allStudents.slice(1, 2));
      students = gradebook.studentsThatCanSeeAssignment('2302'); // re-cache
      deepEqual(Object.keys(students), ['1102']);
    });
  });
});

QUnit.module('Gradebook#setSortRowsBySetting', (hooks) => {
  let server
  let options
  let gradebook

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({ respondImmediately: true })
    options = { settings_update_url: '/course/1/gradebook_settings' }
    server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ])
    gradebook = createGradebook(options);
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('sets the "sort rows by" setting', function () {
    gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending');
    const sortRowsBySetting = gradebook.getSortRowsBySetting();
    equal(sortRowsBySetting.columnId, 'assignment_201');
    equal(sortRowsBySetting.settingKey, 'grade');
    equal(sortRowsBySetting.direction, 'descending');
  });

  test('sorts the grid rows after updating the setting', function () {
    sandbox.stub(gradebook, 'sortGridRows').callsFake(() => {
      const sortRowsBySetting = gradebook.getSortRowsBySetting();
      equal(sortRowsBySetting.columnId, 'assignment_201', 'sortRowsBySetting.columnId was set beforehand');
      equal(sortRowsBySetting.settingKey, 'grade', 'sortRowsBySetting.settingKey was set beforehand');
      equal(sortRowsBySetting.direction, 'descending', 'sortRowsBySetting.direction was set beforehand');
    });
    gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending');
  });
})

QUnit.module('Gradebook#sortRowsWithFunction', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [
      { id: '3', sortable_name: 'Z Lastington', someProperty: false },
      { id: '4', sortable_name: 'A Firstington', someProperty: true }
    ];
  },
  sortFn (row) { return row.someProperty; }
});

test('returns two objects in the rows collection', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn);

  equal(this.gradebook.gridData.rows.length, 2);
});

test('sorts with a passed in function', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn);
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '4', 'when fn is true, order first');
  equal(secondRow.id, '3', 'when fn is false, order second');
});

test('sorts by descending when asc is false', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn, { asc: false });
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '3', 'when fn is false, order first');
  equal(secondRow.id, '4', 'when fn is true, order second');
});

test('relies on localeSort when rows have equal sorting criteria results', function () {
  const value = 0;
  this.gradebook.gridData.rows[0].someProperty = value;
  this.gradebook.gridData.rows[1].someProperty = value;
  this.gradebook.sortRowsWithFunction(this.sortFn);
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.sortable_name, 'A Firstington', 'A Firstington sorts first');
  equal(secondRow.sortable_name, 'Z Lastington', 'Z Lastington sorts second');
});

test('relies on idSort when rows have equal sorting criteria and the same sortable name', function () {
  const value = 0;
  this.gradebook.gridData.rows[0].someProperty = value;
  this.gradebook.gridData.rows[1].someProperty = value;
  const name = 'Same Name';
  this.gradebook.gridData.rows[0].sortable_name = name;
  this.gradebook.gridData.rows[1].sortable_name = name;
  this.gradebook.sortRowsWithFunction(this.sortFn);
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '3', 'lower id sorts first');
  equal(secondRow.id, '4', 'higher id sorts second');
});

test('relies on descending idSort when rows have equal sorting criteria and the same sortable name', function () {
  const value = 0;
  this.gradebook.gridData.rows[0].someProperty = value;
  this.gradebook.gridData.rows[1].someProperty = value;
  const name = 'Same Name';
  this.gradebook.gridData.rows[0].sortable_name = name;
  this.gradebook.gridData.rows[1].sortable_name = name;
  this.gradebook.sortRowsWithFunction(this.sortFn, { asc: false });
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '4', 'higher id sorts first');
  equal(secondRow.id, '3', 'lower id sorts second');
});

QUnit.module('Gradebook#missingSort', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [
      { id: '3', sortable_name: 'Z Lastington', assignment_201: { missing: false }},
      { id: '4', sortable_name: 'A Firstington', assignment_201: { missing: true }}
    ];
  }
});

test('sorts by missing', function () {
  this.gradebook.missingSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '4', 'when missing is true, order first');
  equal(secondRow.id, '3', 'when missing is false, order second');
});

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.gridData.rows = [
    { id: '1', sortable_name: 'Z Last Graded', assignment_201: { missing: false }},
    { id: '3', sortable_name: 'Z Last Missing', assignment_201: { missing: true }},
    { id: '2', sortable_name: 'A First Graded', assignment_201: { missing: false }},
    { id: '4', sortable_name: 'A First Missing', assignment_201: { missing: true }}
  ];
  this.gradebook.missingSort('assignment_201');
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows;

  equal(firstRow.sortable_name, 'A First Missing', 'A First Missing sorts first');
  equal(secondRow.sortable_name, 'Z Last Missing', 'Z Last Missing sorts second');
  equal(thirdRow.sortable_name, 'A First Graded', 'A First Graded sorts third');
  equal(fourthRow.sortable_name, 'Z Last Graded', 'Z Last Graded sorts fourth');
});

test('relies on id sorting when rows have equal sorting criteria results and same sortable name', function () {
  this.gradebook.gridData.rows = [
    { id: '2', sortable_name: 'Student Name', assignment_201: { missing: true }},
    { id: '3', sortable_name: 'Student Name', assignment_201: { missing: true }},
    { id: '4', sortable_name: 'Student Name', assignment_201: { missing: true }},
    { id: '1', sortable_name: 'Student Name', assignment_201: { missing: true }}
  ];
  this.gradebook.missingSort('assignment_201');
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '1');
  equal(secondRow.id, '2');
  equal(thirdRow.id, '3');
  equal(fourthRow.id, '4');
});

test('when no submission is found, it is missing', function () {
  // Since SubmissionStateMap always creates an assignment key even when there
  // is no corresponding submission, the correct way to test this is to have a
  // key for the assignment with a missing criteria key
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'Z Lastington', assignment_201: { missing: false }},
    { id: '4', sortable_name: 'A Firstington', assignment_201: {} }
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '4', 'missing assignment sorts first');
  equal(secondRow.id, '3', 'graded assignment sorts second');
})

QUnit.module('Gradebook#lateSort', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [
      { id: '3', sortable_name: 'Z Lastington', assignment_201: { late: false }},
      { id: '4', sortable_name: 'A Firstington', assignment_201: { late: true }}
    ];
  }
});

test('sorts by late', function () {
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '4', 'when late is true, order first');
  equal(secondRow.id, '3', 'when late is false, order second');
});

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.gridData.rows = [
    { id: '1', sortable_name: 'Z Last Not Late', assignment_201: { late: false }},
    { id: '3', sortable_name: 'Z Last Late', assignment_201: { late: true }},
    { id: '2', sortable_name: 'A First Not Late', assignment_201: { late: false }},
    { id: '4', sortable_name: 'A First Late', assignment_201: { late: true }}
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows;

  equal(firstRow.sortable_name, 'A First Late', 'A First Late sorts first');
  equal(secondRow.sortable_name, 'Z Last Late', 'Z Last Late sorts second');
  equal(thirdRow.sortable_name, 'A First Not Late', 'A First Not Late sorts third');
  equal(fourthRow.sortable_name, 'Z Last Not Late', 'Z Last Not Late sorts fourth');
});

test('relies on id sort when rows have equal sorting criteria results and the same sortable name', function () {
  this.gradebook.gridData.rows = [
    { id: '4', sortable_name: 'Student Name', assignment_201: { late: true }},
    { id: '3', sortable_name: 'Student Name', assignment_201: { late: true }},
    { id: '2', sortable_name: 'Student Name', assignment_201: { late: true }},
    { id: '1', sortable_name: 'Student Name', assignment_201: { late: true }}
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '1');
  equal(secondRow.id, '2');
  equal(thirdRow.id, '3');
  equal(fourthRow.id, '4');
});

test('when no submission is found, it is not late', function () {
  // Since SubmissionStateMap always creates an assignment key even when there
  // is no corresponding submission, the correct way to test this is to have a
  // key for the assignment with a missing criteria key (e.g. `late`)
  this.gradebook.gridData.rows = [
    { id: '3', sortable_name: 'Z Lastington', assignment_201: {}},
    { id: '4', sortable_name: 'A Firstington', assignment_201: { late: true }}
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.gridData.rows;

  equal(firstRow.id, '4', 'when late is true, order first');
  equal(secondRow.id, '3', 'when no submission is found, order second');
});

QUnit.module('Gradebook#getSelectedEnrollmentFilters');

test('returns empty array when all settings are off', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'false'
    }
  });
  equal(gradebook.getSelectedEnrollmentFilters().length, 0);
});

test('returns array including "concluded" when setting is on', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'false'
    }
  });

  ok(gradebook.getSelectedEnrollmentFilters().includes('concluded'));
  notOk(gradebook.getSelectedEnrollmentFilters().includes('inactive'));
});

test('returns array including "inactive" when setting is on', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'true'
    }
  });
  ok(gradebook.getSelectedEnrollmentFilters().includes('inactive'));
  notOk(gradebook.getSelectedEnrollmentFilters().includes('concluded'));
});

test('returns array including multiple values when settings are on', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'true'
    }
  });
  ok(gradebook.getSelectedEnrollmentFilters().includes('inactive'));
  ok(gradebook.getSelectedEnrollmentFilters().includes('concluded'));
});

QUnit.module('Gradebook#toggleEnrollmentFilter', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub()
      }
    };
    sandbox.stub(this.gradebook, 'reloadStudentData').returns({});
    sandbox.stub(this.gradebook, 'saveSettings').callsFake((_data, callback) => { callback() });
  }
});

test('changes the value of @getSelectedEnrollmentFilters', function () {
  studentRowHeaderConstants.enrollmentFilterKeys.forEach((key) => {
    const previousValue = this.gradebook.getSelectedEnrollmentFilters().includes(key);
    this.gradebook.toggleEnrollmentFilter(key, true);
    const newValue = this.gradebook.getSelectedEnrollmentFilters().includes(key);
    notEqual(previousValue, newValue);
  });
});

test('saves settings', function () {
  this.gradebook.toggleEnrollmentFilter('inactive');
  strictEqual(this.gradebook.saveSettings.callCount, 1);
});

test('updates the student column header', function () {
  this.gradebook.toggleEnrollmentFilter('inactive');
  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
});

test('includes the "student" column id when updating column headers', function () {
  this.gradebook.toggleEnrollmentFilter('inactive');
  const [columnIds] = this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args;
  deepEqual(columnIds, ['student']);
});

test('reloads student data after saving settings', function () {
  this.gradebook.toggleEnrollmentFilter('inactive');
  strictEqual(this.gradebook.reloadStudentData.callCount, 1);
});

QUnit.module('Gradebook "Enter Grades as" Setting', function (suiteHooks) {
  let server
  let options
  let gradebook

  suiteHooks.beforeEach(() => {
    options = { settings_update_url: '/course/1/gradebook_settings' }
    server = sinon.fakeServer.create({ respondImmediately: true })
    server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ])
    gradebook = createGradebook(options);
    gradebook.setAssignments({
      2301: { id: '2301', grading_type: 'points', name: 'Math Assignment', published: true },
      2302: { id: '2302', grading_type: 'points', name: 'English Assignment', published: false }
    });
    gradebook.gradebookGrid.grid = {
      invalidate () {}
    };
    gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders () {}
      }
    };
  });

  suiteHooks.afterEach(() => {
    server.restore()
  })

  QUnit.module('#getEnterGradesAsSetting', function () {
    test('returns the setting when stored', function () {
      gradebook.setEnterGradesAsSetting('2301', 'percent');
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent');
    });

    test('defaults to "points" for a "points" assignment', function () {
      gradebook.getAssignment('2301').grading_type = 'points';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'points');
    });

    test('defaults to "percent" for a "percent" assignment', function () {
      gradebook.getAssignment('2301').grading_type = 'percent';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent');
    });

    test('defaults to "passFail" for a "pass_fail" assignment', function () {
      gradebook.getAssignment('2301').grading_type = 'pass_fail';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'passFail');
    });

    test('defaults to "gradingScheme" for a "letter_grade" assignment', function () {
      gradebook.getAssignment('2301').grading_type = 'letter_grade';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'gradingScheme');
    });

    test('defaults to "gradingScheme" for a "gpa_scale" assignment', function () {
      gradebook.getAssignment('2301').grading_type = 'gpa_scale';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'gradingScheme');
    });

    test('defaults to null for a "not_graded" assignment', function () {
      gradebook.getAssignment('2301').grading_type = 'not_graded';
      strictEqual(gradebook.getEnterGradesAsSetting('2301'), null);
    });

    test('defaults to null for a "not_graded" assignment previously set as "points"', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'points');
      gradebook.getAssignment('2301').grading_type = 'not_graded';
      strictEqual(gradebook.getEnterGradesAsSetting('2301'), null);
    });

    test('defaults to null for a "not_graded" assignment previously set as "percent"', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
      gradebook.getAssignment('2301').grading_type = 'not_graded';
      strictEqual(gradebook.getEnterGradesAsSetting('2301'), null);
    });

    test('defaults to "points" for a "points" assignment previously set as "gradingScheme"', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme');
      gradebook.getAssignment('2301').grading_type = 'points';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'points');
    });

    test('defaults to "percent" for a "percent" assignment previously set as "gradingScheme"', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme');
      gradebook.getAssignment('2301').grading_type = 'percent';
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent');
    });
  });

  QUnit.module('#updateEnterGradesAsSetting', function (hooks) {
    hooks.beforeEach(function () {
      sinon.stub(gradebook, 'saveSettings').callsFake((_data, callback) => { callback() });
      sinon.stub(gradebook.gradebookGrid, 'invalidate');
      sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders');
    });

    hooks.afterEach(function () {
      gradebook.saveSettings.restore();
    });

    test('updates the setting in Gradebook', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
      equal(gradebook.getEnterGradesAsSetting('2301'), 'percent');
    });

    test('saves gradebooks settings', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
      strictEqual(gradebook.saveSettings.callCount, 1);
    });

    test('saves gradebooks settings after updating the "enter grades as" setting', function () {
      gradebook.saveSettings.callsFake(() => {
        equal(gradebook.getEnterGradesAsSetting('2301'), 'percent');
      });
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
    });

    test('updates the column header for the related assignment column', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
      strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
    });

    test('updates the column header with the assignment column id', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
      const [columnIds] = gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args;
      deepEqual(columnIds, ['assignment_2301']);
    });

    test('updates the column header after settings have been saved', function () {
      gradebook.saveSettings.callsFake((_data, callback) => {
        strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 0);
        callback();
        strictEqual(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
      });
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
    });

    test('invalidates the grid', function () {
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
      strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1);
    });

    test('invalidates the grid after updating the column header', function () {
      gradebook.gradebookGrid.invalidate.callsFake(() => {
        strictEqual(gradebook.gradebookGrid.invalidate.callCount, 1);
      });
      gradebook.updateEnterGradesAsSetting('2301', 'percent');
    });
  });
});

QUnit.module('Gradebook Grading Schemes', (suiteHooks) => {
  const defaultGradingScheme = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]];
  const gradingScheme = {
    id: '2801',
    data: [['😂', 0.9], ['🙂', 0.8], ['😐', 0.7], ['😢', 0.6], ['💩', 0]],
    title: 'Emoji Grades'
  };

  let gradebook;

  function createInitializedGradebook (options) {
    gradebook = createGradebook({
      default_grading_standard: defaultGradingScheme,
      grading_schemes: [gradingScheme],
      ...options
    });
    gradebook.initialize();
    gradebook.setAssignments({
      2301: {
        grading_standard_id: '2801',
        grading_type: 'points',
        id: '2301',
        name: 'Math Assignment',
        published: true
      },
      2302: {
        grading_standard_id: null,
        grading_type: 'points',
        id: '2302',
        name: 'English Assignment',
        published: false
      }
    });
  }

  suiteHooks.beforeEach(() => {
    stubDataLoader()
  });

  QUnit.module('#getDefaultGradingScheme', () => {
    test('returns the default grading scheme when present', () => {
      createInitializedGradebook();
      deepEqual(gradebook.getDefaultGradingScheme().data, defaultGradingScheme);
    });

    test('returns null when the default grading scheme is not present', () => {
      createInitializedGradebook({ default_grading_standard: undefined });
      strictEqual(gradebook.getDefaultGradingScheme(), null);
    });
  });

  QUnit.module('#getGradingScheme', () => {
    test('returns the grading scheme matching the given id', () => {
      createInitializedGradebook();
      deepEqual(gradebook.getGradingScheme('2801'), gradingScheme);
    });

    test('returns undefined when no grading scheme exists with the given id', () => {
      createInitializedGradebook();
      strictEqual(gradebook.getGradingScheme('2802'), undefined);
    });
  });

  QUnit.module('#getAssignmentGradingScheme', () => {
    test('returns the grading scheme associated with the assignment', () => {
      createInitializedGradebook();
      deepEqual(gradebook.getAssignmentGradingScheme('2301'), gradingScheme);
    });

    test('returns the default grading scheme when the assignment does not use a specific scheme', () => {
      createInitializedGradebook();
      deepEqual(gradebook.getAssignmentGradingScheme('2302').data, defaultGradingScheme);
    });
  });
});

QUnit.module('Gradebook#saveSettings', {
  setup () {
    this.server = sinon.fakeServer.create({ respondImmediately: true });
    this.options = { settings_update_url: '/course/1/gradebook_settings' };
  },

  teardown () {
    this.server.restore();
  }
});

test('calls ajaxJSON with the settings_update_url', function () {
  const options = { settings_update_url: 'http://someUrl/' };
  const gradebook = createGradebook({ ...options });
  const ajaxJSONStub = sandbox.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  equal(ajaxJSONStub.firstCall.args[0], options.settings_update_url);
});

test('calls ajaxJSON as a PUT request', function () {
  const gradebook = createGradebook();
  const ajaxJSONStub = sandbox.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  equal(ajaxJSONStub.firstCall.args[1], 'PUT');
});

test('calls ajaxJSON with default gradebook_settings', function () {
  const expectedSettings = {
    colors: {
      dropped: '#FEF0E5',
      excused: '#FEF7E5',
      late: '#E5F3FC',
      missing: '#FFE8E5',
      resubmitted: '#E5F7E5'
    },
    enter_grades_as: {},
    filter_columns_by: {
      assignment_group_id: null,
      context_module_id: null,
      grading_period_id: null
    },
    filter_rows_by: {
      section_id: null
    },
    selected_view_options_filters: ['assignmentGroups'],
    show_concluded_enrollments: true,
    show_inactive_enrollments: true,
    show_unpublished_assignments: true,
    show_final_grade_overrides: false,
    sort_rows_by_column_id: 'student',
    sort_rows_by_direction: 'ascending',
    sort_rows_by_setting_key: 'sortable_name',
    student_column_display_as: 'first_last',
    student_column_secondary_info: 'none',
  };
  const gradebook = createGradebook({
    settings: {
      selected_view_options_filters: ['assignmentGroups'],
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'true',
      show_unpublished_assignments: 'true',
      sort_rows_by_column_id: 'student',
      sort_rows_by_direction: 'ascending',
      sort_rows_by_setting_key: 'sortable_name',
      student_column_display_as: 'first_last',
      student_column_secondary_info: 'none',
    }
  });
  const ajaxJSONStub = sandbox.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  deepEqual(ajaxJSONStub.firstCall.args[2], { gradebook_settings: { ...expectedSettings }});
});

test('ensures selected_view_options_filters is not empty in order to force the stored value to change', function () {
  // an empty array will be excluded from the request, which is ignored in the
  // update, which means the previous setting remains persisted
  const gradebook = createGradebook({
    settings: {
      selected_view_options_filters: [],
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'true',
      show_unpublished_assignments: 'true',
      sort_rows_by_column_id: 'student',
      sort_rows_by_direction: 'ascending',
      sort_rows_by_setting_key: 'sortable_name',
      student_column_display_as: 'first_last',
      student_column_secondary_info: 'none',
    }
  });
  const ajaxJSONStub = sandbox.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  const settings = ajaxJSONStub.firstCall.args[2];
  deepEqual(settings.gradebook_settings.selected_view_options_filters, ['']);
});

test('calls ajaxJSON with parameters', function () {
  const gradebook = createGradebook({
    settings: {
      filter_columns_by: {
        assignment_group_id: '2201',
        context_module_id: '2601',
        grading_period_id: '1401'
      },
      filter_rows_by: {
        section_id: '2001'
      },
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'true',
      show_unpublished_assignments: 'true',
      show_final_grade_overrides: 'true'
    }
  });
  const ajaxJSONStub = sandbox.stub($, 'ajaxJSON');
  gradebook.saveSettings({
    selected_view_options_filters: [],
    showConcludedEnrollments: false,
    showInactiveEnrollments: false,
    showUnpublishedAssignments: false,
    showFinalGradeOverrides: false,
    studentColumnDisplayAs: 'last_first',
    studentColumnSecondaryInfo: 'login_id',
    sortRowsBy: {
      columnId: 'assignment_1',
      settingKey: 'late',
      direction: 'ascending',
    },
  });

  deepEqual(ajaxJSONStub.firstCall.args[2], {
    gradebook_settings: {
      colors: {
        dropped: '#FEF0E5',
        excused: '#FEF7E5',
        late: '#E5F3FC',
        missing: '#FFE8E5',
        resubmitted: '#E5F7E5'
      },
      enter_grades_as: {},
      filter_columns_by: {
        assignment_group_id: '2201',
        context_module_id: '2601',
        grading_period_id: '1401'
      },
      filter_rows_by: {
        section_id: '2001'
      },
      selected_view_options_filters: [''],
      show_concluded_enrollments: false,
      show_inactive_enrollments: false,
      show_unpublished_assignments: false,
      show_final_grade_overrides: false,
      sort_rows_by_column_id: 'assignment_1',
      sort_rows_by_direction: 'ascending',
      sort_rows_by_setting_key: 'late',
      student_column_display_as: 'last_first',
      student_column_secondary_info: 'login_id'
    }
  });
});

test('calls successFn when response is successful', function () {
  // The request is sent as a PUT but ajaxJSON does not play nice with
  // sinon.fakeServer's fakeHTTPMethods setting.
  this.server.respondWith('POST', this.options.settings_update_url, [
    200, { 'Content-Type': 'application/json' }, '{}'
  ]);
  const successFn = sinon.stub();
  const gradebook = createGradebook(this.options);
  gradebook.saveSettings({}, successFn, null);

  strictEqual(successFn.callCount, 1);
});

test('calls errorFn when response is not successful', function () {
  // The requests is sent as a PUT but ajaxJSON does not play nice with
  // sinon.fakeServer's fakeHTTPMethods setting.
  this.server.respondWith('POST', this.options.settings_update_url, [
    401, { 'Content-Type': 'application/json' }, '{}'
  ]);
  const errorFn = sinon.stub();
  const gradebook = createGradebook(this.options);
  gradebook.saveSettings({}, null, errorFn);

  strictEqual(errorFn.callCount, 1);
});

QUnit.module('Gradebook#updateColumns', function (hooks) {
  let gradebook;

  hooks.beforeEach(function () {
    gradebook = createGradebook();
    sinon.stub(gradebook.gradebookGrid, 'updateColumns');
    sinon.stub(gradebook, 'setVisibleGridColumns');
    sinon.stub(gradebook, 'updateColumnHeaders');
  });

  test('sets the visible grid columns', function () {
    gradebook.updateColumns();
    strictEqual(gradebook.setVisibleGridColumns.callCount, 1);
  });

  test('sets the columns on the grid', function () {
    gradebook.updateColumns();
    strictEqual(gradebook.gradebookGrid.updateColumns.callCount, 1);
  });

  test('sets the columns after updating the grid', function () {
    gradebook.gradebookGrid.updateColumns.callsFake(() => {
      strictEqual(gradebook.setVisibleGridColumns.callCount, 1, 'setVisibleGridColumns was already called');
    });
    gradebook.updateColumns();
  });

  test('calls updateColumnHeaders', function () {
    gradebook.updateColumns();
    strictEqual(gradebook.updateColumnHeaders.callCount, 1);
  });
});

QUnit.module('Gradebook#updateColumnsAndRenderViewOptionsMenu', function (hooks) {
  let gradebook;

  hooks.beforeEach(function () {
    gradebook = createGradebook();
    sinon.stub(gradebook, 'updateColumns');
    sinon.stub(gradebook, 'renderViewOptionsMenu');
  });

  test('calls updateColumns', function () {
    gradebook.updateColumnsAndRenderViewOptionsMenu();
    strictEqual(gradebook.updateColumns.callCount, 1);
  });

  test('calls renderViewOptionsMenu', function () {
    gradebook.updateColumnsAndRenderViewOptionsMenu();
    strictEqual(gradebook.renderViewOptionsMenu.callCount, 1);
  });
});

QUnit.module('Gradebook React Header Component References', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('#setHeaderComponentRef stores a reference by a column id', function () {
  const studentRef = { column: 'student' };
  const totalGradeRef = { column: 'total_grade' };
  this.gradebook.setHeaderComponentRef('student', studentRef);
  this.gradebook.setHeaderComponentRef('total_grade', totalGradeRef);
  equal(this.gradebook.getHeaderComponentRef('student'), studentRef);
  equal(this.gradebook.getHeaderComponentRef('total_grade'), totalGradeRef);
});

test('#setHeaderComponentRef replaces an existing reference', function () {
  const ref = { column: 'student' };
  this.gradebook.setHeaderComponentRef('student', { column: 'previous' });
  this.gradebook.setHeaderComponentRef('student', ref);
  equal(this.gradebook.getHeaderComponentRef('student'), ref);
});

test('#removeHeaderComponentRef removes an existing reference', function () {
  const ref = { column: 'student' };
  this.gradebook.setHeaderComponentRef('student', ref);
  this.gradebook.removeHeaderComponentRef('student');
  equal(typeof this.gradebook.getHeaderComponentRef('student'), 'undefined');
});

QUnit.module('Gradebook#initShowUnpublishedAssignments');

test('if unset, default to true', function () {
  const gradebook = createGradebook();
  gradebook.initShowUnpublishedAssignments(undefined);

  strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true);
});

test('sets to true if passed "true"', function () {
  const gradebook = createGradebook();
  gradebook.initShowUnpublishedAssignments('true');

  strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true);
});

test('sets to false if passed "false"', function () {
  const gradebook = createGradebook();
  gradebook.initShowUnpublishedAssignments('false');

  strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false);
});

QUnit.module('Gradebook#initShowOverrides', () => {
  const truthyMap = {
    undefined: false,
    'true': true,
    'false': false
  }

  test('defaults to false', () => {
    const gradebook = createGradebook()
    const showFinalGradeOverrides = undefined
    gradebook.initShowOverrides(showFinalGradeOverrides)
    strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, truthyMap[showFinalGradeOverrides])
    gradebook.destroy()
  })

  QUnit.module('given final_grade_override_enabled is false', (hooks) => {
    let gradebook

    hooks.beforeEach(() => {
      gradebook = createGradebook({final_grade_override_enabled: false})
    })

    hooks.afterEach(() => {
      gradebook.destroy()
    })

    test('defaults to false', () => {
      gradebook = createGradebook()
      const showFinalGradeOverrides = undefined
      gradebook.initShowOverrides(showFinalGradeOverrides)
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, truthyMap[showFinalGradeOverrides])
    })

    test('cannot be set to true', () => {
      gradebook = createGradebook()
      const showFinalGradeOverrides = 'true'
      gradebook.initShowOverrides(showFinalGradeOverrides)
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, !truthyMap[showFinalGradeOverrides])
    })

    test('can be set to false', () => {
      gradebook = createGradebook()
      const showFinalGradeOverrides = 'false'
      gradebook.initShowOverrides(showFinalGradeOverrides)
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, truthyMap[showFinalGradeOverrides])
    })
  })

  QUnit.module('given final_grade_override_enabled is true', (hooks) => {
    let gradebook

    hooks.beforeEach(() => {
      gradebook = createGradebook({final_grade_override_enabled: true})
    })

    hooks.afterEach(() => {
      gradebook.destroy()
    })

    test('defaults to false', () => {
      const showFinalGradeOverrides = undefined
      gradebook.initShowOverrides(showFinalGradeOverrides)
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, truthyMap[showFinalGradeOverrides])
    })

    test('can be set to true', () => {
      const showFinalGradeOverrides = 'true'
      gradebook.initShowOverrides(showFinalGradeOverrides)
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, truthyMap[showFinalGradeOverrides])
    })

    test('can be set to false', () => {
      const showFinalGradeOverrides = 'false'
      gradebook.initShowOverrides(showFinalGradeOverrides)
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, truthyMap[showFinalGradeOverrides])
    })
  })
})

QUnit.module('Gradebook#toggleUnpublishedAssignments', () => {
  test('toggles showUnpublishedAssignments to true when currently false', function () {
    const gradebook = createGradebook()
    gradebook.gridDisplaySettings.showUnpublishedAssignments = false
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox.stub(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true)
  })

  test('toggles showUnpublishedAssignments to false when currently true', function () {
    const gradebook = createGradebook()
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox.stub(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
  })

  test('calls updateColumnsAndRenderViewOptionsMenu after toggling', function () {
    const gradebook = createGradebook()
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    const stubFn = sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu').callsFake(function () {
      strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
    })
    sandbox.stub(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    strictEqual(stubFn.callCount, 1)
  })

  test('calls saveSettings after updateColumnsAndRenderViewOptionsMenu', function () {
    const gradebook = createGradebook()
    const updateColumnsAndRenderViewOptionsMenuStub = sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    const saveSettingsStub = sandbox.stub(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    sinon.assert.callOrder(updateColumnsAndRenderViewOptionsMenuStub, saveSettingsStub)
  })

  test('calls saveSettings with showUnpublishedAssignments', function () {
    const settings = {show_unpublished_assignments: 'true'}
    const gradebook = createGradebook({settings})
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    const saveSettingsStub = sandbox.stub(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    const [{showUnpublishedAssignments}] = saveSettingsStub.firstCall.args
    strictEqual(showUnpublishedAssignments, !settings.show_unpublished_assignments)
  })

  test('calls saveSettings successfully', function () {
    const server = sinon.fakeServer.create({ respondImmediately: true })
    const options = { settings_update_url: '/course/1/gradebook_settings' }
    server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ])

    const gradebook = createGradebook({ options })
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    const saveSettingsStub = sinon.spy(gradebook, 'saveSettings')
    gradebook.toggleUnpublishedAssignments()

    strictEqual(saveSettingsStub.callCount, 1)
    server.restore()
  })

  test('calls saveSettings and rolls back on failure', function () {
    const server = sinon.fakeServer.create({ respondImmediately: true })
    const options = { settings_update_url: '/course/1/gradebook_settings' }
    server.respondWith('POST', options.settings_update_url, [
      401, { 'Content-Type': 'application/json' }, '{}'
    ])

    const gradebook = createGradebook({ options })
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    const stubFn = sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    stubFn.onFirstCall().callsFake(function () {
      strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, false)
    })
    stubFn.onSecondCall().callsFake(function () {
      strictEqual(gradebook.gridDisplaySettings.showUnpublishedAssignments, true)
    })
    gradebook.toggleUnpublishedAssignments()
    strictEqual(stubFn.callCount, 2)
    server.restore()
  })
})

QUnit.module('Gradebook#toggleOverrides', () => {
  test('toggles showFinalGradeOverrides to true when currently false', function () {
    const gradebook = createGradebook();
    gradebook.gridDisplaySettings.showFinalGradeOverrides = false;
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
    sandbox.stub(gradebook, 'saveSettings');
    gradebook.toggleOverrides();

    strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, true);
  });

  test('toggles showFinalGradeOverrides to false when currently true', function () {
    const gradebook = createGradebook();
    gradebook.gridDisplaySettings.showFinalGradeOverrides = true;
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
    sandbox.stub(gradebook, 'saveSettings');
    gradebook.toggleOverrides();

    strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, false);
  });

  test('calls showFinalGradeOverrides after toggling', function () {
    const gradebook = createGradebook();
    gradebook.gridDisplaySettings.showFinalGradeOverrides = true;
    const stubFn = sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu').callsFake(function () {
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, false);
    });
    sandbox.stub(gradebook, 'saveSettings');
    gradebook.toggleOverrides();

    strictEqual(stubFn.callCount, 1);
  });

  test('calls saveSettings with showFinalGradeOverrides', function () {
    const gradebookProps = {settings: {show_final_grade_overrides: 'true'}, final_grade_override_enabled: true}
    const gradebook = createGradebook(gradebookProps);
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
    const saveSettingsStub = sandbox.stub(gradebook, 'saveSettings');
    gradebook.toggleOverrides();

    const [{showFinalGradeOverrides}] = saveSettingsStub.firstCall.args
    strictEqual(showFinalGradeOverrides, false);
  });

  test('calls saveSettings successfully', function () {
    const server = sinon.fakeServer.create({ respondImmediately: true });
    const options = { settings_update_url: '/course/1/gradebook_settings' };
    server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ]);

    const gradebook = createGradebook({ options });
    gradebook.gridDisplaySettings.showFinalGradeOverrides = true;
    sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
    const saveSettingsStub = sinon.spy(gradebook, 'saveSettings');
    gradebook.toggleOverrides();

    strictEqual(saveSettingsStub.callCount, 1);
    server.restore()
  });

  test('calls saveSettings and rolls back on failure', function () {
    const server = sinon.fakeServer.create({ respondImmediately: true });
    const options = { settings_update_url: '/course/1/gradebook_settings' };
    server.respondWith('POST', options.settings_update_url, [
      401, { 'Content-Type': 'application/json' }, '{}'
    ]);

    const gradebook = createGradebook({ options });
    gradebook.gridDisplaySettings.showFinalGradeOverrides = true;
    const stubFn = sandbox.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
    stubFn.onFirstCall().callsFake(function () {
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, false);
    });
    stubFn.onSecondCall().callsFake(function () {
      strictEqual(gradebook.gridDisplaySettings.showFinalGradeOverrides, true);
    });
    gradebook.toggleOverrides();
    strictEqual(stubFn.callCount, 2);
    server.restore()
  });
});

QUnit.module('Gradebook#renderViewOptionsMenu');

test('passes showUnpublishedAssignments to props', function () {
  const gradebook = createGradebook();
  gradebook.gridDisplaySettings.showUnpublishedAssignments = true;
  const createElementStub = sandbox.stub(React, 'createElement');
  sandbox.stub(ReactDOM, 'render');
  gradebook.renderViewOptionsMenu();

  strictEqual(createElementStub.firstCall.args[1].showUnpublishedAssignments, gradebook.gridDisplaySettings.showUnpublishedAssignments);
});

test('passes toggleUnpublishedAssignments as onSelectShowUnpublishedAssignments to props', function () {
  const gradebook = createGradebook();
  gradebook.toggleUnpublishedAssignments = () => {};
  const createElementStub = sandbox.stub(React, 'createElement');
  sandbox.stub(ReactDOM, 'render');
  gradebook.renderViewOptionsMenu();

  strictEqual(createElementStub.firstCall.args[1].toggleUnpublishedAssignments, gradebook.onSelectShowUnpublishedAssignments);
});

QUnit.module('Gradebook#updateSubmission', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.students = { 1101: { id: '1101' } };
    this.submission = {
      assignment_id: '201',
      grade: '123.45',
      gradingType: 'percent',
      submitted_at: '2015-05-04T12:00:00Z',
      user_id: '1101'
    };
  }
});

test('formats the grade for the submission', function () {
  sandbox.spy(GradeFormatHelper, 'formatGrade');
  this.gradebook.updateSubmission(this.submission);
  equal(GradeFormatHelper.formatGrade.callCount, 1);
});

test('includes submission attributes when formatting the grade', function () {
  sandbox.spy(GradeFormatHelper, 'formatGrade');
  this.gradebook.updateSubmission(this.submission);
  const [grade, options] = GradeFormatHelper.formatGrade.getCall(0).args;
  equal(grade, '123.45', 'parameter 1 is the submission grade');
  equal(options.gradingType, 'percent', 'options.gradingType is the submission gradingType');
  strictEqual(options.delocalize, false, 'submission grades from the server are not localized');
});

test('sets the formatted grade on submission', function () {
  sandbox.stub(GradeFormatHelper, 'formatGrade').returns('123.45%');
  this.gradebook.updateSubmission(this.submission);
  equal(this.submission.grade, '123.45%');
});

test('sets the raw grade on submission', function () {
  sandbox.stub(GradeFormatHelper, 'formatGrade').returns('123.45%');
  this.gradebook.updateSubmission(this.submission);
  equal(this.submission.rawGrade, '123.45');
});

QUnit.module('Gradebook#arrangeColumnsBy', (hooks) => {
  let server
  let options
  let gradebook

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({ respondImmediately: true })
    options = { gradebook_column_order_settings_url: '/grade_column_order_settings_url' }
    server.respondWith('POST', options.gradebook_column_order_settings_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ])
    gradebook = createGradebook(options);
    gradebook.makeColumnSortFn = () => () => 1;
    gradebook.gradebookGrid.grid = {
      getColumns () { return []; },
      getOptions () {
        return {
          numberOfColumnsToFreeze: 0
        };
      },
      invalidate () {},
      setColumns () {},
      setNumberOfColumnsToFreeze () {}
    }
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('renders the view options menu', function () {
    sandbox.stub(gradebook, 'renderViewOptionsMenu');
    sandbox.stub(gradebook, 'updateColumnHeaders');

    gradebook.arrangeColumnsBy({ sortBy: 'due_date', direction: 'ascending' }, false);

    strictEqual(gradebook.renderViewOptionsMenu.callCount, 1);
  });
});

QUnit.module('Gradebook#updateCurrentGradingPeriod', {
  setup () {
    this.server = sinon.createFakeServer({ respondImmediately: true })
    this.server.respondWith([200, {}, ''])

    const fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="grading-periods-filter-container"></div>'

    this.gradebook = createGradebook({
      grading_period_set: {
        id: '1501',
        grading_periods: [{ id: '1401' }, { id: '1402' }]
      },
      settings: {
        filter_columns_by: {
          grading_period_id: '1402'
        },
        selected_view_options_filters: ['gradingPeriods']
      }
    });
    sinon.spy(this.gradebook, 'saveSettings');
    sandbox.stub(this.gradebook, 'resetGrading');
    sandbox.stub(this.gradebook, 'sortGridRows');
    sandbox.stub(this.gradebook, 'updateFilteredContentInfo');
    sandbox.stub(this.gradebook, 'updateColumnsAndRenderViewOptionsMenu');
    sandbox.stub(this.gradebook, 'renderActionMenu');
  },

  teardown () {
    this.server.restore()
  }
});

test('updates the filter setting with the given grading period id', function () {
  this.gradebook.updateCurrentGradingPeriod('1401');
  strictEqual(this.gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1401');
});

test('saves settings after updating the filter setting', function () {
  this.gradebook.updateCurrentGradingPeriod('1401');
  strictEqual(this.gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1401', 'setting was already updated')
});

test('resets grading after updating the filter setting', function () {
  this.gradebook.updateCurrentGradingPeriod('1401');
  strictEqual(this.gradebook.resetGrading.callCount, 1)
});

test('sorts grid grows after resetting grading', function () {
  this.gradebook.sortGridRows.callsFake(() => {
    strictEqual(this.gradebook.resetGrading.callCount, 1, 'grading was already reset');
  });
  this.gradebook.updateCurrentGradingPeriod('1401');
});

test('sets assignment warnings after resetting grading', function () {
  this.gradebook.updateFilteredContentInfo.callsFake(() => {
    strictEqual(this.gradebook.resetGrading.callCount, 1, 'grading was already reset');
  });
  this.gradebook.updateCurrentGradingPeriod('1401');
});

test('updates columns and menus after settings assignment warnings', function () {
  this.gradebook.updateColumnsAndRenderViewOptionsMenu.callsFake(() => {
    strictEqual(this.gradebook.updateFilteredContentInfo.callCount, 1, 'assignment warnings were already set');
  });
  this.gradebook.updateCurrentGradingPeriod('1401');
});

test('has no effect when the grading period has not changed', function () {
  this.gradebook.updateCurrentGradingPeriod('1402');
  strictEqual(this.gradebook.saveSettings.callCount, 0, 'saveSettings was not called');
  strictEqual(this.gradebook.resetGrading.callCount, 0, 'resetGrading was not called');
  strictEqual(this.gradebook.updateFilteredContentInfo.callCount, 0, 'setAssignmentVisibility was not called');
  strictEqual(this.gradebook.updateColumnsAndRenderViewOptionsMenu.callCount, 0,
    'updateColumnsAndRenderViewOptionsMenu was not called');
});

test('renders the action menu', function () {
  this.gradebook.updateCurrentGradingPeriod('1401');
  strictEqual(this.gradebook.renderActionMenu.callCount, 1)
});

QUnit.module('Gradebook#updateCurrentModule', {
  setup () {
    this.server = sinon.createFakeServer({ respondImmediately: true })
    this.server.respondWith([200, {}, ''])

    const fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="modules-filter-container"></div>'

    this.gradebook = createGradebook({
      settings: {
        filter_columns_by: {
          context_module_id: '2'
        },
        selected_view_options_filters: ['modules']
      }
    });
    this.gradebook.setContextModules([
      { id: '1', name: 'Module 1', position: 1 },
      { id: '2', name: 'Another Module', position: 2 },
      { id: '3', name: 'Module 2', position: 3 },
    ]);
    sinon.spy(this.gradebook, 'setFilterColumnsBySetting');
    sandbox.spy($, 'ajaxJSON')
    sandbox.stub(this.gradebook, 'updateFilteredContentInfo');
    sandbox.stub(this.gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  },

  teardown () {
    this.server.restore()
  }
});

test('updates the filter setting with the given module id', function () {
  this.gradebook.updateCurrentModule('1');
  strictEqual(this.gradebook.getFilterColumnsBySetting('contextModuleId'), '1');
});

test('saves settings with the new filter setting', function () {
  this.gradebook.updateCurrentModule('1');

  strictEqual($.ajaxJSON.getCall(0).args[2].gradebook_settings.filter_columns_by.context_module_id, '1');
});

test('saves settings after updating the filter setting', function () {
  this.gradebook.updateCurrentModule('1');

  const settingUpdateCallId = this.gradebook.setFilterColumnsBySetting.getCall(0).callId;
  const settingSaveCallId = $.ajaxJSON.getCall(0).callId;

  ok(settingUpdateCallId < settingSaveCallId, 'settings were saved on the backend after being updated on the front end');
});

test('sets assignment warnings after updating the filter setting', function () {
  this.gradebook.updateCurrentModule('1');

  const settingUpdateCallId = this.gradebook.setFilterColumnsBySetting.getCall(0).callId;
  const updateFilteredContentInfoCallId = this.gradebook.updateFilteredContentInfo.getCall(0).callId;

  ok(settingUpdateCallId < updateFilteredContentInfoCallId, 'grading was reset after setting was updated');
});

test('updates columns and menus after setting assignment warnings', function () {
  this.gradebook.updateCurrentModule('1');

  const updateFilteredContentInfoCallId = this.gradebook.updateFilteredContentInfo.getCall(0).callId;
  const updateColumnsAndMenusCallId = this.gradebook.updateColumnsAndRenderViewOptionsMenu.getCall(0).callId;

  ok(updateFilteredContentInfoCallId < updateColumnsAndMenusCallId, 'columns and menus were updated after setting assignment warnings');
});

test('has no effect when the module has not changed', function () {
  this.gradebook.updateCurrentModule('2');
  strictEqual($.ajaxJSON.callCount, 0, 'saveSettings was not called');
  strictEqual(this.gradebook.updateFilteredContentInfo.callCount, 0, 'setAssignmentVisibility was not called');
  strictEqual(this.gradebook.updateColumnsAndRenderViewOptionsMenu.callCount, 0,
    'updateColumnsAndRenderViewOptionsMenu was not called');
});

QUnit.module('Gradebook#updateCurrentAssignmentGroup', {
  setup () {
    this.server = sinon.createFakeServer({ respondImmediately: true })
    this.server.respondWith([200, {}, ''])

    const fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="assignment-group-filter-container"></div>'

    this.gradebook = createGradebook({
      settings: {
        filter_columns_by: {
          assignment_group_id: '2'
        },
        selected_view_options_filters: ['assignmentGroups']
      }
    });
    this.gradebook.setAssignmentGroups({
      '1': { id: '1' },
      '2': { id: '2' }
    })
    sinon.spy(this.gradebook, 'setFilterColumnsBySetting');
    sandbox.spy($, 'ajaxJSON')
    sandbox.stub(this.gradebook, 'updateFilteredContentInfo');
    sandbox.stub(this.gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  },

  teardown () {
    this.server.restore()
  }
});

test('updates the filter setting with the given assignment group id', function () {
  this.gradebook.updateCurrentAssignmentGroup('1');
  strictEqual(this.gradebook.getFilterColumnsBySetting('assignmentGroupId'), '1');
});

test('saves settings with the new filter setting', function () {
  this.gradebook.updateCurrentAssignmentGroup('1');

  strictEqual($.ajaxJSON.getCall(0).args[2].gradebook_settings.filter_columns_by.assignment_group_id, '1');
});

test('saves settings after updating the filter setting', function () {
  this.gradebook.updateCurrentAssignmentGroup('1');

  const settingUpdateCallId = this.gradebook.setFilterColumnsBySetting.getCall(0).callId;
  const settingSaveCallId = $.ajaxJSON.getCall(0).callId;

  ok(settingUpdateCallId < settingSaveCallId, 'settings were saved on the backend after being updated on the front end');
});

test('sets assignment warnings after updating the filter setting', function () {
  this.gradebook.updateCurrentAssignmentGroup('1');

  const settingUpdateCallId = this.gradebook.setFilterColumnsBySetting.getCall(0).callId;
  const updateFilteredContentInfoCallId = this.gradebook.updateFilteredContentInfo.getCall(0).callId;

  ok(settingUpdateCallId < updateFilteredContentInfoCallId, 'grading was reset after setting was updated');
});

test('updates columns and menus after setting assignment warnings', function () {
  this.gradebook.updateCurrentAssignmentGroup('1');

  const updateFilteredContentInfoCallId = this.gradebook.updateFilteredContentInfo.getCall(0).callId;
  const updateColumnsAndMenusCallId = this.gradebook.updateColumnsAndRenderViewOptionsMenu.getCall(0).callId;

  ok(updateFilteredContentInfoCallId < updateColumnsAndMenusCallId, 'columns and menus were updated after setting assignment warnings');
});

test('has no effect when the assignment group has not changed', function () {
  this.gradebook.updateCurrentAssignmentGroup('2');
  strictEqual($.ajaxJSON.callCount, 0, 'saveSettings was not called');
  strictEqual(this.gradebook.updateFilteredContentInfo.callCount, 0, 'setAssignmentVisibility was not called');
  strictEqual(this.gradebook.updateColumnsAndRenderViewOptionsMenu.callCount, 0,
    'updateColumnsAndRenderViewOptionsMenu was not called');
});

QUnit.module('Gradebook#initSubmissionStateMap');

test('initializes a new submission state map', function () {
  const gradebook = createGradebook();
  const originalMap = gradebook.submissionStateMap;
  gradebook.initSubmissionStateMap();
  strictEqual(gradebook.submissionStateMap.constructor, SubmissionStateMap);
  notEqual(originalMap, gradebook.submissionStateMap);
});

test('sets the submission state map .hasGradingPeriods to true when a grading period set exists', function () {
  const gradebook = createGradebook({
    grading_period_set: { id: '1501', grading_periods: [{ id: '701' }, { id: '702' }] }
  });
  gradebook.initSubmissionStateMap();
  strictEqual(gradebook.submissionStateMap.hasGradingPeriods, true);
});

test('sets the submission state map .hasGradingPeriods to false when no grading period set exists', function () {
  const gradebook = createGradebook();
  gradebook.initSubmissionStateMap();
  strictEqual(gradebook.submissionStateMap.hasGradingPeriods, false);
});

test('sets the submission state map .selectedGradingPeriodID to the "grading period to show"', function () {
  const gradebook = createGradebook();
  sandbox.stub(gradebook, 'getGradingPeriodToShow').returns('1401');
  gradebook.initSubmissionStateMap();
  strictEqual(gradebook.submissionStateMap.selectedGradingPeriodID, '1401');
});

test('sets the submission state map .isAdmin when the current user roles includes "admin"', function () {
  fakeENV.setup({ current_user_roles: ['admin'] });
  const gradebook = createGradebook();
  gradebook.initSubmissionStateMap();
  strictEqual(gradebook.submissionStateMap.isAdmin, true);
  fakeENV.teardown();
});

test('sets the submission state map .isAdmin when the current user roles do not include "admin"', function () {
  const gradebook = createGradebook();
  gradebook.initSubmissionStateMap();
  strictEqual(gradebook.submissionStateMap.isAdmin, false);
});

QUnit.module('Gradebook#initPostGradesLtis');

test('sets postGradesLtis as an array', function () {
  const gradebook = createGradebook({ post_grades_ltis: [] });
  deepEqual(gradebook.postGradesLtis, []);
});

test('sets postGradesLtis to conform to ActionMenu.propTypes.postGradesLtis', function () {
  const options = {
    post_grades_ltis: [{
      id: '1',
      name: 'Pinnacle',
      onSelect () {}
    }, {
      id: '2',
      name: 'Kimono',
      onSelect () {}
    }]
  };

  const gradebook = createGradebook(options);
  gradebook.initPostGradesLtis();
  const props = gradebook.postGradesLtis;

  sandbox.spy(console, 'error');
  PropTypes.checkPropTypes({postGradesLtis: ActionMenu.propTypes.postGradesLtis}, props, 'prop', 'ActionMenu');
  ok(console.error.notCalled); // eslint-disable-line no-console
});

QUnit.module('Gradebook', () => {
  QUnit.module('#getActionMenuProps', (hooks) => {
    let options;

    hooks.beforeEach(() => {
      $fixtures.innerHTML = '<span data-component="ActionMenu"><button /></span>';
      options = {
        context_allows_gradebook_uploads: true,
        currentUserId: '123',
        export_gradebook_csv_url: 'http://example.com/export',
        gradebook_import_url: 'http://example.com/import',
        post_grades_feature: false,
        publish_to_sis_enabled: false,
        grading_period_set: {
          id: '1501',
          grading_periods: [
            { id: '701' },
            { id: '702' }
          ],
        },
        current_grading_period_id: '702'
      };
    });

    hooks.afterEach(() => {
      $fixtures.innerHTML = '';
    });

    test('sets publishGradesToSis.isEnabled to true when "publish to SIS" is enabled', () => {
      options.publish_to_sis_enabled = true;
      const gradebook = createGradebook(options);
      const props = gradebook.getActionMenuProps();
      strictEqual(props.publishGradesToSis.isEnabled, true);
    });

    test('sets publishGradesToSis.isEnabled to false when "publish to SIS" is not enabled', () => {
      options.publish_to_sis_enabled = false;
      const gradebook = createGradebook(options);
      const props = gradebook.getActionMenuProps();
      strictEqual(props.publishGradesToSis.isEnabled, false);
    });

    test('sets gradingPeriodId', () => {
      const gradebook = createGradebook(options);
      const props = gradebook.getActionMenuProps();
      strictEqual(props.gradingPeriodId, '702');
    });
  });

  QUnit.module('#updateFilterSettings', (hooks) => {
    let gradebook
    let currentFilters

    hooks.beforeEach(() => {
      $fixtures.innerHTML = `
        <div id="assignment-group-filter-container"></div>
        <div id="grading-periods-filter-container"></div>
        <div id="modules-filter-container"></div>
        <div id="sections-filter-container"></div>
        <div id="search-filter-container">
          <input type="text" />
        </div>
      `
      currentFilters = ['assignmentGroups', 'modules', 'gradingPeriods', 'sections']
      gradebook = createGradebook({
        grading_period_set: {
          id: '1501',
          grading_periods: [{ id: '1401', name: 'Grading Period #1' }, { id: '1402', name: 'Grading Period #2' }]
        },
        sections: [{ id: '2001', name: 'Freshmen' }, { id: '2002', name: 'Sophomores' }],
        sections_enabled: true,
        settings: {
          filter_columns_by: {
            assignment_group_id: '2',
            grading_period_id: '1402',
            context_module_id: '2'
          },
          filter_rows_by: {
            section_id: '2001'
          },
          selected_view_options_filters: currentFilters
        }
      })
      gradebook.setAssignmentGroups({
        '1': { id: '1', name: 'Assignment Group #1' },
        '2': { id: '2', name: 'Assignment Group #2' }
      })
      gradebook.setContextModules([
        { id: '1', name: 'Module 1', position: 1 },
        { id: '2', name: 'Another Module', position: 2 },
        { id: '3', name: 'Module 2', position: 3 }
      ])

      sinon.spy(gradebook, 'setFilterColumnsBySetting')
      sinon.stub(gradebook, 'saveSettings')
      sinon.stub(gradebook, 'resetGrading')
      sinon.stub(gradebook, 'sortGridRows')
      sinon.stub(gradebook, 'updateFilteredContentInfo')
      sinon.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      sinon.stub(gradebook, 'renderViewOptionsMenu')
      sinon.stub(gradebook, 'renderActionMenu')
    })

    hooks.afterEach(() => {
      gradebook = null
      $fixtures.innerHTML = ''
    })

    test('getFilterColumnsBySetting returns the assignment group filter setting', () => {
      strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2')
    })

    test('deletes the assignment group filter setting when the filter is hidden ' +
      'and assignment groups have loaded', () => {
      gradebook.setAssignmentGroupsLoaded(true)
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'assignmentGroups'))
      strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), null)
    })

    test('does not delete the assignment group filter setting when the filter is ' +
      'hidden and assignment groups have not loaded', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'assignmentGroups'))
      strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2')
    })

    test('getFilterColumnsBySetting returns the grading period filter setting', () => {
      strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1402')
    })

    test('deletes the grading period filter setting when the filter is hidden', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'gradingPeriods'))
      strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), null)
    })

    test('getFilterColumnsBySetting returns the modules filter setting', () => {
      strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), '2')
    })

    test('deletes the modules filter setting when the filter is hidden and modules have loaded', () => {
      gradebook.contentLoadStates.contextModulesLoaded = true
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'modules'))
      strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), null)
    })

    test('does not delete the modules filter setting when the filter is hidden and modules have not loaded', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'modules'))
      strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), '2')
    })

    test('getFilterColumnsBySetting returns the sections filter setting', () => {
      strictEqual(gradebook.getFilterRowsBySetting('sectionId'), '2001')
    })

    test('deletes the sections filter setting when the filter is hidden', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'sections'))
      strictEqual(gradebook.getFilterRowsBySetting('sectionId'), null)
    })
  })

  QUnit.module('Gradebook#getOverridesViewOptionsMenuProps', () => {
    test('includes exactly what ViewOptionsMenu overrides props require', () => {
      const props = createGradebook().getOverridesViewOptionsMenuProps()
      const {propTypes: {overrides}} = ViewOptionsMenu
      const consoleSpy = sinon.spy(console, 'error')
      PropTypes.checkPropTypes({overrides}, props, 'prop', 'ViewOptionsMenu')
      strictEqual(consoleSpy.called, false)
      consoleSpy.restore()
    })

    test('disabled defaults to true', function () {
      const gradebook = createGradebook()
      const props = gradebook.getOverridesViewOptionsMenuProps()
      strictEqual(props.disabled, true)
    })

    test('disabled is false when the grid is ready', function () {
      const gradebook = createGradebook()
      sinon.stub(gradebook.gridReady, 'state').returns('resolved')
      const props = gradebook.getOverridesViewOptionsMenuProps()
      strictEqual(props.disabled, false)
    })

    test('disabled is true if the overrides column is updating', function () {
      const gradebook = createGradebook()
      sinon.stub(gradebook.gridReady, 'state').returns('resolved')
      gradebook.setOverridesColumnUpdating(true)
      const props = gradebook.getOverridesViewOptionsMenuProps()
      strictEqual(props.disabled, true)
    })

    test('disabled is false if the overrides column is not updating', function () {
      const gradebook = createGradebook()
      sinon.stub(gradebook.gridReady, 'state').returns('resolved')
      gradebook.setOverridesColumnUpdating(false)
      const props = gradebook.getOverridesViewOptionsMenuProps()
      strictEqual(props.disabled, false)
    })

    test('onSelect calls toggleOverrides', function () {
      const gradebook = createGradebook({ showFinalGradeOverrides: true })
      sinon.stub(gradebook, 'toggleOverrides')
      const props = gradebook.getOverridesViewOptionsMenuProps()
      props.onSelect()
      strictEqual(gradebook.toggleOverrides.callCount, 1)
      gradebook.toggleOverrides.restore()
    })

    test('selected reports showFinalGradeOverrides', function () {
      const show_final_grade_overrides = false
      const gradebook = createGradebook({settings: {show_final_grade_overrides}})
      const props = gradebook.getOverridesViewOptionsMenuProps()
      equal(props.selected, show_final_grade_overrides)
    })
  })
})

QUnit.module('Gradebook#getInitialGridDisplaySettings', () => {
  test('sets selectedPrimaryInfo based on the settings passed in', function () {
    const settings = { student_column_display_as: 'last_first' }
    const {gridDisplaySettings: {selectedPrimaryInfo}} = createGradebook({settings})
    strictEqual(selectedPrimaryInfo, settings.student_column_display_as)
  })

  test('sets selectedPrimaryInfo to default if no settings passed in', function () {
    const {gridDisplaySettings: {selectedPrimaryInfo}} = createGradebook()
    strictEqual(selectedPrimaryInfo, 'first_last')
  })

  test('sets selectedPrimaryInfo to default if unknown settings passed in', function () {
    const settings = { student_column_display_as: 'gary_42' }
    const {gridDisplaySettings: {selectedPrimaryInfo}} = createGradebook({settings})
    strictEqual(selectedPrimaryInfo, 'first_last')
  })

  test('sets selectedSecondaryInfo based on the settings passed in', function () {
    const settings = { student_column_secondary_info: 'login_id' }
    const {gridDisplaySettings: {selectedSecondaryInfo}} = createGradebook({settings})
    strictEqual(selectedSecondaryInfo, settings.student_column_secondary_info)
  })

  test('sets selectedSecondaryInfo to default if no settings passed in', function () {
    const {gridDisplaySettings: {selectedSecondaryInfo}} = createGradebook()
    strictEqual(selectedSecondaryInfo, 'none')
  })

  test('sets sortRowsBy > columnId based on the settings passed in', function () {
    const settings = { sort_rows_by_column_id: 'assignment_1' }
    const {gridDisplaySettings: {sortRowsBy: {columnId}}} = createGradebook({settings})
    strictEqual(columnId, settings.sort_rows_by_column_id)
  })

  test('sets sortRowsBy > columnId to default if no settings passed in', function () {
    const {gridDisplaySettings: {sortRowsBy: {columnId}}} = createGradebook()
    strictEqual(columnId, 'student')
  })

  test('sets sortRowsBy > settingKey based on the settings passed in', function () {
    const settings = { sort_rows_by_setting_key: 'grade' }
    const {gridDisplaySettings: {sortRowsBy: {settingKey}}} = createGradebook({settings})
    strictEqual(settingKey, settings.sort_rows_by_setting_key)
  })

  test('sets sortRowsBy > settingKey to default if no settings passed in', function () {
    const {gridDisplaySettings: {sortRowsBy: {settingKey}}} = createGradebook()
    strictEqual(settingKey, 'sortable_name')
  })

  test('sets sortRowsBy > Direction based on the settings passed in', function () {
    const settings = { sort_rows_by_direction: 'descending' }
    const {gridDisplaySettings: {sortRowsBy: {direction}}} = createGradebook({settings})
    strictEqual(direction, settings.sort_rows_by_direction)
  })

  test('sets sortRowsBy > Direction to default if no settings passed in', function () {
    const {gridDisplaySettings: {sortRowsBy: {direction}}} = createGradebook()
    strictEqual(direction, 'ascending')
  })

  test('sets showEnrollments.concluded to a default value', function () {
    const {gridDisplaySettings: {showEnrollments: {concluded}}} = createGradebook()
    strictEqual(concluded, false)
  })

  test('sets showEnrollments.inactive to a default value', function () {
    const {gridDisplaySettings: {showEnrollments: {inactive}}} = createGradebook()
    strictEqual(inactive, false)
  })

  test('sets showUnpublishedAssignment to a default value', function () {
    const {gridDisplaySettings: {showUnpublishedAssignments}} = createGradebook()
    strictEqual(showUnpublishedAssignments, true)
  })

  test('sets showFinalGradeOverrides to a default value', function () {
    const {gridDisplaySettings: {showFinalGradeOverrides}} = createGradebook()
    strictEqual(showFinalGradeOverrides, false)
  })
})

QUnit.module('Gradebook#isFilteringColumnsByGradingPeriod', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradingPeriodSet = { id: '1501', gradingPeriods: [{ id: '701' }, { id: '702' }] };
    this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '702');
  }
});

test('returns true when the "filter columns by" setting includes a grading period', function () {
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), true);
});

test('returns false when the "filter columns by" setting includes the "all grading periods" value ("0")', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false);
});

test('returns false when the "filter columns by" setting does not include a grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', null);
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false);
});

test('returns false when the "filter columns by" setting does not include a valid grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '799');
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false);
});

test('returns false when no grading period set exists', function () {
  this.gradebook.gradingPeriodSet = null;
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false);
});

test('returns true when the "filter columns by" setting is null and the current_grading_period_id is set', function () {
  this.gradebook.options.current_grading_period_id = '701';
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', null);
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), true);
});

QUnit.module('Gradebook#getGradingPeriodToShow', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradingPeriodSet = { id: '1501', gradingPeriods: [{ id: '701' }, { id: '702' }] };
    this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '702');
  }
});

test('returns the "filter columns by" setting when it includes a grading period', function () {
  strictEqual(this.gradebook.getGradingPeriodToShow(), '702');
});

test('returns "0" when the "filter columns by" setting includes the "all grading periods" value ("0")', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0');
  strictEqual(this.gradebook.getGradingPeriodToShow(), '0');
});

test('returns "0" when the "filter columns by" setting does not include a grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', null);
  strictEqual(this.gradebook.getGradingPeriodToShow(), '0');
});

test('returns "0" when the "filter columns by" setting does not include a valid grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '799');
  strictEqual(this.gradebook.getGradingPeriodToShow(), '0');
});

test('returns "0" when no grading period set exists', function () {
  this.gradebook.gradingPeriodSet = null;
  strictEqual(this.gradebook.getGradingPeriodToShow(), '0');
});

test('returns the current_grading_period_id when set and the "filter columns by" setting is null', function () {
  this.gradebook.options.current_grading_period_id = '701';
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', null);
  strictEqual(this.gradebook.getGradingPeriodToShow(), '701');
});

QUnit.module('Gradebook#setSelectedPrimaryInfo', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub()
      }
    };
    sandbox.stub(this.gradebook, 'saveSettings');
    sandbox.stub(this.gradebook, 'buildRows');
  }
});

test('updates the selectedPrimaryInfo in the grid display settings', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', true);

  strictEqual(this.gradebook.gridDisplaySettings.selectedPrimaryInfo, 'last_first');
});

test('saves the new grid display settings', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', true);

  strictEqual(this.gradebook.saveSettings.callCount, 1);
});

test('re-renders the grid unless asked not to do it', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false);

  strictEqual(this.gradebook.buildRows.callCount, 1);
});

test('updates the student column header', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false);

  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
});

test('includes the "student" column id when updating column headers', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false);
  const [columnIds] = this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args;
  deepEqual(columnIds, ['student']);
});

QUnit.module('Gradebook#setSelectedSecondaryInfo', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub()
      }
    };
    sandbox.stub(this.gradebook, 'saveSettings');
    sandbox.stub(this.gradebook, 'buildRows');
  }
});

test('updates the selectedSecondaryInfo in the grid display settings', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', true);

  strictEqual(this.gradebook.gridDisplaySettings.selectedSecondaryInfo, 'last_first');
});

test('saves the new grid display settings', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', true);

  strictEqual(this.gradebook.saveSettings.callCount, 1);
});

test('re-renders the grid unless asked not to do it', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false);

  strictEqual(this.gradebook.buildRows.callCount, 1);
});

test('updates the student column header', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false);

  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
});

test('includes the "student" column id when updating column headers', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false);
  const [columnIds] = this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args;
  deepEqual(columnIds, ['student']);
});

QUnit.module('Gradebook#setSortRowsBySetting', {
  setup () {
    this.gradebook = createGradebook();
    sandbox.stub(this.gradebook, 'saveSettings');
    sandbox.stub(this.gradebook, 'sortGridRows');

    this.gradebook.setSortRowsBySetting('assignment_1', 'grade', 'descending');
  }
});

test('updates the sort column in the grid display settings', function () {
  strictEqual(this.gradebook.gridDisplaySettings.sortRowsBy.columnId, 'assignment_1');
});

test('updates the sort setting key in the grid display settings', function () {
  strictEqual(this.gradebook.gridDisplaySettings.sortRowsBy.settingKey, 'grade');
});

test('updates the sort direction in the grid display settings', function () {
  strictEqual(this.gradebook.gridDisplaySettings.sortRowsBy.direction, 'descending');
});

test('saves the new grid display settings', function () {
  strictEqual(this.gradebook.saveSettings.callCount, 1);
});

test('re-sorts the grid rows', function () {
  strictEqual(this.gradebook.sortGridRows.callCount, 1);
});

QUnit.module('Gradebook#onGridBlur', {
  setup () {
    $fixtures.innerHTML = `
      <div id="application">
        <div id="wrapper">
          <div id="StudentTray__Container"></div>
          <span data-component="GridColor"></span>
          <div id="gradebook_grid"></div>
        </div>
      </div>
    `;

    this.gradebook = createGradebook();
    this.gradebook.gridData.rows = [{ id: '1101' }];
    const students = [{
      enrollments: [{ type: 'StudentEnrollment', grades: { html_url: 'http://example.url/' } }],
      id: '1101',
      name: 'Adam Jones',
      assignment_2301: {
        assignment_id: '2301', id: '2501', late: false, missing: false, excused: false, seconds_late: 0
      },
      enrollment_state: ['active']
    }]
    this.gradebook.gotChunkOfStudents(students);
    this.gradebook.initGrid();
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
        submission_types: ['online_text_entry']
      }
    })
    this.gradebook.assignmentGroups = {9000: {group_weight: 100}}

    // Since the activeLocationChanged handlers use delayed calls, we need to
    // hijack timers and tick() before calling setActiveLocation() below.
    const clock = sinon.useFakeTimers();
    clock.tick(0);
    this.gradebook.gradebookGrid.gridSupport.state.setActiveLocation('body', { cell: 0, row: 0 });
    clock.restore();

    sinon.spy(this.gradebook.gradebookGrid.gridSupport.state, 'blur');
  },

  teardown () {
    this.gradebook.destroy();
    $fixtures.innerHTML = '';
  }
});

test('closes grid details tray when open', function () {
  this.gradebook.setSubmissionTrayState(true, '1101', '2301');
  this.gradebook.onGridBlur({ target: document.body });
  strictEqual(this.gradebook.gridDisplaySettings.submissionTray.open, false);
});

test('does not close grid details tray when not open', function () {
  const closeSubmissionTrayStub = sandbox.stub(this.gradebook, 'closeSubmissionTray');
  this.gradebook.setSubmissionTrayState(false, '1101', '2301');
  this.gradebook.onGridBlur({ target: document.body });
  strictEqual(closeSubmissionTrayStub.callCount, 0);
});

test('blurs the grid when clicking off grid cells', function () {
  this.gradebook.onGridBlur({ target: document.body });
  strictEqual(this.gradebook.gradebookGrid.gridSupport.state.blur.callCount, 1);
});

test('does not blur the grid when clicking on the active cell', function () {
  const $activeNode = this.gradebook.gradebookGrid.gridSupport.state.getActiveNode();
  this.gradebook.onGridBlur({ target: $activeNode });
  strictEqual(this.gradebook.gradebookGrid.gridSupport.state.blur.callCount, 0);
});

test('does not blur the grid when clicking on another grid cell', function () {
  const $activeNode = this.gradebook.gradebookGrid.gridSupport.state.getActiveNode();
  this.gradebook.gradebookGrid.gridSupport.state.setActiveLocation('body', { cell: 1, row: 0 });
  this.gradebook.onGridBlur({ target: $activeNode });
  strictEqual(this.gradebook.gradebookGrid.gridSupport.state.blur.callCount, 0);
});

QUnit.module('GridColor', {
  setup () {
    $fixtures.innerHTML = `
      <div id="application">
        <span data-component="GridColor"></span>
        <div id="gradebook_grid"></div>
      </div>
    `;
  },

  teardown () {
    $fixtures.innerHTML = '';
  }
});

test('is rendered on init', function () {
  const gradebook = createGradebook();
  const renderGridColorStub = sandbox.stub(gradebook, 'renderGridColor');
  sandbox.stub(gradebook, 'onGridInit');
  gradebook.initGrid();
  ok(renderGridColorStub.called);
});

test('is rendered on renderGridColor', function () {
  const gradebook = createGradebook({ colors: statusColors() });
  gradebook.renderGridColor();
  const style = document.querySelector('[data-component="GridColor"] style').innerText;
  equal(style, [
    `.even .gradebook-cell.late { background-color: ${defaultColors.blue}; }`,
    `.odd .gradebook-cell.late { background-color: ${darken(defaultColors.blue, 5)}; }`,
    '.slick-cell.editable .gradebook-cell.late { background-color: white; }',
    `.even .gradebook-cell.missing { background-color: ${defaultColors.salmon}; }`,
    `.odd .gradebook-cell.missing { background-color: ${darken(defaultColors.salmon, 5)}; }`,
    '.slick-cell.editable .gradebook-cell.missing { background-color: white; }',
    `.even .gradebook-cell.resubmitted { background-color: ${defaultColors.green}; }`,
    `.odd .gradebook-cell.resubmitted { background-color: ${darken(defaultColors.green, 5)}; }`,
    '.slick-cell.editable .gradebook-cell.resubmitted { background-color: white; }',
    `.even .gradebook-cell.dropped { background-color: ${defaultColors.orange}; }`,
    `.odd .gradebook-cell.dropped { background-color: ${darken(defaultColors.orange, 5)}; }`,
    '.slick-cell.editable .gradebook-cell.dropped { background-color: white; }',
    `.even .gradebook-cell.excused { background-color: ${defaultColors.yellow}; }`,
    `.odd .gradebook-cell.excused { background-color: ${darken(defaultColors.yellow, 5)}; }`,
    '.slick-cell.editable .gradebook-cell.excused { background-color: white; }'
  ].join(''));
  $fixtures.innerHTML = '';
});

QUnit.module('Gradebook#updateSubmissionsFromExternal', {
  setup () {
    const columns = [
      { id: 'student', type: 'student' },
      { id: 'assignment_232', type: 'assignment' },
      { id: 'total_grade', type: 'total_grade' },
      { id: 'assignment_group_12', type: 'assignment' }
    ];
    this.gradebook = createGradebook();
    this.gradebook.students = {
      1101: { id: '1101', assignment_201: {}, assignment_202: {} },
      1102: { id: '1102', assignment_201: {} }
    };
    this.gradebook.assignments = []
    this.gradebook.submissionStateMap = {
      setSubmissionCellState () {},
      getSubmissionState () { return { locked: false } }
    };
    this.gradebook.gradebookGrid.grid = {
      updateCell: sinon.stub(),
      getColumns () { return columns },
    };
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub()
      }
    };
    sandbox.stub(this.gradebook, 'updateSubmission');
  }
});

test('updates row cells', function () {
  const submissions = [
    { assignment_id: '201', user_id: '1101', score: 10, assignment_visible: true },
    { assignment_id: '201', user_id: '1102', score: 8, assignment_visible: true }
  ];
  sandbox.stub(this.gradebook, 'updateRowCellsForStudentIds');
  this.gradebook.updateSubmissionsFromExternal(submissions);
  strictEqual(this.gradebook.updateRowCellsForStudentIds.callCount, 1);
});

test('updates row cells only once for each student', function () {
  const submissions = [
    { assignment_id: '201', user_id: '1101', score: 10, assignment_visible: true },
    { assignment_id: '202', user_id: '1101', score: 9, assignment_visible: true },
    { assignment_id: '201', user_id: '1102', score: 8, assignment_visible: true }
  ];
  sandbox.stub(this.gradebook, 'updateRowCellsForStudentIds');
  this.gradebook.updateSubmissionsFromExternal(submissions);
  const [studentIds] = this.gradebook.updateRowCellsForStudentIds.lastCall.args;
  deepEqual(studentIds, ['1101', '1102']);
});

test('ignores submissions for students not currently loaded', function () {
  const submissions = [
    { assignment_id: '201', user_id: '1101', score: 10, assignment_visible: true },
    { assignment_id: '201', user_id: '1103', score: 9, assignment_visible: true },
    { assignment_id: '201', user_id: '1102', score: 8, assignment_visible: true }
  ];
  sandbox.stub(this.gradebook, 'updateRowCellsForStudentIds');
  this.gradebook.updateSubmissionsFromExternal(submissions);
  const [studentIds] = this.gradebook.updateRowCellsForStudentIds.lastCall.args;
  deepEqual(studentIds, ['1101', '1102']);
});

test('updates column headers', function () {
  const submissions = [
    { assignment_id: '201', user_id: '1101', score: 10, assignment_visible: true }
  ];
  this.gradebook.updateSubmissionsFromExternal(submissions);
  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1);
});

test('includes the column ids for related assignments when updating column headers', function () {
  const submissions = [
    { assignment_id: '201', user_id: '1101', score: 10, assignment_visible: true },
    { assignment_id: '202', user_id: '1101', score: 9, assignment_visible: true },
    { assignment_id: '201', user_id: '1102', score: 8, assignment_visible: true }
  ];
  this.gradebook.updateSubmissionsFromExternal(submissions);
  const [columnIds] = this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args;
  deepEqual(columnIds.sort(), ['assignment_201', 'assignment_202']);
});

QUnit.module('Gradebook#getSubmissionTrayProps', function(suiteHooks) {
  const url = '/api/v1/courses/1/assignments/2/submissions/3';
  const mountPointId = 'StudentTray__Container';
  const defaultGradingScheme = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]];
  let gradebook;

  suiteHooks.beforeEach(() => {
    moxios.install();
    moxios.stubRequest(url, { status: 200, response: { submission_comments: [] }});
    $fixtures.innerHTML = `<div id="${mountPointId}"></div><div id="application"></div>`;
    gradebook = createGradebook({
      default_grading_standard: defaultGradingScheme
    });
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
        submission_types: ['online_text_entry']
      }
    })
    gradebook.students = {
      1101: {
        id: '1101',
        name: 'J&#x27;onn J&#x27;onzz',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        },
        enrollments: [
          {
            grades: {
              html_url: 'http://gradesUrl/'
            }
          }
        ],
        isConcluded: false
      }
    };
    gradebook.initSubmissionStateMap();
    gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit () {},
        focus () {}
      },
      state: {
        getActiveLocation: () => ({ region: 'body', cell: 0, row: 0 })
      },
      grid: {
        getColumns: () => []
      }
    };
  });

  suiteHooks.afterEach(() => {
    const node = document.getElementById(mountPointId);
    ReactDOM.unmountComponentAtNode(node);
    $fixtures.innerHTML = '';
    moxios.uninstall();
  });

  test('gradingDisabled is true when the submission state is locked', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ locked: true });
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));
    strictEqual(props.gradingDisabled, true);
  });

  test('gradingDisabled is false when the submission state is not locked', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ locked: false });
    gradebook.student('1101').isConcluded = false;
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));
    strictEqual(props.gradingDisabled, false);
  });

  test('gradingDisabled is false when the submission state is undefined', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns(undefined);
    gradebook.student('1101').isConcluded = false;
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));
    strictEqual(props.gradingDisabled, false);
  });

  test('gradingDisabled is true when the student enrollment is concluded', function () {
    gradebook.student('1101').isConcluded = true;
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));
    strictEqual(props.gradingDisabled, true);
  });

  test('gradingDisabled is false when the student enrollment is not concluded', function () {
    gradebook.student('1101').isConcluded = false;
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));
    strictEqual(props.gradingDisabled, false);
  });

  test('onGradeSubmission is the Gradebook "gradeSubmission" method', function () {
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));
    equal(props.onGradeSubmission, gradebook.gradeSubmission);
  });

  test('student has valid gradesUrl', function () {
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.student.gradesUrl, 'http://gradesUrl/#tab-assignments');
  });

  test('student has html decoded name', function () {
    gradebook.students[1101].name = 'J&#x27;onn J&#x27;onzz';
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.student.name, "J'onn J'onzz");
  });

  test('student has isConcluded property', function () {
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.student.isConcluded, false);
  });

  test('isInOtherGradingPeriod is true when the SubmissionStateMap returns true', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ inOtherGradingPeriod: true });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInOtherGradingPeriod, true);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInOtherGradingPeriod is false when the SubmissionStateMap returns false', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ inOtherGradingPeriod: false });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInOtherGradingPeriod, false);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInOtherGradingPeriod is false when the SubmissionStateMap returns undefined', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInOtherGradingPeriod, false);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInClosedGradingPeriod is true when the SubmissionStateMap returns true', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ inClosedGradingPeriod: true });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInClosedGradingPeriod, true);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInClosedGradingPeriod is false when the SubmissionStateMap returns false', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ inClosedGradingPeriod: false });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInClosedGradingPeriod, false);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInClosedGradingPeriod is false when the SubmissionStateMap returns undefined', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInClosedGradingPeriod, false);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInNoGradingPeriod is true when the SubmissionStateMap returns true', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ inNoGradingPeriod: true });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInNoGradingPeriod, true);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInNoGradingPeriod is false when the SubmissionStateMap returns false', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ inNoGradingPeriod: false });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInNoGradingPeriod, false);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('isInNoGradingPeriod is false when the SubmissionStateMap returns undefined', function () {
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({ });

    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(props.isInNoGradingPeriod, false);

    gradebook.submissionStateMap.getSubmissionState.restore();
  });

  test('gradingScheme is the grading scheme for the assignment', function () {
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    deepEqual(props.gradingScheme, defaultGradingScheme);
  });

  test('enterGradesAs is the "enter grades as" setting for the assignment', function () {
    sinon.spy(gradebook, 'getEnterGradesAsSetting');
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'));

    strictEqual(gradebook.getEnterGradesAsSetting.withArgs('2301').callCount, 1);
    strictEqual(props.enterGradesAs, 'points');
  });

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
    const pendingGradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
    const submission = {assignmentId: '2301', userId: '1101'}

    gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
    gradebook.setSubmissionTrayState(true, '1101', '2301')

    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    deepEqual(
      props.pendingGradeInfo,
      { ...pendingGradeInfo, assignmentId: '2301', userId: '1101' }
    )
  })

  test('sets pendingGradeInfo to null when no pending grade exists for the current student/assignment', () => {
    const pendingGradeInfo = {enteredAs: null, excused: false, grade: null, score: null, valid: true}
    const submission = {assignmentId: '2302', userId: '1101'}

    gradebook.addPendingGradeInfo(submission, pendingGradeInfo)
    gradebook.setSubmissionTrayState(true, '1101', '2301')

    const props = gradebook.getSubmissionTrayProps(gradebook.student('1101'))
    notOk(props.pendingGradeInfo)
  })
});

QUnit.module('Gradebook#renderSubmissionTray', {
  setup () {
    moxios.install();
    const url = '/api/v1/courses/1/assignments/2/submissions/3';
    moxios.stubRequest(url, { status: 200, response: { submission_comments: [] }});
    this.mountPointId = 'StudentTray__Container';
    $fixtures.innerHTML = `<div id="${this.mountPointId}"></div><div id="application"></div>`;
    this.gradebook = createGradebook();
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
        submission_types: ['online_text_entry']
      }
    })
    this.gradebook.setAssignmentGroups({9000: {group_weight: 100}})
    this.gradebook.students = {
      1101: {
        id: '1101',
        name: 'J&#x27;onn J&#x27;onzz',
        assignment_2301: {
          assignment_id: '2301', id: '2501', late: false, missing: false, excused: false, seconds_late: 0
        },
        enrollments: [
          {
            grades: {
              html_url: 'http://gradesUrl/'
            }
          }
        ],
        isConcluded: false
      }
    };
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit () {},
        focus () {}
      },
      state: {
        getActiveLocation: () => ({ region: 'body', cell: 0, row: 0 })
      },
      grid: {
        getColumns: () => []
      }
    };
  },

  teardown () {
    const node = document.getElementById(this.mountPointId);
    ReactDOM.unmountComponentAtNode(node);
    $fixtures.innerHTML = '';
    moxios.uninstall();
  }
});

test('shows a submission tray on the page when rendering an open tray', function () {
  const clock = sinon.useFakeTimers();
  this.gradebook.setSubmissionTrayState(true, '1101', '2301');
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'));
  clock.tick(500); // wait for Tray to transition open
  ok(document.querySelector('[aria-label="Submission tray"]'));
  clock.restore();
});

test('does not show a submission tray on the page when rendering a closed tray', function () {
  const clock = sinon.useFakeTimers();
  this.gradebook.setSubmissionTrayState(false, '1101', '2301');
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'));
  clock.tick(500); // wait for Tray transition to ensure it has not opened
  notOk(document.querySelector('[aria-label="Submission tray"]'));
  clock.restore();
});

test('shows a submission tray when the related submission has not loaded for the student', function () {
  const clock = sinon.useFakeTimers();
  this.gradebook.setSubmissionTrayState(true, '1101', '2301');
  this.gradebook.student('1101').assignment_2301 = undefined;
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'));
  clock.tick(500); // wait for Tray to transition open
  ok(document.querySelector('[aria-label="Submission tray"]'));
  clock.restore();
});

test('calls getSubmissionTrayProps with the student', function () {
  sinon.spy(this.gradebook, 'getSubmissionTrayProps');
  this.gradebook.setSubmissionTrayState(true, '1101', '2301');
  this.gradebook.renderSubmissionTray(this.gradebook.student('1101'));
  deepEqual(this.gradebook.getSubmissionTrayProps.firstCall.args, [this.gradebook.student('1101')]);
});

QUnit.module('Gradebook#renderSubmissionTray - Student Carousel', function (hooks) {
  let gradebook;
  let mountPointId;
  let clock;

  hooks.beforeEach(() => {
    mountPointId = 'StudentTray__Container';
    $fixtures.innerHTML = `<div id="${mountPointId}"></div><div id="application"></div>`;
    moxios.install();
    const url = '/api/v1/courses/1/assignments/2301/submissions/1101?include=submission_comments';
    moxios.stubRequest(url, { status: 200, response: { submission_comments: [] }});
    gradebook = createGradebook();
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
        submission_types: ['online_text_entry']
      }
    })
    gradebook.setAssignmentGroups({9000: {group_weight: 100}})

    gradebook.students = {
      1100: {
        id: '1100',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        },
        enrollments: [{ grades: { html_url: 'http://gradesUrl/' } }],
        isConcluded: false
      },
      1101: {
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        },
        enrollments: [{ grades: { html_url: 'http://gradesUrl/' } }],
        isConcluded: false
      },
      1102: {
        id: '1100',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        },
        enrollments: [{ grades: { html_url: 'http://gradesUrl/' } }],
        isConcluded: false
      }
    };
    sinon.stub(gradebook, 'listRows').returns([1100, 1101, 1102].map(id => gradebook.students[id]));
    gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit () {},
        focus () {}
      },
      state: {
        getActiveLocation: () => ({ region: 'body', cell: 0, row: 0 })
      },
      grid: {
        getColumns: () => []
      }
    };
    clock = sinon.useFakeTimers();
  });

  hooks.afterEach(() => {
    if (clock) {
      clock.restore();
    }
    const node = document.getElementById(mountPointId);
    ReactDOM.unmountComponentAtNode(node);
    moxios.uninstall();
    $fixtures.innerHTML = '';
  });

  test('does not show the previous student arrow for the first student', function () {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({ region: 'body', cell: 0, row: 0 });
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    clock.tick(500); // wait for Tray to transition open

    strictEqual(document.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows the next student arrow for the first student', function () {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({ region: 'body', cell: 0, row: 0 });
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    clock.tick(500); // wait for Tray to transition open

    strictEqual(document.querySelectorAll('#student-carousel .right-arrow-button-container button').length, 1);
  });

  test('does not show the next student arrow for the last student', function () {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({ region: 'body', cell: 0, row: 2 });
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    clock.tick(500); // wait for Tray to transition open

    strictEqual(document.querySelectorAll('#student-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows the previous student arrow for the last student', function () {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({ region: 'body', cell: 0, row: 2 });
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    clock.tick(500); // wait for Tray to transition open

    strictEqual(document.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 1);
  });

  test('clicking the next student arrow calls loadTrayStudent with "next"', function () {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({ region: 'body', cell: 0, row: 1 });
    sinon.stub(gradebook, 'loadTrayStudent');
    sinon.stub(gradebook, 'getCommentsUpdating').returns(false);
    sinon.stub(gradebook, 'getSubmissionCommentsLoaded').returns(true);
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    clock.tick(500); // wait for Tray to transition open

    const nextStudentButton = document.querySelector('#student-carousel .right-arrow-button-container button');
    nextStudentButton.click();
    strictEqual(gradebook.loadTrayStudent.callCount, 1);
    deepEqual(gradebook.loadTrayStudent.getCall(0).args, ['next'])
  });

  test('clicking the previous student arrow calls loadTrayStudent with "previous"', function () {
    gradebook.gradebookGrid.gridSupport.state.getActiveLocation = () => ({ region: 'body', cell: 0, row: 1 });
    sinon.stub(gradebook, 'loadTrayStudent');
    sinon.stub(gradebook, 'getCommentsUpdating').returns(false);
    sinon.stub(gradebook, 'getSubmissionCommentsLoaded').returns(true);
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    clock.tick(500); // wait for Tray to transition open

    const nextStudentButton = document.querySelector('#student-carousel .left-arrow-button-container button');
    nextStudentButton.click();
    strictEqual(gradebook.loadTrayStudent.callCount, 1);
    deepEqual(gradebook.loadTrayStudent.getCall(0).args, ['previous'])
  });

  test('calls loadSubmissionComments', function () {
    const loadSubmissionCommentsStub = sinon.stub(gradebook, 'loadSubmissionComments');
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    strictEqual(loadSubmissionCommentsStub.callCount, 1);
  });

  test('does not call loadSubmissionComments if not open', function () {
    const loadSubmissionCommentsStub = sinon.stub(gradebook, 'loadSubmissionComments');
    gradebook.setSubmissionTrayState(false, '1101', '2301');
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    strictEqual(loadSubmissionCommentsStub.callCount, 0);
  });

  test('does not call loadSubmissionComments if loaded', function () {
    const loadSubmissionCommentsStub = sinon.stub(gradebook, 'loadSubmissionComments');
    gradebook.setSubmissionTrayState(true, '1101', '2301');
    gradebook.setSubmissionCommentsLoaded(true);
    gradebook.renderSubmissionTray(gradebook.student('1101'));
    strictEqual(loadSubmissionCommentsStub.callCount, 0);
  });
});

QUnit.module('Gradebook#loadTrayStudent', function (hooks) {
  let gradebook;

  hooks.beforeEach(() => {
    gradebook = createGradebook();
    gradebook.gradebookGrid.gridSupport = {
      state: {
        getActiveLocation: () => ({ region: 'body', cell: 0, row: 1 }),
        setActiveLocation: sinon.stub()
      },
      helper: {
        commitCurrentEdit () {}
      }
    };
    gradebook.students = {
      1100: {
        id: '1100',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        }
      },
      1101: {
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        }
      },
      1102: {
        id: '1102',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301', late: false, missing: false, excused: false, seconds_late: 0
        }
      }
    };
    sinon.stub(gradebook, 'listRows').returns([1100, 1101, 1102].map(id => gradebook.students[id]));
    sinon.stub(gradebook, 'updateRowAndRenderSubmissionTray');
    sinon.stub(gradebook, 'unloadSubmissionComments');
  });

  test('when called with "previous", changes the highlighted cell to the previous row', function () {
    gradebook.loadTrayStudent('previous');

    const expectation = ['body', { cell: 0, row: 0}];
    deepEqual(gradebook.gradebookGrid.gridSupport.state.setActiveLocation.firstCall.args, expectation);
  });

  test('when called with "previous", updates the submission tray state', function () {
    gradebook.loadTrayStudent('previous');

    const submissionTrayState = gradebook.getSubmissionTrayState();
    const fieldsToConsider = ['open', 'studentId'];

    const actual = {}
    fieldsToConsider.forEach((field) => { actual[field] = submissionTrayState[field] });

    const expectation = { open: true, studentId: '1100' };
    deepEqual(actual, expectation);
  });

  test('when called with "previous", updates and renders the submission tray with the new student', function () {
    gradebook.loadTrayStudent('previous');

    deepEqual(gradebook.updateRowAndRenderSubmissionTray.firstCall.args, ['1100']);
  });

  test('when called with "previous" while on the first row, does not change the highlighted cell', function () {
    sinon.stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation').returns({ region: 'body', cell: 0, row: 0 });
    gradebook.loadTrayStudent('previous');

    strictEqual(gradebook.gradebookGrid.gridSupport.state.setActiveLocation.callCount, 0);
  });

  test('when called with "previous" while on the first row, does not update the submission tray state', function () {
    sinon.stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation').returns({ region: 'body', cell: 0, row: 0 });
    sinon.stub(gradebook, 'setSubmissionTrayState');
    gradebook.loadTrayStudent('previous');

    strictEqual(gradebook.setSubmissionTrayState.callCount, 0);
  });

  test('when called with "previous" while on the first row, does not update and render the submission tray', function () {
    sinon.stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation').returns({ region: 'body', cell: 0, row: 0 });
    gradebook.loadTrayStudent('previous');

    strictEqual(gradebook.updateRowAndRenderSubmissionTray.callCount, 0);
  });

  test('when called with "next", changes the highlighted cell to the next row', function () {
    gradebook.loadTrayStudent('next');

    const expectation = ['body', { cell: 0, row: 2}];
    deepEqual(gradebook.gradebookGrid.gridSupport.state.setActiveLocation.firstCall.args, expectation);
  });

  test('when called with "next", updates the submission tray state', function () {
    gradebook.loadTrayStudent('next');

    const submissionTrayState = gradebook.getSubmissionTrayState();
    const fieldsToConsider = ['open', 'studentId'];

    const actual = {};
    fieldsToConsider.forEach((field) => { actual[field] = submissionTrayState[field] });

    const expectation = { open: true, studentId: '1102' };
    deepEqual(actual, expectation);
  });

  test('when called with "next", updates and renders the submission tray with the new student', function () {
    gradebook.loadTrayStudent('next');

    deepEqual(gradebook.updateRowAndRenderSubmissionTray.firstCall.args, ['1102']);
  });

  test('when called with "next" while on the last row, does not change the highlighted cell', function () {
    sinon.stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation').returns({ region: 'body', cell: 0, row: 2 });
    gradebook.loadTrayStudent('next');

    strictEqual(gradebook.gradebookGrid.gridSupport.state.setActiveLocation.callCount, 0);
  });

  test('when called with "next" while on the last row, does not update the submission tray state', function () {
    sinon.stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation').returns({ region: 'body', cell: 0, row: 2 });
    sinon.stub(gradebook, 'setSubmissionTrayState');
    gradebook.loadTrayStudent('next');

    strictEqual(gradebook.setSubmissionTrayState.callCount, 0);
  });

  test('when called with "next" while on the last row, does not update and render the submission tray', function () {
    sinon.stub(gradebook.gradebookGrid.gridSupport.state, 'getActiveLocation').returns({ region: 'body', cell: 0, row: 2 });
    gradebook.loadTrayStudent('next');

    strictEqual(gradebook.updateRowAndRenderSubmissionTray.callCount, 0);
  });
});

QUnit.module('Gradebook#updateRowAndRenderSubmissionTray', {
  setup () {
    this.gradebook = createGradebook();
    sandbox.stub(this.gradebook, 'updateRowCellsForStudentIds');
    sandbox.stub(this.gradebook, 'renderSubmissionTray');
  }
});

test('unloads comments for the submission', function () {
  sandbox.stub(this.gradebook, 'unloadSubmissionComments');
  this.gradebook.updateRowAndRenderSubmissionTray('1');

  strictEqual(this.gradebook.unloadSubmissionComments.callCount, 1);
});

test('updates the row cell for the given student id', function () {
  this.gradebook.updateRowAndRenderSubmissionTray('1');
  strictEqual(this.gradebook.updateRowCellsForStudentIds.callCount, 1);
  deepEqual(
    this.gradebook.updateRowCellsForStudentIds.getCall(0).args[0],
    ['1']
  );
});

test('renders the submission tray', function () {
  this.gradebook.updateRowAndRenderSubmissionTray('1');
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 1);
});

QUnit.module('Gradebook#toggleSubmissionTrayOpen', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit () {},
        focus () {}
      }
    };
    sandbox.stub(this.gradebook, 'updateRowAndRenderSubmissionTray');
  }
});

test('sets the tray state to open if it was closed', function () {
  const openState = { before: this.gradebook.getSubmissionTrayState().open };
  this.gradebook.toggleSubmissionTrayOpen('1', '2');
  openState.after = this.gradebook.getSubmissionTrayState().open;
  deepEqual(openState, { before: false, after: true });
});

test('sets the tray state to closed if it was open', function () {
  this.gradebook.setSubmissionTrayState(true, '1', '2');
  const openState = { before: this.gradebook.getSubmissionTrayState().open };
  this.gradebook.toggleSubmissionTrayOpen('1', '2');
  openState.after = this.gradebook.getSubmissionTrayState().open;
  deepEqual(openState, { before: true, after: false });
});

test('sets the studentId and assignmentId state for the tray', function () {
  this.gradebook.toggleSubmissionTrayOpen('1', '2');
  const { studentId, assignmentId } = this.gradebook.getSubmissionTrayState();
  deepEqual({ studentId, assignmentId }, { studentId: '1', assignmentId: '2' });
});

QUnit.module('Gradebook#closeSubmissionTray', {
  setup () {
    this.gradebook = createGradebook();
    this.activeStudentId = '1101';
    this.gradebook.gridData.rows = [{ id: this.activeStudentId }];
    this.gradebook.gradebookGrid.grid = { getActiveCell () { return { row: 0 } } };
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit () {},
        focus () {},
        beginEdit () {}
      }
    };
    this.gradebook.setSubmissionTrayState(true, '1101', '2');
    sandbox.stub(this.gradebook, 'updateRowAndRenderSubmissionTray');
  }
});

test('sets the state of the tray to closed', function () {
  const openState = { before: this.gradebook.getSubmissionTrayState().open };
  this.gradebook.closeSubmissionTray();
  openState.after = this.gradebook.getSubmissionTrayState().open;
  deepEqual(openState, { before: true, after: false });
});

test('calls updateRowAndRenderSubmissionTray with the student id for the active row', function () {
  this.gradebook.closeSubmissionTray();
  strictEqual(this.gradebook.updateRowAndRenderSubmissionTray.callCount, 1);
  strictEqual(
    this.gradebook.updateRowAndRenderSubmissionTray.getCall(0).args[0],
    this.activeStudentId
  );
});

test('puts the active grid cell back into "editing" mode', function () {
  sandbox.stub(this.gradebook.gradebookGrid.gridSupport.helper, 'beginEdit');
  this.gradebook.closeSubmissionTray();
  strictEqual(this.gradebook.gradebookGrid.gridSupport.helper.beginEdit.callCount, 1);
});

QUnit.module('Gradebook#setSubmissionTrayState', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit: sinon.stub(),
        focus: sinon.stub()
      }
    };
  }
});

test('sets the state of the submission tray', function () {
  this.gradebook.setSubmissionTrayState(true, '1', '2');
  const expected = {
    open: true,
    studentId: '1',
    assignmentId: '2',
    commentsLoaded: false,
    comments: [],
    commentsUpdating: false,
    editedCommentId: null
  };

  deepEqual(this.gradebook.gridDisplaySettings.submissionTray, expected);
});

test('puts cell in view mode when tray is opened', function () {
  this.gradebook.setSubmissionTrayState(true, '1', '2');
  strictEqual(this.gradebook.gradebookGrid.gridSupport.helper.commitCurrentEdit.callCount, 1);
});

test('does not put cell in view mode when tray is closed', function () {
  this.gradebook.setSubmissionTrayState(false, '1', '2');
  strictEqual(this.gradebook.gradebookGrid.gridSupport.helper.commitCurrentEdit.callCount, 0);
});

QUnit.module('Gradebook#getSubmissionTrayState', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('returns the state of the submission tray', function () {
  const expected = {
    open: false,
    studentId: null,
    assignmentId: null ,
    commentsLoaded: false,
    comments: [],
    commentsUpdating: false,
    editedCommentId: null
  };

  deepEqual(this.gradebook.getSubmissionTrayState(), expected);
});

test('returns the state of the submission tray when accessed directly', function () {
  this.gradebook.gridDisplaySettings.submissionTray.open = true;
  this.gradebook.gridDisplaySettings.submissionTray.studentId = '1';
  this.gradebook.gridDisplaySettings.submissionTray.assignmentId = '2';
  const expected = {
    open: true,
    studentId: '1',
    assignmentId: '2',
    commentsLoaded: false,
    comments: [],
    commentsUpdating: false,
    editedCommentId: null
  };

  deepEqual(this.gradebook.getSubmissionTrayState(), expected);
});

QUnit.module('Gradebook Assignment Actions', function (suiteHooks) {
  let gradebook;
  let assignments;

  suiteHooks.beforeEach(function () {
    gradebook = createGradebook({
      download_assignment_submissions_url: 'http://example.com/submissions'
    });

    assignments = [{
      id: '2301',
      submission_types: ['online_text_entry']
    }, {
      id: '2302',
      submission_types: ['online_text_entry']
    }];

    gradebook.gotAllAssignmentGroups([
      { id: '2201', position: 1, name: 'Assignments', assignments: assignments.slice(0, 1) },
      { id: '2202', position: 2, name: 'Homework', assignments: assignments.slice(1, 2) }
    ]);
  });

  QUnit.module('#getDownloadSubmissionsAction', function () {
    test('includes the "hidden" property', function () {
      const action = gradebook.getDownloadSubmissionsAction('2301');
      equal(typeof action.hidden, 'boolean');
    });

    test('includes the "onSelect" callback', function () {
      const action = gradebook.getDownloadSubmissionsAction('2301');
      equal(typeof action.onSelect, 'function');
    });
  });

  QUnit.module('#getReuploadSubmissionsAction', function () {
    test('includes the "hidden" property', function () {
      const action = gradebook.getReuploadSubmissionsAction('2301');
      equal(typeof action.hidden, 'boolean');
    });

    test('includes the "onSelect" callback', function () {
      const action = gradebook.getReuploadSubmissionsAction('2301');
      equal(typeof action.onSelect, 'function');
    });
  });

  QUnit.module('#getSetDefaultGradeAction', function () {
    test('includes the "disabled" property', function () {
      const action = gradebook.getSetDefaultGradeAction('2301');
      equal(typeof action.disabled, 'boolean');
    });

    test('includes the "onSelect" callback', function () {
      const action = gradebook.getSetDefaultGradeAction('2301');
      equal(typeof action.onSelect, 'function');
    });
  });

  QUnit.module('#getCurveGradesAction', function () {
    test('includes the "isDisabled" property', function () {
      const action = gradebook.getCurveGradesAction('2301');
      equal(typeof action.isDisabled, 'boolean');
    });

    test('includes the "onSelect" callback', function () {
      const action = gradebook.getCurveGradesAction('2301');
      equal(typeof action.onSelect, 'function');
    });
  });

  QUnit.module('#getMuteAssignmentAction', function () {
    test('includes the "disabled" property', function () {
      const action = gradebook.getMuteAssignmentAction('2301');
      equal(typeof action.disabled, 'boolean');
    });

    test('includes the "onSelect" callback', function () {
      const action = gradebook.getMuteAssignmentAction('2301');
      equal(typeof action.onSelect, 'function');
    });
  });
});

QUnit.module('Gradebook#setLatePolicy', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('sets the late policy state', function () {
  const latePolicy = { lateSubmissionInterval: 'day' };
  this.gradebook.setLatePolicy(latePolicy);
  deepEqual(this.gradebook.courseContent.latePolicy, latePolicy);
});

QUnit.module('Gradebook#applyLatePolicy', {
  setup () {
    this.gradingStandard = [['A', 0]];
    this.gradebook = createGradebook({ grading_standard: this.gradingStandard });
    this.gradebook.gradingPeriodSet = { gradingPeriods: [{ id: 100, isClosed: true }, { id: 101, isClosed: false }] };
    this.latePolicyApplicator = sandbox.stub(LatePolicyApplicator, 'processSubmission').returns(true);

    this.submission1 = {
      user_id: 10,
      assignment_id: 'assignment_1',
      grading_period_id: null
    };

    this.submission2 = {
      user_id: 10,
      assignment_id: 'assignment_2',
      grading_period_id: 100
    };

    this.submission3 = {
      user_id: 11,
      assignment_id: 'assignment_2',
      grading_period_id: 101
    };

    this.submission4 = {
      user_id: 12,
      assignment_id: 'assignment_1',
      grading_period_id: null
    };

    this.gradebook.assignments = { assignment_1: 'assignment1value', assignment_2: 'assignment2value' };
    this.gradebook.students = {
      10: {
        assignment_1: this.submission1,
        assignment_2: this.submission2
      },
      11: {
        assignment_2: this.submission3
      },
      12: {
        assignment_1: this.submission4,
        isConcluded: true
      }
    }
    this.gradebook.courseContent.latePolicy = 'latepolicy';
  }
});

test('does not affect submissions in closed grading periods', function () {
  this.gradebook.applyLatePolicy();
  notOk(this.latePolicyApplicator.calledWith(this.submission2, 'assignment2value', this.gradingStandard, 'latepolicy'));
});

test('does not grade submissions for concluded students', function () {
  sinon.stub(this.gradebook, 'calculateStudentGrade');
  this.gradebook.applyLatePolicy();
  const gradesCalculated = this.gradebook.calculateStudentGrade.calledWith(this.gradebook.students[12]);
  strictEqual(gradesCalculated, false);
  this.gradebook.calculateStudentGrade.restore();
});

test('affects submissions that are not in a grading period', function () {
  this.gradebook.applyLatePolicy();
  ok(this.latePolicyApplicator.calledWith(this.submission1, 'assignment1value', this.gradingStandard, 'latepolicy'));
});

test('affects submissions that are in not-closed grading periods', function () {
  this.gradebook.applyLatePolicy();
  ok(this.latePolicyApplicator.calledWith(this.submission3, 'assignment2value', this.gradingStandard, 'latepolicy'));
});

QUnit.module('Gradebook', () => {
  let gradebook

  QUnit.module('#isGradeEditable()', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.students = {1101: {id: '1101', isConcluded: false}}
      sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({hideGrade: false, locked: false})
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
      sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').returns({hideGrade: false, locked: true})
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
      deepEqual(
        gradebook.getPendingGradeInfo(submission),
        {...pendingGradeInfo, assignmentId: '2301', userId: '1101'}
      )
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
      deepEqual(
        gradebook.getPendingGradeInfo({assignmentId: '2301', userId: '1102'}),
        {...pendingGradeInfo, assignmentId: '2301', userId: '1102'}
      )
    })

    test('does not affect other submissions for the same user', () => {
      gradebook.addPendingGradeInfo({assignmentId: '2302', userId: '1101'}, pendingGradeInfo)
      gradebook.removePendingGradeInfo(submission)
      deepEqual(
        gradebook.getPendingGradeInfo({assignmentId: '2302', userId: '1101'}),
        {...pendingGradeInfo, assignmentId: '2302', userId: '1101'}
      )
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
      const defaultGradingScheme = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['E', 0.50]]
      gradebook = createGradebook({default_grading_standard: defaultGradingScheme})
      gradebook.setAssignments({
        2301: {
          grading_type: 'letter_grade',
          id: '2301',
          name: 'Math Assignment',
          points_possible: 10,
          published: true
        },
        2302: {
          grading_type: 'letter_grade',
          id: '2302',
          name: 'English Assignment',
          points_possible: 5,
          published: false
        }
      })
      submission = {
        assignmentId: '2301',
        enteredScore: 9,
        enteredGrade: 'B',
        excused: false,
        id: '2501',
        userId: '1101'
      }
      gradeInfo = {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      response = {
        data: {score: 10}
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
      gradeInfo = {enteredAs: 'gradingScheme', excused: false, grade: 'complete', score: 10, valid: true}
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
          valid: false
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

      test('re-renders the submission tray if it is open', function () {
        sinon.stub(gradebook, 'getSubmissionTrayState').callsFake(() => ({ open: true }))

        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 1)

        gradebook.getSubmissionTrayState.restore()
      })

      test('does not attempt to re-render the submission tray if it is not open', function () {
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
          valid: false
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
        deepEqual(
          gradebook.getPendingGradeInfo({assignmentId: '2301', userId: '1101'}),
          {...gradeInfo, assignmentId: '2301', userId: '1101'}
        )
      })

      test('does not update the grade via the api', () => {
        strictEqual(gradebook.apiUpdateSubmission.callCount, 0)
      })

      test('shows a flash alert', function () {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "error" type for the flash alert', function () {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })

      test('mentions the invalid grade in the flash alert', function () {
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

      test('re-renders the submission tray if it is open', function () {
        sinon.stub(gradebook, 'getSubmissionTrayState').callsFake(() => ({ open: true }))
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 1)
        gradebook.getSubmissionTrayState.restore()
      })

      test('does not attempt to re-render the submission tray if it is not open', function () {
        gradebook.gradeSubmission(submission, gradeInfo)
        strictEqual(gradebook.renderSubmissionTray.callCount, 0)
      })
    })
  })
})

QUnit.module('Gradebook#updateSubmissionAndRenderSubmissionTray', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.gradebookGrid.gridSupport = {
      helper: {
        commitCurrentEdit () {}
      }
    }
    this.gradebook.students = {1101: {id: '1101'}}
    this.promise = {
      then (thenFn) {
        this.thenFn = thenFn;
        return this;
      },

      catch (catchFn) {
        this.catchFn = catchFn;
        return this;
      }
    };
    this.submission = { assignmentId: '2301', latePolicyStatus: 'none', userId: '1101' }
    this.gradebook.updateSubmission({
      assignment_id: '2301',
      entered_grade: 'A',
      entered_score: 9.5,
      excused: false,
      grade: 'B',
      score: 8.5,
      user_id: '1101'
    })

    sandbox.stub(GradebookApi, 'updateSubmission').returns(this.promise);
    this.gradebook.setSubmissionTrayState(true, '1101', '2301');
  }
});

test('stores the pending grade info before sending the request', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  strictEqual(this.gradebook.submissionIsUpdating(this.submission), true);
});

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
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 1);
});

test('on success the pending grade info is removed', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  sandbox.stub(this.gradebook, 'updateSubmissionsFromExternal');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  this.promise.thenFn({ data: { all_submissions: [{ id: '293', ...this.submission }] } });
  strictEqual(this.gradebook.getPendingGradeInfo(this.submission), null)
});

test('on success the tray has been rendered a second time', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  sandbox.stub(this.gradebook, 'updateSubmissionsFromExternal');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  this.promise.thenFn({ data: { all_submissions: [{ id: '293', ...this.submission }] } });
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 2);
});

test('on failure the pending grade info is removed', function () {
  // without a retry strategy, clearing the request data is the only way to
  // revert to a stable state
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual(this.gradebook.getPendingGradeInfo(this.submission), null)
  });
});

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
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual(this.gradebook.renderSubmissionTray.callCount, 2);
  });
});

test('on failure a flash error is triggered', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  sandbox.stub($, 'flashError');
  this.gradebook.updateSubmissionAndRenderSubmissionTray({submission: this.submission})
  return this.promise.catchFn(new Error('A failure')).catch(() => {
    strictEqual($.flashError.callCount, 1);
  });
});

QUnit.module('#getSubmissionComments', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('is empty', function () {
  deepEqual(this.gradebook.getSubmissionComments(), []);
});

test('gets comments', function () {
  const comments = ['a comment'];
  this.gradebook.setSubmissionComments(comments);
  deepEqual(this.gradebook.getSubmissionComments(), comments);
});

QUnit.module('#setSubmissionComments', {
  setup () {
    this.gradebook = createGradebook();
  }
});

test('sets comments on gridDisplaySettings.submissionTray', function () {
  const comments = ['a comment'];
  this.gradebook.setSubmissionComments(comments);
  deepEqual(this.gradebook.gridDisplaySettings.submissionTray.comments, comments);
});

QUnit.module('#updateSubmissionComments', {
  setup () {
    this.gradebook = createGradebook();
  },
});

test('calls renderSubmissionTray', function () {
  const renderSubmissionTrayStub = sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.updateSubmissionComments([]);
  strictEqual(renderSubmissionTrayStub.callCount, 1);
});

test('sets the edited comment ID to null', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.setEditedCommentId('5');
  this.gradebook.updateSubmissionComments([]);
  strictEqual(this.gradebook.getSubmissionTrayState().editedCommentId, null);
});

test('calls setSubmissionComments', function () {
  const setSubmissionCommentsStub = sandbox.stub(this.gradebook, 'setSubmissionComments');
  this.gradebook.unloadSubmissionComments();
  strictEqual(setSubmissionCommentsStub.callCount, 1);
});

test('calls setSubmissionComments', function () {
  const setSubmissionCommentsStub = sandbox.stub(this.gradebook, 'setSubmissionComments');
  this.gradebook.unloadSubmissionComments();
  strictEqual(setSubmissionCommentsStub.callCount, 1);
});

test('calls setSubmissionComments with an empty collection of comments', function () {
  const setSubmissionCommentsStub = sandbox.stub(this.gradebook, 'setSubmissionComments');
  this.gradebook.unloadSubmissionComments();
  deepEqual(setSubmissionCommentsStub.firstCall.args[0], []);
});

test('calls setSubmissionCommentsLoaded', function () {
  const setSubmissionCommentsLoadedStub = sandbox.stub(this.gradebook, 'setSubmissionCommentsLoaded');
  this.gradebook.unloadSubmissionComments();
  strictEqual(setSubmissionCommentsLoadedStub.callCount, 1);
});

test('calls setSubmissionCommentsLoaded with an empty collection of comments', function () {
  const setSubmissionCommentsLoadedStub = sandbox.stub(this.gradebook, 'setSubmissionCommentsLoaded');
  this.gradebook.unloadSubmissionComments();
  strictEqual(setSubmissionCommentsLoadedStub.firstCall.args[0], false);
});

QUnit.module('#apiCreateSubmissionComment', {
  setup () {
    moxios.install();
    this.gradebook = createGradebook();
  },
  teardown () {
    moxios.uninstall();
  }
});

test('calls the success function on a successful call', function () {
  const url = '/api/v1/courses/1/assignments/2/submissions/3';
  moxios.stubRequest(url, { status: 200, response: { submission_comments: [] }});

  this.gradebook.setSubmissionTrayState(false, '3', '2');
  const updateSubmissionCommentsStub = sandbox.stub(this.gradebook, 'updateSubmissionComments');
  const promise = this.gradebook.apiCreateSubmissionComment('a comment');
  return promise.then(function () {
    strictEqual(updateSubmissionCommentsStub.callCount, 1);
  })
});

test('calls showFlashSuccess on a successful call', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray');
  const url = '/api/v1/courses/1/assignments/2/submissions/3';
  moxios.stubRequest(url, { status: 200, response: { submission_comments: [] }});

  this.gradebook.setSubmissionTrayState(false, '3', '2');
  const showFlashSuccessStub = sandbox.stub(FlashAlert, 'showFlashSuccess');
  const promise = this.gradebook.apiCreateSubmissionComment('a comment');
  return promise.then(function () {
    strictEqual(showFlashSuccessStub.callCount, 1);
  });
});

test('calls the success function on an unsuccessful call', function () {
  const url = '/api/v1/courses/1/assignments/2/submissions/3';
  moxios.stubRequest(url, { status: 401, response: [] });

  this.gradebook.setSubmissionTrayState(false, '3', '2');
  const setCommentsUpdatingStub = sandbox.stub(this.gradebook, 'setCommentsUpdating');
  const promise = this.gradebook.apiCreateSubmissionComment('a comment');
  return promise.then(function () {
    strictEqual(setCommentsUpdatingStub.callCount, 1);
  });
});

test('calls showFlashError on an unsuccessful call', function () {
  const url = '/api/v1/courses/1/assignments/2/submissions/3';
  moxios.stubRequest(url, { status: 401, response: [] });

  this.gradebook.setSubmissionTrayState(false, '3', '2');
  const showFlashErrorStub = sandbox.stub(FlashAlert, 'showFlashError');
  const promise = this.gradebook.apiCreateSubmissionComment('a comment');
  return promise.then(function () {
    strictEqual(showFlashErrorStub.callCount, 1);
  });
});

QUnit.module('#apiUpdateSubmissionComment', function (hooks) {
  let gradebook;
  const sandbox = sinon.sandbox.create();
  const editedTimestamp = '2015-10-08T22:09:27Z';

  hooks.beforeEach(function () {
    moxios.install();
    gradebook = createGradebook();
    gradebook.setSubmissionComments([
      { id: '23', createdAt: '2015-10-04T22:09:27Z', editedAt: null, comment: 'a comment' },
      { id: '25', createdAt: '2015-10-05T22:09:27Z', editedAt: null, comment: 'another comment' }
    ]);
  });

  hooks.afterEach(function () {
    FlashAlert.destroyContainer();
    moxios.uninstall();
    sandbox.restore();
  });

  function stubCommentUpdateSuccess (comment) {
    moxios.stubRequest(
      '/submission_comments/23',
      {
        status: 200,
        response: {
          submission_comment: {
            id: '23',
            created_at: '2015-10-04T22:09:27Z',
            comment,
            edited_at: editedTimestamp
          }
        }
      }
    );
  }

  function stubCommentUpdateFailure (status) {
    moxios.stubRequest(
      '/submission_comments/23',
      { status, response: [] }
    );
  }

  test('updates the comment if the call is successful', function () {
    sandbox.stub(gradebook, 'renderSubmissionTray');
    const updatedComment = 'an updated comment';
    stubCommentUpdateSuccess(updatedComment);

    return gradebook.apiUpdateSubmissionComment(updatedComment, '23').then(() => {
      const comment = gradebook.getSubmissionComments()[0].comment;
      strictEqual(comment, updatedComment);
    })
  });

  test('updates the edited_at if the call is successful', function () {
    sandbox.stub(gradebook, 'renderSubmissionTray');
    const updatedComment = 'an updated comment';
    stubCommentUpdateSuccess(updatedComment);

    return gradebook.apiUpdateSubmissionComment(updatedComment, '23').then(() => {
      const editedAt = gradebook.getSubmissionComments()[0].editedAt;
      strictEqual(editedAt.getTime(), new Date(editedTimestamp).getTime());
    });
  });

  test('flashes a success message if the call is successful', function () {
    sandbox.stub(gradebook, 'renderSubmissionTray');
    sandbox.stub(FlashAlert, 'showFlashSuccess').returns(function () {});
    const updatedComment = 'an updated comment';
    stubCommentUpdateSuccess(updatedComment);

    return gradebook.apiUpdateSubmissionComment(updatedComment, '23').then(() => {
      strictEqual(FlashAlert.showFlashSuccess.callCount, 1);
    });
  });

  test('leaves other comments unchanged if the call is successful', function () {
    sandbox.stub(gradebook, 'renderSubmissionTray');
    const updatedComment = 'an updated comment';
    stubCommentUpdateSuccess(updatedComment);
    const originalComment = gradebook.getSubmissionComments()[1];

    return gradebook.apiUpdateSubmissionComment('an updated comment', '23').then(() => {
      const comment = gradebook.getSubmissionComments()[1];
      strictEqual(comment, originalComment);
    })
  });

  test('does not update the comment state if the call is unsuccessful', function () {
    sandbox.stub(gradebook, 'renderSubmissionTray');
    stubCommentUpdateFailure(401);
    const originalComment = gradebook.getSubmissionComments()[0].comment;

    return gradebook.apiUpdateSubmissionComment('an updated comment', '23').then(() => {
      const comment = gradebook.getSubmissionComments()[0].comment;
      strictEqual(comment, originalComment);
    })
  });

  test('flashes an error message if the call is unsuccessful', function () {
    sandbox.stub(gradebook, 'renderSubmissionTray');
    sandbox.stub(FlashAlert, 'showFlashError').returns(function () {});
    stubCommentUpdateFailure(401);

    return gradebook.apiUpdateSubmissionComment('an updated comment', '23').then(() => {
      strictEqual(FlashAlert.showFlashError.callCount, 1);
    });
  });
});

QUnit.module('#apiDeleteSubmissionComment', {
  setup () {
    moxios.install();
    this.gradebook = createGradebook();
  },
  teardown () {
    FlashAlert.destroyContainer();
    moxios.uninstall();
  }
});

test('calls the success function on a successful call', function () {
  const url = '/submission_comments/42';

  moxios.stubRequest(url, { status: 200, response: [] });

  const removeSubmissionCommentStub = sandbox.stub(this.gradebook, 'removeSubmissionComment');
  const promise = this.gradebook.apiDeleteSubmissionComment('42');
  return promise.then(function () {
    strictEqual(removeSubmissionCommentStub.callCount, 1);
  });
});

test('calls showFlashSuccess on a successful call', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray');
  const url = '/submission_comments/42';
  moxios.stubRequest(url, { status: 200, response: [] });

  const showFlashSuccessStub = sandbox.stub(FlashAlert, 'showFlashSuccess');
  const promise = this.gradebook.apiDeleteSubmissionComment('42');
  return promise.then(function () {
    strictEqual(showFlashSuccessStub.callCount, 1);
  });
});

test('calls the success function on an unsuccessful call', function () {
  sinon.stub(this.gradebook, 'renderSubmissionTray');
  const url = '/submission_comments/42';
  moxios.stubRequest(url, { status: 401, response: [] });

  const showFlashErrorStub = sandbox.stub(FlashAlert, 'showFlashError').returns(() => {})
  const promise = this.gradebook.apiDeleteSubmissionComment('42');
  return promise.then(function() {
    strictEqual(showFlashErrorStub.callCount, 1);
  });
});

test('calls removeSubmissionComment on success', function () {
  const url = '/submission_comments/42';

  moxios.stubRequest(url, { status: 200, response: [] });

  const successStub = sinon.stub();
  const removeSubmissionCommentStub = sandbox.stub(this.gradebook, 'removeSubmissionComment');
  const promise = this.gradebook.apiDeleteSubmissionComment('42', successStub, () => {});
  return promise.then(function() {
    strictEqual(removeSubmissionCommentStub.callCount, 1);
  });
});

QUnit.module('#removeSubmissionComment', {
  setup () {
    this.gradebook = createGradebook();
  },
  comments () {
    return [{
      id: '42',
      author: {
        display_name: 'foo',
        avatar_image_url: '//avatar_image_url/',
        html_url: '//html_url/'
      },
      created_at: new Date('2017-09-15'),
      comment: 'a comment'
    }];
  },

});

test('removes matching comment id', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.setSubmissionComments(this.comments());
  this.gradebook.removeSubmissionComment('42');
  deepEqual(this.gradebook.getSubmissionComments(), []);
});

test('removes none if no matching comment id', function () {
  sandbox.stub(this.gradebook, 'renderSubmissionTray');
  this.gradebook.setSubmissionComments([{ id: '84' }]);
  this.gradebook.removeSubmissionComment('42');
  deepEqual(this.gradebook.getSubmissionComments(), [{ id: '84' }]);
});

QUnit.module('#editSubmissionComment', function (hooks) {
  let gradebook;

  hooks.beforeEach(function () {
    gradebook = createGradebook();
    sinon.stub(gradebook, 'renderSubmissionTray');
  });

  hooks.afterEach(function () {
    gradebook.renderSubmissionTray.restore();
  });

  test('stores the id of the comment being edited', function () {
    gradebook.editSubmissionComment('23');
    strictEqual(gradebook.gridDisplaySettings.submissionTray.editedCommentId, '23');
  });

  test('renders the submission tray', function () {
    gradebook.editSubmissionComment('23');
    ok(gradebook.renderSubmissionTray.calledOnce);
  });
});

QUnit.module('#setEditedCommentId', function () {
  test('sets the editedCommentId', function () {
    const gradebook = createGradebook();
    gradebook.setEditedCommentId('23');
    strictEqual(gradebook.gridDisplaySettings.submissionTray.editedCommentId, '23');
  });
});

QUnit.module('#renderGradebookSettingsModal', (hooks) => {
  let gradebook;

  function gradebookSettingsModalProps () {
    return ReactDOM.render.firstCall.args[0].props;
  }

  hooks.beforeEach(() => {
    sinon.stub(ReactDOM, 'render');
  });

  hooks.afterEach(() => {
    ReactDOM.render.restore();
  });

  test('renders the GradebookSettingsModal component', function () {
    gradebook = createGradebook();
    gradebook.renderGradebookSettingsModal();
    const componentName = ReactDOM.render.firstCall.args[0].type.name;
    strictEqual(componentName, 'GradebookSettingsModal');
  });

  test('passes graded_late_submissions_exist option to the modal as a prop', function () {
    gradebook = createGradebook({ graded_late_submissions_exist: true });
    gradebook.renderGradebookSettingsModal();
    strictEqual(gradebookSettingsModalProps().gradedLateSubmissionsExist, true);
  });

  test('passes the context_id option to the modal as a prop', function () {
    gradebook = createGradebook({ context_id: '8473' });
    gradebook.renderGradebookSettingsModal();
    strictEqual(gradebookSettingsModalProps().courseId, '8473');
  });

  test('passes the locale option to the modal as a prop', function () {
    gradebook = createGradebook({ locale: 'de' });
    gradebook.renderGradebookSettingsModal();
    strictEqual(gradebookSettingsModalProps().locale, 'de');
  });
});

QUnit.module('Gradebook#renderAnonymousSpeedGraderAlert', (hooks) => {
  let gradebook;
  const onClose = () => {}
  const alertProps = {
    speedGraderUrl: 'http://test.url:3000',
    onClose
  };

  function anonymousSpeedGraderAlertProps () {
    return ReactDOM.render.firstCall.args[0].props;
  }

  hooks.beforeEach(() => {
    sinon.stub(ReactDOM, 'render');
  });

  hooks.afterEach(() => {
    ReactDOM.render.restore();
  });

  test('renders the AnonymousSpeedGraderAlert component', function () {
    gradebook = createGradebook();
    gradebook.renderAnonymousSpeedGraderAlert(alertProps);
    const componentName = ReactDOM.render.firstCall.args[0].type.name;
    strictEqual(componentName, 'AnonymousSpeedGraderAlert');
  });

  test('passes speedGraderUrl to the modal as a prop', function () {
    gradebook = createGradebook();
    gradebook.renderAnonymousSpeedGraderAlert(alertProps);
    strictEqual(anonymousSpeedGraderAlertProps().speedGraderUrl, 'http://test.url:3000');
  });

  test('passes onClose to the modal as a prop', function () {
    gradebook = createGradebook();

    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    strictEqual(anonymousSpeedGraderAlertProps().onClose, onClose);
  });
});

QUnit.module('Gradebook#showAnonymousSpeedGraderAlertForURL', (hooks) => {
  let gradebook;

  function anonymousSpeedGraderAlertProps () {
    return gradebook.renderAnonymousSpeedGraderAlert.firstCall.args[0];
  }

  hooks.beforeEach(() => {
    $fixtures.innerHTML = `
      <div id="application">
        <div id="wrapper">
          <div data-component='AnonymousSpeedGraderAlert'></div>
        </div>
      </div>
    `;
  });

  hooks.afterEach(() => {
    $fixtures.innerHTML = '';
  });

  test('renders the alert with the supplied speedGraderURL', function () {
    gradebook = createGradebook();
    sinon.stub(AnonymousSpeedGraderAlert.prototype, 'open');
    sinon.spy(gradebook, 'renderAnonymousSpeedGraderAlert');
    gradebook.showAnonymousSpeedGraderAlertForURL('http://test.url:3000');

    strictEqual(anonymousSpeedGraderAlertProps().speedGraderUrl, 'http://test.url:3000');
    gradebook.renderAnonymousSpeedGraderAlert.restore();
    AnonymousSpeedGraderAlert.prototype.open.restore();
  });
});

QUnit.module('Gradebook#hideAnonymousSpeedGraderAlert', (hooks) => {
  let gradebook;

  hooks.beforeEach(() => {
    $fixtures.innerHTML = `
      <div id="application">
        <div id="wrapper">
          <div data-component='AnonymousSpeedGraderAlert'></div>
        </div>
      </div>
    `;

    sinon.stub(ReactDOM, 'unmountComponentAtNode');
  });

  hooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode.restore();

    $fixtures.innerHTML = '';
  });

  test('unmounts the component at the alert mount point', function () {
    const clock = sinon.useFakeTimers();
    gradebook = createGradebook();
    gradebook.hideAnonymousSpeedGraderAlert();

    // allow the component to unmount (which is handled via a delayed call)
    clock.tick(0);

    const mountPoint = ReactDOM.unmountComponentAtNode.firstCall.args[0];
    strictEqual(mountPoint.dataset.component, 'AnonymousSpeedGraderAlert');
    clock.restore();
  });
});

QUnit.module('Gradebook', () => {
  let gradebook
  let server

  QUnit.module('#setVisibleGridColumns()', hooks => {
    hooks.beforeEach(() => {
      server = sinon.fakeServer.create({respondImmediately: true})
      const options = {gradebook_column_order_settings_url: '/grade_column_order_settings_url'}
      server.respondWith('POST', options.gradebook_column_order_settings_url, [
        200,
        {'Content-Type': 'application/json'},
        '{}'
      ])

      $fixtures.innerHTML = `
        <div id="application">
          <div id="wrapper">
            <div id="StudentTray__Container"></div>
            <span data-component="GridColor"></span>
            <div id="gradebook_grid"></div>
          </div>
        </div>
      `
    })

    hooks.afterEach(() => {
      $fixtures.innerHTML = ''
      server.restore()
    })

    function createAndInitGradebook(options) {
      gradebook = createGradebook(options)
      gradebook.gotAllAssignmentGroups([
        {
          assignments: [
            {
              assignment_group_id: '2201',
              id: '2301',
              name: 'Math Assignment',
              points_possible: 10,
              published: true
            },
            {
              assignment_group_id: '2201',
              id: '2302',
              name: 'English Assignment',
              points_possible: 10,
              published: false
            }
          ],
          group_weight: 40,
          id: '2201',
          name: 'Assignments'
        }
      ])

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
        },
        {
          id: '1199',
          name: 'Test Student',
          enrollments: [{type: 'StudentViewEnrollment', grades: {html_url: 'http://example.url/'}}]
        }
      ]
      gradebook.courseContent.students.setStudentIds(['1101', '1102', '1199'])
      gradebook.buildRows()
      gradebook.gotChunkOfStudents(students)
      gradebook.initGrid()
    }

    function countColumn(columnSection, columnId) {
      return columnSection.filter(id => id === columnId).length
    }

    QUnit.module('when the "Total Grade" column will be frozen', contextHooks => {
      contextHooks.beforeEach(() => {
        createAndInitGradebook()
      })

      test('adds total_grade to frozen columns when not yet included', () => {
        gradebook.gradebookColumnOrderSettings.freezeTotalGrade = true
        strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade'), 0)

        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade'), 1)
      })

      test('does not add total_grade to scrollable columns', () => {
        gradebook.gradebookColumnOrderSettings.freezeTotalGrade = true
        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.scrollable, 'total_grade'), 0)
      })

      test('does not add total_grade to frozen columns when already included', () => {
        gradebook.freezeTotalGradeColumn()
        strictEqual(
          countColumn(gradebook.gridData.columns.frozen, 'total_grade'),
          1,
          'column is frozen before setting visible grid columns'
        )

        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade'), 1)
      })
    })

    QUnit.module('when the "Total Grade Override" column is used', contextHooks => {
      contextHooks.beforeEach(() => {
        createAndInitGradebook({final_grade_override_enabled: true})
        gradebook.setShowFinalGradeOverrides(true)
      })

      test('adds total_grade_override to scrollable columns', () => {
        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.scrollable, 'total_grade_override'), 1)
      })

      test('does not add total_grade_override to frozen columns', () => {
        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade_override'), 0)
      })
    })

    QUnit.module('when the "Total Grade Override" column is not used', contextHooks => {
      contextHooks.beforeEach(() => {
        createAndInitGradebook({final_grade_override_enabled: true})
        gradebook.setShowFinalGradeOverrides(false)
      })

      test('does not add total_grade_override to scrollable columns', () => {
        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.scrollable, 'total_grade_override'), 0)
      })

      test('does not add total_grade_override to frozen columns', () => {
        gradebook.setVisibleGridColumns()
        strictEqual(countColumn(gradebook.gridData.columns.frozen, 'total_grade_override'), 0)
      })
    })
  })
})

QUnit.module('Gradebook#gotGradingPeriodAssignments', () => {
  test('sets the grading period assignments', function () {
    const gradebook = createGradebook()
    const gradingPeriodAssignments = { 1: [12, 7, 4], 8: [6, 2, 9] }
    const fakeResponse = { grading_period_assignments: gradingPeriodAssignments }
    gradebook.gotGradingPeriodAssignments(fakeResponse)
    strictEqual(gradebook.courseContent.gradingPeriodAssignments, gradingPeriodAssignments)
  })
})

QUnit.module('Gradebook#updateStudentHeadersAndReloadData', (hooks) => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
    const reloadStudentDataResponse = { updateGradingPeriodAssignments: { then: (fn) => fn() } }
    sinon.stub(gradebook, 'reloadStudentData').returns(reloadStudentDataResponse)
  })

  test('makes a call to update column headers', () => {
    const updateColumnHeaders = sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders')
    gradebook.updateStudentHeadersAndReloadData()
    strictEqual(updateColumnHeaders.callCount, 1)
  })

  test('updates the student column header', () => {
    const updateColumnHeaders = sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders')
    gradebook.updateStudentHeadersAndReloadData()
    const [columnHeadersToUpdate] = updateColumnHeaders.lastCall.args
    deepEqual(columnHeadersToUpdate, ['student'])
  })

  test('reloads student data', () => {
    gradebook.updateStudentHeadersAndReloadData()
    strictEqual(gradebook.reloadStudentData.callCount, 1)
  })

  test('reloads the student data after the column headers have been updated', () => {
    const updateColumnHeaders = sinon.stub(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders')
    gradebook.updateStudentHeadersAndReloadData()
    sinon.assert.callOrder(updateColumnHeaders, gradebook.reloadStudentData)
  })
})

QUnit.module('Gradebook#gotAllAssignmentGroups', (hooks) => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook()
  })

  test('sets the "assignment groups loaded" state', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.gotAllAssignmentGroups([])
    strictEqual(gradebook.setAssignmentGroupsLoaded.callCount, 1)
  })

  test('sets the "assignment groups loaded" state to true', () => {
    sinon.stub(gradebook, 'setAssignmentGroupsLoaded')
    gradebook.gotAllAssignmentGroups([])
    strictEqual(gradebook.setAssignmentGroupsLoaded.getCall(0).args[0], true)
  })
})

QUnit.module('Gradebook#setAssignmentGroupsLoaded', (hooks) => {
  let server
  let options
  let gradebook

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({ respondImmediately: true })
    options = { settings_update_url: '/course/1/gradebook_settings' }
    server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ])
    gradebook = createGradebook(options);
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('sets contentLoadStates.assignmentGroupsLoaded to true when passed true', () => {
    gradebook.setAssignmentGroupsLoaded(true)
    strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, true)
  })

  test('sets contentLoadStates.assignmentGroupsLoaded to false when passed false', () => {
    gradebook.setAssignmentGroupsLoaded(false)
    strictEqual(gradebook.contentLoadStates.assignmentGroupsLoaded, false)
  })
})

QUnit.module('Gradebook#handleAssignmentMutingChange', (hooks) => {
  let columnId
  let server
  let options
  let gradebook
  const sortByStudentNameSettings = { columnId: 'student', settingKey: 'sortable_name', direction: 'ascending' }

  hooks.beforeEach(() => {
    server = sinon.fakeServer.create({ respondImmediately: true })
    options = { settings_update_url: '/course/1/gradebook_settings' }
    server.respondWith('POST', options.settings_update_url, [
      200, { 'Content-Type': 'application/json' }, '{}'
    ])
    gradebook = createGradebook(options);
    columnId = gradebook.getAssignmentColumnId('2301')
  })

  hooks.afterEach(() => {
    server.restore()
  })

  test('resets grading', () => {
    sinon.stub(gradebook, 'resetGrading')
    gradebook.handleAssignmentMutingChange({ id: '2301' })
    strictEqual(gradebook.resetGrading.callCount, 1)
    gradebook.resetGrading.restore()
  })

  test('when sorted by an anonymous assignment, gradebook changes sort', () => {
    gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending')
    gradebook.handleAssignmentMutingChange({ id: '2301', anonymize_students: true })
    deepEqual(gradebook.getSortRowsBySetting(), sortByStudentNameSettings)
  })

  test('when sorted by assignment group of an anonymous assignment, gradebook changes sort', () => {
    const groupId = '7'
    gradebook.setSortRowsBySetting(gradebook.getAssignmentGroupColumnId(groupId), 'grade', 'ascending')
    gradebook.handleAssignmentMutingChange({ id: '2301', anonymize_students: true, assignment_group_id: groupId })
    deepEqual(gradebook.getSortRowsBySetting(), sortByStudentNameSettings)
  })

  test('when sorted by total grade, gradebook changes sort', () => {
    gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending')
    gradebook.handleAssignmentMutingChange({ id: '2301', anonymize_students: true })
    deepEqual(gradebook.getSortRowsBySetting(), sortByStudentNameSettings)
  })

  test('when assignment is not anonymous, gradebook does not change sort', () => {
    gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending')
    const sortSettings = gradebook.getSortRowsBySetting()
    gradebook.handleAssignmentMutingChange({ id: '2301', anonymize_students: false })
    deepEqual(gradebook.getSortRowsBySetting(), sortSettings)
  })

  test('when gradebook is sorted by an unrelated column, gradebook does not change sort', () => {
    gradebook.setSortRowsBySetting(gradebook.getAssignmentColumnId('2222'), 'grade', 'ascending')
    const sortSettings = gradebook.getSortRowsBySetting()
    gradebook.handleAssignmentMutingChange({ id: '2301', anonymize_students: true })
    deepEqual(gradebook.getSortRowsBySetting(), sortSettings)
  })
})
