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

import axios from 'axios'
import moxios from 'moxios'

QUnit.module('Custom Axios Tests', {
  setup() {
    moxios.install()
  },
  teardown() {
    moxios.uninstall()
  }
})

test('Accept headers request stringified ids', assert => {
  const done = assert.async()

  moxios.stubRequest('/some/url', {
    status: 200,
    responseText: 'hello'
  })

  axios.get('/some/url').then(response => {
    ok(response.config.headers.Accept.includes('application/json+canvas-string-ids'))
    done()
  })

  moxios.wait(() => {})
})

test('passes X-Requested-With header', assert => {
  const done = assert.async()

  moxios.stubRequest('/some/url', {
    status: 200,
    responseText: 'hello'
  })

  axios.get('/some/url').then(response => {
    ok(response.config.headers['X-Requested-With'] === 'XMLHttpRequest')
    done()
  })

  moxios.wait(() => {})
})
