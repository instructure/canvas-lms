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
import natcompare from 'compiled/util/natcompare';
import round from 'compiled/util/round';
import fakeENV from 'helpers/fakeENV';
import { createCourseGradesWithGradingPeriods as createGrades } from 'spec/jsx/gradebook/GradeCalculatorSpecHelper';
import { createGradebook } from 'spec/jsx/gradezilla/default_gradebook/GradebookSpecHelper';

import SubmissionDetailsDialog from 'compiled/SubmissionDetailsDialog';
import CourseGradeCalculator from 'jsx/gradebook/CourseGradeCalculator';
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';
import DataLoader from 'jsx/gradezilla/DataLoader';
import StudentRowHeaderConstants from 'jsx/gradezilla/default_gradebook/constants/StudentRowHeaderConstants';
import Gradebook from 'compiled/gradezilla/Gradebook';
import UserSettings from 'compiled/userSettings';
import ActionMenu from 'jsx/gradezilla/default_gradebook/components/ActionMenu';
import GradebookApi from 'jsx/gradezilla/default_gradebook/GradebookApi';

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

QUnit.module('Gradebook#calculateStudentGrade', {
  setupThis (options = {}) {
    const assignments = [
      { id: '201', points_possible: 10, omit_from_final_grade: false }
    ];
    const submissions = [
      { assignment_id: 201, score: 10 }
    ];
    return {
      gradingPeriodToShow: '0',
      isAllGradingPeriods: Gradebook.prototype.isAllGradingPeriods,
      assignmentGroups: [
        { id: '301', group_weight: 60, rules: {}, assignments }
      ],
      options: {
        group_weighting_scheme: 'points'
      },
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
      submissionsForStudent () {
        return submissions;
      },
      addDroppedClass () {},
      ...options
    };
  },

  setup () {
    this.calculate = Gradebook.prototype.calculateStudentGrade;
  }
});

test('calculates grades using properties from the gradebook', function () {
  const self = this.setupThis();
  this.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  this.calculate.call(self, {
    id: '101',
    loaded: true,
    initialized: true
  });
  const args = CourseGradeCalculator.calculate.getCall(0).args;
  equal(args[0], self.submissionsForStudent());
  equal(args[1], self.assignmentGroups);
  equal(args[2], self.options.group_weighting_scheme);
  equal(args[3], self.gradingPeriodSet);
});

test('scopes effective due dates to the user', function () {
  const self = this.setupThis();
  this.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  this.calculate.call(self, {
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
  const self = this.setupThis({
    gradingPeriodSet: null
  });
  this.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  this.calculate.call(self, {
    id: '101',
    loaded: true,
    initialized: true
  });
  const args = CourseGradeCalculator.calculate.getCall(0).args;
  equal(args[0], self.submissionsForStudent());
  equal(args[1], self.assignmentGroups);
  equal(args[2], self.options.group_weighting_scheme);
  equal(typeof args[3], 'undefined');
  equal(typeof args[4], 'undefined');
});

test('calculates grades without grading period data when effective due dates are not defined', function () {
  const self = this.setupThis({
    effectiveDueDates: null
  });
  this.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  this.calculate.call(self, {
    id: '101',
    loaded: true,
    initialized: true
  });
  const args = CourseGradeCalculator.calculate.getCall(0).args;
  equal(args[0], self.submissionsForStudent());
  equal(args[1], self.assignmentGroups);
  equal(args[2], self.options.group_weighting_scheme);
  equal(typeof args[3], 'undefined');
  equal(typeof args[4], 'undefined');
});

test('stores the current grade on the student when not including ungraded assignments', function () {
  const exampleGrades = createGrades();
  const self = this.setupThis({
    include_ungraded_assignments: false
  });
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  this.calculate.call(self, student);
  equal(student.total_grade, exampleGrades.current);
});

test('stores the final grade on the student when including ungraded assignments', function () {
  const exampleGrades = createGrades();
  const self = this.setupThis({
    include_ungraded_assignments: true
  });
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  this.calculate.call(self, student);
  equal(student.total_grade, exampleGrades.final);
});

test('stores the current grade from the selected grading period when not including ungraded assignments', function () {
  const exampleGrades = createGrades();
  const self = this.setupThis({
    gradingPeriodToShow: 701,
    include_ungraded_assignments: false
  });
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  this.calculate.call(self, student);
  equal(student.total_grade, exampleGrades.gradingPeriods[701].current);
});

test('stores the final grade from the selected grading period when including ungraded assignments', function () {
  const exampleGrades = createGrades();
  const self = this.setupThis({
    gradingPeriodToShow: 701,
    include_ungraded_assignments: true
  });
  this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades);
  const student = {
    id: '101',
    loaded: true,
    initialized: true
  };
  this.calculate.call(self, student);
  equal(student.total_grade, exampleGrades.gradingPeriods[701].final);
});

test('does not calculate when the student is not loaded', function () {
  const self = this.setupThis();
  this.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  this.calculate.call(self, {
    id: '101',
    loaded: false,
    initialized: true
  });
  notOk(CourseGradeCalculator.calculate.called);
});

test('does not calculate when the student is not initialized', function () {
  const self = this.setupThis();
  this.stub(CourseGradeCalculator, 'calculate').returns(createGrades());
  this.calculate.call(self, {
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
  this.spy(natcompare, 'strings');
  Gradebook.prototype.localeSort('a', 'b');
  equal(natcompare.strings.callCount, 1);
  deepEqual(natcompare.strings.getCall(0).args, ['a', 'b']);
});

test('substitutes falsy args with empty string', function () {
  this.spy(natcompare, 'strings');
  Gradebook.prototype.localeSort(0, false);
  equal(natcompare.strings.callCount, 1);
  deepEqual(natcompare.strings.getCall(0).args, ['', '']);
});

QUnit.module('Gradebook#gradeSort by an assignment', {
  setup () {
    this.studentA = { assignment_201: { score: 10, possible: 20 } };
    this.studentB = { assignment_201: { score: 6, possible: 10 } };
  }
});

test('always sorts by score', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: true });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', true);
  // a positive value indicates reversing the order of inputs
  equal(comparison, 4, 'studentA with the higher score is ordered second');
});

test('optionally sorts in descending order', function () {
  const gradebook = createGradebook({ show_total_grade_as_points: true });
  const comparison = gradebook.gradeSort(this.studentA, this.studentB, 'assignment_201', false);
  // a negative value indicates preserving the order of inputs
  equal(comparison, -4, 'studentA with the higher score is ordered first');
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
  gradebookStubs () {
    return {
      indexedOverrides: Gradebook.prototype.indexedOverrides,
      indexedGradingPeriods: _.indexBy(this.gradingPeriods, 'id')
    };
  },

  setupThis (options = {}) {
    return {
      ...this.gradebookStubs(),
      gradingPeriodSet: { id: '1' },
      getGradingPeriodToShow () {
        return '1';
      },
      options: {
        all_grading_periods_totals: false
      },
      ...options
    };
  },

  setup () {
    this.hideAggregateColumns = Gradebook.prototype.hideAggregateColumns;
  }
});

test('returns false if there are no grading periods', function () {
  const self = this.setupThis({
    gradingPeriodSet: null,
    isAllGradingPeriods () {
      return false;
    }
  });
  notOk(this.hideAggregateColumns.call(self));
});

test('returns false if there are no grading periods, even if isAllGradingPeriods is true', function () {
  const self = this.setupThis({
    gradingPeriodSet: null,
    getGradingPeriodToShow () {
      return '0';
    },
    isAllGradingPeriods () {
      return true;
    }
  });
  notOk(this.hideAggregateColumns.call(self));
});

test('returns false if "All Grading Periods" is not selected', function () {
  const self = this.setupThis({
    isAllGradingPeriods () {
      return false;
    }
  });
  notOk(this.hideAggregateColumns.call(self));
});

test('returns true if "All Grading Periods" is selected', function () {
  const self = this.setupThis({
    getGradingPeriodToShow () {
      return '0';
    },
    isAllGradingPeriods () {
      return true;
    }
  });
  ok(this.hideAggregateColumns.call(self));
});

test('returns false if "All Grading Periods" is selected and the grading period set has' +
  '"Display Totals for All Grading Periods option" enabled', function () {
  const self = this.setupThis({
    getGradingPeriodToShow () {
      return '0';
    },
    isAllGradingPeriods () {
      return true;
    },
    gradingPeriodSet: { displayTotalsForAllGradingPeriods: true }
  });
  notOk(this.hideAggregateColumns.call(self));
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
    this.stub(this.gradebook, 'wrapColumnSortFn');
    this.stub(this.gradebook, 'compareAssignmentPositions');
    this.stub(this.gradebook, 'compareAssignmentDueDates');
    this.stub(this.gradebook, 'compareAssignmentNames');
    this.stub(this.gradebook, 'compareAssignmentPointsPossible');
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

QUnit.module('Gradebook#wrapColumnSortFn');

test('returns -1 if second argument is of type total_grade', function () {
  const sortFn = createGradebook().wrapColumnSortFn(this.stub());
  equal(sortFn({}, { type: 'total_grade' }), -1);
});

test('returns 1 if first argument is of type total_grade', function () {
  const sortFn = createGradebook().wrapColumnSortFn(this.stub());
  equal(sortFn({ type: 'total_grade' }, {}), 1);
});

test('returns -1 if second argument is an assignment_group and the first is not', function () {
  const sortFn = createGradebook().wrapColumnSortFn(this.stub());
  equal(sortFn({}, { type: 'assignment_group' }), -1);
});

test('returns 1 if first arg is an assignment_group and second arg is not', function () {
  const sortFn = createGradebook().wrapColumnSortFn(this.stub());
  equal(sortFn({type: 'assignment_group'}, {}), 1);
});

test('returns difference in object.positions if both args are assignement_groups', function () {
  const sortFn = createGradebook().wrapColumnSortFn(this.stub());
  const a = { type: 'assignment_group', object: { position: 10 }};
  const b = { type: 'assignment_group', object: { position: 5 }};

  equal(sortFn(a, b), 5);
});

test('calls wrapped function when either column is not total_grade nor assignment_group', function () {
  const wrappedFn = this.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn);
  sortFn({}, {});
  ok(wrappedFn.called);
});

test('calls wrapped function with arguments in given order when no direction is given', function () {
  const wrappedFn = this.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn);
  const first = { field: 1 };
  const second = { field: 2 };
  const expectedArgs = [first, second];

  sortFn(first, second);

  strictEqual(wrappedFn.callCount, 1);
  deepEqual(wrappedFn.firstCall.args, expectedArgs);
});

test('calls wrapped function with arguments in given order when direction is ascending', function () {
  const wrappedFn = this.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn, 'ascending');
  const first = { field: 1 };
  const second = { field: 2 };
  const expectedArgs = [first, second];

  sortFn(first, second);

  strictEqual(wrappedFn.callCount, 1);
  deepEqual(wrappedFn.firstCall.args, expectedArgs);
});

test('calls wrapped function with arguments in reverse order when direction is descending', function () {
  const wrappedFn = this.stub();
  const sortFn = createGradebook().wrapColumnSortFn(wrappedFn, 'descending');
  const first = { field: 1 };
  const second = { field: 2 };
  const expectedArgs = [second, first];

  sortFn(first, second);

  strictEqual(wrappedFn.callCount, 1);
  deepEqual(wrappedFn.firstCall.args, expectedArgs);
});

QUnit.module('Gradebook#makeCompareAssignmentCustomOrderFn');

test('returns position difference if both are defined in the index', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  this.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'foo' };
  const b = { id: 'bar' };
  equal(sortFn(a, b), -1);
});

test('returns -1 if the first arg is in the order and the second one is not', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  this.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'foo' };
  const b = { id: 'NO' };
  equal(sortFn(a, b), -1);
});

test('returns 1 if the second arg is in the order and the first one is not', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  this.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'NO' };
  const b = { id: 'bar' };
  equal(sortFn(a, b), 1);
});

test('calls wrapped compareAssignmentPositions otherwise', function () {
  const sortOrder = { customOrder: ['foo', 'bar'] };
  const gradeBook = createGradebook();
  this.stub(gradeBook, 'compareAssignmentPositions');
  const sortFn = gradeBook.makeCompareAssignmentCustomOrderFn(sortOrder);

  const a = { id: 'taco' };
  const b = { id: 'cat' };
  sortFn(a, b);
  ok(gradeBook.compareAssignmentPositions.called);
});

