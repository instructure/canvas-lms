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

import moment from 'moment';
import SubmissionStateMap from 'jsx/gradezilla/SubmissionStateMap';

const studentWithoutSubmission = {
  id: '1',
  group_ids: ['1'],
  sections: ['1']
};

const studentWithSubmission = {
  id: '1',
  group_ids: ['1'],
  sections: ['1'],
  assignment_1: {}
};

const yesterday = moment(new Date()).subtract(1, 'day');
const tomorrow = moment(new Date()).add(1, 'day');

function createMap (opts = {}) {
  const defaults = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false,
    anonymousModeratedMarkingEnabled: false
  };

  const params = { ...defaults, ...opts };
  return new SubmissionStateMap(params);
}

function createAndSetupMap (assignment, student, opts = {}) {
  const map = createMap(opts);
  const assignments = {};
  assignments[assignment.id] = assignment;
  map.setup([student], assignments);
  return map;
}

QUnit.module('#setSubmissionCellState', function() {
  test('the submission state is locked if assignment is not published', function() {
    const assignment = {
      id: '1',
      published: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, true);
  });

  test('the submission state has hideGrade set if assignment is not published', function() {
    const assignment = {
      id: '1',
      published: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, true);
  });

  test('the submission state is locked if assignment is not visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: []
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, true);
  });

  test('the submission state has hideGrade set if assignment is not visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: true,
      assignment_visibility: []
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, true);
  });

  test('the submission state is not locked if assignment is published and visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.locked, false);
  });

  test('the submission state has hideGrade not set if assignment is published and visible', function() {
    const assignment = {
      id: '1',
      published: true,
      only_visible_to_overrides: false
    };
    const map = createAndSetupMap(assignment, studentWithSubmission);
    const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
    strictEqual(submission.hideGrade, false);
  });

  QUnit.module('anonymous moderated marking enabled', function() {
    test('the submission state is locked when the student is not assigned', function() {
      const assignment = {
        id: '1',
        published: true,
        only_visible_to_overrides: true,
        assignment_visibility: ['2']
      }
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true })
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
      strictEqual(submission.locked, true)
    })

    test('the submission state is not locked if not moderated grading', function() {
      const assignment = {
        id: '1',
        published: true,
        moderated_grading: false
      };
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true });
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
      strictEqual(submission.locked, false);
    });

    test('the submission state has hideGrade not set if not moderated grading', function() {
      const assignment = {
        id: '1',
        published: true,
        moderated_grading: false
      };
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true });
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
      strictEqual(submission.hideGrade, false);
    });

    test('the submission state is not locked if moderated grading and grades published', function() {
      const assignment = {
        id: '1',
        published: true,
        moderated_grading: true,
        grades_published: true
      };
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true });
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
      strictEqual(submission.locked, false);
    });

    test('the submission state has hideGrade not set if moderated grading and grades published', function() {
      const assignment = {
        id: '1',
        published: true,
        moderated_grading: true,
        grades_published: true
      };
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true });
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
      strictEqual(submission.hideGrade, false);
    });

    test('the submission state is locked if moderated grading and grades not published', function() {
      const assignment = {
        id: '1',
        published: true,
        moderated_grading: true,
        grades_published: false
      };
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true });
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
      strictEqual(submission.locked, true);
    });

    test('the submission state has hideGrade not set if moderated grading and grades not published', function() {
      const assignment = {
        id: '1',
        published: true,
        moderated_grading: true,
        grades_published: false
      };
      const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true });
      const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id });
      strictEqual(submission.hideGrade, false);
    });

    QUnit.module('when the assignment is anonymous', function(hooks) {
      let assignment

      hooks.beforeEach(() => {
        assignment = { id: '1', published: true, anonymous_grading: true }
      })

      test('the submission state is locked when the assignment is muted', function() {
        assignment.muted = true
        const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true })
        const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
        strictEqual(submission.locked, true)
      })

      test('the submission state is hidden when the assignment is muted', function() {
        assignment.muted = true
        const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true })
        const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
        strictEqual(submission.hideGrade, true)
      })

      test('the submission state is unlocked when the assignment is unmuted', function() {
        const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true })
        const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
        strictEqual(submission.locked, false)
      })

      test('the submission state is not hidden when the assignment is unmuted', function() {
        const map = createAndSetupMap(assignment, studentWithSubmission, { anonymousModeratedMarkingEnabled: true })
        const submission = map.getSubmissionState({ user_id: studentWithSubmission.id, assignment_id: assignment.id })
        strictEqual(submission.hideGrade, false)
      })
    })
  });

  QUnit.module('no submission', function() {
    test('the submission object is missing if the assignment is late', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: yesterday } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.missing, true);
    });

    test('the submission object is not missing if the assignment is not late', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: tomorrow } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.missing, false);
    });

    test('the submission object is not missing, if the assignment is not late ' +
      'and there are no due dates', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: {}
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.missing, false);
    });

    test('the submission object has seconds_late set to zero', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: new Date() } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.seconds_late, 0);
    });

    test('the submission object has late set to false', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: new Date() } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.late, false);
    });

    test('the submission object has excused set to false', function () {
      const assignment = {
        id: '1',
        published: true,
        effectiveDueDates: { 1: { due_at: new Date() } }
      };
      const map = createAndSetupMap(assignment, studentWithoutSubmission);
      const submission = map.getSubmission(studentWithoutSubmission.id, assignment.id);
      strictEqual(submission.excused, false);
    });
  });
});
