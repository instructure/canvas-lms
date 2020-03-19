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

import Pubsub from '../pubsub'

const pubsub = new Pubsub()
describe('PubSub Helper', () => {
  it('should properly subscribe to published values', () => {
    const myMock = jest.fn()

    pubsub.subscribe('test-channel', myMock)
    expect(myMock).not.toHaveBeenCalled()

    pubsub.publish('test-channel', 'testing')
    expect(myMock).toHaveBeenCalledWith('testing')
  })
  it('should properly unsubscribe from published values', () => {
    const myMock = jest.fn()

    const unsub = pubsub.subscribe('test-channel', myMock)
    expect(myMock).not.toHaveBeenCalled()

    pubsub.publish('test-channel', 'testing')
    expect(myMock).toHaveBeenCalledWith('testing')

    unsub()

    pubsub.publish('test-channel', 'testing123')
    expect(myMock).not.toHaveBeenCalledWith('testing123')
  })
})
