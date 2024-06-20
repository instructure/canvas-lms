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
import ImportQuizzesNextView from '../../ImportQuizzesNextView'
import assertions from '@canvas/test-utils/assertionsSpec'

describe('Import Quizzes Next', () => {
  test('it should be accessible', async () => {
    const importQuizzesNext = new ImportQuizzesNextView({
      quizzesNextEnabled: true,
      migrationDefault: false,
      disableNQMigrationCheckbox: false,
      model: new Backbone.Model(),
    })
    await assertions.isAccessible(importQuizzesNext, {a11yReport: true})
  })

  test('it should have checkbox enabled, and not checked', () => {
    const importQuizzesNext = new ImportQuizzesNextView({
      quizzesNextEnabled: true,
      migrationDefault: false,
      disableNQMigrationCheckbox: false,
      model: new Backbone.Model(),
    })
    importQuizzesNext.render()
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':enabled')).toBe(true)
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':checked')).toBe(false)
  })

  test('it should have checkbox disabled, and not checked', () => {
    const importQuizzesNext = new ImportQuizzesNextView({
      quizzesNextEnabled: false,
      migrationDefault: false,
      disableNQMigrationCheckbox: true,
      model: new Backbone.Model(),
    })
    importQuizzesNext.render()
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':disabled')).toBe(true)
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':checked')).toBe(false)
  })

  test('it should have checkbox enabled, and checked', () => {
    const importQuizzesNext = new ImportQuizzesNextView({
      quizzesNextEnabled: true,
      migrationDefault: true,
      disableNQMigrationCheckbox: false,
      model: new Backbone.Model(),
    })
    importQuizzesNext.render()
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':enabled')).toBe(true)
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':checked')).toBe(true)
  })

  test('it should have checkbox disabled, and checked', () => {
    const importQuizzesNext = new ImportQuizzesNextView({
      model: new Backbone.Model(),
      quizzesNextEnabled: false,
      migrationDefault: true,
      disableNQMigrationCheckbox: true,
    })
    importQuizzesNext.render()
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':disabled')).toBe(true)
    expect(importQuizzesNext.$el.find('#importQuizzesNext').is(':checked')).toBe(true)
  })
})
