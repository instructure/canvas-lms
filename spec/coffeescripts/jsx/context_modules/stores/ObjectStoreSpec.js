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

import store from 'jsx/context_modules/stores/ObjectStore'

QUnit.module('ObjectStore', {
  setup() {
    this.testStore = new store('/api/v1/courses/2/folders')
    this.server = sinon.fakeServer.create()
    this.foldersPageOne = [
      {
        full_name: 'course files/@123',
        id: 112,
        name: '@123',
        parent_folder_id: 13,
        position: 16,
        locked: false,
        folders_url: 'http://canvas.dev/api/v1/folders/112/folders',
        files_url: 'http://canvas.dev/api/v1/folders/112/files',
        files_count: 0,
        folders_count: 3
      },
      {
        full_name: 'course files/A new special folder',
        id: 103,
        name: 'A new special folder',
        parent_folder_id: 13,
        position: 13,
        locked: false,
        folders_url: 'http://canvas.dev/api/v1/folders/103/folders',
        files_url: 'http://canvas.dev/api/v1/folders/103/files',
        files_count: 0,
        folders_count: 0
      }
    ]
    this.foldersPageTwo = [
      {
        full_name: 'course files/@123',
        id: 325,
        name: '@123',
        parent_folder_id: 13,
        position: 16,
        locked: false,
        folders_url: 'http://canvas.dev/api/v1/folders/325/folders',
        files_url: 'http://canvas.dev/api/v1/folders/325/files',
        files_count: 0,
        folders_count: 0
      },
      {
        full_name: 'course files/A new special folder',
        id: 326,
        name: 'A new special folder',
        parent_folder_id: 13,
        position: 13,
        locked: false,
        folders_url: 'http://canvas.dev/api/v1/folders/326/folders',
        files_url: 'http://canvas.dev/api/v1/folders/326/files',
        files_count: 0,
        folders_count: 0
      }
    ]
    this.foldersPageThree = [
      {
        full_name: 'course files/@123',
        id: 123,
        name: '@123',
        parent_folder_id: 13,
        position: 16,
        locked: false,
        folders_url: 'http://canvas.dev/api/v1/folders/325/folders',
        files_url: 'http://canvas.dev/api/v1/folders/325/files',
        files_count: 0,
        folders_count: 0
      },
      {
        full_name: 'course files/A new special folder',
        id: 456,
        name: 'A new special folder',
        parent_folder_id: 13,
        position: 13,
        locked: false,
        folders_url: 'http://canvas.dev/api/v1/folders/326/folders',
        files_url: 'http://canvas.dev/api/v1/folders/326/files',
        files_count: 0,
        folders_count: 0
      }
    ]
    return this.testStore.reset()
  },
  teardown() {
    this.server.restore()
    return this.testStore.reset()
  }
})

test('fetch', function() {
  this.server.respondWith('GET', /\/folders/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.foldersPageOne)
  ])
  this.testStore.fetch()
  this.server.respond()
  deepEqual(this.testStore.getState().items, this.foldersPageOne, 'Should get one page of items')
})

test('fetch with fetchAll', function() {
  const linkHeaders =
    '<http://folders?page=1&per_page=2>; rel="current",' +
    '<http://page2>; rel="next",' +
    '<http://folders?page=1&per_page=2>; rel="first",' +
    '<http://page2>; rel="last"'
  const linkHeaders2 =
    '<http://folders?page=2&per_page=2>; rel="current",' +
    '<http://page3>; rel="next",' +
    '<http://folders?page=1&per_page=2>; rel="first",' +
    '<http://page3>; rel="last"'
  this.server.respondWith('GET', /\/folders/, [
    200,
    {
      'Content-Type': 'application/json',
      Link: linkHeaders
    },
    JSON.stringify(this.foldersPageOne)
  ])
  this.testStore.fetch({fetchAll: true})
  this.server.respond()
  this.server.respondWith('GET', /page2/, [
    200,
    {
      'Content-Type': 'application/json',
      Link: linkHeaders2
    },
    JSON.stringify(this.foldersPageTwo)
  ])
  this.server.respond()
  this.server.respondWith('GET', /page3/, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.foldersPageThree)
  ])
  this.server.respond()
  deepEqual(
    this.testStore.getState().items,
    this.foldersPageOne.concat(this.foldersPageTwo).concat(this.foldersPageThree),
    'Should get all pages of items'
  )
})

test('fetch with error', function() {
  this.server.respondWith('GET', /\/folders/, [500, {}, ''])
  this.testStore.fetch()
  this.server.respond()
  const state = this.testStore.getState()
  equal(state.items.length, 0, "Shouldn't load any items")
  equal(state.hasMore, true, 'Should set the hasMore flag')
  equal(state.isLoaded, false, 'Should make the isLoaded flag false')
})
