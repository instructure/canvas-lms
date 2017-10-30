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

import SubmissionStateMap from 'jsx/gradezilla/SubmissionStateMap';

const student = {
  id: '1',
  group_ids: ['1'],
  sections: ['1']
};

function createMap (opts = {}) {
  const params = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false,
    ...opts
  };

  return new SubmissionStateMap(params);
}

function createAndSetupMap (assignment, opts = {}) {
  const submissionStateMap = createMap(opts);
  const assignments = {};
  assignments[assignment.id] = assignment;
  submissionStateMap.setup([student], assignments);
  return submissionStateMap;
}

QUnit.module('SubmissionStateMap without grading periods', function (suiteHooks) {
  const dueDate = '2015-07-15';
  let assignment;
  let submissionStateMap;
  let options;

  suiteHooks.beforeEach(() => {
    options = { hasGradingPeriods: false };
    assignment = { id: '1', published: true, effectiveDueDates: {} };
  });

  QUnit.module('inNoGradingPeriod', function (_hooks) {
    test('returns undefined if submission has no grading period', function () {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false
      }
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inNoGradingPeriod, undefined);
    });

    test('returns undefined if submission has a grading period', function () {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        grading_period_id: 1,
        in_closed_grading_period: false
      }
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inNoGradingPeriod, undefined);
    });
  });

  QUnit.module('inOtherGradingPeriod', function (hooks) {
    hooks.beforeEach(() => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false
      };
    });

    test('returns undefined if filtering by grading period and submission is not in any grading period', function () {
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inOtherGradingPeriod, undefined);
    });

    test('returns undefined if filtering by grading period and submission is in another grading period', function () {
      assignment.effectiveDueDates[student.id].grading_period_id = '1';
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inOtherGradingPeriod, undefined);
    });

    test('returns undefined if filtering by grading period and submission is in the same grading period', function () {
      assignment.effectiveDueDates[student.id].grading_period_id = '2';
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inOtherGradingPeriod, undefined);
    });
  });

  QUnit.module('inClosedGradingPeriod', function (hooks) {
    hooks.beforeEach(() => {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
      };
    });

    test('returns undefined if submission is in a closed grading period', function () {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = true;
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inClosedGradingPeriod, undefined);
    });

    test('returns undefined if submission is in a closed grading period', function () {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = false;
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inClosedGradingPeriod, undefined);
    });
  });
});

QUnit.module('SubmissionStateMap with grading periods', function (suiteHooks) {
  const dueDate = '2015-07-15';
  let assignment;
  let submissionStateMap;
  let options;

  suiteHooks.beforeEach(() => {
    options = { hasGradingPeriods: true, selectedGradingPeriodID: '0' };
    assignment = { id: '1', published: true, effectiveDueDates: {} };
  });

  QUnit.module('inNoGradingPeriod', function (_hooks2) {
    test('returns true if submission has no grading period', function () {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false
      }
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inNoGradingPeriod, true);
    });

    test('returns false if submission has a grading period', function () {
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        grading_period_id: 1,
        in_closed_grading_period: false
      }
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inNoGradingPeriod, false);
    });
  });

  QUnit.module('inOtherGradingPeriod', function (hooks) {
    hooks.beforeEach(() => {
      options = { hasGradingPeriods: true, selectedGradingPeriodID: '2' };
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
        in_closed_grading_period: false
      };
    });

    test('returns false if filtering by grading period and submission is not in any grading period', function () {
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inOtherGradingPeriod, false);
    });

    test('returns true if filtering by grading period and submission is in another grading period', function () {
      assignment.effectiveDueDates[student.id].grading_period_id = '1';
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inOtherGradingPeriod, true);
    });

    test('returns false if filtering by grading period and submission is in the same grading period', function () {
      assignment.effectiveDueDates[student.id].grading_period_id = '2';
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inOtherGradingPeriod, false);
    });
  });

  QUnit.module('inClosedGradingPeriod', function (hooks) {
    hooks.beforeEach(() => {
      options = { hasGradingPeriods: true, selectedGradingPeriodID: '2' };
      assignment.effectiveDueDates[student.id] = {
        due_at: dueDate,
      };
    });

    test('returns true if submission is in a closed grading period', function () {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = true;
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inClosedGradingPeriod, true);
    });

    test('returns true if submission is in a closed grading period', function () {
      assignment.effectiveDueDates[student.id].in_closed_grading_period = false;
      submissionStateMap = createAndSetupMap(assignment, options);

      const state = submissionStateMap.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });

      strictEqual(state.inClosedGradingPeriod, false);
    });
  });
});
