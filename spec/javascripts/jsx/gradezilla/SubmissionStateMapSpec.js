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

const student = {
  id: '1',
  group_ids: ['1'],
  sections: ['1']
};

function createMap (opts = {}) {
  const defaults = {
    hasGradingPeriods: false,
    selectedGradingPeriodID: '0',
    isAdmin: false
  };

  const params = { ...defaults, ...opts };
  return new SubmissionStateMap(params);
}

function createAndSetupMap (assignment, opts = {}) {
  const map = createMap(opts);
  const assignments = {};
  assignments[assignment.id] = assignment;
  map.setup([student], assignments);
  return map;
}

QUnit.module('#setSubmissionCellState - when there is no submission');

test('the submission object is missing if the assignment is late', function () {
  const yesterday = moment(new Date()).subtract(1, 'day')
  const assignment = {
    id: '1',
    published: true,
    effectiveDueDates: { 1: { due_at: yesterday } }
  };
  const map = createAndSetupMap(assignment);
  const submission = map.getSubmission(student.id, assignment.id);
  strictEqual(submission.missing, true);
});

test('the submission object is not missing if the assignment is not late', function () {
  const tomorrow = moment(new Date()).add(1, 'day')
  const assignment = {
    id: '1',
    published: true,
    effectiveDueDates: { 1: { due_at: tomorrow } }
  };
  const map = createAndSetupMap(assignment);
  const submission = map.getSubmission(student.id, assignment.id);
  strictEqual(submission.missing, false);
});

test('the submission object is not missing, if the assignment is not late ' +
  'and there are no due dates', function () {
  const assignment = {
    id: '1',
    published: true,
    effectiveDueDates: {}
  };
  const map = createAndSetupMap(assignment);
  const submission = map.getSubmission(student.id, assignment.id);
  strictEqual(submission.missing, false);
});

test('the submission object has seconds_late set to zero', function () {
  const assignment = {
    id: '1',
    published: true,
    effectiveDueDates: { 1: { due_at: new Date() } }
  };
  const map = createAndSetupMap(assignment);
  const submission = map.getSubmission(student.id, assignment.id);
  strictEqual(submission.seconds_late, 0);
});

test('the submission object has late set to false', function () {
  const assignment = {
    id: '1',
    published: true,
    effectiveDueDates: { 1: { due_at: new Date() } }
  };
  const map = createAndSetupMap(assignment);
  const submission = map.getSubmission(student.id, assignment.id);
  strictEqual(submission.late, false);
});

test('the submission object has excused set to false', function () {
  const assignment = {
    id: '1',
    published: true,
    effectiveDueDates: { 1: { due_at: new Date() } }
  };
  const map = createAndSetupMap(assignment);
  const submission = map.getSubmission(student.id, assignment.id);
  strictEqual(submission.excused, false);
});
