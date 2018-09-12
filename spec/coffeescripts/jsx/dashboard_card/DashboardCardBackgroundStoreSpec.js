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

import DashboardCardBackgroundStore from 'jsx/dashboard_card/DashboardCardBackgroundStore'
import fakeENV from 'helpers/fakeENV'

const TEST_COLORS = {
  '#008400': '#008400',
  '#91349B': '#91349B',
  '#E1185C': '#E1185C'
}
DashboardCardBackgroundStore.reset = function() {
  return this.setState({
    courseColors: TEST_COLORS,
    usedDefaults: []
  })
}

QUnit.module('DashboardCardBackgroundStore', {
  setup() {
    DashboardCardBackgroundStore.reset()
    fakeENV.setup()
    ENV.PREFERENCES = {custom_colors: TEST_COLORS}
    ENV.current_user_id = 22
    this.server = sinon.fakeServer.create()
    this.response = []
    this.server.respondWith('POST', '/api/v1/users/22/colors/course_1', [
      200,
      {'Content-Type': 'application/json'},
      ''
    ])
    this.server.respondWith('POST', '/api/v1/users/22/colors/course_2', [
      200,
      {'Content-Type': 'application/json'},
      ''
    ])
    this.server.respondWith('POST', '/api/v1/users/22/colors/course_3', [
      200,
      {'Content-Type': 'application/json'},
      ''
    ])
  },
  teardown() {
    this.server.restore()
    DashboardCardBackgroundStore.reset()
    fakeENV.teardown()
  }
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

test('posts to the server when a default is set', function() {
  DashboardCardBackgroundStore.setDefaultColor('course_1')
  ok(this.server.requests[0].url.match(/course_1/))
  equal(this.server.requests.length, 1)
  this.server.respond()
})

test('sets multiple defaults properly', function() {
  DashboardCardBackgroundStore.setDefaultColors(['course_2', 'course_3'])
  ok(this.server.requests[0].url.match(/course_2/))
  ok(this.server.requests[1].url.match(/course_3/))
  equal(this.server.requests.length, 2)
  return this.server.respond()
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
