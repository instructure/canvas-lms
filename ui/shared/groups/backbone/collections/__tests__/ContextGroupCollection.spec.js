/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import sinon from 'sinon'
import ContextGroupCollection from '../ContextGroupCollection'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'

let collection, sandbox

describe('ContextGroupCollection', () => {
  beforeEach(() => {
    sandbox = sinon.createSandbox()
    collection = new ContextGroupCollection()
  })

  afterEach(() => {
    sandbox.restore()
  })

  const setupFetchSpy = () => {
    return sandbox.spy(PaginatedCollection.prototype, 'fetch')
  }

  test('should add no-cache header when disableCache is true', () => {
    collection.options.disableCache = true

    const fetchSpy = setupFetchSpy()
    collection.fetch()

    expect(fetchSpy.called).toBe(true)
    const callArgs = PaginatedCollection.prototype.fetch.firstCall.args[0]
    expect(callArgs.headers['Cache-Control']).toEqual('no-cache')
  })

  test('should not add no-cache header when disableCache is not defined', () => {
    const fetchSpy = setupFetchSpy()
    collection.fetch()

    expect(fetchSpy.called).toBe(true)
    const callArgs = PaginatedCollection.prototype.fetch.firstCall.args[0]
    expect(callArgs.headers).toBeUndefined()
  })
})
