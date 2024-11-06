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
import UnassignedGroupUserCollection from '../UnassignedGroupUserCollection'

let collection, sandbox

describe('UnassignedGroupUserCollection', () => {
  beforeEach(() => {
    sandbox = sinon.createSandbox()
    collection = new UnassignedGroupUserCollection()
  })

  test('aborts active requests before fetching new ones', () => {
    const fakeRequest1 = {abort: sandbox.spy()}
    const fakeRequest2 = {abort: sandbox.spy()}
    collection = new UnassignedGroupUserCollection()
    collection.lastRequests = [fakeRequest1, fakeRequest2]

    const fetchStub = sandbox.stub(collection, 'fetch').returns(Promise.resolve())

    collection.search('abcde')
    expect(fakeRequest1.abort.calledOnce).toBe(true)
    expect(fakeRequest2.abort.calledOnce).toBe(true)

    expect(fetchStub.calledOnce).toBe(true)
  })
})
