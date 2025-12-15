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
import moment from 'moment-timezone'
import * as Actions from '../loading-actions'
import {queryClient} from '@canvas/query'
import {MOCK_QUERY_CARDS_RESPONSE} from '@canvas/k5/react/__tests__/fixtures'

vi.mock('../../utilities/apiUtils', async () => {
  const actual = await vi.importActual('../../utilities/apiUtils')
  return {
    ...actual,
    getContextCodesFromState: actual.getContextCodesFromState,
    findNextLink: vi.fn(),
    transformApiToInternalItem: vi.fn(response => ({
      ...response,
      newActivity: response.new_activity,
      transformedToInternal: true,
    })),
    transformInternalToApiItem: vi.fn(internal => ({...internal, transformedToApi: true})),
    observedUserId: actual.observedUserId,
  }
})

const getBasicState = () => ({
  courses: [],
  groups: [],
  timeZone: 'UTC',
  days: [
    ['2017-05-22', [{id: '42', dateBucketMoment: moment.tz('2017-05-22', 'UTC')}]],
    ['2017-05-24', [{id: '42', dateBucketMoment: moment.tz('2017-05-24', 'UTC')}]],
  ],
  loading: {
    futureNextUrl: null,
    pastNextUrl: null,
  },
  weeklyDashboard: {
    // copied from weekly-reducers INITIAL_OPTIONS
    weekStart: moment.tz('UTC').startOf('week'),
    weekEnd: moment.tz('UTC').endOf('week'),
    thisWeek: moment.tz('UTC').startOf('week'),
    weeks: {},
  },
  selectedObservee: null,
  currentUser: {id: '1'},
})

vi.mock('@canvas/dashboard-card/dashboardCardQueries', () => ({
  fetchDashboardCardsAsync: vi.fn(() => Promise.resolve(MOCK_QUERY_CARDS_RESPONSE)),
}))

describe('getCourseList with GraphQL integration', () => {
  let mockDispatch
  beforeEach(() => {
    mockDispatch = vi.fn()
    global.ENV = {
      FEATURES: {dashboard_graphql_integration: true},
      current_user_id: '1',
    }
  })

  const assertCorrectCourseData = data => {
    expect(data).toHaveLength(3)
    expect(data).toEqual(
      expect.arrayContaining([
        expect.objectContaining({id: '1', shortName: 'Economics 101'}),
        expect.objectContaining({id: '2', shortName: 'Home Room'}),
        expect.objectContaining({id: '3', shortName: 'The Maths'}),
      ]),
    )
  }

  it('returns dashboard cards from cache when available', async () => {
    const queryKey = ['dashboard_cards', {userID: '1', observedUserID: undefined}]
    queryClient.setQueryData(queryKey, MOCK_QUERY_CARDS_RESPONSE)
    const result = await Actions.getCourseList()(mockDispatch, getBasicState)
    assertCorrectCourseData(result.data)
  })

  it('fetches dashboard cards via GraphQL when cache is empty', async () => {
    queryClient.clear()
    const result = await Actions.getCourseList()(mockDispatch, getBasicState)
    assertCorrectCourseData(result.data)
  })
})
