/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {paceContextsActions} from '../pace_contexts'
import {
  PACE_CONTEXTS_SECTIONS_RESPONSE,
  PACE_CONTEXTS_STUDENTS_RESPONSE,
  COURSE,
  DEFAULT_STORE_STATE,
  PACE_CONTEXTS_DEFAULT_STATE,
} from '../../__tests__/fixtures'

const SECTION_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=section&page=1&per_page=10`
const STUDENT_CONTEXTS_API = `/api/v1/courses/${COURSE.id}/pace_contexts?type=student_enrollment&page=1&per_page=10`

const dispatch = jest.fn()

describe('Pace contexts actions', () => {
  afterEach(() => {
    jest.clearAllMocks()
    fetchMock.restore()
  })

  it('fetches section pace contexts', async () => {
    fetchMock.get(SECTION_CONTEXTS_API, JSON.stringify(PACE_CONTEXTS_SECTIONS_RESPONSE))
    const thunkedAction: any = paceContextsActions.fetchPaceContexts({
      contextType: 'section',
      page: 1,
    })
    const getState = () => ({
      ...DEFAULT_STORE_STATE,
      paceContexts: PACE_CONTEXTS_DEFAULT_STATE,
    })
    await thunkedAction(dispatch, getState)
    expect(fetchMock.called(SECTION_CONTEXTS_API, 'GET')).toBe(true)
  })

  it('fetches student pace contexts', async () => {
    fetchMock.get(STUDENT_CONTEXTS_API, JSON.stringify(PACE_CONTEXTS_STUDENTS_RESPONSE))
    const thunkedAction: any = paceContextsActions.fetchPaceContexts({
      contextType: 'student_enrollment',
      page: 1,
    })
    const getState = () => ({
      ...DEFAULT_STORE_STATE,
      paceContexts: PACE_CONTEXTS_DEFAULT_STATE,
    })
    await thunkedAction(dispatch, getState)
    expect(fetchMock.called(STUDENT_CONTEXTS_API, 'GET')).toBe(true)
  })
})
