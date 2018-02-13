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

import FileOptionsCollection from 'compiled/react_files/modules/FileOptionsCollection'

const mockFile = (name, type = 'application/image') => ({
  get(attr) {
    if (attr === 'display_name') return name
  },
  type
})

function setupFolderWith(names) {
  const mockFiles = names.map(name => mockFile(name))
  const folder = {files: {models: mockFiles}}
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

QUnit.module(
  'FileOptionsCollection',
  {
    setup() {
      FileOptionsCollection.resetState()
    },
    teardown() {
      FileOptionsCollection.resetState()
    }
  },

  test('findMatchingFile correctly finds existing files by display_name', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    ok(FileOptionsCollection.findMatchingFile('foo'))
  }),

  test('findMatchingFile returns falsy value when no matching file exists', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    equal(FileOptionsCollection.findMatchingFile('xyz') != null, false)
  }),

  test('segregateOptionBuckets divides files into collsion and resolved buckets', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('file_name.txt', 'overwrite', 'option_name.txt')
    const two = createFileOption('foo')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one, two])
    equal(collisions.length, 1)
    equal(resolved.length, 1)
    equal(collisions[0].file.name, 'foo')
  }),

  test('segregateOptionBuckets uses fileOptions name over actual file name', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('file_name.txt', 'rename', 'foo')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
    equal(collisions.length, 1)
    equal(resolved.length, 0)
    equal(collisions[0].file.name, 'file_name.txt')
  }),
  test('segregateOptionBuckets name conflicts marked as overwrite are considered resolved', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('foo', 'overwrite')
    const {collisions, resolved} = FileOptionsCollection.segregateOptionBuckets([one])
    equal(collisions.length, 0)
    equal(resolved.length, 1)
    equal(resolved[0].file.name, 'foo')
  }),

  test('segregateOptionBuckets detects zip files', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    equal(resolved.length, 0)
    equal(zips[0].file.name, 'other.zip')
  }),

  test('segregateOptionBuckets ignores zip files that have an expandZip option', () => {
    setupFolderWith(['foo', 'bar', 'baz'])
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    one.expandZip = false
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    equal(resolved.length, 1)
    equal(zips.length, 0)
  }),

  test('segregateOptionBuckets ignores zip file names when expandZip option is true', () => {
    setupFolderWith(['other.zip', 'bar', 'baz'])
    const one = createFileOption('other.zip')
    one.file.type = 'application/zip'
    one.expandZip = true
    const {collisions, resolved, zips} = FileOptionsCollection.segregateOptionBuckets([one])
    equal(resolved.length, 1)
    equal(collisions.length, 0)
    equal(zips.length, 0)
  })
)
