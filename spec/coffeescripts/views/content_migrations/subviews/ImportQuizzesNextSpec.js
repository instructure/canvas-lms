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

import Backbone from '@canvas/backbone'
import ImportQuizzesNextView from '@canvas/content-migrations/backbone/views/ImportQuizzesNextView'
import assertions from 'helpers/assertions'

QUnit.module('Import Quizzes Next', {})

test('it should be accessible', assert => {
  const importQuizzesNext = new ImportQuizzesNextView({
    quizzesNextEnabled: true,
    migrationDefault: false,
    model: new Backbone.Model(),
  })
  const done = assert.async()
  assertions.isAccessible(importQuizzesNext, done, {a11yReport: true})
})

test('it should have checkbox enabled, and not checked', () => {
  const importQuizzesNext = new ImportQuizzesNextView({
    quizzesNextEnabled: true,
    migrationDefault: false,
    model: new Backbone.Model(),
  })
  importQuizzesNext.render()
  ok(
    importQuizzesNext.$el.find('#importQuizzesNext').is(':enabled'),
    'import to quizzes next is enabled'
  )
  ok(
    !importQuizzesNext.$el.find('#importQuizzesNext').is(':checked'),
    'import to quizzes next is not checked'
  )
})

test('it should have checkbox disabled, and not checked', () => {
  const importQuizzesNext = new ImportQuizzesNextView({
    quizzesNextEnabled: false,
    migrationDefault: false,
    model: new Backbone.Model(),
  })
  importQuizzesNext.render()
  ok(
    importQuizzesNext.$el.find('#importQuizzesNext').is(':disabled'),
    'import to quizzes next is disabled'
  )
  ok(
    !importQuizzesNext.$el.find('#importQuizzesNext').is(':checked'),
    'import to quizzes next is not checked'
  )
})

test('it should have checkbox enabled, and checked', () => {
  const importQuizzesNext = new ImportQuizzesNextView({
    quizzesNextEnabled: true,
    migrationDefault: true,
    model: new Backbone.Model(),
  })
  importQuizzesNext.render()
  ok(
    importQuizzesNext.$el.find('#importQuizzesNext').is(':enabled'),
    'import to quizzes next is enabled'
  )
  ok(
    importQuizzesNext.$el.find('#importQuizzesNext').is(':checked'),
    'import to quizzes next is checked'
  )
})

test('it should have checkbox disabled, and checked', () => {
  const importQuizzesNext = new ImportQuizzesNextView({
    model: new Backbone.Model(),
    quizzesNextEnabled: false,
    migrationDefault: true,
  })
  importQuizzesNext.render()
  ok(
    importQuizzesNext.$el.find('#importQuizzesNext').is(':disabled'),
    'import to quizzes next is disabled'
  )
  ok(
    importQuizzesNext.$el.find('#importQuizzesNext').is(':checked'),
    'import to quizzes next is checked'
  )
})
