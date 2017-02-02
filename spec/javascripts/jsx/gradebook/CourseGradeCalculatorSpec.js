/*
 * Copyright (C) 2016 - 2017 Instructure, Inc.
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
], (_, CourseGradeCalculator) => {
  let submissions;
  let assignments;
  let assignmentGroups;
  let gradingPeriodSet;
  let gradingPeriods;
  let effectiveDueDates;

  function calculateWithoutGradingPeriods (weightingScheme) {
    return CourseGradeCalculator.calculate(
      submissions, assignmentGroups, weightingScheme
    );
  }

  function calculateWithGradingPeriods (weightingScheme) {
    return CourseGradeCalculator.calculate(
      submissions, assignmentGroups, weightingScheme, gradingPeriodSet, effectiveDueDates
    );
  }

  QUnit.module('CourseGradeCalculator.calculate with no submissions and no assignments', {
    setup () {
      submissions = [];
      assignmentGroups = [
        { id: 301, rules: {}, group_weight: 100, assignments: [] }
      ];
    }
  });

  test('includes assignment group grades', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.assignmentGroups[301].current.score, 0);
    equal(grades.assignmentGroups[301].final.score, 0);
    equal(grades.assignmentGroups[301].current.possible, 0);
    equal(grades.assignmentGroups[301].final.possible, 0);
  });

  test('returns a current and final score of 0 when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.score, 0, 'current score is 0 when there are no submissions');
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions');
  });

  test('includes 0 points possible when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points');
    equal(grades.final.possible, 0, 'final possible is sum of all assignment points');
  });

  test('returns a current and final score of null when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'current score cannot be calculated when there is no data');
    equal(grades.final.score, null, 'final score cannot be calculated when there is no data');
  });

  test('sets possible to 0 for current grade when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.possible, 0, 'current possible is 0 when there are no assignments');
    equal(grades.final.possible, 100, 'percent possible is 100');
  });

  test('uses a score unit of "points" when weighting scheme is not percent', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.scoreUnit, 'points');
  });

  test('uses a score unit of "percentage" when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.scoreUnit, 'percentage');
  });

  QUnit.module('CourseGradeCalculator.calculate with no submissions and some assignments', {
    setup () {
      submissions = [];
      assignments = [
        { id: 201, points_possible: 10, omit_from_final_grade: false },
        { id: 202, points_possible: 5, omit_from_final_grade: false },
        { id: 203, points_possible: 20, omit_from_final_grade: false },
        { id: 204, points_possible: 0, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, rules: {}, group_weight: 50, assignments: assignments.slice(0, 2) },
        { id: 302, rules: {}, group_weight: 50, assignments: assignments.slice(2, 4) }
      ];
    }
  });

  test('includes assignment group grades', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.assignmentGroups[301].current.score, 0);
    equal(grades.assignmentGroups[301].final.score, 0);
    equal(grades.assignmentGroups[301].current.possible, 0);
    equal(grades.assignmentGroups[301].final.possible, 15);
    equal(grades.assignmentGroups[302].current.score, 0);
    equal(grades.assignmentGroups[302].final.score, 0);
    equal(grades.assignmentGroups[302].current.possible, 0);
    equal(grades.assignmentGroups[302].final.possible, 20);
  });

  test('sets scores to 0 when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.score, 0, 'current score is 0 when there are no submissions');
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions');
  });

  test('sets all possible to 0 when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points');
    equal(grades.final.possible, 35, 'final possible is sum of all assignment points');
  });

  test('sets current score to null when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'current score cannot be calculated when all assignments are excluded');
    equal(grades.final.score, 0, 'final score is 0 when there are no submissions');
  });

  test('sets current possible to 0 when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.possible, 0, 'current possible is 0 when no assignments have submissions');
    equal(grades.final.possible, 100, 'percent possible is 100 when submissions are counted');
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('sets scores to null when assignment groups have no weight', function () {
    assignmentGroups[0].group_weight = null;
    assignmentGroups[1].group_weight = null;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'assignment groups must have a defined group weight');
    equal(grades.final.score, null, 'assignment groups must have a defined group weight');
  });

  QUnit.module('CourseGradeCalculator.calculate with some assignments and submissions', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 100 },
        { assignment_id: 202, score: 42 },
        { assignment_id: 203, score: 14 },
        { assignment_id: 204, score: 3 },
        { assignment_id: 205, score: null }
      ];
      assignments = [
        { id: 201, points_possible: 100, omit_from_final_grade: false },
        { id: 202, points_possible: 91, omit_from_final_grade: false },
        { id: 203, points_possible: 55, omit_from_final_grade: false },
        { id: 204, points_possible: 38, omit_from_final_grade: false },
        { id: 205, points_possible: 1000, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, rules: {}, group_weight: 50, assignments: assignments.slice(0, 2) },
        { id: 302, rules: {}, group_weight: 50, assignments: assignments.slice(2, 5) }
      ];
    }
  });

  test('includes assignment group grades', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.assignmentGroups[301].current.score, 142);
    equal(grades.assignmentGroups[301].final.score, 142);
    equal(grades.assignmentGroups[301].current.possible, 191);
    equal(grades.assignmentGroups[301].final.possible, 191);
    equal(grades.assignmentGroups[302].current.score, 17);
    equal(grades.assignmentGroups[302].final.score, 17);
    equal(grades.assignmentGroups[302].current.possible, 93);
    equal(grades.assignmentGroups[302].final.possible, 1093);
  });

  test('includes all assignment group grades regardless of weight', function () {
    assignmentGroups[0].group_weight = 200;
    assignmentGroups[1].group_weight = null;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 142);
    equal(grades.assignmentGroups[301].final.score, 142);
    equal(grades.assignmentGroups[301].current.possible, 191);
    equal(grades.assignmentGroups[301].final.possible, 191);
    equal(grades.assignmentGroups[302].current.score, 17);
    equal(grades.assignmentGroups[302].final.score, 17);
    equal(grades.assignmentGroups[302].current.possible, 93);
    equal(grades.assignmentGroups[302].final.possible, 1093);
  });

  test('adds all scores for current and final grades when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.score, 159, 'current score is sum of all graded submission scores');
    equal(grades.final.score, 159, 'final score is sum of all graded submission scores');
  });

  test('excludes ungraded assignments for the current grade when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.possible, 284, 'current possible excludes points for ungraded assignments');
    equal(grades.final.possible, 1284, 'final possible includes points for ungraded assignments');
  });

  test('sets current and final scores as percentages when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, 46.31, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 37.95, 'final score is weighted using points from all assignments');
  });

  test('excludes ungraded assignments for the current grade when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('up-scales group weights which do not add up to exactly 100 percent', function () {
    // 5 / (5+5) = 50%
    assignmentGroups[0].group_weight = 5;
    assignmentGroups[1].group_weight = 5;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, 46.31, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 37.95, 'final score is weighted using points from all assignments');
  });

  test('does not down-scale group weights which add up to over 100 percent', function () {
    assignmentGroups[0].group_weight = 100;
    assignmentGroups[1].group_weight = 100;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, 92.63, 'current score is effectively double the weight');
    equal(grades.final.score, 75.9, 'final score is effectively double the weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('weights each assignment group score according to its group weight', function () {
    assignmentGroups[0].group_weight = 75;
    assignmentGroups[1].group_weight = 25;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, 60.33, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 56.15, 'final score is weighted using points from all assignments');
  });

  test('rounds percent scores to two decimal places', function () {
    assignmentGroups[0].group_weight = 33.33;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, 40.7, 'current score is weighted using points from graded assignments');
    equal(grades.final.score, 30.67, 'final score is weighted using points from all assignments');
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('sets scores to null when assignment groups have no weight', function () {
    assignmentGroups[0].group_weight = null;
    assignmentGroups[1].group_weight = null;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'assignment groups must have a defined group weight');
    equal(grades.final.score, null, 'assignment groups must have a defined group weight');
  });

  QUnit.module('CourseGradeCalculator.calculate with zero-point assignments', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 10 },
        { assignment_id: 202, score: 5 },
        { assignment_id: 203, score: 20 },
        { assignment_id: 204, score: 0 }
      ];
      assignments = [
        { id: 201, points_possible: 0, omit_from_final_grade: false },
        { id: 202, points_possible: 0, omit_from_final_grade: false },
        { id: 203, points_possible: 0, omit_from_final_grade: false },
        { id: 204, points_possible: 0, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, rules: {}, group_weight: 50, assignments: assignments.slice(0, 2) },
        { id: 302, rules: {}, group_weight: 50, assignments: assignments.slice(2, 4) }
      ];
    }
  });

  test('includes all assignment group grades regardless of points possible', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 15);
    equal(grades.assignmentGroups[301].final.score, 15);
    equal(grades.assignmentGroups[301].current.possible, 0);
    equal(grades.assignmentGroups[301].final.possible, 0);
    equal(grades.assignmentGroups[302].current.score, 20);
    equal(grades.assignmentGroups[302].final.score, 20);
    equal(grades.assignmentGroups[302].current.possible, 0);
    equal(grades.assignmentGroups[302].final.possible, 0);
  });

  test('adds all scores for current and final grades when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.score, 35, 'current score is sum of all submission scores');
    equal(grades.final.score, 35, 'final score is sum of all submission scores');
  });

  test('sets all possible to 0 when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.possible, 0, 'current possible is sum of all assignment points');
    equal(grades.final.possible, 0, 'final possible is sum of all assignment points');
  });

  test('sets scores to null when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'current score cannot be calculated without points possible');
    equal(grades.final.score, null, 'final score cannot be calculated without points possible');
  });

  test('sets current possible to 0 when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points total 0');
    equal(grades.final.possible, 100, 'percent possible is 100 when submissions are counted');
  });

  QUnit.module('CourseGradeCalculator.calculate with only ungraded submissions', {
    setup () {
      submissions = [
        { assignment_id: 201, score: null },
        { assignment_id: 202, score: null },
        { assignment_id: 203, score: null }
      ];
      assignments = [
        { id: 201, points_possible: 5, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false },
        { id: 203, points_possible: 20, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, group_weight: 100, rules: {}, assignments }
      ];
    }
  });

  test('includes all assignment group grades regardless of submissions graded', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 0);
    equal(grades.assignmentGroups[301].final.score, 0);
    equal(grades.assignmentGroups[301].current.possible, 0);
    equal(grades.assignmentGroups[301].final.possible, 35);
  });

  test('sets current score to 0 when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.current.score, 0, 'current score is 0 points when all submissions are excluded');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points are excluded');
  });

  test('sets final score to 0 when weighting scheme is points', function () {
    const grades = calculateWithoutGradingPeriods('points');
    equal(grades.final.score, 0, 'final score is 0 points when all submissions are excluded');
    equal(grades.final.possible, 35, 'final possible is sum of all assignment points');
  });

  test('sets current score to null when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'current score cannot be calculated when all submissions are excluded');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points are excluded');
  });

  test('sets final score to null when weighting scheme is percent', function () {
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.final.score, 0, 'final score cannot be calculated when all submissions are excluded');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('sets scores to 0 when weighting scheme is percent and group weight is not defined', function () {
    assignmentGroups[0].group_weight = null;
    const grades = calculateWithoutGradingPeriods('percent');
    equal(grades.current.score, null, 'current score cannot be calculated without group weight');
    equal(grades.final.score, null, 'final score cannot be calculated without group weight');
  });

  QUnit.module('CourseGradeCalculator.calculate with unweighted grading periods', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 10 },
        { assignment_id: 202, score: 5 },
        { assignment_id: 203, score: 12 },
        { assignment_id: 204, score: 16 }
      ];
      assignments = [
        { id: 201, points_possible: 10, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false },
        { id: 203, points_possible: 20, omit_from_final_grade: false },
        { id: 204, points_possible: 40, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, group_weight: 60, rules: {}, assignments: assignments.slice(0, 2) },
        { id: 302, group_weight: 20, rules: {}, assignments: assignments.slice(2, 3) },
        { id: 303, group_weight: 20, rules: {}, assignments: assignments.slice(3, 4) }
      ];
      gradingPeriods = [
        { id: '701', weight: 50 },
        { id: '702', weight: 50 }
      ];
      gradingPeriodSet = { gradingPeriods, weighted: false };
      effectiveDueDates = {
        201: { grading_period_id: '701' },
        202: { grading_period_id: '701' },
        203: { grading_period_id: '702' },
        204: { grading_period_id: '702' }
      };
    }
  });

  test('includes assignment group grades', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 15);
    equal(grades.assignmentGroups[301].final.score, 15);
    equal(grades.assignmentGroups[301].current.possible, 20);
    equal(grades.assignmentGroups[301].final.possible, 20);
    equal(grades.assignmentGroups[302].current.score, 12);
    equal(grades.assignmentGroups[302].final.score, 12);
    equal(grades.assignmentGroups[302].current.possible, 20);
    equal(grades.assignmentGroups[302].final.possible, 20);
    equal(grades.assignmentGroups[303].current.score, 16);
    equal(grades.assignmentGroups[303].final.score, 16);
    equal(grades.assignmentGroups[303].current.possible, 40);
    equal(grades.assignmentGroups[303].final.possible, 40);
  });

  test('includes grading period weights in gradingPeriods', function () {
    const grades = calculateWithGradingPeriods('percent');
    ok(grades.gradingPeriods);
    equal(grades.gradingPeriods[701].gradingPeriodWeight, 50);
    equal(grades.gradingPeriods[702].gradingPeriodWeight, 50);
  });

  test('includes assignment groups point scores in grading period grades', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].assignmentGroups[301].current.score, 15);
    equal(grades.gradingPeriods[701].assignmentGroups[301].final.score, 15);
    equal(grades.gradingPeriods[702].assignmentGroups[302].current.score, 12);
    equal(grades.gradingPeriods[702].assignmentGroups[302].final.score, 12);
    equal(grades.gradingPeriods[702].assignmentGroups[303].current.score, 16);
    equal(grades.gradingPeriods[702].assignmentGroups[303].final.score, 16);
  });

  test('calculates current and final percent grades within grading periods', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].current.score, 75, 'one assignment group is in this grading period');
    equal(grades.gradingPeriods[701].final.score, 75, 'one assignment group is in this grading period');
    equal(grades.gradingPeriods[701].current.possible, 100, 'current possible is 100 percent');
    equal(grades.gradingPeriods[701].final.possible, 100, 'final possible is 100 percent');
    equal(grades.gradingPeriods[702].current.score, 50, 'two assignment groups are in this grading period');
    equal(grades.gradingPeriods[702].final.score, 50, 'two assignment groups are in this grading period');
    equal(grades.gradingPeriods[702].current.possible, 100, 'current possible is 100 percent');
    equal(grades.gradingPeriods[702].final.possible, 100, 'final possible is 100 percent');
  });

  test('does not weight assignment groups within grading periods when weighting scheme is not percent', function () {
    const grades = calculateWithGradingPeriods('points');
    equal(grades.gradingPeriods[701].current.score, 15, 'current score is sum of scores in grading period 701');
    equal(grades.gradingPeriods[701].final.score, 15, 'final score is sum of scores in grading period 701');
    equal(grades.gradingPeriods[701].current.possible, 20, 'current possible is sum of points in grading period 701');
    equal(grades.gradingPeriods[701].final.possible, 20, 'final possible is sum of points in grading period 701');
    equal(grades.gradingPeriods[702].current.score, 28, 'current score is sum of scores in grading period 702');
    equal(grades.gradingPeriods[702].final.score, 28, 'final score is sum of scores in grading period 702');
    equal(grades.gradingPeriods[702].current.possible, 60, 'current possible is sum of points in grading period 702');
    equal(grades.gradingPeriods[702].final.possible, 60, 'final possible is sum of points in grading period 702');
  });

  test('combines all assignment groups for the course grade', function () {
    // 15/20 * 60% = 45%
    // 12/20 * 20% = 12%
    // 16/40 * 20% = 8%
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 65, 'each assignment group is weighted only by its group_weight');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 65, 'each assignment group is weighted only by its group_weight');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('ignores grading period weights', function () {
    // 15/20 * 60% = 45%
    // 12/20 * 20% = 12%
    // 16/40 * 20% = 8%
    gradingPeriods[0].weight = 25;
    gradingPeriods[1].weight = 75;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 65, 'each assignment group is weighted only by its group_weight');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 65, 'each assignment group is weighted only by its group_weight');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('does not weight assignment groups for course grade when weighting scheme is not percent', function () {
    const grades = calculateWithGradingPeriods('points');
    equal(grades.current.score, 43, 'assignment group scores are totaled per grading period as points');
    equal(grades.current.possible, 80, 'current possible is sum of all assignment points');
    equal(grades.final.score, 43, 'assignment group scores are totaled per grading period as points');
    equal(grades.final.possible, 80, 'final possible is sum of all assignment points');
  });

  test('up-scales group weights which do not add up to exactly 100 percent', function () {
    // 6 / (6+2+2) = 60%
    // 2 / (6+2+2) = 20%
    assignmentGroups[0].group_weight = 6;
    assignmentGroups[1].group_weight = 2;
    assignmentGroups[2].group_weight = 2;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 65, 'each assignment group is weighted only by its group_weight');
    equal(grades.final.score, 65, 'each assignment group is weighted only by its group_weight');
  });

  test('does not down-scale group weights which add up to over 100 percent', function () {
    assignmentGroups[0].group_weight = 120;
    assignmentGroups[1].group_weight = 40;
    assignmentGroups[2].group_weight = 40;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 130, 'current score is effectively double the weight');
    equal(grades.final.score, 130, 'final score is effectively double the weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('includes assignment groups outside of grading periods', function () {
    effectiveDueDates[201].grading_period_id = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 65, 'assignment 201 is included');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 65, 'assignment 201 is included');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('does not divide assignment groups crossing grading periods', function () {
    effectiveDueDates[202].grading_period_id = '702';
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 65, 'assignment group 302 is not divided');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 65, 'assignment group 302 is not divided');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('includes assignment group grades without division', function () {
    effectiveDueDates[202].grading_period_id = '702';
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 15);
    equal(grades.assignmentGroups[301].final.score, 15);
    equal(grades.assignmentGroups[301].current.possible, 20);
    equal(grades.assignmentGroups[301].final.possible, 20);
    equal(grades.assignmentGroups[302].current.score, 12);
    equal(grades.assignmentGroups[302].final.score, 12);
    equal(grades.assignmentGroups[302].current.possible, 20);
    equal(grades.assignmentGroups[302].final.possible, 20);
    equal(grades.assignmentGroups[303].current.score, 16);
    equal(grades.assignmentGroups[303].final.score, 16);
    equal(grades.assignmentGroups[303].current.possible, 40);
    equal(grades.assignmentGroups[303].final.possible, 40);
  });

  test('uses a score unit of "points" when weighting scheme is not percent', function () {
    const grades = calculateWithGradingPeriods('points');
    equal(grades.scoreUnit, 'points');
    equal(grades.gradingPeriods[701].scoreUnit, 'points');
    equal(grades.gradingPeriods[702].scoreUnit, 'points');
  });

  test('uses a score unit of "percentage" when weighting scheme is percent', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.scoreUnit, 'percentage');
    equal(grades.gradingPeriods[701].scoreUnit, 'percentage');
    equal(grades.gradingPeriods[702].scoreUnit, 'percentage');
  });

  QUnit.module('CourseGradeCalculator.calculate with weighted grading periods', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 10 },
        { assignment_id: 202, score: 5 },
        { assignment_id: 203, score: 12 },
        { assignment_id: 204, score: 16 }
      ];
      assignments = [
        { id: 201, points_possible: 10, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false },
        { id: 203, points_possible: 20, omit_from_final_grade: false },
        { id: 204, points_possible: 40, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, group_weight: 60, rules: {}, assignments: assignments.slice(0, 2) },
        { id: 302, group_weight: 20, rules: {}, assignments: assignments.slice(2, 3) },
        { id: 303, group_weight: 20, rules: {}, assignments: assignments.slice(3, 4) }
      ];
      gradingPeriods = [
        { id: '701', weight: 50 },
        { id: '702', weight: 50 }
      ];
      gradingPeriodSet = { gradingPeriods, weighted: true };
      effectiveDueDates = {
        201: { grading_period_id: '701' },
        202: { grading_period_id: '701' },
        203: { grading_period_id: '702' },
        204: { grading_period_id: '702' }
      };
    }
  });

  test('includes grading period attributes in gradingPeriods', function () {
    const grades = calculateWithGradingPeriods('percent');
    ok(grades.gradingPeriods);
    equal(grades.gradingPeriods[701].gradingPeriodId, 701);
    equal(grades.gradingPeriods[702].gradingPeriodId, 702);
    equal(grades.gradingPeriods[701].gradingPeriodWeight, 50);
    equal(grades.gradingPeriods[702].gradingPeriodWeight, 50);
  });

  test('includes assignment groups point scores in grading period grades', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].assignmentGroups[301].current.score, 15);
    equal(grades.gradingPeriods[701].assignmentGroups[301].final.score, 15);
    equal(grades.gradingPeriods[702].assignmentGroups[302].current.score, 12);
    equal(grades.gradingPeriods[702].assignmentGroups[302].final.score, 12);
    equal(grades.gradingPeriods[702].assignmentGroups[303].current.score, 16);
    equal(grades.gradingPeriods[702].assignmentGroups[303].final.score, 16);
  });

  test('calculates current and final percent grades within grading periods', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].current.score, 75, 'one assignment group is in this grading period');
    equal(grades.gradingPeriods[701].final.score, 75, 'one assignment group is in this grading period');
    equal(grades.gradingPeriods[701].current.possible, 100, 'current possible is 100 percent');
    equal(grades.gradingPeriods[701].final.possible, 100, 'final possible is 100 percent');
    equal(grades.gradingPeriods[702].current.score, 50, 'two assignment groups are in this grading period');
    equal(grades.gradingPeriods[702].final.score, 50, 'two assignment groups are in this grading period');
    equal(grades.gradingPeriods[702].current.possible, 100, 'current possible is 100 percent');
    equal(grades.gradingPeriods[702].final.possible, 100, 'final possible is 100 percent');
  });

  test('does not weight assignment groups within grading periods when weighting scheme is not percent', function () {
    const grades = calculateWithGradingPeriods('points');
    equal(grades.gradingPeriods[701].current.score, 15, 'current score is sum of scores in grading period 701');
    equal(grades.gradingPeriods[701].final.score, 15, 'final score is sum of scores in grading period 701');
    equal(grades.gradingPeriods[701].current.possible, 20, 'current possible is sum of points in grading period 701');
    equal(grades.gradingPeriods[701].final.possible, 20, 'final possible is sum of points in grading period 701');
    equal(grades.gradingPeriods[702].current.score, 28, 'current score is sum of scores in grading period 702');
    equal(grades.gradingPeriods[702].final.score, 28, 'final score is sum of scores in grading period 702');
    equal(grades.gradingPeriods[702].current.possible, 60, 'current possible is sum of points in grading period 702');
    equal(grades.gradingPeriods[702].final.possible, 60, 'final possible is sum of points in grading period 702');
  });

  test('weights percent grades of assignment groups for the course grade', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 62.5, 'each assignment group is half the grade');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 62.5, 'each assignment group is half the grade');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('does not weight assignment groups for course grade when weighting scheme is not percent', function () {
    const grades = calculateWithGradingPeriods('points');
    equal(grades.current.score, 60.83, 'assignment group scores are totaled per grading period as points');
    equal(grades.final.score, 60.83, 'assignment group scores are totaled per grading period as points');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('up-scales grading period weights which do not add up to exactly 100 percent', function () {
    // 5 / (5+5) = 50%
    gradingPeriods[0].weight = 5;
    gradingPeriods[1].weight = 5;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 62.5);
    equal(grades.current.possible, 100);
    equal(grades.final.score, 62.5);
    equal(grades.final.possible, 100);
  });

  test('does not down-scale grading period weights which add up to over 100 percent', function () {
    gradingPeriods[0].weight = 100;
    gradingPeriods[1].weight = 100;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 125, 'current score is effectively double the weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.score, 125, 'final score is effectively double the weight');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('uses zero weight for grading periods with null weight', function () {
    // 5 / (0+5) = 100%
    gradingPeriods[0].weight = null;
    gradingPeriods[1].weight = 5;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 50, 'grading period 702 has a current score of 50 percent');
    equal(grades.current.possible, 100);
    equal(grades.final.score, 50, 'grading period 702 has a final score of 50 percent');
    equal(grades.final.possible, 100);
  });

  test('sets scores to zero when all grading period weights are zero', function () {
    gradingPeriods[0].weight = 0;
    gradingPeriods[1].weight = 0;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 0, 'all grading periods have zero weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.score, 0, 'all grading periods have zero weight');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('sets scores to zero when all grading period weights are null', function () {
    gradingPeriods[0].weight = null;
    gradingPeriods[1].weight = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 0, 'all grading periods have zero weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.score, 0, 'all grading periods have zero weight');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('excludes assignments outside of grading periods', function () {
    effectiveDueDates[201].grading_period_id = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 50, 'assignment 201 is excluded');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 50, 'assignment 201 is excluded');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('excludes assignments outside of grading periods for assignment group grades', function () {
    effectiveDueDates[201].grading_period_id = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 5);
    equal(grades.assignmentGroups[301].final.score, 5);
    equal(grades.assignmentGroups[301].current.possible, 10);
    equal(grades.assignmentGroups[301].final.possible, 10);
  });

  test('excludes grades for assignment groups outside of grading periods', function () {
    effectiveDueDates[203].grading_period_id = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(typeof grades.assignmentGroups[302], 'undefined');
  });

  test('weights grading periods with unequal grading period weights', function () {
    gradingPeriods[0].weight = 25;
    gradingPeriods[1].weight = 75;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 56.25);
    equal(grades.final.score, 56.25);
  });

  test('uses full weight for grading periods with no assignments groups', function () {
    assignmentGroups = [assignmentGroups[0]];
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 37.5, 'the grading period with a score is weighted as half of the overall score');
    equal(grades.current.possible, 100);
    equal(grades.final.score, 37.5, 'the grading period with a score is weighted as half of the overall score');
    equal(grades.final.possible, 100);
  });

  // Empty assignment groups are not associated with any grading period.
  test('ignores empty assignments groups', function () {
    assignmentGroups[1].assignments = [];
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 57.5);
    equal(grades.final.score, 57.5);
  });

  test('evaluates null grading period weights as 0 when some grading periods have weight', function () {
    gradingPeriods[0].weight = null;
    gradingPeriods[1].weight = 50;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 50, 'grading period 702 score of 50 effectively has 100 percent weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.score, 50, 'grading period 702 score of 50 effectively has 100 percent weight');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('evaluates null grading period weights as 0 when no grading periods have weight', function () {
    gradingPeriods[0].weight = null;
    gradingPeriods[1].weight = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 0, 'grading period 702 score of 50 effectively has 0 percent weight');
    equal(grades.current.possible, 100, 'current possible remains 100 percent');
    equal(grades.final.score, 0, 'grading period 702 score of 50 effectively has 0 percent weight');
    equal(grades.final.possible, 100, 'final possible remains 100 percent');
  });

  test('sets null weights as 0 in gradingPeriods', function () {
    gradingPeriods[0].weight = null;
    gradingPeriods[1].weight = null;
    const grades = calculateWithGradingPeriods('percent');
    ok(grades.gradingPeriods);
    equal(grades.gradingPeriods[701].gradingPeriodWeight, 0);
    equal(grades.gradingPeriods[702].gradingPeriodWeight, 0);
  });

  test('combines weighted assignment group scores as percent in grading periods without weight', function () {
    gradingPeriods[0].weight = null;
    gradingPeriods[1].weight = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].current.score, 75, 'one assignment group is in grading period 701');
    equal(grades.gradingPeriods[701].current.possible, 100, 'current possible is 100 percent');
    equal(grades.gradingPeriods[701].final.score, 75, 'one assignment group is in grading period 701');
    equal(grades.gradingPeriods[701].final.possible, 100, 'final possible is 100 percent');
    equal(grades.gradingPeriods[702].current.score, 50, 'two assignment groups are in grading period 702');
    equal(grades.gradingPeriods[702].current.possible, 100, 'current possible is 100 percent');
    equal(grades.gradingPeriods[702].final.score, 50, 'two assignment groups are in grading period 702');
    equal(grades.gradingPeriods[702].final.possible, 100, 'final possible is 100 percent');
  });

  test('includes assignment group grades regardless of grading period weight', function () {
    gradingPeriods[0].weight = 200;
    gradingPeriods[1].weight = null;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 15);
    equal(grades.assignmentGroups[301].final.score, 15);
    equal(grades.assignmentGroups[301].current.possible, 20);
    equal(grades.assignmentGroups[301].final.possible, 20);
    equal(grades.assignmentGroups[302].current.score, 12);
    equal(grades.assignmentGroups[302].final.score, 12);
    equal(grades.assignmentGroups[302].current.possible, 20);
    equal(grades.assignmentGroups[302].final.possible, 20);
    equal(grades.assignmentGroups[303].current.score, 16);
    equal(grades.assignmentGroups[303].final.score, 16);
    equal(grades.assignmentGroups[303].current.possible, 40);
    equal(grades.assignmentGroups[303].final.possible, 40);
  });

  test('uses a score unit of "percentage" for course grade', function () {
    let grades = calculateWithGradingPeriods('points');
    equal(grades.scoreUnit, 'percentage');
    grades = calculateWithGradingPeriods('percent');
    equal(grades.scoreUnit, 'percentage');
  });

  test('uses a score unit of "points" for grading period grades when weighting scheme is not percent', function () {
    const grades = calculateWithGradingPeriods('points');
    equal(grades.gradingPeriods[701].scoreUnit, 'points');
    equal(grades.gradingPeriods[702].scoreUnit, 'points');
  });

  test('uses a score unit of "percentage" for grading period grades when weighting scheme is percent', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].scoreUnit, 'percentage');
    equal(grades.gradingPeriods[702].scoreUnit, 'percentage');
  });

  // This is a use case that is STRONGLY discouraged to users, but is still not
  // prevented. Assignment group rules must never be applied to multiple grading
  // periods in combination. Doing so would impact grades in closed grading
  // periods, which must never occur.
  QUnit.module('CourseGradeCalculator.calculate with assignment groups across multiple weighted grading periods', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 10 },
        { assignment_id: 202, score: 5 },
        { assignment_id: 203, score: 3 }
      ];
      assignments = [
        { id: 201, points_possible: 10, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false },
        { id: 203, points_possible: 10, omit_from_final_grade: false }
      ];
      assignmentGroups = [
        { id: 301, group_weight: 50, rules: {}, assignments: assignments.slice(0, 2) },
        { id: 302, group_weight: 50, rules: {}, assignments: assignments.slice(2, 3) }
      ];
      gradingPeriods = [
        { id: '701', weight: 50 },
        { id: '702', weight: 50 }
      ];
      gradingPeriodSet = { gradingPeriods, weighted: true };
      effectiveDueDates = {
        201: { grading_period_id: '701' }, // in first assignment group and first grading period
        202: { grading_period_id: '702' }, // in first assignment group and second grading period
        203: { grading_period_id: '702' }
      };
    }
  });

  test('recombines assignment group grades of divided assignment groups', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.assignmentGroups[301].current.score, 15);
    equal(grades.assignmentGroups[301].final.score, 15);
    equal(grades.assignmentGroups[301].current.possible, 20);
    equal(grades.assignmentGroups[301].final.possible, 20);
  });

  test('recombines assignment group submissions of divided assignment groups', function () {
    const grades = calculateWithGradingPeriods('percent');
    const listSubmissionAssignmentIds = grade => (
      _.pluck(grade.submissions, ({ submission }) => submission.assignment_id)
    );
    deepEqual(listSubmissionAssignmentIds(grades.assignmentGroups[301].current), [201, 202]);
    deepEqual(listSubmissionAssignmentIds(grades.assignmentGroups[301].final), [201, 202]);
    equal(grades.assignmentGroups[301].current.submission_count, 2);
    equal(grades.assignmentGroups[301].final.submission_count, 2);
  });

  test('divides assignment groups across related grading periods', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].assignmentGroups[301].current.score, 10);
    equal(grades.gradingPeriods[701].assignmentGroups[301].final.score, 10);
    equal(grades.gradingPeriods[702].assignmentGroups[301].current.score, 5);
    equal(grades.gradingPeriods[702].assignmentGroups[301].final.score, 5);
    equal(grades.gradingPeriods[702].assignmentGroups[302].current.score, 3);
    equal(grades.gradingPeriods[702].assignmentGroups[302].final.score, 3);
  });

  test('accounts for divided assignment groups in grading period scores', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.gradingPeriods[701].current.score, 100, 'grading period 701 scores include only assignment 201');
    equal(grades.gradingPeriods[701].final.score, 100, 'grading period 701 scores include only assignment 201');
    equal(grades.gradingPeriods[702].current.score, 40, 'grading period 702 scores include assignments 202 & 203');
    equal(grades.gradingPeriods[702].final.score, 40, 'grading period 702 scores include assignments 202 & 203');
  });

  test('weights assignments groups with equal grading period weights', function () {
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 70, 'each grading period accounts for half of the current score');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 70, 'each grading period accounts for half of the final score');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('weights assignments groups with unequal grading period weights', function () {
    gradingPeriods[0].weight = 25;
    gradingPeriods[1].weight = 75;
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 55, 'lower-scoring grading periods with higher weight decrease the current score');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 55, 'lower-scoring grading periods with higher weight decrease the final score');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('excludes assignment groups containing only assignments not assigned to the given student', function () {
    delete effectiveDueDates[203];
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 75, 'assignment 203 is not assigned to the student');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 75, 'assignment 203 is not assigned to the student');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });

  test('excludes assignments not assigned to the given student', function () {
    delete effectiveDueDates[202];
    const grades = calculateWithGradingPeriods('percent');
    equal(grades.current.score, 65, 'assignment 202 is not assigned to the student');
    equal(grades.current.possible, 100, 'current possible is 100 percent');
    equal(grades.final.score, 65, 'assignment 202 is not assigned to the student');
    equal(grades.final.possible, 100, 'final possible is 100 percent');
  });
});
