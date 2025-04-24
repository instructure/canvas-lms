/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import FileOptionsCollection from '../FileOptionsCollection'
import fakeENV from '@canvas/test-utils/fakeENV'

const equal = (a, b) => expect(a).toEqual(b)

const mockFile = (name, type = 'application/image') => ({
  get(attr) {
    if (attr === 'display_name') return name
  },
  type,
})

function setupFolderWith(names) {
  const mockFiles = names.map(name => mockFile(name))
  const folder = {files: {models: mockFiles}}
  return FileOptionsCollection.setFolder(folder)
}

function setupModelLessFolderWith(names) {
  const mockFiles = names.map(name => mockFile(name))
  const folder = {files: mockFiles}
  return FileOptionsCollection.setFolder(folder)
}

function createFileOption(fileName, dup, optionName) {
  const options = {file: {name: fileName}}
  if (dup) {
    options.dup = dup
  }
  if (optionName) {
    options.name = optionName
  }
  return options
}

describe('FileOptionsCollection', () => {
  beforeEach(() => {
    fakeENV.setup({
      context_asset_string: 'course_1',
      current_user: {id: '1'},
      permissions: {
        manage_files: true,
        manage_files_edit: true,
      },
    })
    FileOptionsCollection.resetState()
    FileOptionsCollection.setUploadOptions({
      alwaysRename: false,
      alwaysUploadZips: false,
      errorOnDuplicate: false,
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    FileOptionsCollection.resetState()
  })

  test('findMatchingFile correctly finds existing files by display_name', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    expect(FileOptionsCollection.findMatchingFile('foo')).toBeTruthy()
  })

  test('findMatchingFile correctly finds existing files without model attribute', () => {
    setupModelLessFolderWith(['foo', 'bar', 'baz'])
    expect(FileOptionsCollection.findMatchingFile('foo')).toBeTruthy()
  })

  test('findMatchingFile returns falsy value when no matching file exists', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    expect(FileOptionsCollection.findMatchingFile('xyz')).toBeFalsy()
  })

  test('segregateOptionBuckets divides files into collision and resolved buckets', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('file_name.txt', 'overwrite', 'option_name.txt')
    const two = createFileOption('foo')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one, two])
    expect(collisions).toHaveLength(1)
    expect(resolved).toHaveLength(1)
    expect(collisions[0].file.name).toBe('foo')
  })

  test('segregateOptionBuckets uses fileOptions name over actual file name', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('file_name.txt', 'rename', 'foo')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(collisions).toHaveLength(1)
    expect(resolved).toHaveLength(0)
    expect(collisions[0].file.name).toBe('file_name.txt')
  })

  test('segregateOptionBuckets name conflicts marked as overwrite are considered resolved', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('foo', 'overwrite')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(collisions).toHaveLength(0)
    expect(resolved).toHaveLength(1)
    expect(resolved[0].file.name).toBe('foo')
  })

  test('segregateOptionBuckets detects zip files', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    const {resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(resolved).toHaveLength(0)
    expect(zips[0].file.name).toBe('other.zip')
  })

  test('segregateOptionBuckets ignores zip files that have an expandZip option', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    one.expandZip = false
    const {resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(resolved).toHaveLength(1)
    expect(zips).toHaveLength(0)
  })

  test('segregateOptionBuckets ignores zip file names when expandZip option is true', () => {
    setupFolderWith(['other.zip', 'bar', 'baz'])
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    one.expandZip = true
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(resolved).toHaveLength(1)
    expect(collisions).toHaveLength(0)
    expect(zips).toHaveLength(0)
  })

  test('segregateOptionBuckets skips files', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('foo', 'skip')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(collisions).toHaveLength(0)
    expect(resolved).toHaveLength(0)
  })

  test('segregateOptionBuckets treats zip files like regular files if alwaysUploadZips is true', () => {
    setupFolderWith(['other.zip', 'bar', 'baz'])
    FileOptionsCollection.setUploadOptions({alwaysUploadZips: true})
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(resolved).toHaveLength(0)
    expect(collisions).toHaveLength(1)
    expect(zips).toHaveLength(0)
  })

  test('segregateOptionBuckets automaticaly renames files when alwaysRename is true', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    FileOptionsCollection.setUploadOptions({alwaysRename: true})
    const one = createFileOption('foo')
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    expect(resolved).toHaveLength(1)
    expect(collisions).toHaveLength(0)
    expect(zips).toHaveLength(0)
  })

  test('segregateOptionBuckets sets dup to error when errorOnDuplicate is true and no dup provided', () => {
    setupFolderWith(['baz'])
    FileOptionsCollection.setUploadOptions({errorOnDuplicate: true})
    const one = createFileOption('foo')
    const two = createFileOption('bar', 'overwrite')
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one, two])
    expect(resolved).toHaveLength(2)
    expect(resolved[0].dup).toBe('error')
    expect(resolved[1].dup).toBe('overwrite')
    expect(collisions).toHaveLength(0)
    expect(zips).toHaveLength(0)
  })

  test('segregateOptionBuckets catches known duplicates even when errorOnDuplicate is true', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    FileOptionsCollection.setUploadOptions({errorOnDuplicate: true})
    const one = createFileOption('foo')
    const two = createFileOption('bar')
    const three = createFileOption('boop')
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([
      one,
      two,
      three,
    ])
    expect(resolved).toHaveLength(1)
    expect(resolved[0].dup).toBe('error')
    expect(collisions).toHaveLength(2)
    expect(zips).toHaveLength(0)
  })
})
