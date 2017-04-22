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
  'jsx/gradebook/EffectiveDueDates'
], (_, EffectiveDueDates) => {
  const exampleDueDatesData = {
    201: {
      101: {
        due_at: '2015-05-04T12:00:00Z',
        grading_period_id: '701',
        in_closed_grading_period: true
      },
      102: {
        due_at: '2015-05-05T12:00:00Z',
        grading_period_id: '701',
        in_closed_grading_period: true
      }
    },
    202: {
      101: {
        due_at: '2015-06-04T12:00:00Z',
        grading_period_id: '702',
        in_closed_grading_period: false
      }
    }
  };

  QUnit.module('EffectiveDueDates.scopeToUser');

  test('returns a map with effective due dates keyed to assignment ids', () => {
    const scopedDueDates = EffectiveDueDates.scopeToUser(exampleDueDatesData, '101');
    deepEqual(_.keys(scopedDueDates).sort(), ['201', '202']);
    deepEqual(_.keys(scopedDueDates[201]).sort(), ['due_at', 'grading_period_id', 'in_closed_grading_period']);
  });

  test('includes all effective due dates for the given user', () => {
    const scopedDueDates = EffectiveDueDates.scopeToUser(exampleDueDatesData, '101');
    equal(scopedDueDates[201].due_at, '2015-05-04T12:00:00Z');
    equal(scopedDueDates[201].grading_period_id, '701');
    equal(scopedDueDates[201].in_closed_grading_period, true);
    equal(scopedDueDates[202].due_at, '2015-06-04T12:00:00Z');
    equal(scopedDueDates[202].grading_period_id, '702');
    equal(scopedDueDates[202].in_closed_grading_period, false);
  });

  test('excludes assignments not assigned to the given user', () => {
    const scopedDueDates = EffectiveDueDates.scopeToUser(exampleDueDatesData, '102');
    deepEqual(_.keys(scopedDueDates), ['201']);
    equal(scopedDueDates[201].due_at, '2015-05-05T12:00:00Z');
    equal(scopedDueDates[201].grading_period_id, '701');
    equal(scopedDueDates[201].in_closed_grading_period, true);
  });
});