test('falls back to object id for the indexes if field is not in the map', function () {
  const sortOrder = { customOrder: ['5', '11'] };
  const gradeBook = createGradebook();
  this.stub(gradeBook, 'compareAssignmentPositions');
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

test('comparison is case-insensitive', function () {
  const thirdRecord = this.getRecord('Alpha');

  strictEqual(this.gradebook.compareAssignmentNames(thirdRecord, this.firstRecord), 0);
});

QUnit.module('Gradebook#compareAssignmentPointsPossible', {
  getRecord (pointsPossible) {
    return {
      object: {
        points_possible: pointsPossible
      }
    };
  },

  setup () {
    this.compareAssignmentPointsPossible = Gradebook.prototype.compareAssignmentPointsPossible;
    this.firstRecord = this.getRecord(1);
    this.secondRecord = this.getRecord(2);
  }
});

test('returns a negative number if the points_possible field is smaller in the first record', function () {
  strictEqual(this.compareAssignmentPointsPossible(this.firstRecord, this.secondRecord), -1);
});

test('returns 0 if the points_possible field is the same in both records', function () {
  strictEqual(this.compareAssignmentPointsPossible(this.firstRecord, this.firstRecord), 0);
});

test('returns a positive number if the points_possible field is greater in the first record', function () {
  strictEqual(this.compareAssignmentPointsPossible(this.secondRecord, this.firstRecord), 1);
});

QUnit.module('Gradebook#storeCustomColumnOrder');

test('stores the custom column order (ignoring frozen columns)', function () {
  const columns = [
    { id: 'student' },
    { id: 'assignment_232' },
    { id: 'total_grade' },
    { id: 'assignment_group_12' }
  ];
  const gradeBook = createGradebook();
  this.stub(gradeBook, 'setStoredSortOrder');
  gradeBook.grid = { getColumns: this.stub().returns(columns) };
  gradeBook.parentColumns = [{ id: 'student' }];
  gradeBook.customColumns = [];

  const expectedSortOrder = {
    sortType: 'custom',
    customOrder: ['assignment_232', 'total_grade', 'assignment_group_12']
  };

  gradeBook.storeCustomColumnOrder();
  ok(gradeBook.setStoredSortOrder.calledWith(expectedSortOrder));
});

QUnit.module('Gradebook#getStoredSortOrder', {
  setup () {
    this.gradebookColumnOrderSettings = {
      sortType: 'due_date',
      direction: 'descending'
    };
    this.defaultColumnOrderSettings = {
      sortType: 'assignment_group',
      direction: 'ascending'
    };
    this.invalidColumnOrderSettings = {
      sortType: 'custom'
    };

    this.gradebook = createGradebook({
      gradebook_column_order_settings: this.gradebookColumnOrderSettings
    });
  }
});

test('returns the saved column order settings if they are valid', function () {
  deepEqual(this.gradebook.getStoredSortOrder(), this.gradebookColumnOrderSettings);
});

test('returns the default column order settings if the stored settings are invalid', function () {
  this.gradebook.gradebookColumnOrderSettings = this.invalidColumnOrderSettings;

  deepEqual(this.gradebook.getStoredSortOrder(), this.defaultColumnOrderSettings);
});

test('returns the default column order settings if the column order has never been saved', function () {
  this.gradebook.gradebookColumnOrderSettings = undefined

  deepEqual(this.gradebook.getStoredSortOrder(), this.defaultColumnOrderSettings);
});

QUnit.module('Gradebook#isDefaultSortOrder', {
  setup () {
    this.isDefaultSortOrder = Gradebook.prototype.isDefaultSortOrder;
  }
});

test('returns false if called with due_date', function () {
  strictEqual(this.isDefaultSortOrder('due_date'), false);
});

test('returns false if called with name', function () {
  strictEqual(this.isDefaultSortOrder('name'), false);
});

test('returns false if called with points', function () {
  strictEqual(this.isDefaultSortOrder('points'), false);
});

test('returns false if called with points', function () {
  strictEqual(this.isDefaultSortOrder('custom'), false);
});

test('returns true if called with anything else', function () {
  strictEqual(this.isDefaultSortOrder('alpha'), true);
  strictEqual(this.isDefaultSortOrder('assignment_group'), true);
});

QUnit.module('Gradebook#getVisibleGradeGridColumns', {
  setup () {
    this.getVisibleGradeGridColumns = Gradebook.prototype.getVisibleGradeGridColumns;
    this.makeColumnSortFn = Gradebook.prototype.makeColumnSortFn;
    this.compareAssignmentPositions = Gradebook.prototype.compareAssignmentPositions;
    this.compareAssignmentDueDates = Gradebook.prototype.compareAssignmentDueDates;
    this.wrapColumnSortFn = Gradebook.prototype.wrapColumnSortFn;
    this.getStoredSortOrder = Gradebook.prototype.getStoredSortOrder;
    this.defaultSortType = 'assignment_group';
    this.allAssignmentColumns = [
      {
        object: {
          assignment_group: { position: 1 },
          position: 1,
          name: 'published graded',
          published: true,
          submission_types: ['online_text_entry']
        }
      }, {
        object: {
          assignment_group: { position: 1 },
          position: 2,
          name: 'unpublished',
          published: false,
          submission_types: ['online_text_entry']
        }
      }, {
        object: {
          assignment_group: { position: 1 },
          position: 3,
          name: 'not graded',
          published: true,
          submission_types: ['not_graded']
        }
      }, {
        object: {
          assignment_group: { position: 1 },
          position: 4,
          name: 'attendance',
          published: true,
          submission_types: ['attendance']
        }
      }
    ];
    this.aggregateColumns = [];
    this.parentColumns = [];
    this.customColumnDefinitions = function () {
      return [];
    };
  }
});

test('sorts columns when there is a valid sortType', function () {
  this.spy(this, 'makeColumnSortFn');
  this.isInvalidCustomSort = function () {
    return false;
  };
  this.columnOrderHasNotBeenSaved = function () {
    return false;
  };
  this.gradebookColumnOrderSettings = {
    sortType: 'due_date'
  };
  this.getVisibleGradeGridColumns();
  ok(this.makeColumnSortFn.calledWith({
    sortType: 'due_date'
  }));
});

test('falls back to the default sort type if the custom sort type does not have a customOrder property', function () {
  this.spy(this, 'makeColumnSortFn');
  this.isInvalidCustomSort = function () {
    return true;
  };
  this.gradebookColumnOrderSettings = {
    sortType: 'custom'
  };
  this.makeCompareAssignmentCustomOrderFn = Gradebook.prototype.makeCompareAssignmentCustomOrderFn;
  this.getVisibleGradeGridColumns();
  ok(this.makeColumnSortFn.calledWith({
    sortType: 'assignment_group',
    direction: 'ascending'
  }));
});

test('does not sort columns when gradebookColumnOrderSettings is undefined', function () {
  this.spy(this, 'makeColumnSortFn');
  this.gradebookColumnOrderSettings = undefined;
  this.getVisibleGradeGridColumns();
  notOk(this.makeColumnSortFn.called);
});

test('only contains published and graded assignments', function () {
  const columns = this.getVisibleGradeGridColumns();
  const objectNames = columns.map(c => c.object.name);
  deepEqual(objectNames, ['published graded']);
});

test('when showUnpublishedAssignments is true, include published assignments', function () {
  this.showUnpublishedAssignments = true;
  const columns = this.getVisibleGradeGridColumns();
  const objectNames = columns.map(c => c.object.name);
  deepEqual(objectNames, ['published graded', 'unpublished']);
});

test('does not include ungraded assignments', function () {
  this.showUnpublishedAssignments = true;
  const columns = this.getVisibleGradeGridColumns();
  const objectNames = columns.map(c => c.object.name);
  notOk(objectNames.includes('not graded'));
});

test('does not include attendance assignments when show_attendence is false', function () {
  const columns = this.getVisibleGradeGridColumns();
  const objectNames = columns.map(c => c.object.name);
  notOk(objectNames.includes('attendance'));
});

test('includes attendance assignments when show_attendence is true', function () {
  this.show_attendance = true;
  const columns = this.getVisibleGradeGridColumns();
  const objectNames = columns.map(c => c.object.name);
  ok(objectNames.includes('attendance'));
});

QUnit.module('Gradebook#fieldsToExcludeFromAssignments', {
  setup () {
    this.excludedFields = Gradebook.prototype.fieldsToExcludeFromAssignments;
  }
});

test('includes "description" in the response', function () {
  ok(_.contains(this.excludedFields, 'description'));
});

test('includes "needs_grading_count" in the response', function () {
  ok(_.contains(this.excludedFields, 'needs_grading_count'));
});

QUnit.module('Gradebook#submissionsForStudent', {
  setupThis (options = {}) {
    return {
      gradingPeriodSet: null,
      gradingPeriodToShow: null,
      isAllGradingPeriods () {
        return false;
      },
      effectiveDueDates: {
        1: {
          1: { grading_period_id: '1' }
        },
        2: {
          1: { grading_period_id: '2' }
        }
      },
      ...options
    };
  },

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
    this.submissionsForStudent = Gradebook.prototype.submissionsForStudent;
  }
});

test('returns all submissions for the student when there are no grading periods', function () {
  const self = this.setupThis();
  const submissions = this.submissionsForStudent.call(self, this.student);
  propEqual(_.pluck(submissions, 'assignment_id'), ['1', '2']);
});

test('returns all submissions if "All Grading Periods" is selected', function () {
  const self = this.setupThis({
    gradingPeriodSet: { id: '1' },
    gradingPeriodToShow: '0',
    isAllGradingPeriods () {
      return true;
    }
  });
  const submissions = this.submissionsForStudent.call(self, this.student);
  propEqual(_.pluck(submissions, 'assignment_id'), ['1', '2']);
});

test('only returns submissions due for the student in the selected grading period', function () {
  const self = this.setupThis({
    gradingPeriodSet: { id: '1' },
    gradingPeriodToShow: '2'
  });
  const submissions = this.submissionsForStudent.call(self, this.student);
  propEqual(_.pluck(submissions, 'assignment_id'), ['2']);
});

QUnit.module('Gradebook#studentsUrl', {
  setupThis (options = {}) {
    return {
      getEnrollmentFilters: this.stub().returns({ concluded: false, inactive: false }),
      ...options
    }
  },

  setup () {
    this.studentsUrl = Gradebook.prototype.studentsUrl;
  }
});

test('enrollmentUrl returns "students_url"', function () {
  equal(this.studentsUrl.call(this.setupThis()), 'students_url');
});

test('when concluded only, enrollmentUrl returns "students_with_concluded_enrollments_url"', function () {
  const self = this.setupThis({
    getEnrollmentFilters: this.stub().returns({ concluded: true, inactive: false })
  });
  equal(this.studentsUrl.call(self), 'students_with_concluded_enrollments_url');
});

test('when inactive only, enrollmentUrl returns "students_with_inactive_enrollments_url"', function () {
  const self = this.setupThis({
    getEnrollmentFilters: this.stub().returns({ concluded: false, inactive: true })
  });
  equal(this.studentsUrl.call(self), 'students_with_inactive_enrollments_url');
});

test('when show concluded and hide inactive are true, enrollmentUrl returns ' +
  '"students_with_concluded_and_inactive_enrollments_url"', function () {
  const self = this.setupThis({
    getEnrollmentFilters: this.stub().returns({ concluded: true, inactive: true })
  });
  equal(this.studentsUrl.call(self), 'students_with_concluded_and_inactive_enrollments_url');
});

QUnit.module('Gradebook#weightedGroups', {
  setup () {
    this.weightedGroups = Gradebook.prototype.weightedGroups;
  }
});

test('returns true when group_weighting_scheme is "percent"', function () {
  equal(this.weightedGroups.call({
    options: {
      group_weighting_scheme: 'percent'
    }
  }), true);
});

test('returns false when group_weighting_scheme is not "percent"', function () {
  equal(this.weightedGroups.call({
    options: {
      group_weighting_scheme: 'points'
    }
  }), false);
  equal(this.weightedGroups.call({
    options: {
      group_weighting_scheme: null
    }
  }), false);
});

QUnit.module('Gradebook#weightedGrades', {
  setupThis (groupWeightingScheme, gradingPeriodSet) {
    return {
      options: {
        group_weighting_scheme: groupWeightingScheme
      },
      gradingPeriodSet
    };
  },

  setup () {
    this.weightedGrades = Gradebook.prototype.weightedGrades;
  }
});

test('returns true when group_weighting_scheme is "percent"', function () {
  const self = this.setupThis('percent', {
    weighted: false
  });
  equal(this.weightedGrades.call(self), true);
});

test('returns true when the gradingPeriodSet is weighted', function () {
  const self = this.setupThis('points', {
    weighted: true
  });
  equal(this.weightedGrades.call(self), true);
});

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not weighted', function () {
  const self = this.setupThis('points', {
    weighted: false
  });
  equal(this.weightedGrades.call(self), false);
});

test('returns false when group_weighting_scheme is not "percent" and gradingPeriodSet is not defined', function () {
  const self = this.setupThis('points', null);
  equal(this.weightedGrades.call(self), false);
});

QUnit.module('Gradebook#displayPointTotals', {
  setupThis (showTotalGradeAsPoints, weightedGrades) {
    return {
      options: {
        show_total_grade_as_points: showTotalGradeAsPoints
      },
      weightedGrades () {
        return weightedGrades;
      }
    };
  },

  setup () {
    this.displayPointTotals = Gradebook.prototype.displayPointTotals;
  }
});

test('returns true when grades are not weighted and show_total_grade_as_points is true', function () {
  const self = this.setupThis(true, false);
  equal(this.displayPointTotals.call(self), true);
});

test('returns false when grades are weighted', function () {
  const self = this.setupThis(true, true);
  equal(this.displayPointTotals.call(self), false);
});

test('returns false when show_total_grade_as_points is false', function () {
  const self = this.setupThis(false, false);
  equal(this.displayPointTotals.call(self), false);
});

QUnit.module('Gradebook#switchTotalDisplay', {
  setup () {
    this.gradebook = createGradebook({
      show_total_grade_as_points: true,
      setting_update_url: 'http://settingUpdateUrl'
    });
    this.gradebook.grid = {
      invalidate: this.stub()
    }
    this.stub(this.gradebook, 'renderTotalGradeColumnHeader');

    // Stub this here so the AJAX calls in Dataloader don't get stubbed too
    this.stub($, 'ajaxJSON');
  },

  teardown () {
    UserSettings.contextRemove('warned_about_totals_display');
  }
});

test('sets the warned_about_totals_display setting when called with true', function () {
  notOk(UserSettings.contextGet('warned_about_totals_display'));

  this.gradebook.switchTotalDisplay({ dontWarnAgain: true });

  ok(UserSettings.contextGet('warned_about_totals_display'));
});

test('flips the show_total_grade_as_points property', function () {
  this.gradebook.switchTotalDisplay({ dontWarnAgain: false });

  equal(this.gradebook.options.show_total_grade_as_points, false);

  this.gradebook.switchTotalDisplay({ dontWarnAgain: false });

  equal(this.gradebook.options.show_total_grade_as_points, true);
});

test('updates the total display preferences for the current user', function () {
  this.gradebook.switchTotalDisplay({ dontWarnAgain: false });

  equal($.ajaxJSON.callCount, 1);
  equal($.ajaxJSON.getCall(0).args[0], 'http://settingUpdateUrl');
  equal($.ajaxJSON.getCall(0).args[1], 'PUT');
  equal($.ajaxJSON.getCall(0).args[2].show_total_grade_as_points, false);
});

test('invalidates the grid so it re-renders it', function () {
  this.gradebook.switchTotalDisplay({ dontWarnAgain: false });

  equal(this.gradebook.grid.invalidate.callCount, 1);
});

test('re-renders the total grade column header', function () {
  this.gradebook.switchTotalDisplay({ dontWarnAgain: false });

  equal(this.gradebook.renderTotalGradeColumnHeader.callCount, 1);
});

QUnit.module('Gradebook#togglePointsOrPercentTotals', {
  setup () {
    this.gradebook = createGradebook({
      show_total_grade_as_points: true,
      setting_update_url: 'http://settingUpdateUrl'
    });
    this.stub(this.gradebook, 'switchTotalDisplay');

    // Stub this here so the AJAX calls in Dataloader don't get stubbed too
    this.stub($, 'ajaxJSON');
  },

  teardown () {
    UserSettings.contextRemove('warned_about_totals_display');
  }
});

test('when user is ignoring warnings, immediately toggles the total grade display', function () {
  UserSettings.contextSet('warned_about_totals_display', true);

  this.gradebook.togglePointsOrPercentTotals();

  equal(this.gradebook.switchTotalDisplay.callCount, 1, 'toggles the total grade display');
});

test('when user is not ignoring warnings, return a dialog', function () {
  UserSettings.contextSet('warned_about_totals_display', false);

  const dialog = this.gradebook.togglePointsOrPercentTotals();

  equal(dialog.constructor.name, 'GradeDisplayWarningDialog', 'returns a grade display warning dialog');

  dialog.cancel();
});

test('when user is not ignoring warnings, the dialog has a save property which is the switchTotalDisplay function', function () {
  this.stub(UserSettings, 'contextGet').withArgs('warned_about_totals_display').returns(false);
  const dialog = this.gradebook.togglePointsOrPercentTotals();

  equal(dialog.options.save, this.gradebook.switchTotalDisplay);

  dialog.cancel();
});

QUnit.module('Gradebook#showNotesColumn', {
  setup () {
    this.stub(DataLoader, 'getDataForColumn');
  },

  setupShowNotesColumn (opts = {}) {
    const self = {
      options: {},
      toggleNotesColumn () {},
      ...opts
    };
    this.showNotesColumn = Gradebook.prototype.showNotesColumn.bind(self);
  }
});

test('loads the notes if they have not yet been loaded', function () {
  this.setupShowNotesColumn({
    teacherNotesNotYetLoaded: true
  });
  this.showNotesColumn();
  equal(DataLoader.getDataForColumn.callCount, 1);
});

test('does not load the notes if they are already loaded', function () {
  this.setupShowNotesColumn({
    teacherNotesNotYetLoaded: false
  });
  this.showNotesColumn();
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

test('disabled defaults to false', function () {
  const gradebook = createGradebook();
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, false);
});

test('disabled is true if the teacher notes column is updating', function () {
  const gradebook = createGradebook();
  gradebook.setTeacherNotesColumnUpdating(true);
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, true);
});

