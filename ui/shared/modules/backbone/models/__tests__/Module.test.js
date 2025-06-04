/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Module from '../Module'
import ModuleItemCollection from '../../collections/ModuleItemCollection'
import $ from 'jquery'

const ok = value => expect(value).toBeTruthy()
const equal = (value, expected) => expect(value).toEqual(expected)

describe('Module', () => {
  let ajaxMock

  beforeEach(() => {
    ajaxMock = jest.spyOn($, 'ajax')
  })

  afterEach(() => {
    ajaxMock.mockRestore()
  })

  test('should build an itemCollection from items', () => {
    const mod = new Module({
      id: 3,
      course_id: 4,
      items: [{id: 1}, {id: 2}],
    })
    ok(mod.itemCollection instanceof ModuleItemCollection, 'itemCollection is not built')
    equal(mod.itemCollection.length, 2, 'incorrect item length')
  })

  test('should build an itemCollection and fetch if items are not passed', async () => {
    const mod = new Module({
      id: 3,
      course_id: 4,
    })
    ok(mod.itemCollection instanceof ModuleItemCollection, 'itemCollection is not built')

    // Mock the AJAX request
    ajaxMock.mockImplementation(options => {
      // Simulate successful response
      if (options.success) {
        options.success({id: 2})
      }
      return Promise.resolve({id: 2})
    })

    const fetchPromise = new Promise(resolve => {
      mod.itemCollection.fetch({
        success() {
          equal(mod.itemCollection.length, 1, 'incorrect item length')
          resolve()
        },
      })
    })

    await fetchPromise
  })
})
