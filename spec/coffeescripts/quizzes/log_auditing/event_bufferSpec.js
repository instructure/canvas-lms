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
import EventBuffer from 'compiled/quizzes/log_auditing/event_buffer'
import K from 'compiled/quizzes/log_auditing/constants'

const useLocalStorage = () => EventBuffer.setStorageAdapter(K.EVT_STORAGE_LOCAL_STORAGE)
const useMemoryStorage = () => EventBuffer.setStorageAdapter(K.EVT_STORAGE_MEMORY)

QUnit.module('Quizzes::LogAuditing::EventBuffer', {
  setup() {
    return useMemoryStorage()
  },
  teardown() {
    localStorage.removeItem(K.EVT_STORAGE_KEY)
    return useMemoryStorage()
  }
})

test('#constructor: it auto-loads from localStorage', () => {
  useLocalStorage()
  localStorage.setItem(K.EVT_STORAGE_KEY, JSON.stringify([{event_type: 'some_event'}]))
  const buffer = new EventBuffer()
  ok(!buffer.isEmpty())
})

test('#constructor: it does not auto-load from localStorage', () => {
  useMemoryStorage()
  localStorage.setItem(K.EVT_STORAGE_KEY, JSON.stringify([{event_type: 'some_event'}]))
  const buffer = new EventBuffer()
  ok(buffer.isEmpty())
})

test('#push: it adds to the buffer', () => {
  const buffer = new EventBuffer()
  buffer.push(new QuizEvent('some_type'))
  ok(!buffer.isEmpty())
})

test('#push: it adds to the buffer and updates cache', () => {
  useLocalStorage()
  const buffer = new EventBuffer()
  buffer.push(new QuizEvent('some_type'))
  equal(buffer.getLength(), 1)
  const another_buffer = new EventBuffer()
  equal(another_buffer.getLength(), 1)
})

test('#toJSON', () => {
  const buffer = new EventBuffer()
  buffer.push(new QuizEvent('some_type', {foo: 'bar'}))
  const json = buffer.toJSON()
  ok(json instanceof Array)
  equal(json.length, 1)
})