test('disabled is false if the teacher notes column is not updating', function () {
  const gradebook = createGradebook();
  gradebook.setTeacherNotesColumnUpdating(false);
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.disabled, false);
});

test('onSelect calls createTeacherNotes if there are no teacher notes', function () {
  const gradebook = createGradebook({ teacher_notes: null });
  this.stub(gradebook, 'createTeacherNotes');
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  props.onSelect();
  equal(gradebook.createTeacherNotes.callCount, 1);
});

test('onSelect calls setTeacherNotesHidden with false if teacher notes are hidden', function () {
  const gradebook = createGradebook({ teacher_notes: { hidden: true } });
  this.stub(gradebook, 'setTeacherNotesHidden');
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  props.onSelect();
  equal(gradebook.setTeacherNotesHidden.callCount, 1);
  equal(gradebook.setTeacherNotesHidden.getCall(0).args[0], false)
});

test('onSelect calls setTeacherNotesHidden with true if teacher notes are visible', function () {
  const gradebook = createGradebook({ teacher_notes: { hidden: false } });
  this.stub(gradebook, 'setTeacherNotesHidden');
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
  const gradebook = createGradebook({ teacher_notes: { hidden: true } });
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.selected, false);
});

test('selected is true if teacher notes are visible', function () {
  const gradebook = createGradebook({ teacher_notes: { hidden: false } });
  const props = gradebook.getTeacherNotesViewOptionsMenuProps();
  equal(props.selected, true);
});

QUnit.module('Gradebook#getColumnSortSettingsViewOptionsMenuProps', {
  getProps (sortType = 'due_date', direction = 'ascending') {
    const storedSortOrder = { sortType, direction };

    this.stub(this.gradebook, 'getStoredSortOrder').returns(storedSortOrder);
    const props = this.gradebook.getColumnSortSettingsViewOptionsMenuProps();
    this.gradebook.getStoredSortOrder.restore();

    return props;
  },

  expectedArgs (sortType, direction) {
    return [
      { sortType, direction },
      false
    ];
  },

  setup () {
    this.gradebook = createGradebook();
    this.stub(this.gradebook, 'arrangeColumnsBy');
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

test('sets onSortByNameAscending to a function that sorts columns by name ascending', function () {
  this.getProps().onSortByNameAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('name', 'ascending'));
});

test('sets onSortByNameAscending to a function that sorts columns by name descending', function () {
  this.getProps().onSortByNameDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('name', 'descending'));
});

test('sets onSortByDueDateAscending to a function that sorts columns by due date ascending', function () {
  this.getProps().onSortByDueDateAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('due_date', 'ascending'));
});

test('sets onSortByDueDateAscending to a function that sorts columns by due date descending', function () {
  this.getProps().onSortByDueDateDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('due_date', 'descending'));
});

test('sets onSortByPointsAscending to a function that sorts columns by points ascending', function () {
  this.getProps().onSortByPointsAscending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('points', 'ascending'));
});

test('sets onSortByPointsAscending to a function that sorts columns by points descending', function () {
  this.getProps().onSortByPointsDescending();

  strictEqual(this.gradebook.arrangeColumnsBy.callCount, 1);
  deepEqual(this.gradebook.arrangeColumnsBy.firstCall.args, this.expectedArgs('points', 'descending'));
});

QUnit.module('Gradebook#getViewOptionsMenuProps', {
  setup () {
    this.gradebook = createGradebook();
    this.teacherNotesProps = { propsFor: 'teacherNotes' };
    this.columnSortSettingProps = { propsFor: 'columnSortSettings' };
    this.stub(this.gradebook, 'getTeacherNotesViewOptionsMenuProps').returns(this.teacherNotesProps);
    this.stub(this.gradebook, 'getColumnSortSettingsViewOptionsMenuProps').returns(this.columnSortSettingProps);

    this.props = this.gradebook.getViewOptionsMenuProps();
  }
});

test('includes teacher notes properties', function () {
  strictEqual(this.props.teacherNotes, this.teacherNotesProps);
});

test('includes column sort properties', function () {
  strictEqual(this.props.columnSortSettings, this.columnSortSettingProps);
});

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
    this.stub(GradebookApi, 'createTeacherNotesColumn').returns(this.promise);
    this.gradebook = createGradebook({ context_id: '1201' });
    this.stub(this.gradebook, 'showNotesColumn');
    this.stub(this.gradebook, 'renderViewOptionsMenu');
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
  equal(this.gradebook.options.teacher_notes, column);
});

test('shows the notes column after request resolves', function () {
  this.gradebook.createTeacherNotes();
  equal(this.gradebook.showNotesColumn.callCount, 0);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.showNotesColumn.callCount, 1);
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
  this.stub($, 'flashError');
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
    this.stub(GradebookApi, 'updateTeacherNotesColumn').returns(this.promise);
    this.gradebook = createGradebook({ context_id: '1201', teacher_notes: { id: '2401', hidden: true } });
    this.gradebook.customColumns = [{ id: '2401' }, { id: '2402' }];
    this.stub(this.gradebook, 'showNotesColumn');
    this.stub(this.gradebook, 'reorderCustomColumns');
    this.stub(this.gradebook, 'renderViewOptionsMenu');
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

test('updates teacher notes as not hidden after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false);
  equal(this.gradebook.options.teacher_notes.hidden, true);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.options.teacher_notes.hidden, false);
});

test('shows the notes column after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(false);
  equal(this.gradebook.showNotesColumn.callCount, 0);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: false } });
  equal(this.gradebook.showNotesColumn.callCount, 1);
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
  this.stub($, 'flashError');
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
    this.stub(GradebookApi, 'updateTeacherNotesColumn').returns(this.promise);
    this.gradebook = createGradebook({ context_id: '1201', teacher_notes: { id: '2401', hidden: false } });
    this.stub(this.gradebook, 'hideNotesColumn');
    this.stub(this.gradebook, 'renderViewOptionsMenu');
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

test('updates teacher notes as hidden after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true);
  equal(this.gradebook.options.teacher_notes.hidden, false);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true } });
  equal(this.gradebook.options.teacher_notes.hidden, true);
});

test('hides the notes column after request resolves', function () {
  this.gradebook.setTeacherNotesHidden(true);
  equal(this.gradebook.hideNotesColumn.callCount, 0);
  this.promise.thenFn({ data: { id: '2401', title: 'Notes', position: 1, teacher_notes: true, hidden: true } });
  equal(this.gradebook.hideNotesColumn.callCount, 1);
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
  this.stub($, 'flashError');
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

QUnit.module('Menus', {
  setup () {
    fakeENV.setup({
      current_user_id: '1',
      GRADEBOOK_OPTIONS: {
        context_url: 'http://someUrl/',
        outcome_gradebook_enabled: true
      }
    });
  },

  teardown () {
    $fixtures.innerHTML = '';
    fakeENV.teardown();
  }
});

test('ViewOptionsMenu is rendered on renderViewOptionsMenu', function () {
  $fixtures.innerHTML = '<span data-component="ViewOptionsMenu"></span>';
  const gradebook = createGradebook();
  gradebook.renderViewOptionsMenu();
  const buttonText = document.querySelector('[data-component="ViewOptionsMenu"] Button').innerText.trim();
  equal(buttonText, 'View');
});

test('ActionMenu is rendered on renderActionMenu', function () {
  ReactDOM.render(<span data-component="ActionMenu" />, $fixtures);
  const self = {
    options: {
      gradebook_is_editable: true,
      context_allows_gradebook_uploads: true,
      gradebook_import_url: 'http://someUrl',
      export_gradebook_csv_url: 'http://someUrl'
    },
    postGradesLtis: [],
    postGradesStore: {},
    getActionMenuProps: Gradebook.prototype.getActionMenuProps
  };
  Gradebook.prototype.renderActionMenu.call(self);
  const buttonText = document.querySelector('[data-component="ActionMenu"] Button').innerText.trim();
  equal(buttonText, 'Actions');
});

test('GradebookMenu is rendered on renderGradebookMenu', function () {
  ReactDOM.render(<span data-component="GradebookMenu" data-variant="DefaultGradebook" />, $fixtures);
  const self = {
    options: {
      assignmentOrOutcome: 'assignment',
      navigate () {}
    }
  };
  Gradebook.prototype.renderGradebookMenu.call(self);
  const buttonText = document.querySelector('[data-component="GradebookMenu"] Button').innerText.trim();
  equal(buttonText, 'Gradebook');
});

QUnit.module('addRow', {
  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: { context_id: 1 },
    });
  },

  teardown () {
    fakeENV.teardown();
  }
});

test('does not add filtered out users', function () {
  const gradebook = createGradebook({ sections: { 1: { name: 'Section 1' }, 2: { name: 'Section 2' }} });
  gradebook.sections_enabled = true;
  gradebook.sectionToShow = '2';

  const student1 = {
    enrollments: [{grades: {}}],
    sections: ['1'],
    name: 'student',
  };
  const student2 = {...student1, sections: ['2']};
  const student3 = {...student1, sections: ['2']};
  [student1, student2, student3].forEach((student) => { gradebook.addRow(student) });

  ok(student1.row == null, 'filtered out students get no row number');
  ok(student2.row === 0, 'other students do get a row number');
  ok(student3.row === 1, 'row number increments');
  ok(_.isEqual(gradebook.rows, [student2, student3]));
});

QUnit.module('sortByStudentColumn', {
  setup () {
    this.gradebook = createGradebook();
    this.studentA = { sortable_name: 'Ford, Betty' };
    this.studentB = { sortable_name: 'Jones, Adam' };
    this.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    this.stub(this.gradebook, 'localeSort');
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.sortByCustomColumn('sortable_name', 'ascending');
  equal(this.gradebook.sortRowsBy.callCount, 1);
});

test('sorts using localeSort when the settingKey is "sortable_name"', function () {
  this.gradebook.sortByCustomColumn('sortable_name', 'ascending');
  equal(this.gradebook.localeSort.callCount, 1);
});

test('sorts by sortable_name using the "sortable_name" field on students', function () {
  this.gradebook.sortByCustomColumn('sortable_name', 'ascending');
  const [studentA, studentB] = this.gradebook.localeSort.getCall(0).args;
  equal(studentA, 'Ford, Betty', 'studentA sortable_name is in first position');
  equal(studentB, 'Jones, Adam', 'studentB sortable_name is in second position');
});

test('optionally sorts in descending order', function () {
  this.gradebook.sortByCustomColumn('sortable_name', 'descending');
  const [studentA, studentB] = this.gradebook.localeSort.getCall(0).args;
  equal(studentA, 'Jones, Adam', 'studentB sortable_name is in first position');
  equal(studentB, 'Ford, Betty', 'studentA sortable_name is in second position');
});

QUnit.module('sortByCustomColumn', {
  setup () {
    this.gradebook = createGradebook();
    this.studentA = { custom_col_501: 'Great at math' };
    this.studentB = { custom_col_501: 'Tutors English' };
    this.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    this.stub(this.gradebook, 'localeSort');
  }
});

test('sorts the gradebook rows', function () {
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending');
  equal(this.gradebook.sortRowsBy.callCount, 1);
});

test('sorts using localeSort', function () {
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending');
  equal(this.gradebook.localeSort.callCount, 1);
});

test('sorts using student data stored with the columnId', function () {
  this.gradebook.sortByCustomColumn('custom_col_501', 'ascending');
  const [studentNoteA, studentNoteB] = this.gradebook.localeSort.getCall(0).args;
  equal(studentNoteA, 'Great at math', 'studentA data is in first position');
  equal(studentNoteB, 'Tutors English', 'studentB data is in second position');
});

test('optionally sorts in descending order', function () {
  this.gradebook.sortByCustomColumn('custom_col_501', 'descending');
  const [studentNoteA, studentNoteB] = this.gradebook.localeSort.getCall(0).args;
  equal(studentNoteA, 'Tutors English', 'studentB data is in first position');
  equal(studentNoteB, 'Great at math', 'studentA data is in second position');
});

QUnit.module('sortByAssignmentColumn', {
  setup () {
    this.gradebook = createGradebook();
    this.studentA = { name: 'Adam Jones' };
    this.studentB = { name: 'Betty Ford' };
    this.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    this.stub(this.gradebook, 'gradeSort');
    this.stub(this.gradebook, 'missingSort');
    this.stub(this.gradebook, 'lateSort');
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
    this.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    this.stub(this.gradebook, 'gradeSort');
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
    this.stub(this.gradebook, 'sortRowsBy').callsFake(sortFn => sortFn(this.studentA, this.studentB));
    this.stub(this.gradebook, 'gradeSort');
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
  }
});

test('sorts by the student column by default', function () {
  this.stub(this.gradebook, 'sortByStudentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByStudentColumn.callCount, 1);
});

test('uses the saved sort setting for student column sorting', function () {
  this.gradebook.setSortRowsBySetting('student_name', 'sortable_name', 'ascending');
  this.stub(this.gradebook, 'sortByStudentColumn');
  this.gradebook.sortGridRows();

  const [settingKey, direction] = this.gradebook.sortByStudentColumn.getCall(0).args;
  equal(settingKey, 'sortable_name', 'parameter 1 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 2 is the sort direction');
});

test('optionally sorts by a custom column', function () {
  this.gradebook.setSortRowsBySetting('custom_col_501', null, 'ascending');
  this.stub(this.gradebook, 'sortByCustomColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByCustomColumn.callCount, 1);
});

test('uses the saved sort setting for custom column sorting', function () {
  this.gradebook.setSortRowsBySetting('custom_col_501', null, 'ascending');
  this.stub(this.gradebook, 'sortByCustomColumn');
  this.gradebook.sortGridRows();

  const [columnId, direction] = this.gradebook.sortByCustomColumn.getCall(0).args;
  equal(columnId, 'custom_col_501', 'parameter 1 is the sort columnId');
  equal(direction, 'ascending', 'parameter 2 is the sort direction');
});

test('optionally sorts by an assignment column', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'grade', 'ascending');
  this.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1);
});

test('uses the saved sort setting for assignment sorting', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'grade', 'ascending');
  this.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();

  const [columnId, settingKey, direction] = this.gradebook.sortByAssignmentColumn.getCall(0).args;
  equal(columnId, 'assignment_201', 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('optionally sorts by an assignment group column', function () {
  this.gradebook.setSortRowsBySetting('assignment_group_301', 'grade', 'ascending');
  this.stub(this.gradebook, 'sortByAssignmentGroupColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentGroupColumn.callCount, 1);
});

test('uses the saved sort setting for assignment group sorting', function () {
  this.gradebook.setSortRowsBySetting('assignment_group_301', 'grade', 'ascending');
  this.stub(this.gradebook, 'sortByAssignmentGroupColumn');
  this.gradebook.sortGridRows();

  const [columnId, settingKey, direction] = this.gradebook.sortByAssignmentGroupColumn.getCall(0).args;
  equal(columnId, 'assignment_group_301', 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('optionally sorts by the total grade column', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  this.stub(this.gradebook, 'sortByTotalGradeColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByTotalGradeColumn.callCount, 1);
});

test('uses the saved sort setting for total grade sorting', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  this.stub(this.gradebook, 'sortByTotalGradeColumn');
  this.gradebook.sortGridRows();

  const [direction] = this.gradebook.sortByTotalGradeColumn.getCall(0).args;
  equal(direction, 'ascending', 'the only parameter is the sort direction');
});

test('optionally sorts by missing', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'missing', 'ascending');
  this.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1);
});

test('optionally sorts by late', function () {
  this.gradebook.setSortRowsBySetting('assignment_201', 'late', 'ascending');
  this.stub(this.gradebook, 'sortByAssignmentColumn');
  this.gradebook.sortGridRows();
  equal(this.gradebook.sortByAssignmentColumn.callCount, 1);
});

test('updates the column headers after sorting', function () {
  this.stub(this.gradebook, 'sortByStudentColumn');
  this.stub(this.gradebook, 'updateColumnHeaders').callsFake(() => {
    equal(this.gradebook.sortByStudentColumn.callCount, 1, 'sorting method was called first');
  });
  this.gradebook.sortGridRows();
})

QUnit.module('Gradebook#groupTotalFormatter', {
  setup () {
    fakeENV.setup();
  },

  teardown () {
    fakeENV.teardown();
  },
});

test('calculates percentage from given score and possible values', function () {
  const gradebook = createGradebook();
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 10 }, {});
  ok(groupTotalOutput.includes('9 / 10'));
  ok(groupTotalOutput.includes('90%'));
});

