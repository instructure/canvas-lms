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

import LatePolicyApplicator from 'jsx/grading/LatePolicyApplicator'

QUnit.module('LatePolicyApplicator#processSubmission', function () {
  let assignment;
  let latePolicy;
  let submission;

  test('returns false when submission is not late or missing', function () {
    submission = { late: false, missing: false };
    assignment = { grading_type: 'points', points_possible: 10 };
    equal(LatePolicyApplicator.processSubmission(submission, assignment), false);
  });

  QUnit.module('Missing submissions', function (hooks) {
    hooks.beforeEach(function () {
      submission = { late: false, missing: true, entered_grade: null, entered_score: null, grade: null, score: null };
      assignment = { grading_type: 'points', points_possible: 10 };
      latePolicy = {
        missingSubmissionDeductionEnabled: true,
        missingSubmissionDeduction: 30
      };
    });

    test('returns true if the score on the missing submission is changed', function () {
      strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
    });

    test('returns false if the score on the missing submission is not null', function () {
      submission.score = 5;
      strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
    });

    test('returns false if the grade on the missing submission is not null', function () {
      submission.grade = '5';
      strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
    });

    test('assigns score/grade to the missing submission when missing deduction enabled', function () {
      LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
      strictEqual(submission.score, 7);
      strictEqual(submission.grade, '7');
    });

    test('assigns entered_score/entered_grade when missing deduction enabled', function () {
      LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
      strictEqual(submission.entered_score, 7);
      strictEqual(submission.entered_grade, '7');
    });
  });

  QUnit.module('Late submissions', function (contextHooks) {
    contextHooks.beforeEach(function () {
      submission = { late: true, missing: false };
    });

    test('returns false when assignment has no points_possible', function () {
      assignment = { grading_type: 'points', points_possible: null };
      strictEqual(LatePolicyApplicator.processSubmission(submission, assignment), false);
    });

    test('returns false when assignment grading_type is "pass_fail"', function () {
      assignment = { grading_type: 'pass_fail', points_possible: 10 };
      strictEqual(LatePolicyApplicator.processSubmission(submission, assignment), false);
    });

    QUnit.module('Hourly late submission deduction', function (hooks) {
      hooks.beforeEach(function () {
        submission = {
          late: true,
          missing: false,
          entered_score: 10,
          entered_grade: '10',
          score: 10,
          grade: '10',
          seconds_late: 3600
        };

        assignment = { grading_type: 'points', points_possible: 10 };
        latePolicy = {
          lateSubmissionDeduction: 10,
          lateSubmissionDeductionEnabled: true,
          lateSubmissionMinimumPercentEnabled: false,
          lateSubmissionInterval: 'hour'
        };
      });

      [undefined, null, ''].forEach(function (val) {
        test(`returns false when points_deducted changes between "${val}" and 0`, function () {
          latePolicy.lateSubmissionDeduction = 0;
          submission.points_deducted = val;
          strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
        });
      });

      test('returns false when late submission penalty does not change its values', function () {
        submission.grade = '9';
        submission.score = 9;
        submission.points_deducted = 1;
        strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
      });

      test('returns true when the hourly late submission penalty changes the score on the submission', function () {
        strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
      });

      test('assigns points_deducted to the late submission when hourly late penalty enabled', function () {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.points_deducted, 1);
      });

      test('assigns a pre-deduction entered score/entered grade to the late submission when hourly late penalty enabled', function () {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.entered_score, 10);
        strictEqual(submission.entered_grade, '10');
      });

      test('assigns a post-deduction score/grade to the late submission when hourly late penalty enabled', function () {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.score, 9);
        strictEqual(submission.grade, '9');
      });
    });

    QUnit.module('Daily late submission deduction', function (hooks) {
      hooks.beforeEach(function () {
        submission = {
          late: true,
          missing: false,
          entered_score: 10,
          entered_grade: '10',
          score: 10,
          grade: '10',
          seconds_late: 3600 * 24 * 2
        };

        assignment = { grading_type: 'points', points_possible: 10 };
        latePolicy = {
          lateSubmissionDeduction: 10,
          lateSubmissionDeductionEnabled: true,
          lateSubmissionMinimumPercentEnabled: false,
          lateSubmissionInterval: 'day'
        };
      });

      test('returns true when the daily late submission penalty changes the score on the submission', function () {
        strictEqual(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
      });

      test('assigns points_deducted  to the late submission when daily late penalty enabled', function () {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.points_deducted, 2);
      });

      test('assigns a pre-deduction score/grade to the late submission when daily late penalty enabled', function () {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.entered_score, 10);
        strictEqual(submission.entered_grade, '10');
      });

      test('assigns a post-deduction score/grade to the late submission when daily late penalty enabled', function () {
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.score, 8);
        strictEqual(submission.grade, '8');
      });

      test('does not apply late penalty to late but ungraded submission', function () {
        submission = {
          late: true,
          missing: false,
          entered_score: null,
          entered_grade: null,
          score: null,
          grade: null,
          seconds_late: 3600 * 24 * 2
        };

        strictEqual(submission.score, null);
      });

      test('does not remove existing late penalty when policy disabled', function () {
        submission.grade = '8.5';
        submission.score = 8.5;
        submission.points_deducted = 1.5;
        latePolicy.lateSubmissionDeductionEnabled = false;
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.score, 8.5);
        strictEqual(submission.grade, '8.5');
      });

      test('applies late penalty minimum when enabled', function () {
        latePolicy.lateSubmissionMinimumPercentEnabled = true;
        latePolicy.lateSubmissionMinimumPercent = 90;
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.score, 9);
        strictEqual(submission.grade, '9');
      });

      test('applied late penalty does not bring score below 0', function () {
        submission = {
          late: true,
          missing: false,
          entered_score: 3,
          entered_grade: '3',
          score: 3,
          grade: '3',
          seconds_late: 3600 * 24 * 10
        };

        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.score, 0);
        strictEqual(submission.grade, '0');
      });

      test('does not apply late penalty if entered_score <= late penalty minimum', function () {
        submission = {
          late: true,
          missing: false,
          entered_score: 3,
          entered_grade: '3',
          score: 3,
          grade: '3',
          seconds_late: 3600 * 24 * 10
        };

        latePolicy.lateSubmissionMinimumPercentEnabled = true;
        latePolicy.lateSubmissionMinimumPercent = 50;
        LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy);
        strictEqual(submission.score, 3);
        strictEqual(submission.grade, '3');
      });
    });
  });
});
