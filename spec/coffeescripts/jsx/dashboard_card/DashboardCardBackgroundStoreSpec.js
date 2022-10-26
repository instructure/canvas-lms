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

import fetchMock from 'fetch-mock'
import DashboardCardBackgroundStore from '@canvas/dashboard-card/react/DashboardCardBackgroundStore'
import fakeENV from 'helpers/fakeENV'

const TEST_COLORS = {
  '#008400': '#008400',
  '#91349B': '#91349B',
  '#E1185C': '#E1185C',
}
DashboardCardBackgroundStore.reset = function () {
  return this.setState({
    courseColors: TEST_COLORS,
    usedDefaults: [],
  })
}

QUnit.module('DashboardCardBackgroundStore', {
  setup() {
    DashboardCardBackgroundStore.reset()
    fakeENV.setup()
    ENV.PREFERENCES = {custom_colors: TEST_COLORS}
    ENV.current_user_id = 22
    fetchMock.put('path:/api/v1/users/22/colors/course_1', {
      status: 200,
      headers: {'Content-Type': 'application/json'},
      body: '',
    })
    fetchMock.put('path:/api/v1/users/22/colors/course_2', {
      status: 200,
      headers: {'Content-Type': 'application/json'},
      body: '',
    })
    fetchMock.put('path:/api/v1/users/22/colors/course_3', {
      status: 200,
      headers: {'Content-Type': 'application/json'},
      body: '',
    })
  },
  teardown() {
    fetchMock.restore()
    DashboardCardBackgroundStore.reset()
    fakeENV.teardown()
  },
})

// ================================
// GETTING CUSTOM COLORS FROM ENV
// ================================
test('gets colors from env', () =>
  deepEqual(DashboardCardBackgroundStore.getCourseColors(), TEST_COLORS))

// ===================
//   DEFAULT COLORS
// ===================

test('will not reuse a color if it is used more than the others', () => {
  ok(DashboardCardBackgroundStore.leastUsedDefaults().includes('#008400'))
  DashboardCardBackgroundStore.setState({usedDefaults: ['#008400']})
  ok(!DashboardCardBackgroundStore.leastUsedDefaults().includes('#008400'))
})

test('maintains list of used defaults', () => {
  ok(!DashboardCardBackgroundStore.getUsedDefaults().includes('#91349B'))
  DashboardCardBackgroundStore.markColorUsed('#91349B')
  ok(DashboardCardBackgroundStore.getUsedDefaults().includes('#91349B'))
})

test('PUTs to the server when a default is set', async function () {
  DashboardCardBackgroundStore.setDefaultColor('course_1')
  await fetchMock.flush()
  ok(fetchMock.lastUrl().match(/course_1/))
  equal(fetchMock.calls().length, 1)
})

test('sets multiple defaults properly', async function () {
  DashboardCardBackgroundStore.setDefaultColors(['course_2', 'course_3'])
  await fetchMock.flush()
  ok(fetchMock.calls()[0][0].match(/course_2/))
  ok(fetchMock.calls()[1][0].match(/course_3/))
  equal(fetchMock.calls().length, 2)
})

// ==========================
//    UPDATING CUSTOM COLOR
// ==========================

test('sets a custom color properly', () => {
  DashboardCardBackgroundStore.setState({courseColors: {foo: 'bar'}})
  equal(DashboardCardBackgroundStore.colorForCourse('foo'), 'bar')
  DashboardCardBackgroundStore.setColorForCourse('foo', 'baz')
  equal(DashboardCardBackgroundStore.colorForCourse('foo'), 'baz')
})
