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
import {deletePages} from '../apiClient'

beforeEach(() => {
  moxios.install()
})

afterEach(() => {
  moxios.uninstall()
  jest.clearAllMocks()
})

it('deletes pages', done => {
  moxios.stubRequest('/api/v1/courses/1/pages/my_page', {
    response: {},
  })
  deletePages('courses', '1', ['my_page'])
    .then(response => {
      expect(response.failures).toEqual([])
      expect(response.successes[0].data).toEqual('my_page')
      done() // eslint-disable-line promise/no-callback-in-promise
    })
    .catch(_err => done.fail())
})
