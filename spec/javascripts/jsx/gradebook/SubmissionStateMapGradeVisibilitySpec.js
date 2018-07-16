/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
  'timezone',
  'jsx/gradebook/SubmissionStateMap'
], (_, tz, SubmissionStateMap) => {
  const student = {
    id: '1',
    group_ids: ['1'],
    sections: ['1']
  };

  function createMap(opts={}) {
    const defaults = {
      hasGradingPeriods: false,
      selectedGradingPeriodID: '0',
      isAdmin: false
    };

    const params = Object.assign(defaults, opts);
    return new SubmissionStateMap(params);
  }

  function createAndSetupMap(assignment, opts={}) {
    const map = createMap(opts);
    const assignments = {};
    assignments[assignment.id] = assignment;
    map.setup([student], assignments);
    return map;
  }

  // TODO: the spec setup above should live in a spec helper -- at the
  // time this is being written a significant amount of work is needed
  // to be able to require javascript files that live in the spec directory

  QUnit.module('SubmissionStateMap');

  test ('submission has grade visible if not anonymous', function() {
    const assignment = { id: '1', muted: true };
    const map = createAndSetupMap(assignment);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    strictEqual(state.hideGrade, false);
  });

  test ('submission has grade visible if not muted', function() {
    const assignment = { id: '1', anonymous_grading: true };
    const map = createAndSetupMap(assignment);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    strictEqual(state.hideGrade, false);
  });

  test ('submission has grade hidden if anonymize_students is true', function() {
    const assignment = { id: '1', anonymize_students: true };
    const map = createAndSetupMap(assignment);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    strictEqual(state.hideGrade, true);
  });

  test ('submission has grade visible if not moderated', function() {
    const assignment = { id: '1', moderated_grading: false, grades_published: false };
    const map = createAndSetupMap(assignment);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    strictEqual(state.hideGrade, false);
  });

  test ('submission has grade visible if grades are published', function() {
    const assignment = { id: '1', moderated_grading: false, grades_published: true };
    const map = createAndSetupMap(assignment);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    strictEqual(state.hideGrade, false);
  });

  test ('submission has grade visible if moderated and not published', function() {
    const assignment = { id: '1', moderated_grading: true, grades_published: false };
    const map = createAndSetupMap(assignment);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    strictEqual(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap without grading periods');

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, { hasGradingPeriods: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for a student with assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: null,
      grading_period_id: null,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, { hasGradingPeriods: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap with grading periods and all grading periods selected', {
    setup() {
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_NOT_IN_CLOSED_PERIOD = '2015-08-15';
      this.mapOptions = { hasGradingPeriods: true, selectedGradingPeriodID: '0' };
    }
  });

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_CLOSED_PERIOD,
      grading_period_id: '1',
      in_closed_grading_period: true
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  test('submission has grade visible for an assigned student with assignment due outside of a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_CLOSED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap with grading periods and a non-closed grading period selected', {
    setup() {
      this.SELECTED_PERIOD_ID = '1';
      this.DATE_IN_SELECTED_PERIOD = '2015-08-15';
      this.DATE_NOT_IN_SELECTED_PERIOD = '2015-10-15';
      this.mapOptions = { hasGradingPeriods: true, selectedGradingPeriodID: this.SELECTED_PERIOD_ID };
    }
  });

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });

  QUnit.module('SubmissionStateMap with grading periods and a closed grading period selected', {
    setup() {
      this.SELECTED_PERIOD_ID = '1';
      this.DATE_IN_SELECTED_PERIOD = '2015-07-15';
      this.DATE_NOT_IN_SELECTED_PERIOD = '2015-08-15';
      this.mapOptions = { hasGradingPeriods: true, selectedGradingPeriodID: this.SELECTED_PERIOD_ID };
    }
  });

  test('submission has grade hidden for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade hidden for an assigned student with assignment due outside of the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, true);
  });

  test('submission has grade visible for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: true
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.hideGrade, false);
  });
});
