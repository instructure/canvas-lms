/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import 'jquery-migrate'
import QuizEvent from '../event'

describe('Quizzes::LogAuditing::QuizEvent', () => {
  test('#constructor', () => {
    expect(() => new QuizEvent()).toThrow(/An event type must be specified./)
    expect(new QuizEvent('some_event_type')).toBeTruthy()
  })

  test('#constructor: auto-generates an ID for internal tracking', () => {
    const evt = new QuizEvent('some_event_type')
    expect(evt._id && evt._id.length > 0).toBeTruthy()
  })

  test('QuizEvent.fromJSON', () => {
    const descriptor = {
      client_timestamp: new Date().toJSON(),
      event_type: 'some_type',
      event_data: {foo: 'bar'},
    }
    const event = QuizEvent.fromJSON(descriptor)
    expect(event.recordedAt.toJSON()).toEqual(descriptor.client_timestamp)
    expect(event.type).toEqual(descriptor.event_type)
    expect(event.data).toEqual(descriptor.event_data)
    expect(event.recordedAt).toEqual(new Date(descriptor.client_timestamp))
  })

  test('#constructor: clones event data to avoid mutation', () => {
    const originalData = {answer: 42, nested: {value: 'test'}}
    const event = new QuizEvent('some_event_type', originalData)

    // Verify data is cloned (shallow)
    expect(event.data).toEqual(originalData)
    expect(event.data).not.toBe(originalData)

    // Mutating original should not affect event data (top level)
    originalData.answer = 100
    expect(event.data.answer).toBe(42)
  })
})