test('displays percentage as "-" when group total score is positive infinity', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(Number.POSITIVE_INFINITY);
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
  ok(groupTotalOutput.includes('9 / 0'));
  ok(groupTotalOutput.includes('-'));
});

test('displays percentage as "-" when group total score is negative infinity', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(Number.NEGATIVE_INFINITY);
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
  ok(groupTotalOutput.includes('9 / 0'));
  ok(groupTotalOutput.includes('-'));
});

test('displays percentage as "-" when group total score is not a number', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'calculateAndRoundGroupTotalScore').returns(NaN);
  const groupTotalOutput = gradebook.groupTotalFormatter(0, 0, { score: 9, possible: 0 }, {});
  ok(groupTotalOutput.includes('9 / 0'));
  ok(groupTotalOutput.includes('-'));
});

QUnit.module('Gradebook#onHeaderCellRendered');

test('renders the student column header for the "student" column type', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderStudentColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'student' } });
  equal(gradebook.renderStudentColumnHeader.callCount, 1);
});

test('renders the total grade column header for the "total_grade" column type', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderTotalGradeColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'total_grade' } });
  equal(gradebook.renderTotalGradeColumnHeader.callCount, 1);
});

test('renders the custom column header for the "custom_column" column type', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderCustomColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'custom_column', customColumnId: '2401' } });
  equal(gradebook.renderCustomColumnHeader.callCount, 1);
});

test('uses the column "customColumnId" when rendering a custom column header', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderCustomColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'custom_column', customColumnId: '2401' } });
  const [customColumnId] = gradebook.renderCustomColumnHeader.getCall(0).args;
  equal(customColumnId, '2401');
});

test('renders the assignment column header for the "assignment" column type', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderAssignmentColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'assignment', assignmentId: '2301' } });
  equal(gradebook.renderAssignmentColumnHeader.callCount, 1);
});

test('uses the column "assignmentId" when rendering an assignment column header', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderAssignmentColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'assignment', assignmentId: '2301' } });
  const [assignmentId] = gradebook.renderAssignmentColumnHeader.getCall(0).args;
  equal(assignmentId, '2301');
});

test('renders the assignment group column header for the "assignment_group" column type', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderAssignmentGroupColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'assignment_group', assignmentGroupId: '2201' } });
  equal(gradebook.renderAssignmentGroupColumnHeader.callCount, 1);
});

test('uses the column "assignmentGroupId" when rendering an assignment group column header', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'renderAssignmentGroupColumnHeader');
  gradebook.onHeaderCellRendered(null, { column: { type: 'assignment_group', assignmentGroupId: '2201' } });
  const [assignmentGroupId] = gradebook.renderAssignmentGroupColumnHeader.getCall(0).args;
  equal(assignmentGroupId, '2201');
});

QUnit.module('Gradebook#onBeforeHeaderCellDestroy', {
  setup () {
    this.$mountPoint = document.createElement('div');
    $fixtures.appendChild(this.$mountPoint);
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        login_handle_name: ''
      }
    });
  },

  teardown () {
    $fixtures.innerHTML = '';
    fakeENV.teardown();
  }
});

test('unmounts any component on the cell being destroyed', function () {
  const component = React.createElement('span', {}, 'Example Component');
  ReactDOM.render(component, this.$mountPoint, null);
  Gradebook.prototype.onBeforeHeaderCellDestroy(null, { node: this.$mountPoint });
  const componentExistedAtNode = ReactDOM.unmountComponentAtNode(this.$mountPoint);
  equal(componentExistedAtNode, false, 'the component was already unmounted');
});

QUnit.module('Gradebook#renderStudentColumnHeader', {
  setup () {
    this.$mountPoint = document.createElement('div');
    $fixtures.appendChild(this.$mountPoint);
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        login_handle_name: 'foo'
      }
    });
  },

  teardown () {
    ReactDOM.unmountComponentAtNode(this.$mountPoint);
    $fixtures.innerHTML = '';
    fakeENV.teardown();
  }
});

test('renders the StudentColumnHeader to the "student" column header node', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'getColumnHeaderNode').withArgs('student').returns(this.$mountPoint);
  gradebook.renderStudentColumnHeader();
  ok(this.$mountPoint.innerText.includes('Student Name'), 'the "Student Name" header is rendered');
});

QUnit.module('Gradebook#getStudentColumnHeaderProps');

test('includes properties from gradebook', function () {
  const gradebook = createGradebook({
    login_handle_name: 'foo',
    sis_name: 'bar'
  });
  const props = gradebook.getStudentColumnHeaderProps();
  ok(props.selectedSecondaryInfo, 'selectedSecondaryInfo is present');
  ok(props.selectedPrimaryInfo, 'selectedPrimaryInfo is present');
  equal(typeof props.sectionsEnabled, 'boolean');
  equal(typeof props.onSelectSecondaryInfo, 'function');
  equal(typeof props.onSelectPrimaryInfo, 'function');
  equal(props.loginHandleName, 'foo');
  equal(props.sisName, 'bar');
});

test('includes props for the "Sort by" settings', function () {
  const props = createGradebook().getStudentColumnHeaderProps();
  ok(props.sortBySetting, 'sort by setting is present');
  equal(typeof props.sortBySetting.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.sortBySetting.onSortBySortableNameAscending, 'function', 'props include "onSortBySortableNameAscending"');
  equal(typeof props.sortBySetting.onSortBySortableNameDescending, 'function', 'props include "onSortBySortableNameDescending"');
});

QUnit.module('Gradebook#getStudentColumnSortBySetting', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setStudentsLoaded(true);
  }
});

test('includes the sort direction', function () {
  this.gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending');
  const props = this.gradebook.getStudentColumnSortBySetting();
  equal(props.direction, 'ascending');
});

test('is not disabled when students are loaded', function () {
  const props = this.gradebook.getStudentColumnSortBySetting();
  equal(props.disabled, false);
});

test('is disabled when students are not loaded', function () {
  this.gradebook.setStudentsLoaded(false);
  const props = this.gradebook.getStudentColumnSortBySetting();
  equal(props.disabled, true);
});

test('sets isSortColumn to true when sorting by the student column', function () {
  this.gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending');
  const props = this.gradebook.getStudentColumnSortBySetting();
  equal(props.isSortColumn, true);
});

test('sets isSortColumn to false when not sorting by the student column', function () {
  const columnId = this.gradebook.getAssignmentColumnId('202');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getStudentColumnSortBySetting();
  equal(props.isSortColumn, false);
});

test('sets the onSortBySortableNameAscending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getStudentColumnSortBySetting();

  props.onSortBySortableNameAscending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, 'student', 'parameter 1 is the sort columnId');
  equal(settingKey, 'sortable_name', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('sets the onSortBySortableNameDescending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getStudentColumnSortBySetting();

  props.onSortBySortableNameDescending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, 'student', 'parameter 1 is the sort columnId');
  equal(settingKey, 'sortable_name', 'parameter 2 is the sort settingKey');
  equal(direction, 'descending', 'parameter 3 is the sort direction');
});

test('includes the sort settingKey', function () {
  this.gradebook.setSortRowsBySetting('student', 'sortable_name', 'ascending');
  const props = this.gradebook.getStudentColumnSortBySetting();
  equal(props.settingKey, 'sortable_name');
});

QUnit.module('Gradebook#getCustomColumnHeaderProps');

test('includes the custom column title', function () {
  const gradebook = createGradebook();
  gradebook.customColumns = [{ id: '2401', title: 'Notes' }, { id: '2402', title: 'Other Notes' }];
  const props = gradebook.getCustomColumnHeaderProps('2401');
  equal(props.title, 'Notes');
});

QUnit.module('Gradebook#renderCustomColumnHeader', {
  setup () {
    this.$mountPoint = document.createElement('div');
    $fixtures.appendChild(this.$mountPoint);
  },

  teardown () {
    ReactDOM.unmountComponentAtNode(this.$mountPoint);
    $fixtures.innerHTML = '';
  }
});

test('renders the CustomColumnHeader to the related custom column header node', function () {
  const gradebook = createGradebook();
  gradebook.customColumns = [{ id: '2401', title: 'Notes' }, { id: '2402', title: 'Other Notes' }];
  this.stub(gradebook, 'getColumnHeaderNode').withArgs('custom_col_2401').returns(this.$mountPoint);
  gradebook.renderCustomColumnHeader('2401');
  ok(this.$mountPoint.innerText.includes('Notes'), 'the "Notes" header is rendered');
});

QUnit.module('Gradebook#renderAssignmentColumnHeader', {
  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        context_url: 'http://contextUrl/'
      },
      current_user_roles: []
    });
    this.$mountPoint = document.createElement('div');
    $fixtures.appendChild(this.$mountPoint);
  },

  createGradebook (options = {}) {
    const gradebook = createGradebook(options);
    gradebook.setAssignments({
      201: {
        course_id: '801',
        id: '201',
        html_url: '/assignments/201',
        muted: false,
        name: 'Math Assignment',
        omit_from_final_grade: false,
        published: true,
        submission_types: ['online_text_entry']
      }
    });
    return gradebook;
  },

  teardown () {
    ReactDOM.unmountComponentAtNode(this.$mountPoint);
    $fixtures.innerHTML = '';
    fakeENV.teardown();
  }
});

test('renders the AssignmentColumnHeader to the related assignment column header node', function () {
  const gradebook = this.createGradebook();
  this.stub(gradebook, 'getColumnHeaderNode').withArgs('assignment_201').returns(this.$mountPoint);
  gradebook.renderAssignmentColumnHeader('201');
  ok(this.$mountPoint.innerText.includes('Math Assignment'), 'the Assignment header is rendered');
});

QUnit.module('Gradebook#renderAssignmentGroupColumnHeader', {
  setup () {
    this.$mountPoint = document.createElement('div');
    $fixtures.appendChild(this.$mountPoint);
  },

  createGradebook (options = {}) {
    const gradebook = createGradebook({
      group_weighting_scheme: 'percent',
      ...options
    });
    gradebook.setAssignmentGroups({
      301: { name: 'Assignments', group_weight: 40 }
    });
    return gradebook;
  },

  teardown () {
    ReactDOM.unmountComponentAtNode(this.$mountPoint);
    $fixtures.innerHTML = '';
  }
});

test('renders the AssignmentGroupColumnHeader to the related assignment group column header node', function () {
  const gradebook = this.createGradebook();
  this.stub(gradebook, 'getColumnHeaderNode').withArgs('assignment_group_301').returns(this.$mountPoint);
  gradebook.renderAssignmentGroupColumnHeader('301');
  ok(this.$mountPoint.innerText.includes('Assignments'), 'the Assignment Group header is rendered');
});

QUnit.module('Gradebook#renderTotalGradeColumnHeader', {
  setup () {
    this.$mountPoint = document.createElement('div');
    $fixtures.appendChild(this.$mountPoint);

    this.gradebook = createGradebook();
    this.gradebook.grid = {
      getColumns () { return [] }
    }
    this.stub(this.gradebook, 'getColumnHeaderNode').withArgs('total_grade').returns(this.$mountPoint);
  },

  teardown () {
    ReactDOM.unmountComponentAtNode(this.$mountPoint);
    $fixtures.innerHTML = '';
  }
});

test('renders the TotalGradeColumnHeader to the "total_grade" column header node', function () {
  this.stub(this.gradebook, 'hideAggregateColumns').returns(false);
  this.gradebook.renderTotalGradeColumnHeader();
  ok(this.$mountPoint.innerText.includes('Total'), 'the "Total" header is rendered');
});

test('does not render when aggregate columns are hidden', function () {
  this.stub(this.gradebook, 'hideAggregateColumns').returns(true);
  this.gradebook.renderTotalGradeColumnHeader();
  equal(this.$mountPoint.children.length, 0, 'the mount point contains no elements');
});

QUnit.module('Gradebook#getCustomColumnId');

test('returns a unique key for the custom column', function () {
  equal(Gradebook.prototype.getCustomColumnId('2401'), 'custom_col_2401');
});

QUnit.module('Gradebook#getAssignmentColumnId');

test('returns a unique key for the assignment column', function () {
  equal(Gradebook.prototype.getAssignmentColumnId('201'), 'assignment_201');
});

QUnit.module('Gradebook#getAssignmentGroupColumnId');

test('returns a unique key for the assignment group column', function () {
  equal(Gradebook.prototype.getAssignmentGroupColumnId('301'), 'assignment_group_301');
});

QUnit.module('Gradebook#updateColumnHeaders', {
  setup () {
    const columns = [
      { type: 'assignment_group', assignmentGroupId: '2201' },
      { type: 'assignment', assignmentId: '2301' },
      { type: 'custom_column', customColumnId: '2401' }
    ];
    this.gradebook = createGradebook();
    this.gradebook.grid = {
      getColumns () {
        return columns;
      }
    };
    this.stub(this.gradebook, 'renderStudentColumnHeader');
    this.stub(this.gradebook, 'renderTotalGradeColumnHeader');
    this.stub(this.gradebook, 'renderCustomColumnHeader');
    this.stub(this.gradebook, 'renderAssignmentColumnHeader');
    this.stub(this.gradebook, 'renderAssignmentGroupColumnHeader');
  }
});

test('renders the student column header', function () {
  this.gradebook.updateColumnHeaders();
  equal(this.gradebook.renderStudentColumnHeader.callCount, 1);
});

test('renders the total grade column header', function () {
  this.gradebook.updateColumnHeaders();
  equal(this.gradebook.renderTotalGradeColumnHeader.callCount, 1);
});

test('renders a custom column header for each "custom_column" column type', function () {
  this.gradebook.updateColumnHeaders();
  equal(this.gradebook.renderCustomColumnHeader.callCount, 1);
});

test('uses the column "customColumnId" when rendering a custom column header', function () {
  this.gradebook.updateColumnHeaders();
  const [customColumnId] = this.gradebook.renderCustomColumnHeader.getCall(0).args;
  equal(customColumnId, '2401');
});

test('renders the assignment column header for each "assignment" column type', function () {
  this.gradebook.updateColumnHeaders();
  equal(this.gradebook.renderAssignmentColumnHeader.callCount, 1);
});

test('uses the column "assignmentId" when rendering an assignment column header', function () {
  this.gradebook.updateColumnHeaders();
  const [assignmentId] = this.gradebook.renderAssignmentColumnHeader.getCall(0).args;
  equal(assignmentId, '2301');
});

