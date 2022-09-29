/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import moxios from 'moxios'
import {getCourseRootFolder, getFolderFiles} from '../apiClient'

beforeEach(() => {
  moxios.install()
})

afterEach(() => {
  moxios.uninstall()
  jest.clearAllMocks()
})

it('fetches course root folder', done => {
  moxios.stubRequest('/api/v1/courses/1/folders/root', {
    response: {files: []},
  })
  getCourseRootFolder('1')
    .then(rootFolder => {
      expect(rootFolder).toEqual({files: []})
      done() // eslint-disable-line promise/no-callback-in-promise
    })
    .catch(() => done.fail())
})

it('fetches folder files across pages', done => {
  moxios.stubRequest('/api/v1/folders/1/files?only[]=names', {
    response: [{display_name: 'a.txt'}],
    headers: {
      link: '<http://canvas.example.com/api/v1/folders/1/files?only[]=names&page=2>; rel="next"',
    },
  })
  moxios.stubRequest('http://canvas.example.com/api/v1/folders/1/files?only[]=names&page=2', {
    response: [{display_name: 'b.txt'}],
  })
  getFolderFiles('1')
    .then(files => {
      expect(files.map(f => f.get('display_name'))).toEqual(['a.txt', 'b.txt'])
      done() // eslint-disable-line promise/no-callback-in-promise
    })
    .catch(() => done.fail())
})
