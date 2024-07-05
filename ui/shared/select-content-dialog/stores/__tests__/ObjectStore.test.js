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
import sinon from 'sinon'

describe('ObjectStore', () => {
  let testStore
  let server
  let foldersPageOne
  let foldersPageTwo
  let foldersPageThree

  beforeEach(() => {
    testStore = new Store('/api/v1/courses/2/folders', {someOption: 'value'}) // Update with required second argument
    server = sinon.createFakeServer()
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
    server.restore()
    return testStore.reset()
  })

  test('fetch', () => {
    server.respondWith('GET', /\/folders/, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(foldersPageOne),
    ])
    testStore.fetch()
    server.respond()
    expect(testStore.getState().items).toEqual(foldersPageOne) // Use Jest's expect
  })

  test('fetch with fetchAll', () => {
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
    server.respondWith('GET', /\/folders/, [
      200,
      {
        'Content-Type': 'application/json',
        Link: linkHeaders,
      },
      JSON.stringify(foldersPageOne),
    ])
    testStore.fetch({fetchAll: true})
    server.respond()
    server.respondWith('GET', /page2/, [
      200,
      {
        'Content-Type': 'application/json',
        Link: linkHeaders2,
      },
      JSON.stringify(foldersPageTwo),
    ])
    server.respond()
    server.respondWith('GET', /page3/, [
      200,
      {'Content-Type': 'application/json'},
      JSON.stringify(foldersPageThree),
    ])
    server.respond()
    expect(testStore.getState().items).toEqual(
      foldersPageOne.concat(foldersPageTwo).concat(foldersPageThree)
    ) // Use Jest's expect
  })

  test('fetch with error', () => {
    server.respondWith('GET', /\/folders/, [500, {}, ''])
    testStore.fetch()
    server.respond()
    const state = testStore.getState()
    expect(state.items.length).toBe(0) // Use Jest's expect
    expect(state.hasMore).toBe(true) // Use Jest's expect
    expect(state.isLoaded).toBe(false) // Use Jest's expect
  })
})
