/*
 * Copyright (C) 2016 Instructure, Inc.
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

define([
  'underscore',
  'jsx/gradebook/CourseGradeCalculator'
], function (_, CourseGradeCalculator) {
  QUnit.module('CourseGradeCalculator.calculate with no submissions and no assignments', {
    setup () {
      this.submissions = [];
      this.assignmentGroups = [
        { id: 301, rules: {}, group_weight: 100, assignments: [] }
      ];
    }
  });

  test('returns a current and final score of 0 when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.score, 0, 'current score is 0 when there are no submissions');
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions');
  });

  test('includes 0 points possible when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points');
    equal(grades.final.possible, 0, 'final possible is sum of all assignment points');
  });

  test('returns a current and final score of null when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'current score cannot be calculated when there is no data');
    equal(grades.final.score, null, 'final score cannot be calculated when there is no data');
  });

  test('sets possible to 0 for current grade when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.possible, 0, 'current possible is 0 when there are no assignments');
    equal(grades.final.possible, 100, 'percent possible is 100');
  });

  QUnit.module('CourseGradeCalculator.calculate with no submissions and some assignments', {
    setup () {
      this.submissions = [];
      this.assignments = [
        { id: 201, points_possible: 10, omit_from_final_grade: false },
        { id: 202, points_possible: 5, omit_from_final_grade: false },
        { id: 203, points_possible: 20, omit_from_final_grade: false },
        { id: 204, points_possible: 0, omit_from_final_grade: false }
      ];
      this.assignmentGroups = [
        { id: 301, rules: {}, group_weight: 50, assignments: this.assignments.slice(0, 2) },
        { id: 302, rules: {}, group_weight: 50, assignments: this.assignments.slice(2, 4) }
      ];
    }
  });

  test('sets scores to 0 when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.score, 0, 'current score is 0 when there are no submissions');
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions');
  });

  test('sets all possible to 0 when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points');
    equal(grades.final.possible, 35, 'final possible is sum of all assignment points');
  });

  test('sets current score to null when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'current score cannot be calculated when all assignments are excluded');
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions');
  });

  test('sets current possible to 0 when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.possible, 0, 'current possible is 0 when no assignments have submissions');
    equal(grades.final.possible, 100, 'percent possible is 100 when submissions are counted');
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly a bug, this test is here to ensure this behavior is protected
  // until a decision is made to correct it.
  test('sets scores to null when assignment groups have no weight', function () {
    this.assignmentGroups[0].group_weight = null;
    this.assignmentGroups[1].group_weight = null;
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'assignment groups must have a defined group weight');
    equal(grades.final.score, null, 'assignment groups must have a defined group weight');
  });

  QUnit.module('CourseGradeCalculator.calculate with some assignments and submissions', {
    setup () {
      this.submissions = [
        { assignment_id: 201, score: 100 },
        { assignment_id: 202, score: 42 },
        { assignment_id: 203, score: 14 },
        { assignment_id: 204, score: 3 },
        { assignment_id: 205, score: null }
      ];
      this.assignments = [
        { id: 201, points_possible: 100, omit_from_final_grade: false },
        { id: 202, points_possible: 91, omit_from_final_grade: false },
        { id: 203, points_possible: 55, omit_from_final_grade: false },
        { id: 204, points_possible: 38, omit_from_final_grade: false },
        { id: 205, points_possible: 1000, omit_from_final_grade: false }
      ];
      this.assignmentGroups = [
        { id: 301, rules: {}, group_weight: 50, assignments: this.assignments.slice(0, 2) },
        { id: 302, rules: {}, group_weight: 50, assignments: this.assignments.slice(2, 5) }
      ];
    }
  });

  test('adds all scores for current and final grades when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.score, 159, 'current score is sum of all graded submission scores');
    equal(grades.final.score, 159, 'final score is sum of all graded submission scores');
  });

  test('excludes ungraded assignments for the current grade when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.possible, 284, 'current possible excludes points for ungraded assignments');
    equal(grades.final.possible, 1284, 'final possible includes points for ungraded assignments');
  });

  test('sets current and final scores as percentages when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, 46.31, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 37.95, 'final score is weighted using points from all assignments');
  });

  test('excludes ungraded assignments for the current grade when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('supports group weights which do not add up to exactly 100 percent', function () {
    this.assignmentGroups[0].group_weight = 5;
    this.assignmentGroups[1].group_weight = 5;
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, 46.31, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 37.95, 'final score is weighted using points from all assignments');
  });

  test('adjusts each assignment group score according to its group weight', function () {
    this.assignmentGroups[0].group_weight = 75;
    this.assignmentGroups[1].group_weight = 25;
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, 60.33, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 56.15, 'final score is weighted using points from all assignments');
  });

  test('rounds percent scores to two decimal places', function () {
    this.assignmentGroups[0].group_weight = 33.33;
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, 40.7, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 30.67, 'final score is weighted using points from all assignments');
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly a bug, this test is here to ensure this behavior is protected
  // until a decision is made to correct it.
  test('sets scores to null when assignment groups have no weight', function () {
    this.assignmentGroups[0].group_weight = null;
    this.assignmentGroups[1].group_weight = null;
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'assignment groups must have a defined group weight');
    equal(grades.final.score, null, 'assignment groups must have a defined group weight');
  });

  QUnit.module('CourseGradeCalculator.calculate with zero-point assignments', {
    setup () {
      this.submissions = [
        { assignment_id: 201, score: 10 },
        { assignment_id: 202, score: 5 },
        { assignment_id: 203, score: 20 },
        { assignment_id: 204, score: 0 }
      ];
      this.assignments = [
        { id: 201, points_possible: 0, omit_from_final_grade: false },
        { id: 202, points_possible: 0, omit_from_final_grade: false },
        { id: 203, points_possible: 0, omit_from_final_grade: false },
        { id: 204, points_possible: 0, omit_from_final_grade: false }
      ];
      this.assignmentGroups = [
        { id: 301, rules: {}, group_weight: 50, assignments: this.assignments.slice(0, 2) },
        { id: 302, rules: {}, group_weight: 50, assignments: this.assignments.slice(2, 4) }
      ];
    }
  });

  test('adds all scores for current and final grades when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.score, 35, 'current score is sum of all submission scores');
    equal(grades.final.score, 35, 'final score is sum of all submission scores');
  });

  test('sets all possible to 0 when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points');
    equal(grades.final.possible, 0, 'final possible is sum of all assignment points');
  });

  test('sets scores to null when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'current score cannot be calculated without points possible');
    equal(grades.final.score, null, 'final score cannot be calculated without points possible');
  });

  test('sets current possible to 0 when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points total 0');
    equal(grades.final.possible, 100, 'percent possible is 100 when submissions are counted');
  });

  QUnit.module('CourseGradeCalculator.calculate with only ungraded submissions', {
    setup () {
      this.submissions = [
        { assignment_id: 201, score: null },
        { assignment_id: 202, score: null },
        { assignment_id: 203, score: null }
      ];
      const assignments = [
        { id: 201, points_possible: 5, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false },
        { id: 203, points_possible: 20, omit_from_final_grade: false }
      ];
      this.assignmentGroups = [
        { id: 301, group_weight: 100, rules: {}, assignments }
      ];
    }
  });

  test('sets current score to 0 when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.current.score, 0, 'current score is 0 points when all submissions are excluded');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points are excluded');
  });

  test('sets final score to 0 when weighting scheme is points', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'points');
    equal(grades.final.score, 0, 'final score is 0 points when all submissions are excluded');
    equal(grades.final.possible, 35, 'final possible is sum of all assignment points');
  });

  test('sets current score to null when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'current score cannot be calculated when all submissions are excluded');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points are excluded');
  });

  test('sets final score to null when weighting scheme is percent', function () {
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.final.score, 0, 'final score cannot be calculated when all submissions are excluded');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('sets scores to 0 when weighting scheme is percent and group weight is not defined', function () {
    this.assignmentGroups[0].group_weight = null;
    const grades = CourseGradeCalculator.calculate(this.submissions, this.assignmentGroups, 'percent');
    equal(grades.current.score, null, 'current score cannot be calculated without group weight');
    equal(grades.final.score, null, 'final score cannot be calculated without group weight');
  });
});
