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

QUnit.module('LatePolicyApplicator#processSubmission');

test('returns false when submission is not late or missing', function () {
  const submission = { late: false, missing: false };
  const assignment = { grading_type: 'points', points_possible: 10 };
  equal(LatePolicyApplicator.processSubmission(submission, assignment), false);
});

test('returns false when assignment has no points_possible', function () {
  const submission = { late: true, missing: false };
  const assignment = { grading_type: 'points', points_possible: null };
  equal(LatePolicyApplicator.processSubmission(submission, assignment), false);
});

test('returns false when assignment grading_type is "pass_fail"', function () {
  const submission = { late: true, missing: false };
  const assignment = { grading_type: 'pass_fail', points_possible: 10 };
  equal(LatePolicyApplicator.processSubmission(submission, assignment), false);
});

test('returns false when late submission penalty does not change its values', function () {
  const submission = { late: true, missing: false, entered_score: 10, score: 9, grade: '9', points_deducted: 1, seconds_late: 3600 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionInterval: 'hour'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
});

[undefined, null, ''].forEach(function (val) {
  test(`returns false when points_deducted changes between "${val}" and 0`, function () {
    const submission = { late: true, missing: false, entered_score: 10, score: 10, grade: '10', points_deducted: val, seconds_late: 3600 };
    const assignment = { grading_type: 'points', points_possible: 10 };
    const latePolicy = {
      lateSubmissionDeduction: 0,
      lateSubmissionDeductionEnabled: true,
      lateSubmissionMinimumPercentEnabled: false,
      lateSubmissionInterval: 'hour'
    };

    equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
  });
});

test('applies late penalty to late submission when hourly late penalty enabled', function () {
  const submission = { late: true, missing: false, entered_score: 10, score: 10, grade: '10', seconds_late: 3600 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionInterval: 'hour'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
  equal(submission.score, 9);
  equal(submission.grade, '9');
});

test('applies late penalty to late submission when daily late penalty enabled', function () {
  const submission = { late: true, missing: false, entered_score: 10, score: 10, grade: '10', seconds_late: 3600 * 24 * 2 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionInterval: 'day'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
  equal(submission.score, 8);
  equal(submission.grade, '8');
});

test('does not apply late penalty to late but ungraded submission', function () {
  const submission = { late: true, missing: false, entered_score: null, score: null, grade: null, seconds_late: 3600 * 24 * 2 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionInterval: 'day'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
  equal(submission.score, null);
});

test('does not remove existing late penalty when policy disabled', function () {
  const submission = { late: true, missing: false, entered_score: 10, score: 8.5, grade: '8.5', seconds_late: 10, points_deducted: 1.5 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: false,
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionInterval: 'day'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
  equal(submission.score, 8.5);
  equal(submission.grade, '8.5');
});

test('applies late penalty minimum when enabled', function () {
  const submission = { late: true, missing: false, entered_score: 10, score: 10, grade: '10', seconds_late: 3600 * 24 * 2 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: true,
    lateSubmissionMinimumPercent: 90,
    lateSubmissionInterval: 'day'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
  equal(submission.score, 9);
  equal(submission.grade, '9');
});

test('applied late penalty does not bring score below 0', function () {
  const submission = { late: true, missing: false, entered_score: 3, score: 3, grade: '3', seconds_late: 3600 * 24 * 10 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: false,
    lateSubmissionInterval: 'day'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
  equal(submission.score, 0);
  equal(submission.grade, '0');
});

test('does not apply late penalty if entered_score <= late penalty minimum', function () {
  const submission = { late: true, missing: false, entered_score: 3, score: 3, grade: '3', seconds_late: 3600 * 24 * 10 };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    lateSubmissionDeduction: 10,
    lateSubmissionDeductionEnabled: true,
    lateSubmissionMinimumPercentEnabled: true,
    lateSubmissionMinimumPercent: 50,
    lateSubmissionInterval: 'day'
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), false);
  equal(submission.score, 3);
  equal(submission.grade, '3');
});

test('applies missing grade to missing submission when missing deduction enabled', function () {
  const submission = { late: false, missing: true };
  const assignment = { grading_type: 'points', points_possible: 10 };
  const latePolicy = {
    missingSubmissionDeductionEnabled: true,
    missingSubmissionDeduction: 30
  };

  equal(LatePolicyApplicator.processSubmission(submission, assignment, [], latePolicy), true);
  equal(submission.score, 7);
  equal(submission.grade, '7');
});