test('renders the assignment group column header for each "assignment_group" column type', function () {
  this.gradebook.updateColumnHeaders();
  equal(this.gradebook.renderAssignmentGroupColumnHeader.callCount, 1);
});

test('uses the column "assignmentGroupId" when rendering an assignment group column header', function () {
  this.gradebook.updateColumnHeaders();
  const [assignmentGroupId] = this.gradebook.renderAssignmentGroupColumnHeader.getCall(0).args;
  equal(assignmentGroupId, '2201');
});

test('does not render column headers when the grid has not been created', function () {
  this.gradebook.grid = undefined;
  this.gradebook.updateColumnHeaders();
  equal(this.gradebook.renderStudentColumnHeader.callCount, 0);
  equal(this.gradebook.renderTotalGradeColumnHeader.callCount, 0);
  equal(this.gradebook.renderCustomColumnHeader.callCount, 0);
  equal(this.gradebook.renderAssignmentColumnHeader.callCount, 0);
  equal(this.gradebook.renderAssignmentGroupColumnHeader.callCount, 0);
});

QUnit.module('Gradebook#getAssignmentColumnSortBySetting', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setAssignmentsLoaded(true);
    this.gradebook.setStudentsLoaded(true);
    this.gradebook.setSubmissionsLoaded(true);
  }
});

test('includes the sort direction', function () {
  const columnId = this.gradebook.getAssignmentColumnId('201');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.direction, 'ascending');
});

test('is not disabled when assignments, students, and submissions are loaded', function () {
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.disabled, false);
});

test('is disabled when assignments are not loaded', function () {
  this.gradebook.setAssignmentsLoaded(false);
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.disabled, true);
});

test('is disabled when students are not loaded', function () {
  this.gradebook.setStudentsLoaded(false);
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.disabled, true);
});

test('is disabled when submissions are not loaded', function () {
  this.gradebook.setSubmissionsLoaded(false);
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.disabled, true);
});

test('sets isSortColumn to true when sorting by the given assignment', function () {
  const columnId = this.gradebook.getAssignmentColumnId('201');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.isSortColumn, true);
});

test('sets isSortColumn to false when not sorting by the given assignment', function () {
  const columnId = this.gradebook.getAssignmentColumnId('202');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.isSortColumn, false);
});

test('sets the onSortByGradeAscending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');

  props.onSortByGradeAscending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentColumnId('201'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('sets the onSortByGradeDescending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');

  props.onSortByGradeDescending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentColumnId('201'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'descending', 'parameter 3 is the sort direction');
});

test('sets the onSortByLate function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');

  props.onSortByLate();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentColumnId('201'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'late', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('sets the onSortByMissing function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');

  props.onSortByMissing();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentColumnId('201'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'missing', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('sets the onSortByUnposted function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');

  props.onSortByUnposted();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentColumnId('201'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'unposted', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('includes the sort settingKey', function () {
  const columnId = this.gradebook.getAssignmentColumnId('202');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentColumnSortBySetting('201');
  equal(props.settingKey, 'grade');
});

QUnit.module('Gradebook#getAssignmentColumnHeaderProps', {
  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {
        context_url: 'http://contextUrl/'
      },
      current_user_roles: []
    });
  },

  createGradebook (options = {}) {
    const gradebook = createGradebook(options);
    gradebook.setAssignments({
      201: { name: 'Math Assignment', published: true },
      202: { name: 'English Assignment', published: false }
    });
    return gradebook;
  },

  teardown () {
    fakeENV.teardown();
  }
});

test('includes name from the assignment', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.assignment, 'assignment is present');
  equal(props.assignment.name, 'Math Assignment');
});

test('includes published status for a published assignment', function () {
  const { assignment: { published } } = this.createGradebook().getAssignmentColumnHeaderProps('201');
  strictEqual(published, true);
});

test('includes published status for an unpublished assignment', function () {
  const { assignment: { published } } = this.createGradebook().getAssignmentColumnHeaderProps('202');
  strictEqual(published, false);
});

test('includes props for the "Sort by" setting', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.sortBySetting, 'Sort by setting is present');
  equal(typeof props.sortBySetting.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.sortBySetting.onSortByGradeAscending, 'function', 'props include "onSortByGradeAscending"');
});

test('includes props for the Assignment Details action', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.assignmentDetailsAction, 'Assignment Details action config is present');
  ok('disabled' in props.assignmentDetailsAction, 'props include "disabled"');
  equal(typeof props.assignmentDetailsAction.onSelect, 'function', 'props include "onSelect"');
});

test('includes props for the Set Default Grade action', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.setDefaultGradeAction, 'Set Default Grade action config is present');
  ok('disabled' in props.setDefaultGradeAction, 'props include "disabled"');
  equal(typeof props.setDefaultGradeAction.onSelect, 'function', 'props include "onSelect"');
});

test('includes props for the Download Submissions action', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.downloadSubmissionsAction, 'Download Submissions action config is present');
  ok('hidden' in props.downloadSubmissionsAction, 'props include "hidden"');
  equal(typeof props.downloadSubmissionsAction.onSelect, 'function', 'props include "onSelect"');
});

test('includes props for the Reupload Submissions action', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.reuploadSubmissionsAction, 'Reupload Submissions action config is present');
  ok('hidden' in props.reuploadSubmissionsAction, 'props include "hidden"');
  equal(typeof props.reuploadSubmissionsAction.onSelect, 'function', 'props include "onSelect"');
});

test('includes props for the Mute Assignment action', function () {
  const props = this.createGradebook().getAssignmentColumnHeaderProps('201');
  ok(props.muteAssignmentAction, 'Mute Assignment action config is present');
  ok('disabled' in props.muteAssignmentAction, 'props include "disabled"');
  equal(typeof props.muteAssignmentAction.onSelect, 'function', 'props include "onSelect"');
});

QUnit.module('Gradebook#getAssignmentGroupColumnSortBySetting', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setAssignmentsLoaded(true);
    this.gradebook.setStudentsLoaded(true);
    this.gradebook.setSubmissionsLoaded(true);
  }
});

test('includes the sort direction', function () {
  const columnId = this.gradebook.getAssignmentGroupColumnId('301');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.direction, 'ascending');
});

test('is not disabled when assignments, students, and submissions are loaded', function () {
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.disabled, false);
});

test('is disabled when assignments are not loaded', function () {
  this.gradebook.setAssignmentsLoaded(false);
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.disabled, true);
});

test('is disabled when students are not loaded', function () {
  this.gradebook.setStudentsLoaded(false);
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.disabled, true);
});

test('is disabled when submissions are not loaded', function () {
  this.gradebook.setSubmissionsLoaded(false);
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.disabled, true);
});

test('sets isSortColumn to true when sorting by the given assignment', function () {
  const columnId = this.gradebook.getAssignmentGroupColumnId('301');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.isSortColumn, true);
});

test('sets isSortColumn to false when not sorting by the given assignment', function () {
  const columnId = this.gradebook.getAssignmentGroupColumnId('302');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.isSortColumn, false);
});

test('sets the onSortByGradeAscending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');

  props.onSortByGradeAscending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentGroupColumnId('301'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('sets the onSortByGradeDescending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');

  props.onSortByGradeDescending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, this.gradebook.getAssignmentGroupColumnId('301'), 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'descending', 'parameter 3 is the sort direction');
});

test('includes the sort settingKey', function () {
  const columnId = this.gradebook.getAssignmentGroupColumnId('301');
  this.gradebook.setSortRowsBySetting(columnId, 'grade', 'ascending');
  const props = this.gradebook.getAssignmentGroupColumnSortBySetting('301');
  equal(props.settingKey, 'grade');
});

QUnit.module('Gradebook#getAssignmentGroupColumnHeaderProps', {
  createGradebook (options = {}) {
    const gradebook = createGradebook({
      group_weighting_scheme: 'percent',
      ...options
    });
    gradebook.setAssignmentGroups({
      301: { name: 'Assignments', group_weight: 40 },
      302: { name: 'Homework', group_weight: 60 }
    });
    return gradebook;
  }
});

test('includes properties from the assignment group', function () {
  const props = this.createGradebook().getAssignmentGroupColumnHeaderProps('301');
  ok(props.assignmentGroup, 'assignmentGroup is present');
  equal(props.assignmentGroup.name, 'Assignments');
  equal(props.assignmentGroup.groupWeight, 40);
});

test('sets weightedGroups to true when assignment group weighting scheme is "percent"', function () {
  const props = this.createGradebook().getAssignmentGroupColumnHeaderProps('301');
  equal(props.weightedGroups, true);
});

test('sets weightedGroups to false when assignment group weighting scheme is not "percent"', function () {
  const options = { group_weighting_scheme: 'equal' };
  const props = this.createGradebook(options).getAssignmentGroupColumnHeaderProps('301');
  equal(props.weightedGroups, false);
});

test('includes props for the "Sort by" setting', function () {
  const props = this.createGradebook().getAssignmentGroupColumnHeaderProps('301');
  ok(props.sortBySetting, 'Sort by setting is present');
  equal(typeof props.sortBySetting.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.sortBySetting.onSortByGradeAscending, 'function', 'props include "onSortByGradeAscending"');
});

QUnit.module('Gradebook#getTotalGradeColumnSortBySetting', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.setAssignmentsLoaded(true);
    this.gradebook.setStudentsLoaded(true);
    this.gradebook.setSubmissionsLoaded(true);
  }
});

test('includes the sort direction', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.direction, 'ascending');
});

test('is not disabled when assignments, students, and submissions are loaded', function () {
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.disabled, false);
});

test('is disabled when assignments are not loaded', function () {
  this.gradebook.setAssignmentsLoaded(false);
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.disabled, true);
});

test('is disabled when students are not loaded', function () {
  this.gradebook.setStudentsLoaded(false);
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.disabled, true);
});

test('is disabled when submissions are not loaded', function () {
  this.gradebook.setSubmissionsLoaded(false);
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.disabled, true);
});

test('sets isSortColumn to true when sorting by the total grade', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.isSortColumn, true);
});

test('sets isSortColumn to false when not sorting by the total grade', function () {
  this.gradebook.setSortRowsBySetting('student', 'grade', 'ascending');
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.isSortColumn, false);
});

test('sets the onSortByGradeAscending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getTotalGradeColumnSortBySetting();

  props.onSortByGradeAscending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, 'total_grade', 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'ascending', 'parameter 3 is the sort direction');
});

test('sets the onSortByGradeDescending function', function () {
  this.stub(this.gradebook, 'setSortRowsBySetting');
  const props = this.gradebook.getTotalGradeColumnSortBySetting();

  props.onSortByGradeDescending();
  equal(this.gradebook.setSortRowsBySetting.callCount, 1);

  const [columnId, settingKey, direction] = this.gradebook.setSortRowsBySetting.getCall(0).args;
  equal(columnId, 'total_grade', 'parameter 1 is the sort columnId');
  equal(settingKey, 'grade', 'parameter 2 is the sort settingKey');
  equal(direction, 'descending', 'parameter 3 is the sort direction');
});

test('includes the sort settingKey', function () {
  this.gradebook.setSortRowsBySetting('total_grade', 'grade', 'ascending');
  const props = this.gradebook.getTotalGradeColumnSortBySetting();
  equal(props.settingKey, 'grade');
});

QUnit.module('Gradebook#getTotalGradeColumnGradeDisplayProps', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.togglePointsOrPercentTotals = () => {}
  }
});

test('currentDisplay is set to percentage when show_total_grade_as_points is undefined or false', function () {
  equal(this.gradebook.options.show_total_grade_as_points, undefined);
  equal(this.gradebook.getTotalGradeColumnGradeDisplayProps().currentDisplay, 'percentage');

  this.gradebook.options.show_total_grade_as_points = false;

  equal(this.gradebook.getTotalGradeColumnGradeDisplayProps().currentDisplay, 'percentage');
});

test('currentDisplay is set to percentage when show_total_grade_as_points is true', function () {
  this.gradebook.options.show_total_grade_as_points = true;

  equal(this.gradebook.getTotalGradeColumnGradeDisplayProps().currentDisplay, 'points');
});

test('onSelect is set to the togglePointsOrPercentTotals function', function () {
  equal(this.gradebook.getTotalGradeColumnGradeDisplayProps().onSelect, this.gradebook.togglePointsOrPercentTotals);
});

test('disabled is true when submissions have not loaded yet', function () {
  this.gradebook.setSubmissionsLoaded(false);

  ok(this.gradebook.getTotalGradeColumnGradeDisplayProps().disabled);
});

test('disabled is true when submissions have not loaded yet', function () {
  this.gradebook.setSubmissionsLoaded(true);

  notOk(this.gradebook.getTotalGradeColumnGradeDisplayProps().disabled);
});

test('hidden is false when weightedGroups returns false', function () {
  notOk(this.gradebook.getTotalGradeColumnGradeDisplayProps().hidden);
});

test('hidden is true when weightedGroups returns true', function () {
  this.gradebook.options.group_weighting_scheme = 'percent';

  ok(this.gradebook.getTotalGradeColumnGradeDisplayProps().hidden);
});

QUnit.module('Gradebook#getColumnPositionById', {
  setupGradebook (columns) {
    const gradebook = createGradebook();
    gradebook.grid = {
      getColumns () {
        return columns;
      }
    };

    return gradebook;
  },

  setup () {
    const columns = [
      { id: 'one' },
      { id: 'two' },
      { id: 'three' }
    ];

    this.gradebook = this.setupGradebook(columns);

    this.alternateColumnList = [
      { id: 'two' },
      { id: 'three' },
      { id: 'one' },
    ]
  }
});

test('returns the position of the column in the specified array', function () {
  strictEqual(this.gradebook.getColumnPositionById('two', this.alternateColumnList), 0);
  strictEqual(this.gradebook.getColumnPositionById('three', this.alternateColumnList), 1);
  strictEqual(this.gradebook.getColumnPositionById('one', this.alternateColumnList), 2);
});

test("returns the position of the column from the grid's columns when not specified an array", function () {
  strictEqual(this.gradebook.getColumnPositionById('two'), 1);
  strictEqual(this.gradebook.getColumnPositionById('three'), 2);
  strictEqual(this.gradebook.getColumnPositionById('one'), 0);
});

test('returns null when no column matches the column id passed in', function () {
  strictEqual(this.gradebook.getColumnPositionById('four'), null);
});

QUnit.module('Gradebook#isColumnFrozen', {
  setupGradebook (columns) {
    const gradebook = createGradebook();
    gradebook.grid = {
      columns: [],

      getColumns () {
        return this.columns;
      },

      setColumns (incomingColumns) {
        this.columns = incomingColumns;
      }
    };
    gradebook.grid.setColumns(columns);
    this.stub(gradebook, 'getFrozenColumnCount').returns(1);

    return gradebook;
  },

  setup () {
    const columns = [
      { id: 'one' },
      { id: 'two' },
      { id: 'three' },
      { id: 'total_grade' },
      { id: 'five'}
    ];

    this.gradebook = this.setupGradebook(columns);
    this.gradebook.parentColumns = [
      { id: 'one' },
      { id: 'total_grade' }
    ]
  }
});

test('returns true when the column is frozen', function () {
  strictEqual(this.gradebook.isColumnFrozen('one'), true);
  strictEqual(this.gradebook.isColumnFrozen('total_grade'), true);
});

