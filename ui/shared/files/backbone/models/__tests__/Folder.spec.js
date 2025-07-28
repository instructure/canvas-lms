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

import Folder from '../Folder'
import FileModel from '../File'

describe('Folder', () => {
  let file1, file2, file3, file4, folder1, folder2, folder3, model

  beforeEach(() => {
    file1 = new FileModel({display_name: 'File 1'}, {preflightUrl: '/test'})
    file2 = new FileModel({display_name: 'file 10'}, {preflightUrl: '/test'})
    file3 = new FileModel({display_name: 'File 2'}, {preflightUrl: '/test'})
    file4 = new FileModel({display_name: 'file 20'}, {preflightUrl: '/test'})
    folder1 = new Folder({name: 'New Folder'})
    folder2 = new Folder({name: 'Folder'})
    folder3 = new Folder({name: 'Another Folder'})
    model = new Folder({contentTypes: 'files'})
    model.files.push(file1)
    model.files.push(file2)
    model.files.push(file3)
    model.files.push(file4)
    model.folders.push(folder1)
    model.folders.push(folder2)
    model.folders.push(folder3)
  })

  afterEach(() => {
    model = null
  })

  test('sorts children naturally', () => {
    const actualChildren = model.children({})
    const expectedChildren = [folder3, file1, file3, file2, file4, folder2, folder1]
    expect(actualChildren).toEqual(expectedChildren)
  })
})
