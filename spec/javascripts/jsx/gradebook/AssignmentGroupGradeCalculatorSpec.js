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
  'jsx/gradebook/AssignmentGroupGradeCalculator'
], (_, AssignmentGroupGradeCalculator) => {
  let submissions;
  let assignments;
  let assignmentGroup;

  QUnit.module('AssignmentGroupGradeCalculator.calculate with no submissions and no assignments', {
    setup () {
      submissions = [];
      assignmentGroup = { id: 301, rules: {}, assignments: [], group_weight: 100 };
    }
  });

  test('returns a current and final score of 0', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 0);
    equal(grades.final.score, 0);
  });

  test('includes 0 points possible', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 0);
    equal(grades.final.possible, 0);
  });

  test('includes assignment group attributes', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.assignmentGroupId, 301);
    equal(grades.assignmentGroupWeight, 100);
  });

  test('uses a score unit of "points"', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.scoreUnit, 'points');
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with no submissions and some assignments', {
    setup () {
      submissions = [];
      assignments = [
        { id: 201, points_possible: 100, omit_from_final_grade: false },
        { id: 202, points_possible: 91, omit_from_final_grade: false },
        { id: 203, points_possible: 55, omit_from_final_grade: false },
        { id: 204, points_possible: 38, omit_from_final_grade: false },
        { id: 205, points_possible: 1000, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: {}, assignments };
    }
  });

  test('returns a current and final score of 0', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 0);
    equal(grades.final.score, 0);
  });

  test('include the sum of points possible', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 0);
    equal(grades.final.possible, 1284);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with some assignments and submissions', {
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
      assignmentGroup = { id: 301, rules: {}, assignments };
    }
  });

  test('adds all scores for current and final grades', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 159);
    equal(grades.final.score, 159);
  });

  test('excludes assignment points on ungraded submissions for the current grade', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 284);
    equal(grades.final.possible, 1284);
  });

  test('ignores hidden submissions', function () {
    submissions[1].hidden = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 117);
    equal(grades.final.score, 117);
  });

  test('excludes assignment points on hidden submissions', function () {
    submissions[1].hidden = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 193);
    equal(grades.final.possible, 1193);
  });

  test('ignores excused submissions', function () {
    submissions[1].excused = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 117);
    equal(grades.final.score, 117);
  });

  test('excludes assignment points on excused submissions', function () {
    submissions[1].excused = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 193);
    equal(grades.final.possible, 1193);
  });

  test('excludes submissions "pending review" from the current grade', function () {
    submissions[1].workflow_state = 'pending_review';
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 117);
    equal(grades.current.possible, 193);
  });

  test('includes submissions "pending review" in the final grade', function () {
    submissions[1].workflow_state = 'pending_review';
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.final.score, 159);
    equal(grades.final.possible, 1284);
  });

  test('excludes assignments "omitted from final grade" from the current grade', function () {
    assignmentGroup.assignments[2].omit_from_final_grade = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 145);
    equal(grades.current.possible, 229);
  });

  test('excludes assignments "omitted from final grade" from the final grade', function () {
    assignmentGroup.assignments[2].omit_from_final_grade = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.final.score, 145);
    equal(grades.final.possible, 1229);
  });

  test('excludes ungraded assignments "omitted from final grade" from the final grade', function () {
    assignmentGroup.assignments[4].omit_from_final_grade = true;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.final.score, 159);
    equal(grades.final.possible, 284);
  });

  test('eliminates multiple submissions for the same assignment', function () {
    submissions.push({ ...submissions[0] });
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 159);
    equal(grades.final.score, 159);
    equal(grades.current.possible, 284);
    equal(grades.final.possible, 1284);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with assignments having no points possible', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 10 },
        { assignment_id: 202, score: 10 }
      ];
      assignments = [
        { id: 201, points_possible: 0, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: {}, assignments };
    }
  });

  test('includes scores for submissions on unpointed assignments', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 20);
    equal(grades.final.score, 20);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate "drop_lowest" rule (set to 1)', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 31 },
        { assignment_id: 202, score: 17 },
        { assignment_id: 203, score: 6 }
      ];
      assignments = [
        { id: 201, points_possible: 40, omit_from_final_grade: false },
        { id: 202, points_possible: 24, omit_from_final_grade: false },
        { id: 203, points_possible: 10, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: { drop_lowest: 1 }, assignments };
    }
  });

  test('drops one submission to maximize overall percentage grade', function () {
    // drop 31/40, keep 17/24, keep 6/10 = 23/34 = 67.6%
    // keep 31/40, drop 17/24, keep 6/10 = 37/50 = 74.0%
    // keep 31/40, keep 17/24, drop 6/10 = 48/64 = 75.0%
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 48);
    ok(grades.current.submissions[2].drop);
    equal(grades.final.score, 48);
    ok(grades.final.submissions[2].drop);
  });

  test('drops pointed assignments over unpointed assignments', function () {
    assignmentGroup.assignments[0].points_possible = 0;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 37);
    ok(grades.current.submissions[1].drop);
    equal(grades.final.score, 37);
    ok(grades.final.submissions[1].drop);
  });

  test('excludes points possible from the assignment for the dropped submission', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 64);
    equal(grades.final.possible, 64);
  });

  test('ignores ungraded submissions for the current grade', function () {
    submissions[2].score = null;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 31);
    equal(grades.final.score, 48);
  });

  test('excludes points possible for assignments with ungraded submissions for the current grade', function () {
    submissions[2].score = null;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 40);
    equal(grades.final.possible, 64);
  });

  test('accounts for impact on overall grade rather than score alone', function () {
    submissions[2].score = 7;

    // drop 31/40, keep 17/24, keep 7/10 = 24/34 = 70.6%
    // keep 31/40, drop 17/24, keep 7/10 = 38/50 = 76.0%
    // keep 31/40, keep 17/24, drop 7/10 = 48/64 = 75.0%
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 38);
    equal(grades.current.possible, 50);
    ok(grades.current.submissions[1].drop);
    equal(grades.final.score, 38);
    equal(grades.final.possible, 50);
    ok(grades.final.submissions[1].drop);
  });

  test('does not drop submissions or assignments when drop_lowest is 0', function () {
    assignmentGroup.rules.drop_lowest = 0;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 54, 'current score includes all submission scores');
    equal(grades.current.possible, 74, 'current possible includes all assignments');
    equal(grades.final.score, 54, 'final score includes all submission scores');
    equal(grades.final.possible, 74, 'final possible includes all assignments');
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate "drop_lowest" rule', {
    setup () {
      this.qunitTimeout = QUnit.config.testTimeout;
      QUnit.config.testTimeout = 100;
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
      assignmentGroup = { id: 301, rules: { drop_lowest: 2 }, assignments };
    },

    teardown () {
      QUnit.config.testTimeout = this.qunitTimeout;
      this.qunitTimeout = null;
    }
  });

  test('drops multiple submissions to maximize overall percentage grade', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);

    // drop 100/100, drop 42/91, keep 14/55, keep 3/38, ignore -/1000 =  17/93  = 18.3%
    // drop 100/100, keep 42/91, drop 14/55, keep 3/38, ignore -/1000 =  45/129 = 34.9%
    // drop 100/100, keep 42/91, keep 14/55, drop 3/38, ignore -/1000 =  56/146 = 38.4%
    // keep 100/100, drop 42/91, drop 14/55, keep 3/38, ignore -/1000 = 103/138 = 74.6%
    // keep 100/100, drop 42/91, keep 14/55, drop 3/38, ignore -/1000 = 114/155 = 73.5%
    // keep 100/100, keep 42/91, drop 14/55, drop 3/38, ignore -/1000 = 142/191 = 74.3%
    equal(grades.current.score, 103);
    equal(grades.current.possible, 138);
    ok(grades.current.submissions[1].drop);
    ok(grades.current.submissions[2].drop);

    // drop 100/100, drop 42/91, keep 14/55, keep 3/38, keep 0/1000 =  17/1093 =  1.6%
    // drop 100/100, keep 42/91, drop 14/55, keep 3/38, keep 0/1000 =  45/1129 =  4.0%
    // drop 100/100, keep 42/91, keep 14/55, drop 3/38, keep 0/1000 =  56/1146 =  4.9%
    // drop 100/100, keep 42/91, keep 14/55, keep 3/38, drop 0/1000 =  59/184  = 32.1%
    // keep 100/100, drop 42/91, drop 14/55, keep 3/38, keep 0/1000 = 103/1138 =  9.1%
    // keep 100/100, drop 42/91, keep 14/55, drop 3/38, keep 0/1000 = 114/1155 =  9.9%
    // keep 100/100, drop 42/91, keep 14/55, drop 3/38, drop 0/1000 = 117/193  = 60.6%
    // keep 100/100, keep 42/91, drop 14/55, drop 3/38, keep 0/1000 = 142/1191 = 11.9%
    // keep 100/100, keep 42/91, drop 14/55, keep 3/38, drop 0/1000 = 145/229  = 63.3%
    // keep 100/100, keep 42/91, keep 14/55, drop 3/38, drop 0/1000 = 156/246  = 63.4%
    equal(grades.final.score, 156);
    equal(grades.final.possible, 246);
    ok(grades.final.submissions[3].drop);
    ok(grades.final.submissions[4].drop);
  });

  test('drops all but one score when drop_lowest is equal to the number of submissions', function () {
    assignmentGroup.rules = { drop_lowest: 4 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 100);
    equal(grades.current.possible, 100);
    ok(grades.current.submissions[1].drop);
    ok(grades.current.submissions[3].drop);
    ok(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[4].drop);
    equal(grades.final.score, 100);
    equal(grades.final.possible, 100);
    ok(grades.final.submissions[1].drop);
    ok(grades.final.submissions[2].drop);
    ok(grades.final.submissions[3].drop);
    ok(grades.final.submissions[4].drop);
    notOk(grades.final.submissions[0].drop);
  });

  // This test is here because the reductive algorithm used for grading can
  // potentially enter into an infinite loop. While this setup data is indeed
  // ridiculous, its presence guarantees that the algorithm will always finish.
  test('works in ridiculous circumstances', function () {
    submissions[0].score = null;
    submissions[1].score = 3;
    submissions[2].score = null;
    submissions[3].score = null;
    submissions[4].score = null;
    assignmentGroup.assignments[0].points_possible = 20;
    assignmentGroup.assignments[1].points_possible = 10;
    assignmentGroup.assignments[2].points_possible = 10;
    assignmentGroup.assignments[3].points_possible = 100000000000000007629769841091887003294964970946560;
    assignmentGroup.assignments[4].points_possible = null;
    assignmentGroup.rules = { drop_lowest: 2 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 3);
    equal(grades.current.possible, 10);
    equal(grades.final.score, 3);
    equal(grades.final.possible, 20);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate "drop_highest" rule (set to 1)', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 31 },
        { assignment_id: 202, score: 17 },
        { assignment_id: 203, score: 6 }
      ];
      assignments = [
        { id: 201, points_possible: 40, omit_from_final_grade: false },
        { id: 202, points_possible: 24, omit_from_final_grade: false },
        { id: 203, points_possible: 10, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: { drop_highest: 1 }, assignments };
    }
  });

  test('drops one submission to minimize overall percentage grade', function () {
    // drop 31/40, keep 17/24, keep 6/10 = 23/34 = 67.6%
    // keep 31/40, drop 17/24, keep 6/10 = 37/50 = 74.0%
    // keep 31/40, keep 17/24, drop 6/10 = 48/64 = 75.0%
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 23);
    ok(grades.current.submissions[0].drop);
    equal(grades.final.score, 23);
    ok(grades.final.submissions[0].drop);
  });

  test('excludes points possible from the assignment for the dropped submission', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 34);
    equal(grades.final.possible, 34);
  });

  test('ignores ungraded submissions for the current grade', function () {
    submissions[0].score = null;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 6);
    equal(grades.final.score, 6);
  });

  test('excludes points possible for assignments with ungraded submissions for the current grade', function () {
    submissions[0].score = null;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.possible, 10);
    equal(grades.final.possible, 50);
  });

  test('accounts for impact on overall grade rather than score alone', function () {
    submissions[2].score = 10;

    // drop 31/40, keep 17/24, keep 10/10 = 27/34 = 79.4%
    // keep 31/40, drop 17/24, keep 10/10 = 41/50 = 82.0%
    // keep 31/40, keep 17/24, drop 10/10 = 48/64 = 75.0%
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 48);
    equal(grades.current.possible, 64);
    ok(grades.current.submissions[2].drop);
    equal(grades.final.score, 48);
    equal(grades.final.possible, 64);
    ok(grades.final.submissions[2].drop);
  });

  test('does not drop submissions or assignments when drop_highest is 0', function () {
    assignmentGroup.rules.drop_highest = 0;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 54, 'current score includes all submission scores');
    equal(grades.current.possible, 74, 'current possible includes all assignments');
    equal(grades.final.score, 54, 'final score includes all submission scores');
    equal(grades.final.possible, 74, 'final possible includes all assignments');
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate "drop_highest" rule', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 100 },
        { assignment_id: 202, score: 42 },
        { assignment_id: 203, score: 14 },
        { assignment_id: 204, score: 30 },
        { assignment_id: 205, score: null }
      ];
      assignments = [
        { id: 201, points_possible: 100, omit_from_final_grade: false },
        { id: 202, points_possible: 91, omit_from_final_grade: false },
        { id: 203, points_possible: 55, omit_from_final_grade: false },
        { id: 204, points_possible: 38, omit_from_final_grade: false },
        { id: 205, points_possible: 1000, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: { drop_highest: 2 }, assignments };
    }
  });

  test('drops multiple submissions to minimize overall percentage grade', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);

    // drop 100/100, drop 42/91, keep 14/55, keep 30/38, ignore -/1000 =  34/93  = 36.6%
    // drop 100/100, keep 42/91, drop 14/55, keep 30/38, ignore -/1000 =  72/129 = 55.8%
    // drop 100/100, keep 42/91, keep 14/55, drop 30/38, ignore -/1000 =  56/146 = 38.4%
    // keep 100/100, drop 42/91, drop 14/55, keep 30/38, ignore -/1000 = 130/138 = 94.2%
    // keep 100/100, drop 42/91, keep 14/55, drop 30/38, ignore -/1000 = 114/155 = 73.5%
    // keep 100/100, keep 42/91, drop 14/55, drop 30/38, ignore -/1000 = 142/191 = 74.3%
    equal(grades.current.score, 56);
    equal(grades.current.possible, 146);
    ok(grades.current.submissions[0].drop);
    ok(grades.current.submissions[3].drop);

    // drop 100/100, drop 42/91, keep 14/55, keep 30/38, keep 0/1000 =  44/1093 =  4.0%
    // drop 100/100, keep 42/91, drop 14/55, keep 30/38, keep 0/1000 =  72/1129 =  6.4%
    // drop 100/100, keep 42/91, keep 14/55, drop 30/38, keep 0/1000 =  56/1146 =  4.9%
    // drop 100/100, keep 42/91, keep 14/55, keep 30/38, drop 0/1000 =  86/184  = 46.7%
    // keep 100/100, drop 42/91, drop 14/55, keep 30/38, keep 0/1000 = 130/1138 = 11.4%
    // keep 100/100, drop 42/91, keep 14/55, drop 30/38, keep 0/1000 = 114/1155 =  9.9%
    // keep 100/100, drop 42/91, keep 14/55, drop 30/38, drop 0/1000 = 117/193  = 74.6%
    // keep 100/100, keep 42/91, drop 14/55, drop 30/38, keep 0/1000 = 142/1191 = 11.9%
    // keep 100/100, keep 42/91, drop 14/55, keep 30/38, drop 0/1000 = 172/229  = 75.1%
    // keep 100/100, keep 42/91, keep 14/55, drop 30/38, drop 0/1000 = 156/246  = 63.4%
    equal(grades.final.score, 44);
    equal(grades.final.possible, 1093);
    ok(grades.final.submissions[0].drop);
    ok(grades.final.submissions[1].drop);
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('does not drop any scores when drop_highest is equal to the number of submissions', function () {
    assignmentGroup.rules = { drop_highest: 4 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 186);
    equal(grades.current.possible, 284);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    notOk(grades.current.submissions[4].drop);
    equal(grades.final.score, 0);
    equal(grades.final.possible, 1000);
    ok(grades.final.submissions[0].drop);
    ok(grades.final.submissions[1].drop);
    ok(grades.final.submissions[2].drop);
    ok(grades.final.submissions[3].drop);
    notOk(grades.final.submissions[4].drop);
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('does not drop any scores when drop_highest is greater than the number of submissions', function () {
    assignmentGroup.rules = { drop_highest: 5 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 186);
    equal(grades.current.possible, 284);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    notOk(grades.current.submissions[4].drop);
    equal(grades.final.score, 186);
    equal(grades.final.possible, 1284);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
    notOk(grades.final.submissions[4].drop);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with "drop_lowest" and "drop_highest" rules', {
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
      assignmentGroup = { id: 301, rules: { drop_lowest: 1, drop_highest: 1 }, assignments };
    }
  });

  test('drops the most and least favorable scores', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 56);
    equal(grades.current.possible, 146);
    ok(grades.current.submissions[0].drop);
    ok(grades.current.submissions[3].drop);
    equal(grades.final.score, 59);
    equal(grades.final.possible, 184);
    ok(grades.final.submissions[0].drop);
    ok(grades.final.submissions[4].drop);
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('does not drop higher scores when combined drop rules match the number of submissions', function () {
    assignmentGroup.rules = { drop_lowest: 2, drop_highest: 2 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 103);
    equal(grades.current.possible, 138);
    ok(grades.current.submissions[1].drop);
    ok(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[3].drop);
    notOk(grades.current.submissions[4].drop);
    equal(grades.final.score, 14);
    equal(grades.final.possible, 55);
    ok(grades.final.submissions[0].drop);
    ok(grades.final.submissions[1].drop);
    ok(grades.final.submissions[3].drop);
    ok(grades.final.submissions[4].drop);
    notOk(grades.final.submissions[2].drop);
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('does not drop higher scores when combined drop rules exceed the number of submissions', function () {
    assignmentGroup.rules = { drop_lowest: 2, drop_highest: 3 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 103);
    equal(grades.current.possible, 138);
    ok(grades.current.submissions[1].drop);
    ok(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[3].drop);
    notOk(grades.current.submissions[4].drop);
    equal(grades.final.score, 156);
    equal(grades.final.possible, 246);
    ok(grades.final.submissions[3].drop);
    ok(grades.final.submissions[4].drop);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[2].drop);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with equivalent submissions and assignments', {
    setup () {
      submissions = [
        { assignment_id: 201, score: 9 },
        { assignment_id: 202, score: 9 },
        { assignment_id: 203, score: 9 },
        { assignment_id: 204, score: 9 }
      ];
      assignments = [
        { id: 201, points_possible: 10, omit_from_final_grade: false },
        { id: 202, points_possible: 10, omit_from_final_grade: false },
        { id: 203, points_possible: 10, omit_from_final_grade: false },
        { id: 204, points_possible: 10, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: {}, assignments };
    }
  });

  test('drops the same low-score submission regardless of submission order', function () {
    assignmentGroup.rules = { drop_lowest: 1 };
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop');
    submissions.reverse();
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop');
    equal(droppedSubmission1.assignment_id, droppedSubmission2.assignment_id);
  });

  test('drops the same high-score submission regardless of submission order', function () {
    assignmentGroup.rules = { drop_highest: 1 };
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop');
    submissions.reverse();
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop');
    equal(droppedSubmission1.assignment_id, droppedSubmission2.assignment_id);
  });

  test('drops the same low-score submission for unpointed assignments', function () {
    assignmentGroup.rules = { drop_lowest: 1 };
    assignmentGroup.assignments[0].points_possible = 0;
    assignmentGroup.assignments[1].points_possible = 0;
    assignmentGroup.assignments[2].points_possible = 0;
    assignmentGroup.assignments[3].points_possible = 0;
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop');
    submissions.reverse();
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop');
    equal(droppedSubmission1.assignment_id, droppedSubmission2.assignment_id);
  });

  test('drops the same high-score submission for unpointed assignments', function () {
    assignmentGroup.rules = { drop_highest: 1 };
    assignmentGroup.assignments[0].points_possible = 0;
    assignmentGroup.assignments[1].points_possible = 0;
    assignmentGroup.assignments[2].points_possible = 0;
    assignmentGroup.assignments[3].points_possible = 0;
    let grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission1 = _.find(grades.current.submissions, 'drop');
    submissions.reverse();
    grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    const droppedSubmission2 = _.find(grades.current.submissions, 'drop');
    equal(droppedSubmission1.assignment_id, droppedSubmission2.assignment_id);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with only unpointed assignments', {
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
      assignmentGroup = { id: 301, rules: {}, assignments };
    }
  });

  test('drops the submission with the lowest score when drop_lowest is 1', function () {
    assignmentGroup.rules = { drop_lowest: 1 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 35, 'all scores above the 0 are included');
    ok(grades.current.submissions[3].drop);
  });

  test('drops the submission with the highest score when drop_highest is 1', function () {
    assignmentGroup.rules = { drop_highest: 1 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 15, 'all scores below the 20 are included');
    ok(grades.current.submissions[2].drop);
  });

  test('drops submissions that match the given rules', function () {
    assignmentGroup.rules = { drop_highest: 1, drop_lowest: 2 };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 10, 'only the score of 10 is included');
    ok(grades.current.submissions[1].drop);
    ok(grades.current.submissions[2].drop);
    ok(grades.current.submissions[3].drop);
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate with only ungraded submissions', {
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
      assignmentGroup = { id: 301, rules: {}, assignments };
    }
  });

  test('sets current score as 0', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 0, 'current score is 0 points when all submissions are excluded');
    equal(grades.current.possible, 0, 'current possible is 0 when all assignment points are excluded');
  });

  test('sets final score as 0', function () {
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.final.score, 0, 'final score is 0 points when all submissions are excluded');
    equal(grades.final.possible, 35, 'final possible is sum of all assignment points');
  });

  QUnit.module('AssignmentGroupGradeCalculator.calculate "never_drop" rule', {
    // drop 31/40, keep 19/24, keep 12/16, keep 6/10 = 37/50 = 74.0%
    // keep 31/40, drop 19/24, keep 12/16, keep 6/10 = 49/66 = 74.2%
    // keep 31/40, keep 19/24, drop 12/16, keep 6/10 = 56/74 = 75.7%
    // keep 31/40, keep 19/24, keep 12/16, drop 6/10 = 62/80 = 77.5%

    setup () {
      submissions = [
        { assignment_id: 201, score: 31 },
        { assignment_id: 202, score: 19 },
        { assignment_id: 203, score: 12 },
        { assignment_id: 204, score: 6 }
      ];
      assignments = [
        { id: 201, points_possible: 40, omit_from_final_grade: false },
        { id: 202, points_possible: 24, omit_from_final_grade: false },
        { id: 203, points_possible: 16, omit_from_final_grade: false },
        { id: 204, points_possible: 10, omit_from_final_grade: false }
      ];
      assignmentGroup = { id: 301, rules: { never_drop: [204] }, assignments };
    }
  });

  test('prevents submissions from being dropped for low scores', function () {
    assignmentGroup.rules.drop_lowest = 1;
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 56);
    equal(grades.current.possible, 74);
    ok(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[3].drop);
    equal(grades.final.score, 56);
    equal(grades.final.possible, 74);
    ok(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[3].drop);
  });

  test('prevents submissions from being dropped for high scores', function () {
    assignmentGroup.rules = { drop_highest: 1, never_drop: [201] };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 49);
    equal(grades.current.possible, 66);
    ok(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    equal(grades.final.score, 49);
    equal(grades.final.possible, 66);
    ok(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
  });

  test('considers multiple assignments', function () {
    assignmentGroup.rules = { drop_lowest: 1, never_drop: [203, 204] };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 49);
    equal(grades.current.possible, 66);
    ok(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    equal(grades.final.score, 49);
    equal(grades.final.possible, 66);
    ok(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('does not drop any scores when drop_lowest is equal to the number of droppable submissions', function () {
    assignmentGroup.rules = { drop_lowest: 1, never_drop: [202, 203, 204] };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 68);
    equal(grades.current.possible, 90);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    equal(grades.final.score, 68);
    equal(grades.final.possible, 90);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
  });

  // This behavior was explicitly written into the grade calculator. While
  // possibly unintended, this test is here to ensure this behavior is protected
  // until a decision is made to change it.
  test('does not drop any scores when drop_highest is equal to the number of droppable submissions', function () {
    assignmentGroup.rules = { drop_highest: 1, never_drop: [202, 203, 204] };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    equal(grades.current.score, 68);
    equal(grades.current.possible, 90);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    equal(grades.final.score, 68);
    equal(grades.final.possible, 90);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
  });

  test('does not drop any low score submissions when all assignments are listed as "never drop"', function () {
    assignmentGroup.rules = { drop_lowest: 1, never_drop: [201, 202, 203, 204] };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
  });

  test('does not drop any high score submissions when all assignments are listed as "never drop"', function () {
    assignmentGroup.rules = { drop_highest: 1, never_drop: [201, 202, 203, 204] };
    const grades = AssignmentGroupGradeCalculator.calculate(submissions, assignmentGroup);
    notOk(grades.current.submissions[0].drop);
    notOk(grades.current.submissions[1].drop);
    notOk(grades.current.submissions[2].drop);
    notOk(grades.current.submissions[3].drop);
    notOk(grades.final.submissions[0].drop);
    notOk(grades.final.submissions[1].drop);
    notOk(grades.final.submissions[2].drop);
    notOk(grades.final.submissions[3].drop);
  });
});