test('returns false when the column is not frozen', function () {
  strictEqual(this.gradebook.isColumnFrozen('two'), false);
  strictEqual(this.gradebook.isColumnFrozen('three'), false);
});

QUnit.module('Gradebook#freezeTotalGradeColumn', {
  setupGradebook () {
    const gradebook = createGradebook();
    gradebook.grid = {
      columns: [],

      getColumns () {
        return this.columns;
      },

      setColumns (incomingColumns) {
        this.columns = incomingColumns;
      },

      setNumberOfColumnsToFreeze () {},

      invalidate () {}
    };

    this.stub(gradebook.grid, 'setNumberOfColumnsToFreeze');
    this.stub(gradebook, 'updateColumnHeaders');

    const columns = [
      { id: 'one' },
      { id: 'student' },
      { id: 'three'},
      { id: 'aggregate_1' },
      { id: 'total_grade' },
    ];
    gradebook.grid.setColumns(columns);
    gradebook.allAssignmentColumns = [
      {
        id: 'three',
        object: {
          submission_types: []
        }
      }
    ]
    gradebook.parentColumns = [
      { id: 'one' },
      { id: 'student' },
    ];
    gradebook.aggregateColumns = [
      { id: 'aggregate_1' },
      { id: 'total_grade' }
    ];
    gradebook.customColumns = [];

    return gradebook;
  },

  setup () {
    this.gradebook = this.setupGradebook();
  }
});

test('freezes the total_grade column logically', function () {
  strictEqual(this.gradebook.isColumnFrozen('total_grade'), false);

  this.gradebook.freezeTotalGradeColumn();

  strictEqual(this.gradebook.isColumnFrozen('total_grade'), true);
});

test('freezes the total_grade column "physically" by telling the grid how many columns to freeze', function () {
  this.gradebook.freezeTotalGradeColumn();

  strictEqual(this.gradebook.grid.setNumberOfColumnsToFreeze.getCall(0).args[0], 3);
});

test('puts the total_grade column to the right of the student column', function () {
  this.gradebook.freezeTotalGradeColumn();

  strictEqual(this.gradebook.getColumnPositionById('total_grade'), 2);
});

test('re-renders column headers after reordering is done', function () {
  this.gradebook.freezeTotalGradeColumn();

  strictEqual(this.gradebook.updateColumnHeaders.callCount, 1);
});

test('preserves the order of any existing movable columns that have been dragged elsewhere', function () {
  const newColumnOrder = [
    { id: 'student' },
    { id: 'one' },
    { id: 'aggregate_1' },
    { id: 'total_grade' },
    { id: 'three' },
  ];
  this.gradebook.grid.setColumns(newColumnOrder);
  const expectedColumnOrder = ['student', 'total_grade', 'one', 'aggregate_1', 'three'];

  this.gradebook.freezeTotalGradeColumn();

  deepEqual(this.gradebook.grid.getColumns().map(item => item.id), expectedColumnOrder);
});

QUnit.module('Gradebook#updateFrozenColumnsAndRenderGrid', {
  setupGradebook () {
    const gradebook = createGradebook();
    gradebook.grid = {
      columns: [],

      getColumns () {
        return this.columns;
      },

      setColumns (incomingColumns) {
        this.columns = incomingColumns;
      },

      setNumberOfColumnsToFreeze () {},
      invalidate () {},
    };

    this.stub(gradebook.grid, 'setNumberOfColumnsToFreeze');
    this.stub(gradebook.grid, 'invalidate');
    this.stub(gradebook, 'updateColumnHeaders');

    this.totalGradeColumn = { id: 'total_grade' };

    gradebook.grid.setColumns([
      { id: 'one' },
      { id: 'student' },
      this.totalGradeColumn,
      { id: 'three'},
      { id: 'aggregate_1' },
    ]);
    gradebook.allAssignmentColumns = [
      {
        id: 'three',
        object: {
          submission_types: []
        }
      }
    ]
    gradebook.parentColumns = [
      { id: 'one' },
      { id: 'student' },
      this.totalGradeColumn,
    ];
    gradebook.aggregateColumns = [
      { id: 'aggregate_1' },
    ];
    gradebook.customColumns = [];

    return gradebook;
  },

  setup () {
    this.gradebook = this.setupGradebook();
  }
});

test('updates the frozen column count', function () {
  this.gradebook.updateFrozenColumnsAndRenderGrid();

  strictEqual(this.gradebook.grid.setNumberOfColumnsToFreeze.callCount, 1);
});

test('updates the frozen column count to the number of parentColumns', function () {
  this.gradebook.updateFrozenColumnsAndRenderGrid();

  strictEqual(this.gradebook.grid.setNumberOfColumnsToFreeze.firstCall.args[0], 3);
});

test('sets the columns of the grid', function () {
  const setColumnsSpy = this.spy(this.gradebook.grid, 'setColumns');

  this.gradebook.updateFrozenColumnsAndRenderGrid();

  strictEqual(setColumnsSpy.callCount, 1);
});

test('sets the columns of the grid to the provided columns', function () {
  const setColumnsSpy = this.spy(this.gradebook.grid, 'setColumns');
  const newColumns = [
    { id: 'one' },
    { id: 'two' },
    { id: 'three' },
    { id: 'four' },
    { id: 'five' },
  ];

  this.gradebook.updateFrozenColumnsAndRenderGrid(newColumns);

  deepEqual(setColumnsSpy.firstCall.args[0], newColumns);
});

test('sets the columns of the grid to the return value of getVisibleGradeGridColumns if no args given', function () {
  const setColumnsSpy = this.spy(this.gradebook.grid, 'setColumns');
  const { parentColumns, allAssignmentColumns, aggregateColumns } = this.gradebook;
  const expectedColumns = [...parentColumns, ...allAssignmentColumns, ...aggregateColumns];

  this.gradebook.updateFrozenColumnsAndRenderGrid();

  deepEqual(setColumnsSpy.firstCall.args[0], expectedColumns);
});

test('invalidates the grid, forcing a re-render', function () {
  this.gradebook.updateFrozenColumnsAndRenderGrid();

  strictEqual(this.gradebook.grid.invalidate.callCount, 1);
});

test('re-renders column headers', function () {
  this.gradebook.updateFrozenColumnsAndRenderGrid();

  strictEqual(this.gradebook.updateColumnHeaders.callCount, 1);
});

QUnit.module('Gradebook#moveTotalGradeColumnToEnd', {
  setupGradebook () {
    const gradebook = createGradebook();
    gradebook.grid = {
      columns: [],

      getColumns () {
        return this.columns;
      },

      setColumns (incomingColumns) {
        this.columns = incomingColumns;
      },

      setNumberOfColumnsToFreeze () {},

      invalidate () {}
    };

    this.stub(gradebook.grid, 'setNumberOfColumnsToFreeze');
    this.stub(gradebook, 'updateColumnHeaders');
    this.totalGradeColumn = { id: 'total_grade' };

    gradebook.grid.setColumns([
      { id: 'one' },
      { id: 'student' },
      this.totalGradeColumn,
      { id: 'three'},
      { id: 'aggregate_1' },
    ]);
    gradebook.allAssignmentColumns = [
      {
        id: 'three',
        object: {
          submission_types: []
        }
      }
    ]
    gradebook.parentColumns = [
      { id: 'one' },
      { id: 'student' },
      this.totalGradeColumn,
    ];
    gradebook.aggregateColumns = [
      { id: 'aggregate_1' },
    ];
    gradebook.customColumns = [];

    return gradebook;
  },

  setup () {
    this.gradebook = this.setupGradebook();
  }
});

test('unfreezes the total_grade column', function () {
  strictEqual(this.gradebook.isColumnFrozen('total_grade'), true);

  this.gradebook.moveTotalGradeColumnToEnd();

  strictEqual(this.gradebook.isColumnFrozen('total_grade'), false);
  strictEqual(this.gradebook.grid.setNumberOfColumnsToFreeze.firstCall.args[0], 2);
});

test('puts the total_grade column at the end', function () {
  strictEqual(this.gradebook.getColumnPositionById('total_grade'), 2);

  this.gradebook.moveTotalGradeColumnToEnd();

  strictEqual(this.gradebook.getColumnPositionById('total_grade'), 4);
});

test('re-renders column headers after reordering is done', function () {
  this.gradebook.moveTotalGradeColumnToEnd();

  strictEqual(this.gradebook.updateColumnHeaders.callCount, 1);
});

test('puts the total_grade column at the end if the user dragged it elsewhere but did not freeze it', function () {
  const { parentColumns, allAssignmentColumns, aggregateColumns } = this.gradebook;
  parentColumns.splice(2, 1);

  const newColumnLayout = parentColumns.concat(Array(this.totalGradeColumn))
    .concat(allAssignmentColumns).concat(aggregateColumns);

  // The total_grade column lives either in parentColumns or aggregateColumns but when it is in
  // aggregateColumns it can be dragged around internal to the grid without syncing back with
  // aggregateColumns.  This simulates that.
  aggregateColumns.push(this.totalGradeColumn);

  this.gradebook.grid.setColumns(newColumnLayout);
  this.gradebook.moveTotalGradeColumnToEnd();

  strictEqual(this.gradebook.getColumnPositionById('total_grade'), 4);
});

test('preserves the order of any existing movable columns that have been dragged elsewhere', function () {
  const newColumnOrder = [
    { id: 'student' },
    { id: 'one' },
    { id: 'aggregate_1' },
    { id: 'total_grade' },
    { id: 'three' },
  ];
  this.gradebook.grid.setColumns(newColumnOrder);
  const expectedColumnOrder = ['student', 'one', 'aggregate_1', 'three', 'total_grade'];

  this.gradebook.moveTotalGradeColumnToEnd();

  deepEqual(this.gradebook.grid.getColumns().map(item => item.id), expectedColumnOrder);
});

QUnit.module('Gradebook#getTotalGradeColumnPositionProps', {
  setup () {
    const parentColumns = [
      { id: 'student' },
    ];
    const assignmentColumns = [
      { id: 'assignment_1' }
    ];
    const aggregateColumns = [
      { id: 'assignment_group_1' }
    ];

    this.totalColumn = { id: 'total_grade' };

    this.gradebook = createGradebook();
    this.gradebook.parentColumns = parentColumns;
    this.gradebook.assignmentColumns = assignmentColumns;
    this.gradebook.aggregateColumns = aggregateColumns;
    this.gradebook.grid = {
      getColumns () {
        return parentColumns.concat(assignmentColumns).concat(aggregateColumns);
      }
    }
  }
});

test('isInFront is true if the total_grade column is frozen', function () {
  this.gradebook.parentColumns.push(this.totalColumn);

  strictEqual(this.gradebook.getTotalGradeColumnPositionProps().isInFront, true);
});

test('isInFront is false if the total_grade column is not frozen', function () {
  strictEqual(this.gradebook.getTotalGradeColumnPositionProps().isInFront, false);
});

test('isInFront is false if the total_grade column is not frozen even if it is in first place', function () {
  const { totalColumn, gradebook: { parentColumns, assignmentColumns, aggregateColumns } } = this;
  this.stub(this.gradebook.grid, 'getColumns').returns(
    [totalColumn, ...parentColumns, ...assignmentColumns, ...aggregateColumns]
  )

  strictEqual(this.gradebook.getTotalGradeColumnPositionProps().isInFront, false);
});

test('isInBack is true if the total_grade column is the last column', function () {
  this.gradebook.aggregateColumns.push(this.totalColumn);

  strictEqual(this.gradebook.getTotalGradeColumnPositionProps().isInBack, true);
});

test('isInBack is false if the total_grade column is not the last column', function () {
  this.gradebook.aggregateColumns.unshift(this.totalColumn);

  strictEqual(this.gradebook.getTotalGradeColumnPositionProps().isInBack, false);
});

test('onMoveToFront calls freezeTotalGradeColumn', function () {
  this.clock = sinon.useFakeTimers()
  this.stub(this.gradebook, 'freezeTotalGradeColumn');

  this.gradebook.getTotalGradeColumnPositionProps().onMoveToFront();

  strictEqual(this.gradebook.freezeTotalGradeColumn.callCount, 0, 'does not call it right away');

  this.clock.tick(10);
  strictEqual(this.gradebook.freezeTotalGradeColumn.callCount, 1, 'but after a 10ms timeout');

  this.clock.restore();
});

test('onMoveToBack calls @moveTotalGradeColumnToEnd', function () {
  this.clock = sinon.useFakeTimers()
  this.stub(this.gradebook, 'moveTotalGradeColumnToEnd');

  this.gradebook.getTotalGradeColumnPositionProps().onMoveToBack();

  strictEqual(this.gradebook.moveTotalGradeColumnToEnd.callCount, 0, 'does not call it right away');

  this.clock.tick(10);
  strictEqual(this.gradebook.moveTotalGradeColumnToEnd.callCount, 1, 'but after a 10ms timeout');

  this.clock.restore();
});

QUnit.module('Gradebook#getTotalGradeColumnHeaderProps', {
  createGradebook (options = {}) {
    const gradebook = createGradebook({
      group_weighting_scheme: 'percent',
      ...options
    });
    gradebook.setAssignmentGroups({
      301: { name: 'Assignments', group_weight: 40 },
      302: { name: 'Homework', group_weight: 60 }
    });
    gradebook.grid = {
      getColumns: () => []
    }

    return gradebook;
  }
});

test('includes props for the "Sort by" setting', function () {
  const props = this.createGradebook().getTotalGradeColumnHeaderProps();
  ok(props.sortBySetting, 'Sort by setting is present');
  equal(typeof props.sortBySetting.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.sortBySetting.onSortByGradeAscending, 'function', 'props include "onSortByGradeAscending"');
});

test('includes props for the "Grade Display" settings', function () {
  const props = this.createGradebook().getTotalGradeColumnHeaderProps();
  ok(props.gradeDisplay, 'Grade Display setting is present');
  equal(typeof props.gradeDisplay.disabled, 'boolean', 'props include "disabled"');
  equal(typeof props.gradeDisplay.hidden, 'boolean', 'props include "hidden"');
  equal(typeof props.gradeDisplay.currentDisplay, 'string', 'props include "currentDisplay"');
  equal(typeof props.gradeDisplay.onSelect, 'function', 'props include "onSelect"');
});

test('includes props for the "Position" settings', function () {
  const props = this.createGradebook().getTotalGradeColumnHeaderProps();
  ok(props.position, 'Position setting is present');
  strictEqual(typeof props.position.isInFront, 'boolean', 'props include "isInFront"');
  strictEqual(typeof props.position.isInBack, 'boolean', 'props include "isInBack"');
  strictEqual(typeof props.position.onMoveToFront, 'function', 'props include "onMoveToFront"');
  strictEqual(typeof props.position.onMoveToBack, 'function', 'props include "onMoveToBack"');
});

QUnit.module('Gradebook#setStudentDisplay', {
  createGradebook (multipleSections = false) {
    const options = {};

    if (multipleSections) {
      options.sections = [
        { id: '1000', name: 'section1000' },
        { id: '2000', name: 'section2000' }
      ];
    }

    return createGradebook(options);
  },

  createStudent () {
    return {
      name: 'test student',
      sortable_name: 'student, test',
      sections: ['1000'],
      sis_user_id: 'sis_user_id',
      login_id: 'canvas_login_id',
      enrollments: [{grades: {html_url: 'http://example.url/'}}]
    };
  },

  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: { context_id: 10 },
    });
  },

  teardown () {
    fakeENV.teardown();
  }
});

