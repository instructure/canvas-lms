/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
  'react',
  'react-addons-test-utils',
  'jsx/shared/TimeZoneSelect'
], (React, TestUtils, TimeZoneSelect) => {

  QUnit.module('TimeZoneSelect Component');

  test('filterTimeZones', () => {
    const timezones = [{
      name: 'Central'
    }, {
      name: 'Eastern'
    }, {
      name: 'Mountain'
    }, {
      name: 'Pacific'
    }];

    const priorityZones = [{
      name: 'Mountain'
    }];

    const component = TestUtils.renderIntoDocument(
      <TimeZoneSelect timezones={timezones} priority_timezones={priorityZones} />
    );

    const withoutPriority = component.filterTimeZones(timezones, priorityZones);
    const expected = [{
      name: 'Central'
    }, {
      name: 'Eastern'
    }, {
      name: 'Pacific'
    }];

    deepEqual(withoutPriority, expected, 'the filter removed zones with priority');
  });


});