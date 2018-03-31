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

import QuizEvent from 'compiled/quizzes/log_auditing/event'

QUnit.module('Quizzes::LogAuditing::QuizEvent')

test('#constructor', () => {
  ok(!!new QuizEvent('some_event_type'), 'it can be created')
  return throws(
    () => new QuizEvent(),
    /An event type must be specified./,
    'it requires an event type'
  )
})

test('#constructor: auto-generates an ID for internal tracking', () => {
  const evt = new QuizEvent('some_event_type')
  ok(evt._id && evt._id.length > 0)
})

test('QuizEvent.fromJSON', () => {
  const descriptor = {
    client_timestamp: new Date().toJSON(),
    event_type: 'some_type',
    event_data: {foo: 'bar'}
  }
  const event = QuizEvent.fromJSON(descriptor)
  equal(event.recordedAt.toJSON(), descriptor.client_timestamp)
  equal(event.type, descriptor.event_type, 'it parses the type')
  propEqual(event.data, descriptor.event_data, 'it parses the custom data')
  deepEqual(
    event.recordedAt,
    new Date(descriptor.client_timestamp),
    'it parses the recording timestamp'
  )
})
