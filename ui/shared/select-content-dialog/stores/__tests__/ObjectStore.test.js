/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import Store from '../ObjectStore'
import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../msw/mswServer'
import {waitFor} from '@testing-library/dom'

const handlers = []
const server = mswServer(handlers)

describe('ObjectStore', () => {
  let testStore
  let foldersPageOne
  let foldersPageTwo
  let foldersPageThree

  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    testStore = new Store('/api/v1/courses/2/folders', {someOption: 'value'}) // Update with required second argument
    foldersPageOne = [
      {
        full_name: 'course files/@123',
        id: 112,
        name: '@123',
        parent_folder_id: 13,
        position: 16,
        locked: false,
        folders_url: 'https://canvas.dev/api/v1/folders/112/folders',
        files_url: 'https://canvas.dev/api/v1/folders/112/files',
        files_count: 0,
        folders_count: 3,
      },
      {
        full_name: 'course files/A new special folder',
        id: 103,
        name: 'A new special folder',
        parent_folder_id: 13,
        position: 13,
        locked: false,
        folders_url: 'https://canvas.dev/api/v1/folders/103/folders',
        files_url: 'https://canvas.dev/api/v1/folders/103/files',
        files_count: 0,
        folders_count: 0,
      },
    ]
    foldersPageTwo = [
      {
        full_name: 'course files/@123',
        id: 325,
        name: '@123',
        parent_folder_id: 13,
        position: 16,
        locked: false,
        folders_url: 'https://canvas.dev/api/v1/folders/325/folders',
        files_url: 'https://canvas.dev/api/v1/folders/325/files',
        files_count: 0,
        folders_count: 0,
      },
      {
        full_name: 'course files/A new special folder',
        id: 326,
        name: 'A new special folder',
        parent_folder_id: 13,
        position: 13,
        locked: false,
        folders_url: 'https://canvas.dev/api/v1/folders/326/folders',
        files_url: 'https://canvas.dev/api/v1/folders/326/files',
        files_count: 0,
        folders_count: 0,
      },
    ]
    foldersPageThree = [
      {
        full_name: 'course files/@123',
        id: 123,
        name: '@123',
        parent_folder_id: 13,
        position: 16,
        locked: false,
        folders_url: 'https://canvas.dev/api/v1/folders/325/folders',
        files_url: 'https://canvas.dev/api/v1/folders/325/files',
        files_count: 0,
        folders_count: 0,
      },
      {
        full_name: 'course files/A new special folder',
        id: 456,
        name: 'A new special folder',
        parent_folder_id: 13,
        position: 13,
        locked: false,
        folders_url: 'https://canvas.dev/api/v1/folders/326/folders',
        files_url: 'https://canvas.dev/api/v1/folders/326/files',
        files_count: 0,
        folders_count: 0,
      },
    ]
    return testStore.reset()
  })

  afterEach(() => {
    return testStore.reset()
  })

  test('fetch', async () => {
    server.use(
      http.get(/\/folders/, () => {
        return HttpResponse.json(foldersPageOne)
      }),
    )
    testStore.fetch()
    await waitFor(() => {
      expect(testStore.getState().items).toEqual(foldersPageOne)
    })
  })

  test('fetch with fetchAll', async () => {
    const linkHeaders =
      '<https://folders?page=1&per_page=2>; rel="current",' +
      '<https://page2>; rel="next",' +
      '<https://folders?page=1&per_page=2>; rel="first",' +
      '<https://page2>; rel="last"'
    const linkHeaders2 =
      '<https://folders?page=2&per_page=2>; rel="current",' +
      '<https://page3>; rel="next",' +
      '<https://folders?page=1&per_page=2>; rel="first",' +
      '<https://page3>; rel="last"'

    server.use(
      http.get(/\/folders/, () => {
        return new HttpResponse(JSON.stringify(foldersPageOne), {
          headers: {
            'Content-Type': 'application/json',
            Link: linkHeaders,
          },
        })
      }),
      http.get(/page2/, () => {
        return new HttpResponse(JSON.stringify(foldersPageTwo), {
          headers: {
            'Content-Type': 'application/json',
            Link: linkHeaders2,
          },
        })
      }),
      http.get(/page3/, () => {
        return HttpResponse.json(foldersPageThree)
      }),
    )

    testStore.fetch({fetchAll: true})

    await waitFor(() => {
      expect(testStore.getState().items).toEqual(
        foldersPageOne.concat(foldersPageTwo).concat(foldersPageThree),
      )
    })
  })

  test('fetch with error', async () => {
    server.use(
      http.get(/\/folders/, () => {
        return new HttpResponse(null, {status: 500})
      }),
    )
    testStore.fetch()

    await waitFor(() => {
      const state = testStore.getState()
      expect(state.items).toHaveLength(0)
      expect(state.hasMore).toBe(true)
      expect(state.isLoaded).toBe(false)
    })
  })
})
