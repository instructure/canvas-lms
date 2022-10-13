/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {start} from '../index'

describe('start', () => {
  beforeEach(() => {
    window.ENV = {
      ACCOUNT: {id: '1234'},
    }
  })

  afterEach(() => {
    document.getElementById('fixtures').remove()
  })

  it('renders without errors', () => {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)

    const fakeAxios = {
      put: jest.fn(() => ({then() {}})),
      get: jest.fn(() => ({then() {}})),
    }

    expect(() => {
      start(fixtures, {
        context: 'account',
        contextId: '1',
        api: fakeAxios,
        liveRegion: [],
      })
    }).not.toThrow()
  })
})
