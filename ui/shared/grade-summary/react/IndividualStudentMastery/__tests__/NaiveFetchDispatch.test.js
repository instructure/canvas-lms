/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import NaiveFetchDispatch from '../NaiveFetchDispatch'

describe('Outcomes > IndividualStudentMastery > NaiveFetchDispatch', () => {
  const URL = 'http://localhost/example'

  let dispatch

  beforeEach(() => {
    dispatch = new NaiveFetchDispatch({activeRequestLimit: 2})
  })

  describe('#fetch()', () => {
    let exampleData

    function resourceUrl(resourceIndex) {
      return `${URL}/?index=${resourceIndex}`
    }

    function stageRequests(resourceCount) {
      for (let resourceIndex = 1; resourceIndex <= resourceCount; resourceIndex++) {
        exampleData[resourceIndex] = {resourceIndex}
        fetchMock.mock(resourceUrl(resourceIndex), exampleData[resourceIndex])
      }
    }

    function fetch(resourceIndex) {
      return new Promise((resolve, reject) => {
        dispatch.fetch(resourceUrl(resourceIndex)).then(resolve).catch(reject)
      })
    }

    beforeEach(() => {
      exampleData = {}
      stageRequests(4)
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('sends a request for the resource', async () => {
      await fetch(1)
      expect(fetchMock.calls(url => url.match(URL))).toHaveLength(1)
    })

    it('resolves with the data from the request', async () => {
      const response = await fetch(1)
      expect(await response.json()).toMatchObject(exampleData[1])
    })

    it('resolves when flooded with requests', async () => {
      const requests = [1, 2, 3, 4].map(fetch)
      await Promise.all(requests)
      expect(fetchMock.calls(url => url.match(URL))).toHaveLength(4) // 4 resources
    })
  })
})
