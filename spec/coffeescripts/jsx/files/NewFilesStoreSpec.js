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

import NewFilesStore from 'jsx/files/NewFilesStore'

QUnit.module('NewFilesStore')

test('constructor', () => {
  const store = new NewFilesStore()
  ok(store, 'constructs properly')
  equal(store.files.length, 0, 'files is initally empty')
  equal(store.folders.length, 0, 'folders is initally empty')
})

test('adds single folder to store', () => {
  const store = new NewFilesStore()
  store.addFolders([{id: 1}])
  equal(store.folders.length, 1, 'store length is one')
})

test('adds multiple folders to the store', () => {
  const store = new NewFilesStore()
  store.addFolders([{id: 1}, {id: 2}])
  equal(store.folders.length, 2, 'store length is two')
})

test("doesn't add duplicates to the store", () => {
  const store = new NewFilesStore()
  store.addFolders([{id: 1}])
  store.addFolders([{id: 1}])
  equal(store.folders.length, 1, 'store length is one')
})

test('triggers change when adding folders', () => {
  const store = new NewFilesStore()
  let called = false
  store.addChangeListener(() => (called = true))
  store.addFolders([{id: 1}])
  ok(called, 'change listener handler was called')
})

test('removes single folder from the store', () => {
  const store = new NewFilesStore()
  store.addFolders([{id: 1}])
  store.removeFolders([{id: 1}])
  equal(store.folders.length, 0, 'store contains no folders')
})

test('removes multiple folders from the store', () => {
  const store = new NewFilesStore()
  store.addFolders([{id: 1}, {id: 2}, {id: 3}])
  store.removeFolders([{id: 1}, {id: 2}])
  equal(store.folders.length, 1, 'store contains one folder after deletion')
  deepEqual(store.folders[0], {id: 3}, 'store contains folder with id 3 after deletion')
})

test('adds single file to store', () => {
  const store = new NewFilesStore()
  store.addFiles([{id: 1, parent_folder_id: 1}])
  equal(store.files.length, 1, 'file store length is one')
})

test('adds multiple files to the store', () => {
  const store = new NewFilesStore()
  store.addFiles([{id: 1, parent_folder_id: 1}, {id: 2, parent_folder_id: 1}])
  equal(store.files.length, 2, 'store length is two')
})

test("doesn't add duplicates to the store", () => {
  const store = new NewFilesStore()
  store.addFiles([{id: 1, parent_folder_id: 1}])
  store.addFiles([{id: 1, parent_folder_id: 1}])
  equal(store.files.length, 1, 'store length is one')
})

test('triggers change when adding files', () => {
  const store = new NewFilesStore()
  let called = false
  store.addChangeListener(() => (called = true))
  store.addFiles([{id: 1, parent_folder_id: 1}])
  ok(called, 'change listener handler was called')
})

test('removes single file from the store', () => {
  const store = new NewFilesStore()
  store.addFiles([{id: 1, parent_folder_id: 1}])
  store.removeFiles([{id: 1, parent_folder_id: 1}])
  equal(store.files.length, 0, 'store contains no files')
})

test('removes multiple files from the store', () => {
  const store = new NewFilesStore()
  store.addFiles([
    {id: 1, parent_folder_id: 1},
    {id: 2, parent_folder_id: 1},
    {id: 3, parent_folder_id: 1}
  ])
  store.removeFiles([{id: 1, parent_folder_id: 1}, {id: 2, parent_folder_id: 1}])
  equal(store.files.length, 1, 'store contains one file after deletion')
  deepEqual(
    store.files[0],
    {id: 3, parent_folder_id: 1},
    'store contains file with id 3 after deletion'
  )
})

test('triggers change when removing folders', () => {
  const store = new NewFilesStore()
  store.addFolders([{id: 1}])

  let called = false
  store.addChangeListener(() => (called = true))
  store.removeFolders([{id: 1}])
  ok(called, 'change listener handler was called')
})

test('triggers change when removing files', () => {
  const store = new NewFilesStore()
  store.addFiles([{id: 1}])

  let called = false
  store.addChangeListener(() => (called = true))
  store.removeFiles([{id: 1}])
  ok(called, 'change listener handler was called')
})
