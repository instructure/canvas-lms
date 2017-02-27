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

  const tooltipKeys = {
    NOT_IN_ANY_GP: "not_in_any_grading_period",
    IN_ANOTHER_GP: "in_another_grading_period",
    IN_CLOSED_GP: "in_closed_grading_period",
    NONE: null
  };

  function createMap(opts={}) {
    const defaults = {
      hasGradingPeriods: false,
      selectedGradingPeriodID: '0',
      isAdmin: false,
      gradingPeriods: []
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

  QUnit.module('SubmissionStateMap without grading periods');

  test('submission has no tooltip for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, { hasGradingPeriods: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  test('submission has no tooltip for a student with visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: null,
      grading_period_id: null,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, { hasGradingPeriods: false });
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  QUnit.module('SubmissionStateMap with grading periods and all grading periods selected', {
    setup() {
      this.DATE_IN_CLOSED_PERIOD = '2015-07-15';
      this.DATE_NOT_IN_CLOSED_PERIOD = '2015-08-15';
      this.mapOptions = { hasGradingPeriods: true, selectedGradingPeriodID: '0' };
    }
  });

  test('submission has no tooltip for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  test('submission shows "in closed period" tooltip for an assigned student with assignment due in a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_CLOSED_PERIOD,
      grading_period_id: '1',
      in_closed_grading_period: true
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.IN_CLOSED_GP);
  });

  test('user is admin: submission has no tooltip for an assigned student with assignment due in a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_CLOSED_PERIOD,
      grading_period_id: '1',
      in_closed_grading_period: true
    };

    const mapOptions = Object.assign(this.mapOptions, { isAdmin: true });
    const map = createAndSetupMap(assignment, mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  test('submission has no tooltip for an assigned student with assignment due outside of a closed grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_CLOSED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  QUnit.module('SubmissionStateMap with grading periods and a non-closed grading period selected', {
    setup() {
      this.SELECTED_PERIOD_ID = '1';
      this.DATE_IN_SELECTED_PERIOD = '2015-06-15';
      this.DATE_NOT_IN_SELECTED_PERIOD = '2015-07-15';
      this.mapOptions = { hasGradingPeriods: true, selectedGradingPeriodID: this.SELECTED_PERIOD_ID };
    }
  });

  test('submission has no tooltip for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  test('submission has no tooltip for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  test('submission shows "not in any period" tooltip for an assigned student with a submission not in any grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: null,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NOT_IN_ANY_GP);
  });

  test('submission shows "in another period" tooltip for an assigned student with assignment due in a non-selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.IN_ANOTHER_GP);
  });

  QUnit.module('SubmissionStateMap with grading periods and a closed grading period selected', {
    setup() {
      this.SELECTED_PERIOD_ID = '1';
      this.DATE_IN_SELECTED_PERIOD = '2015-07-15';
      this.DATE_NOT_IN_SELECTED_PERIOD = '2015-08-15';
      this.mapOptions = { hasGradingPeriods: true, selectedGradingPeriodID: this.SELECTED_PERIOD_ID };
    }
  });

  test('submission has no tooltip for a student without assignment visibility', function() {
    const assignment = { id: '1', effectiveDueDates: {}, only_visible_to_overrides: true };
    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });

  test('submission shows "in another period" tooltip for an assigned student with assignment due in a non-selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: '2',
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.IN_ANOTHER_GP);
  });

  test('submission shows "not in any period" tooltip for an assigned student with assignment due in no grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_NOT_IN_SELECTED_PERIOD,
      grading_period_id: null,
      in_closed_grading_period: false
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NOT_IN_ANY_GP);
  });

  test('submission shows "in closed period" tooltip for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: true
    };

    const map = createAndSetupMap(assignment, this.mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.IN_CLOSED_GP);
  });

  test('user is admin: submission has no tooltip for an assigned student with assignment due in the selected grading period', function() {
    const assignment = { id: '1', effectiveDueDates: {} };
    assignment.effectiveDueDates[student.id] = {
      due_at: this.DATE_IN_SELECTED_PERIOD,
      grading_period_id: this.SELECTED_PERIOD_ID,
      in_closed_grading_period: true
    };

    const mapOptions = { ...this.mapOptions, isAdmin: true };
    const map = createAndSetupMap(assignment, mapOptions);
    const state = map.getSubmissionState({ user_id: student.id, assignment_id: assignment.id });
    equal(state.tooltip, tooltipKeys.NONE);
  });
});