test('sets a display_name prop on the given student with their name', function () {
  const gradebook = this.createGradebook();
  const student = this.createStudent();

  gradebook.setStudentDisplay(student);

  ok(student.display_name.includes(student.name));
});

test('when secondaryInfo is set as "section", sets display_name with sections', function () {
  const gradebook = this.createGradebook(true);
  const student = this.createStudent();

  gradebook.setSelectedSecondaryInfo('section', true);
  gradebook.setStudentDisplay(student);

  ok(student.display_name.includes(student.sections[0]));
});

test('when secondaryInfo is set as "sis_id", sets display_name with sis id', function () {
  const gradebook = this.createGradebook(true);
  const student = this.createStudent();

  gradebook.setSelectedSecondaryInfo('sis_id', true);
  gradebook.setStudentDisplay(student);

  ok(student.display_name.includes(student.sis_user_id));
});

test('when secondaryInfo is set as "login_id", sets display_name with login id', function () {
  const gradebook = this.createGradebook(true);
  const student = this.createStudent();

  gradebook.setSelectedSecondaryInfo('login_id', true);
  gradebook.setStudentDisplay(student);

  ok(student.display_name.includes(student.login_id));
});

test('when secondaryInfo is set as "none", sets display_name without other values', function () {
  const gradebook = this.createGradebook(true);
  const student = this.createStudent();

  gradebook.setSelectedSecondaryInfo('none', true);
  gradebook.setStudentDisplay(student);

  notOk(student.display_name.includes(student.sections[0]));
  notOk(student.display_name.includes(student.sis_user_id));
  notOk(student.display_name.includes(student.login_id));
});

test('when primaryInfo is set as "first_last", sets display_name with student name', function () {
  const gradebook = this.createGradebook();
  const student = this.createStudent();

  gradebook.setSelectedPrimaryInfo('first_last', true);
  gradebook.setStudentDisplay(student);

  ok(student.display_name.includes(student.name));
});

test('when primaryInfo is set as "last_first", sets display_name with student sortable_name', function () {
  const gradebook = this.createGradebook();
  const student = this.createStudent();

  gradebook.setSelectedPrimaryInfo('last_first', true);
  gradebook.setStudentDisplay(student);

  ok(student.display_name.includes(student.sortable_name));
});

test('when primaryInfo is set as "anonymous", sets display_name without other values', function () {
  const gradebook = this.createGradebook();
  const student = this.createStudent();

  gradebook.setSelectedPrimaryInfo('anonymous', true);
  gradebook.setStudentDisplay(student);

  notOk(student.display_name.includes(student.name));
  notOk(student.display_name.includes(student.sortable_name));
});

QUnit.module('Gradebook#setSortRowsBySetting');

test('sets the "sort rows by" setting', function () {
  const gradebook = createGradebook();
  gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending');
  const sortRowsBySetting = gradebook.getSortRowsBySetting();
  equal(sortRowsBySetting.columnId, 'assignment_201');
  equal(sortRowsBySetting.settingKey, 'grade');
  equal(sortRowsBySetting.direction, 'descending');
});

test('sorts the grid rows after updating the setting', function () {
  const gradebook = createGradebook();
  this.stub(gradebook, 'sortGridRows').callsFake(() => {
    const sortRowsBySetting = gradebook.getSortRowsBySetting();
    equal(sortRowsBySetting.columnId, 'assignment_201', 'sortRowsBySetting.columnId was set beforehand');
    equal(sortRowsBySetting.settingKey, 'grade', 'sortRowsBySetting.settingKey was set beforehand');
    equal(sortRowsBySetting.direction, 'descending', 'sortRowsBySetting.direction was set beforehand');
  });
  gradebook.setSortRowsBySetting('assignment_201', 'grade', 'descending');
});

QUnit.module('Gradebook#getFrozenColumnCount');

test('returns number of columns in frozen section', function () {
  const gradebook = createGradebook();
  gradebook.parentColumns = [{ id: 'student' }, { id: 'secondary_identifier' }];
  gradebook.customColumns = [{ id: 'custom_col_1' }];
  equal(gradebook.getFrozenColumnCount(), 3);
});

QUnit.module('Gradebook#sortRowsWithFunction', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.rows = [
      { id: '3', sortable_name: 'Z Lastington', someProperty: false },
      { id: '4', sortable_name: 'A Firstington', someProperty: true }
    ];
    this.gradebook.grid = { // stubs for slickgrid
      removeCellCssStyles () {},
      addCellCssStyles () {},
      invalidate () {}
    };
  },
  sortFn (row) { return !!row.someProperty; }
});

test('returns two objects in the rows collection', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn);

  equal(this.gradebook.rows.length, 2);
});

test('sorts with a passed in function', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn);
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.id, '4', 'when fn is true, order first');
  equal(secondRow.id, '3', 'when fn is false, order second');
});

test('sorts by descending when asc is false', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn, { asc: false });
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.id, '3', 'when fn is false, order first');
  equal(secondRow.id, '4', 'when fn is true, order second');
});

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.sortRowsWithFunction(this.sortFn);
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.sortable_name, 'A Firstington', 'A Firstington sorts first');
  equal(secondRow.sortable_name, 'Z Lastington', 'Z Lastington sorts second');
});

QUnit.module('Gradebook#missingSort', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.rows = [
      { id: '3', sortable_name: 'Z Lastington', assignment_201: { workflow_state: 'graded' }},
      { id: '4', sortable_name: 'A Firstington', assignment_201: { workflow_state: 'unsubmitted' }}
    ];
    this.gradebook.grid = { // stubs for slickgrid
      removeCellCssStyles () {},
      addCellCssStyles () {},
      invalidate () {}
    };
  }
});

test('sorts by missing', function () {
  this.gradebook.missingSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.id, '4', 'when missing is true, order first');
  equal(secondRow.id, '3', 'when missing is false, order second');
});

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.rows = [
    { id: '1', sortable_name: 'Z Last Graded', assignment_201: { workflow_state: 'graded' }},
    { id: '3', sortable_name: 'Z Last Missing', assignment_201: { workflow_state: 'unsubmitted' }},
    { id: '2', sortable_name: 'A First Graded', assignment_201: { workflow_state: 'graded' }},
    { id: '4', sortable_name: 'A First Missing', assignment_201: { workflow_state: 'unsubmitted' }}
  ];
  this.gradebook.missingSort('assignment_201');
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.rows;

  equal(firstRow.sortable_name, 'A First Missing', 'A First Missing sorts first');
  equal(secondRow.sortable_name, 'Z Last Missing', 'Z Last Missing sorts second');
  equal(thirdRow.sortable_name, 'A First Graded', 'A First Graded sorts third');
  equal(fourthRow.sortable_name, 'Z Last Graded', 'Z Last Graded sorts fourth');
});

test('when no submission is found, it is missing', function () {
  // Since SubmissionStateMap always creates an assignment key even when there
  // is no corresponding submission, the correct way to test this is to have a
  // key for the assignment with a missing criteria key (e.g. `workflow_state`)
  this.gradebook.rows = [
    { id: '3', sortable_name: 'Z Lastington', assignment_201: { workflow_state: 'graded'}},
    { id: '4', sortable_name: 'A Firstington', assignment_201: {} }
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.id, '4', 'missing assignment sorts first');
  equal(secondRow.id, '3', 'graded assignment sorts second');
})

QUnit.module('Gradebook#lateSort', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.rows = [
      { id: '3', sortable_name: 'Z Lastington', assignment_201: { late: false }},
      { id: '4', sortable_name: 'A Firstington', assignment_201: { late: true }}
    ];
    this.gradebook.grid = { // stubs for slickgrid
      removeCellCssStyles () {},
      addCellCssStyles () {},
      invalidate () {}
    };
  }
});

test('sorts by late', function () {
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.id, '4', 'when late is true, order first');
  equal(secondRow.id, '3', 'when late is false, order second');
});

test('relies on localeSort when rows have equal sorting criteria results', function () {
  this.gradebook.rows = [
    { id: '1', sortable_name: 'Z Last Not Late', assignment_201: { late: false }},
    { id: '3', sortable_name: 'Z Last Late', assignment_201: { late: true }},
    { id: '2', sortable_name: 'A First Not Late', assignment_201: { late: false }},
    { id: '4', sortable_name: 'A First Late', assignment_201: { late: true }}
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow, thirdRow, fourthRow] = this.gradebook.rows;

  equal(firstRow.sortable_name, 'A First Late', 'A First Late sorts first');
  equal(secondRow.sortable_name, 'Z Last Late', 'Z Last Late sorts second');
  equal(thirdRow.sortable_name, 'A First Not Late', 'A First Not Late sorts third');
  equal(fourthRow.sortable_name, 'Z Last Not Late', 'Z Last Not Late sorts fourth');
});

test('when no submission is found, it is not late', function () {
  // Since SubmissionStateMap always creates an assignment key even when there
  // is no corresponding submission, the correct way to test this is to have a
  // key for the assignment with a missing criteria key (e.g. `late`)
  this.gradebook.rows = [
    { id: '3', sortable_name: 'Z Lastington', assignment_201: {}},
    { id: '4', sortable_name: 'A Firstington', assignment_201: { late: true }}
  ];
  this.gradebook.lateSort('assignment_201');
  const [firstRow, secondRow] = this.gradebook.rows;

  equal(firstRow.id, '4', 'when late is true, order first');
  equal(secondRow.id, '3', 'when no submission is found, order second');
});

QUnit.module('Gradebook#getSelectedEnrollmentFilters', {
  setup () {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: { context_id: 10 },
    });
  },

  teardown () {
    fakeENV.teardown();
  }
});

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
    fakeENV.setup({
      GRADEBOOK_OPTIONS: { context_id: 10 },
    });
  },

  teardown () {
    fakeENV.teardown();
  }
});

test('changes the value of @getSelectedEnrollmentFilters', function () {
  const gradebook = createGradebook();

  for (let i = 0; i < 2; i++) {
    StudentRowHeaderConstants.enrollmentFilterKeys.forEach((key) => {
      const previousValue = gradebook.getSelectedEnrollmentFilters().includes(key);
      gradebook.toggleEnrollmentFilter(key, true);
      const newValue = gradebook.getSelectedEnrollmentFilters().includes(key);
      notEqual(previousValue, newValue);
    });
  }
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
  const ajaxJSONStub = this.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  equal(ajaxJSONStub.firstCall.args[0], options.settings_update_url);
});

test('calls ajaxJSON as a PUT request', function () {
  const gradebook = createGradebook();
  const ajaxJSONStub = this.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  equal(ajaxJSONStub.firstCall.args[1], 'PUT');
});

test('calls ajaxJSON with default gradebook_settings', function () {
  const expectedSettings = {
    show_concluded_enrollments: true,
    show_inactive_enrollments: true,
    show_unpublished_assignments: true,
    sort_rows_by_column_id: 'student',
    sort_rows_by_direction: 'ascending',
    sort_rows_by_setting_key: 'sortable_name',
    student_column_display_as: 'first_last',
    student_column_secondary_info: 'none',
  };
  const gradebook = createGradebook({
    settings: {
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
  const ajaxJSONStub = this.stub($, 'ajaxJSON');
  gradebook.saveSettings();
  deepEqual(ajaxJSONStub.firstCall.args[2], { gradebook_settings: { ...expectedSettings }});
});

test('calls ajaxJSON with parameters', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'true',
      show_unpublished_assignments: 'true'
    }
  });
  const ajaxJSONStub = this.stub($, 'ajaxJSON');
  gradebook.saveSettings({
    showConcludedEnrollments: false,
    showInactiveEnrollments: false,
    showUnpublishedAssignments: false,
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
      show_concluded_enrollments: false,
      show_inactive_enrollments: false,
      show_unpublished_assignments: false,
      sort_rows_by_column_id: 'assignment_1',
      sort_rows_by_direction: 'ascending',
      sort_rows_by_setting_key: 'late',
      student_column_display_as: 'last_first',
      student_column_secondary_info: 'login_id',
    }
  });
});

test('calls successFn when response is successful', function () {
  // The requests is sent as a PUT but ajaxJSON does not play nice with
  // sinon.fakeServer's fakeHTTPMethods setting.
  this.server.respondWith('POST', this.options.settings_update_url, [
    200, { 'Content-Type': 'application/json' }, '{}'
  ]);
  const successFn = this.stub();
  const saveSettings = Gradebook.prototype.saveSettings;
  const self = {
    options: this.options,
    getEnrollmentFilters () { return {}; },
    getSelectedPrimaryInfo () { return 'first_last'; },
    getSelectedSecondaryInfo () { return 'none'; },
    getSortRowsBySetting () {
      return {
        sort_rows_by_column_id: 'student',
        sort_rows_by_direction: 'ascending',
        sort_rows_by_setting_key: 'sortable_name',
      };
    },
  };
  saveSettings.call(self, {}, successFn, null);

  strictEqual(successFn.callCount, 1);
});

test('calls errorFn when response is not successful', function () {
  // The requests is sent as a PUT but ajaxJSON does not play nice with
  // sinon.fakeServer's fakeHTTPMethods setting.
  this.server.respondWith('POST', this.options.settings_update_url, [
    401, { 'Content-Type': 'application/json' }, '{}'
  ]);
  const errorFn = this.stub();
  const saveSettings = Gradebook.prototype.saveSettings;
  const self = {
    options: this.options,
    getEnrollmentFilters () { return {}; },
    getSelectedPrimaryInfo () { return 'first_last'; },
    getSelectedSecondaryInfo () { return 'none'; },
    getSortRowsBySetting () {
      return {
        sort_rows_by_column_id: 'student',
        sort_rows_by_direction: 'ascending',
        sort_rows_by_setting_key: 'sortable_name',
      };
    },
  };
  saveSettings.call(self, {}, null, errorFn);

  strictEqual(errorFn.callCount, 1);
});

QUnit.module('Gradebook#updateColumnsAndRenderViewOptionsMenu');

test('calls setColumns with getVisibleGradeGridColumns as arguments', function () {
  const gradebook = createGradebook();
  const setColumnsStub = this.stub();
  gradebook.rows = [
    { id: '3', sortable_name: 'Z Lastington', someProperty: false },
    { id: '4', sortable_name: 'A Firstington', someProperty: true }
  ];
  gradebook.grid = { // stubs for slickgrid
    setColumns: setColumnsStub,
    getColumns: () => gradebook.rows
  };
  this.stub(gradebook, 'getVisibleGradeGridColumns').returns(gradebook.rows);
  this.stub(gradebook, 'updateColumnHeaders');
  this.stub(gradebook, 'renderViewOptionsMenu');
  gradebook.updateColumnsAndRenderViewOptionsMenu();

  strictEqual(setColumnsStub.callCount, 1);
  strictEqual(setColumnsStub.firstCall.args[0], gradebook.rows);
});

test('calls updateColumnHeaders', function () {
  const gradebook = createGradebook();
  gradebook.grid = { setColumns: () => {} };
  this.stub(gradebook, 'getVisibleGradeGridColumns');
  this.stub(gradebook, 'renderViewOptionsMenu');
  const updateColumnHeadersStub = this.stub(gradebook, 'updateColumnHeaders');
  gradebook.updateColumnsAndRenderViewOptionsMenu();

  strictEqual(updateColumnHeadersStub.callCount, 1);
});

