/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import axios from '../index'
import moxios from 'moxios'

const ok = value => expect(value).toBeTruthy()
const equal = (value, expected) => expect(value).toEqual(expected)

describe('Custom Axios Tests', () => {
  beforeEach(() => {
    moxios.install()
  })

  afterEach(() => {
    moxios.uninstall()
  })

  test('Accept headers request stringified ids', done => {
    moxios.stubRequest('/some/url', {
      status: 200,
      responseText: 'hello',
    })

    axios.get('/some/url').then(response => {
      ok(response.config.headers.Accept.includes('application/json+canvas-string-ids'))
      done()
    })

    moxios.wait(() => {})
  })

  test('passes X-Requested-With header', done => {
    moxios.stubRequest('/some/url', {
      status: 200,
      responseText: 'hello',
    })

    // eslint-disable-next-line promise/catch-or-return
    axios.get('/some/url').then(response => {
      ok(response.config.headers['X-Requested-With'] === 'XMLHttpRequest')
      done()
    })

    moxios.wait(() => {})
  })
})
