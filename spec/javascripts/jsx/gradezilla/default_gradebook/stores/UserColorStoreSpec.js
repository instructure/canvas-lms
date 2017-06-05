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

import { getUserColors } from 'jsx/gradezilla/default_gradebook/stores/UserColorStore'
import colors from 'jsx/gradezilla/default_gradebook/constants/colors'

const { dark, light } = colors;

QUnit.module('UserColorStore.getUserColors');

test("given a user's preference, use those first", function () {
  const userColors = {
    dropped: 'pink',
    excused: 'orange',
    late: 'lavender',
    missing: 'yellow',
    resubmitted: 'purple'
  };
  const expectedColors = {
    light: {
      dropped: light.pink,
      excused: light.orange,
      late: light.lavender,
      missing: light.yellow,
      resubmitted: light.purple
    },
    dark: {
      dropped: dark.pink,
      excused: dark.orange,
      late: dark.lavender,
      missing: dark.yellow,
      resubmitted: dark.purple
    }
  };
  deepEqual(getUserColors(userColors), expectedColors);
});

test('has light key', function () {
  ok('light' in getUserColors());
});

test('has dark key', function () {
  ok('dark' in getUserColors());
});

test('dropped defaults to light orange', function () {
  const { light: { dropped } } = getUserColors();
  const { light: { orange } } = colors;
  equal(dropped, orange);
});

test('dropped defaults to dark orange', function () {
  const { dark: { dropped } } = getUserColors();
  const { dark: { orange } } = colors;
  equal(dropped, orange);
});

test('excused defaults to light yellow', function () {
  const { light: { excused } } = getUserColors();
  const { light: { yellow } } = colors;
  equal(excused, yellow);
});

test('excused defaults to dark yellow', function () {
  const { dark: { excused } } = getUserColors();
  const { dark: { yellow } } = colors;
  equal(excused, yellow);
});

test('late defaults to light blue', function () {
  const { light: { late } } = getUserColors();
  const { light: { blue } } = colors;
  equal(late, blue);
});

test('late defaults to dark blue', function () {
  const { dark: { late } } = getUserColors();
  const { dark: { blue } } = colors;
  equal(late, blue);
});

test('missing defaults to light purple', function () {
  const { light: { missing } } = getUserColors();
  const { light: { purple } } = colors;
  equal(missing, purple);
});

test('missing defaults to dark purple', function () {
  const { dark: { missing } } = getUserColors();
  const { dark: { purple } } = colors;
  equal(missing, purple);
});

test('resubmitted defaults to light green', function () {
  const { light: { resubmitted } } = getUserColors();
  const { light: { green } } = colors;
  equal(resubmitted, green);
});

test('resubmitted defaults to dark green', function () {
  const { dark: { resubmitted } } = getUserColors();
  const { dark: { green } } = colors;
  equal(resubmitted, green);
});

test('ignores other keys', function () {
  const colorKeys = Object.keys(getUserColors({ light: { fakeKey: 'fakeKey' } }).light);
  notOk(colorKeys.includes('fakeKey'));
});
