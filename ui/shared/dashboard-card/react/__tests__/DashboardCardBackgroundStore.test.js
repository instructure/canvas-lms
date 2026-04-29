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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import DashboardCardBackgroundStore from '../DashboardCardBackgroundStore'
import fakeENV from '@canvas/test-utils/fakeENV'

const ok = x => expect(x).toBeTruthy()
const deepEqual = (a, b) => expect(a).toEqual(b)
const equal = (a, b) => expect(a).toBe(b)

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

const server = setupServer()

// Track API calls
const apiCalls = []

describe('DashboardCardBackgroundStore', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    apiCalls.length = 0
    DashboardCardBackgroundStore.reset()
    fakeENV.setup()
    ENV.PREFERENCES = {custom_colors: TEST_COLORS}
    ENV.current_user_id = 22
    server.use(
      http.put('/api/v1/users/22/colors/:assetString', ({params}) => {
        apiCalls.push(`/api/v1/users/22/colors/${params.assetString}`)
        return HttpResponse.json({}, {status: 200})
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    DashboardCardBackgroundStore.reset()
    fakeENV.teardown()
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
    // Wait for async operation
    await new Promise(resolve => setTimeout(resolve, 50))
    ok(apiCalls.some(url => url.includes('course_1')))
    equal(apiCalls.length, 1)
  })

  test('sets multiple defaults properly', async function () {
    DashboardCardBackgroundStore.setDefaultColors(['course_2', 'course_3'])
    // Wait for async operations
    await new Promise(resolve => setTimeout(resolve, 100))
    ok(apiCalls.some(url => url.includes('course_2')))
    ok(apiCalls.some(url => url.includes('course_3')))
    equal(apiCalls.length, 2)
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
})
