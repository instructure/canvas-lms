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

import axios from '@canvas/axios'
import AssignmentApi from '../AssignmentApi'

describe('AssignmentApi', () => {
  let getStub
  const courseId = 23

  beforeEach(() => {
    getStub = jest.spyOn(axios, 'get').mockResolvedValue({
      response: {},
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  test('getAssignmentsByName makes a request with a search term', async () => {
    const url = `/api/v1/courses/${courseId}/assignments`
    const searchTerm = "Gary's late assignment"
    const params = {
      params: {
        search_term: searchTerm,
      },
    }

    await AssignmentApi.getAssignmentsByName(courseId, searchTerm)

    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url, params)
  })

  test('getAssignmentsNextPage makes a request with given url', async () => {
    const url = 'https://example.com/assignments?page=2'

    await AssignmentApi.getAssignmentsNextPage(url)

    expect(getStub).toHaveBeenCalledTimes(1)
    expect(getStub).toHaveBeenCalledWith(url)
  })
})
