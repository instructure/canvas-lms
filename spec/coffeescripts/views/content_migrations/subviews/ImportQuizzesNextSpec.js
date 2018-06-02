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

import Backbone from 'Backbone'
import ImportQuizzesNextView from 'compiled/views/content_migrations/subviews/ImportQuizzesNextView'
import assertions from 'helpers/assertions'

QUnit.module('Import Quizzes Next', {})

test('it should be accessible', function(assert) {
  const importQuizzesNext = new ImportQuizzesNextView({quizzesNextEnabled: true, model: new Backbone.Model()})
  const done = assert.async()
  assertions.isAccessible(importQuizzesNext, done, {a11yReport: true})
})

test('it should have checkbox enabled', function()  {
  const importQuizzesNext = new ImportQuizzesNextView({quizzesNextEnabled: true, model: new Backbone.Model()})
  importQuizzesNext.render()
  ok(importQuizzesNext.$el.find('#importQuizzesNext').is(':enabled'), 'import to quizzes next is enabled')
})

test('it should have checkbox disabled', function() {
  const importQuizzesNext = new ImportQuizzesNextView({quizzesNextEnabled: false, model: new Backbone.Model()})
  importQuizzesNext.render()
  ok(importQuizzesNext.$el.find('#importQuizzesNext').is(':disabled'), 'import to quizzes next is disabled')
})