test('calls renderViewOptionsMenu', function () {
  const gradebook = createGradebook();
  gradebook.grid = { setColumns: () => {} };
  this.stub(gradebook, 'getVisibleGradeGridColumns');
  this.stub(gradebook, 'updateColumnHeaders');
  const renderViewOptionsMenuStub = this.stub(gradebook, 'renderViewOptionsMenu');
  gradebook.updateColumnsAndRenderViewOptionsMenu();

  strictEqual(renderViewOptionsMenuStub.callCount, 1);
});

QUnit.module('Gradebook#initShowUnpublishedAssignments');

test('if unset, default to true', function () {
  const gradebook = createGradebook();
  gradebook.initShowUnpublishedAssignments(undefined);

  strictEqual(gradebook.showUnpublishedAssignments, true);
});

test('sets to true if passed "true"', function () {
  const gradebook = createGradebook();
  gradebook.initShowUnpublishedAssignments('true');

  strictEqual(gradebook.showUnpublishedAssignments, true);
});

test('sets to false if passed "false"', function () {
  const gradebook = createGradebook();
  gradebook.initShowUnpublishedAssignments('false');

  strictEqual(gradebook.showUnpublishedAssignments, false);
});

QUnit.module('Gradebook#toggleUnpublishedAssignments');

test('toggles showUnpublishedAssignments to true when currently false', function () {
  const gradebook = createGradebook();
  gradebook.showUnpublishedAssignments = false;
  this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  this.stub(gradebook, 'saveSettings');
  gradebook.toggleUnpublishedAssignments();

  strictEqual(gradebook.showUnpublishedAssignments, true);
});

test('toggles showUnpublishedAssignments to false when currently true', function () {
  const gradebook = createGradebook();
  gradebook.showUnpublishedAssignments = true;
  this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  this.stub(gradebook, 'saveSettings');
  gradebook.toggleUnpublishedAssignments();

  strictEqual(gradebook.showUnpublishedAssignments, false);
});

test('calls updateColumnsAndRenderViewOptionsMenu after toggling', function () {
  const gradebook = createGradebook();
  gradebook.showUnpublishedAssignments = true;
  const stubFn = this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu').callsFake(function () {
    strictEqual(gradebook.showUnpublishedAssignments, false);
  });
  this.stub(gradebook, 'saveSettings');
  gradebook.toggleUnpublishedAssignments();

  strictEqual(stubFn.callCount, 1);
});

test('calls saveSettings after updateColumnsAndRenderViewOptionsMenu', function () {
  const gradebook = createGradebook();
  const updateColumnsAndRenderViewOptionsMenuStub = this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  const saveSettingsStub = this.stub(gradebook, 'saveSettings');
  gradebook.toggleUnpublishedAssignments();

  sinon.assert.callOrder(updateColumnsAndRenderViewOptionsMenuStub, saveSettingsStub);
});

test('calls saveSettings with showUnpublishedAssignments', function () {
  const gradebook = createGradebook();
  gradebook.showUnpublishedAssignments = true;
  this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  const saveSettingsStub = this.stub(gradebook, 'saveSettings');
  gradebook.toggleUnpublishedAssignments();

  const { showUnpublishedAssignments } = gradebook;
  deepEqual(saveSettingsStub.firstCall.args[0], { showUnpublishedAssignments });
});

test('calls saveSettings successfully', function () {
  const server = sinon.fakeServer.create({ respondImmediately: true });
  const options = { settings_update_url: '/course/1/gradebook_settings' };
  server.respondWith('POST', options.settings_update_url, [
    200, { 'Content-Type': 'application/json' }, '{}'
  ]);

  const gradebook = createGradebook({ options });
  gradebook.showUnpublishedAssignments = true;
  this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  const saveSettingsStub = this.spy(gradebook, 'saveSettings');
  gradebook.toggleUnpublishedAssignments();

  strictEqual(saveSettingsStub.callCount, 1);
});

test('calls saveSettings and rollsback on failure', function () {
  const server = sinon.fakeServer.create({ respondImmediately: true });
  const options = { settings_update_url: '/course/1/gradebook_settings' };
  server.respondWith('POST', options.settings_update_url, [
    401, { 'Content-Type': 'application/json' }, '{}'
  ]);

  const gradebook = createGradebook({ options });
  gradebook.showUnpublishedAssignments = true;
  const stubFn = this.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu');
  stubFn.onFirstCall().callsFake(function () {
    strictEqual(gradebook.showUnpublishedAssignments, false);
  });
  stubFn.onSecondCall().callsFake(function () {
    strictEqual(gradebook.showUnpublishedAssignments, true);
  });
  gradebook.toggleUnpublishedAssignments();
  strictEqual(stubFn.callCount, 2);
});

QUnit.module('Gradebook#renderViewOptionsMenu');

test('passes showUnpublishedAssignments to props', function () {
  const gradebook = createGradebook();
  gradebook.showUnpublishedAssignments = true;
  const createElementStub = this.stub(React, 'createElement');
  this.stub(ReactDOM, 'render');
  gradebook.renderViewOptionsMenu();

  strictEqual(createElementStub.firstCall.args[1].showUnpublishedAssignments, gradebook.showUnpublishedAssignments);
});

test('passes toggleUnpublishedAssignments as onSelectShowUnpublishedAssignments to props', function () {
  const gradebook = createGradebook();
  gradebook.toggleUnpublishedAssignments = () => {};
  const createElementStub = this.stub(React, 'createElement');
  this.stub(ReactDOM, 'render');
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
  this.spy(GradeFormatHelper, 'formatGrade');
  this.gradebook.updateSubmission(this.submission);
  equal(GradeFormatHelper.formatGrade.callCount, 1);
});

test('includes submission attributes when formatting the grade', function () {
  this.spy(GradeFormatHelper, 'formatGrade');
  this.gradebook.updateSubmission(this.submission);
  const [grade, options] = GradeFormatHelper.formatGrade.getCall(0).args;
  equal(grade, '123.45', 'parameter 1 is the submission grade');
  equal(options.gradingType, 'percent', 'options.gradingType is the submission gradingType');
  strictEqual(options.delocalize, false, 'submission grades from the server are not localized');
});

test('sets the formatted grade on submission', function () {
  this.stub(GradeFormatHelper, 'formatGrade').returns('123.45%');
  this.gradebook.updateSubmission(this.submission);
  equal(this.submission.grade, '123.45%');
});

QUnit.module('Gradebook#arrangeColumnsBy', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.parentColumns = [];
    this.gradebook.customColumns = [];
    this.gradebook.makeColumnSortFn = () => () => 1;
    this.gradebook.grid = {
      getColumns () { return []; },
      setColumns () {}
    }
  }
});

test('renders the view options menu', function () {
  this.stub(this.gradebook, 'renderViewOptionsMenu');
  this.stub(this.gradebook, 'updateColumnHeaders');
  this.stub(this.gradebook.grid, 'setColumns');

  this.gradebook.arrangeColumnsBy({ sortBy: 'due_date', direction: 'ascending' }, false);

  strictEqual(this.gradebook.renderViewOptionsMenu.callCount, 1);
});

QUnit.module('Gradebook#onColumnsReordered', {
  setup () {
    this.gradebook = createGradebook();
    this.gradebook.customColumns = [];
    this.gradebook.grid = {
      getColumns () { return []; },
      setColumns () {}
    }

    this.stub(this.gradebook, 'renderViewOptionsMenu');
    this.stub(this.gradebook, 'updateColumnHeaders');
  }
});

test('re-renders the View options menu', function () {
  this.stub(this.gradebook, 'storeCustomColumnOrder');

  this.gradebook.onColumnsReordered();

  strictEqual(this.gradebook.renderViewOptionsMenu.callCount, 1);
});

test('re-renders all column headers', function () {
  this.stub(this.gradebook, 'storeCustomColumnOrder');

  this.gradebook.onColumnsReordered();

  strictEqual(this.gradebook.updateColumnHeaders.callCount, 1);
});

QUnit.module('Gradebook#initPostGradesLtis');

test('sets postGradesLtis as an array', function () {
  const self = {
    options: {
      post_grades_ltis: []
    }
  };
  Gradebook.prototype.initPostGradesLtis.apply(self);

  deepEqual(self.postGradesLtis, []);
});

test('sets postGradesLtis to conform to ActionMenu.propTypes.postGradesLtis', function () {
  const self = {
    options: {
      post_grades_ltis: [{
        id: '1',
        name: 'Pinnacle',
        onSelect () {}
      }, {
        id: '2',
        name: 'Kimono',
        onSelect () {}
      }]
    }
  };
  Gradebook.prototype.initPostGradesLtis.apply(self);

  strictEqual(ActionMenu.propTypes.postGradesLtis(self.postGradesLtis), null);
});

QUnit.module('Gradebook#getActionMenuProps', {
  setup () {
    fakeENV.setup({
      current_user_id: '1',
    });
  },

  teardown () {
    $fixtures.innerHTML = '';
    fakeENV.teardown();
  }
});

test('generates props that conform to ActionMenu.propTypes', function () {
  ReactDOM.render(<span data-component="ActionMenu"><button /></span>, $fixtures);
  const self = {
    options: {
      gradebook_is_editable: true,
      context_allows_gradebook_uploads: true,
      gradebook_import_url: 'http://example.com/import',
      currentUserId: '123',
      export_gradebook_csv_url: 'http://example.com/export',
      post_grades_feature: false,
      publish_to_sis_enabled: false
    },
    postGradesLtis: [],
    postGradesStore: {}
  };

  const props = Gradebook.prototype.getActionMenuProps.apply(self);

  Object.keys(ActionMenu.propTypes).forEach((propKey) => {
    const validator = ActionMenu.propTypes[propKey];

    strictEqual(validator(props, propKey, 'ActionMenu'), null);
  });
});

QUnit.module('Gradebook#getInitialGridDisplaySettings');

test('sets selectedPrimaryInfo based on the settings passed in', function () {
  const loadedSettings = { student_column_display_as: 'last_first' };
  const actualSettings = createGradebook({ settings: loadedSettings }).gridDisplaySettings;

  strictEqual(actualSettings.selectedPrimaryInfo, 'last_first');
});

test('sets selectedPrimaryInfo to default if no settings passed in', function () {
  const actualSettings = createGradebook().gridDisplaySettings;

  strictEqual(actualSettings.selectedPrimaryInfo, 'first_last');
});

test('sets selectedSecondaryInfo based on the settings passed in', function () {
  const loadedSettings = { student_column_secondary_info: 'login_id' };
  const actualSettings = createGradebook({ settings: loadedSettings }).gridDisplaySettings;

  strictEqual(actualSettings.selectedSecondaryInfo, 'login_id');
});

test('sets selectedSecondaryInfo to default if no settings passed in', function () {
  const actualSettings = createGradebook().gridDisplaySettings;

  strictEqual(actualSettings.selectedSecondaryInfo, 'none');
});

test('sets sortRowsBy > columnId based on the settings passed in', function () {
  const loadedSettings = { sort_rows_by_column_id: 'assignment_1' };
  const actualSettings = createGradebook({ settings: loadedSettings }).gridDisplaySettings;

  strictEqual(actualSettings.sortRowsBy.columnId, 'assignment_1');
});

test('sets sortRowsBy > columnId to default if no settings passed in', function () {
  const actualSettings = createGradebook().gridDisplaySettings;

  strictEqual(actualSettings.sortRowsBy.columnId, 'student');
});

test('sets sortRowsBy > settingKey based on the settings passed in', function () {
  const loadedSettings = { sort_rows_by_setting_key: 'grade' };
  const actualSettings = createGradebook({ settings: loadedSettings }).gridDisplaySettings;

  strictEqual(actualSettings.sortRowsBy.settingKey, 'grade');
});

test('sets sortRowsBy > settingKey to default if no settings passed in', function () {
  const actualSettings = createGradebook().gridDisplaySettings;

  strictEqual(actualSettings.sortRowsBy.settingKey, 'sortable_name');
});

test('sets sortRowsBy > Direction based on the settings passed in', function () {
  const loadedSettings = { sort_rows_by_direction: 'descending' };
  const actualSettings = createGradebook({ settings: loadedSettings }).gridDisplaySettings;

  strictEqual(actualSettings.sortRowsBy.direction, 'descending');
});

test('sets sortRowsBy > Direction to default if no settings passed in', function () {
  const actualSettings = createGradebook().gridDisplaySettings;

  strictEqual(actualSettings.sortRowsBy.direction, 'ascending');
});

test('sets showEnrollments to a default value', function () {
  const expectedSettings = {
    concluded: false,
    inactive: false,
  };
  const actualSettings = createGradebook().gridDisplaySettings;

  deepEqual(actualSettings.showEnrollments, expectedSettings);
});

test('sets showUnpublishedDisplayed to a default value', function () {
  const expectedSettings = false;
  const actualSettings = createGradebook().gridDisplaySettings;

  strictEqual(actualSettings.showUnpublishedDisplayed, expectedSettings);
});

QUnit.module('Gradebook#setSelectedPrimaryInfo', {
  setup () {
    this.gradebook = createGradebook();
    this.stub(this.gradebook, 'saveSettings');
    this.stub(this.gradebook, 'buildRows');
    this.stub(this.gradebook, 'renderStudentColumnHeader');
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

test('re-renders the header of the student name column unless asked not to do it', function () {
  this.gradebook.setSelectedPrimaryInfo('last_first', false);

  strictEqual(this.gradebook.renderStudentColumnHeader.callCount, 1);
});

QUnit.module('Gradebook#setSelectedSecondaryInfo', {
  setup () {
    this.gradebook = createGradebook();
    this.stub(this.gradebook, 'saveSettings');
    this.stub(this.gradebook, 'buildRows');
    this.stub(this.gradebook, 'renderStudentColumnHeader');
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

test('re-renders the header of the student name column unless asked not to do it', function () {
  this.gradebook.setSelectedSecondaryInfo('last_first', false);

  strictEqual(this.gradebook.renderStudentColumnHeader.callCount, 1);
});

QUnit.module('Gradebook#setSortRowsBySetting', {
  setup () {
    this.gradebook = createGradebook();
    this.stub(this.gradebook, 'saveSettings');
    this.stub(this.gradebook, 'sortGridRows');

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
    this.editorLock = {
      commitCurrentEdit () {}
    };
    this.gradebook = createGradebook();
    this.gradebook.grid = {
      getActiveCell () {
        return { row: 0, cell: 0 };
      },
      getEditorLock: () => this.editorLock
    }

    $fixtures.innerHTML = `
      <div class="slick-cell active">
        <div class="example-target"></div>
      </div>
    `;
  },

  teardown () {
    $fixtures.innerHTML = '';
    this.fixture = null;
  }
});

test('commits the current edit when clicking off the active cell', function () {
  this.spy(this.editorLock, 'commitCurrentEdit');
  this.gradebook.onGridBlur({ target: document.querySelector('body') });
  equal(this.editorLock.commitCurrentEdit.callCount, 1);
});

test('commits the current edit when clicking within the active cell', function () {
  this.spy(this.editorLock, 'commitCurrentEdit');
  this.gradebook.onGridBlur({ target: $fixtures.querySelector('.example-target') });
  equal(this.editorLock.commitCurrentEdit.callCount, 0);
});

test('does not prevent default when clicking within the active cell', function () {
  this.spy(this.editorLock, 'commitCurrentEdit');
  const returnValue = this.gradebook.onGridBlur({ target: $fixtures.querySelector('.example-target') });
  equal(typeof returnValue, 'undefined', 'jQuery event handlers prevent default when returning false');
});
