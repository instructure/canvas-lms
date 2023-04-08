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

import Folder from '@canvas/files/backbone/models/Folder'
import FileModel from '@canvas/files/backbone/models/File'

QUnit.module('Folder', {
  setup() {
    this.file1 = new FileModel({display_name: 'File 1'}, {preflightUrl: '/test'})
    this.file2 = new FileModel({display_name: 'file 10'}, {preflightUrl: '/test'})
    this.file3 = new FileModel({display_name: 'File 2'}, {preflightUrl: '/test'})
    this.file4 = new FileModel({display_name: 'file 20'}, {preflightUrl: '/test'})
    this.folder1 = new Folder({name: 'New Folder'})
    this.folder2 = new Folder({name: 'Folder'})
    this.folder3 = new Folder({name: 'Another Folder'})
    this.model = new Folder({contentTypes: 'files'})
    this.model.files.push(this.file1)
    this.model.files.push(this.file2)
    this.model.files.push(this.file3)
    this.model.files.push(this.file4)
    this.model.folders.push(this.folder1)
    this.model.folders.push(this.folder2)
    return this.model.folders.push(this.folder3)
  },
  teardown() {
    this.model = null
  },
})

test('sorts children naturally', function () {
  const actualChildren = this.model.children({})
  const expectedChildren = [
    this.folder3,
    this.file1,
    this.file3,
    this.file2,
    this.file4,
    this.folder2,
    this.folder1,
  ]
  deepEqual(actualChildren, expectedChildren, 'Children did not sort properly')
})
