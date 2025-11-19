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

import {redirectWithHorizonParams} from '@canvas/horizon/utils'
import fakeENV from '@canvas/test-utils/fakeENV'
import WikiPage from '../../models/WikiPage'
import WikiPageDeleteDialog from '../WikiPageDeleteDialog'
import $ from 'jquery'

// Mock the horizon utils module
jest.mock('@canvas/horizon/utils', () => ({
  redirectWithHorizonParams: jest.fn(),
}))

describe('WikiPageDeleteDialog', () => {
  let originalLocation

  beforeEach(() => {
    fakeENV.setup()
    originalLocation = window.location
    delete window.location
    window.location = {href: '', origin: 'https://canvas.instructure.com'}
  })

  afterEach(() => {
    fakeENV.teardown()
    window.location = originalLocation
    jest.restoreAllMocks()
  })

  test('maintains the view of the model', () => {
    let view
    const model = new WikiPage()
    model.view = view = {}
    new WikiPageDeleteDialog({model})
    expect(model.view).toBe(view)
  })

  describe('redirect functionality', () => {
    beforeEach(() => {
      redirectWithHorizonParams.mockClear()
    })

    test('calls redirectWithHorizonParams when wiki page is deleted successfully', () => {
      const model = new WikiPage({title: 'Test Page'})

      // Mock the model's destroy method to return a jQuery Deferred-like object
      const destroyDeferred = {
        then: jest.fn(callback => {
          callback()
          return destroyDeferred
        }),
        fail: jest.fn(() => destroyDeferred),
      }
      model.destroy = jest.fn().mockReturnValue(destroyDeferred)

      const dialog = new WikiPageDeleteDialog({
        model,
        wiki_pages_path: '/courses/1/pages',
      })

      // Mock jQuery functions
      global.$ = Object.assign(jest.fn(), {
        cookie: jest.fn(),
        flashMessage: jest.fn(),
        Deferred: function () {
          const dfd = {
            resolve: jest.fn(),
            reject: jest.fn(),
            promise: jest.fn().mockReturnThis(),
          }
          return dfd
        },
      })

      // Mock the dialog element's disableWhileLoading method
      dialog.$el = {
        disableWhileLoading: jest.fn(dfd => dfd),
      }

      // Call submit to trigger the deletion
      dialog.submit()

      expect(redirectWithHorizonParams).toHaveBeenCalledWith('/courses/1/pages')
    })

    test('uses wiki_pages_path for redirect after deletion', () => {
      const model = new WikiPage({title: 'Another Test Page'})
      const wikiPagesPath = '/courses/123/pages'

      // Mock the model's destroy method to return a jQuery Deferred-like object
      const destroyDeferred = {
        then: jest.fn(callback => {
          callback()
          return destroyDeferred
        }),
        fail: jest.fn(() => destroyDeferred),
      }
      model.destroy = jest.fn().mockReturnValue(destroyDeferred)

      const dialog = new WikiPageDeleteDialog({
        model,
        wiki_pages_path: wikiPagesPath,
      })

      // Mock jQuery functions
      global.$ = Object.assign(jest.fn(), {
        cookie: jest.fn(),
        flashMessage: jest.fn(),
        Deferred: function () {
          const dfd = {
            resolve: jest.fn(),
            reject: jest.fn(),
            promise: jest.fn().mockReturnThis(),
          }
          return dfd
        },
      })

      // Mock the dialog element
      dialog.$el = {
        disableWhileLoading: jest.fn(dfd => dfd),
      }

      dialog.submit()

      expect(redirectWithHorizonParams).toHaveBeenCalledWith(wikiPagesPath)
    })

    test('does not redirect when wiki_pages_path is not provided', () => {
      const model = new WikiPage({title: 'Test Page'})

      // Mock the model's destroy method to return a jQuery Deferred-like object
      const destroyDeferred = {
        then: jest.fn(callback => {
          callback()
          return destroyDeferred
        }),
        fail: jest.fn(() => destroyDeferred),
      }
      model.destroy = jest.fn().mockReturnValue(destroyDeferred)

      const dialog = new WikiPageDeleteDialog({
        model,
        // Note: no wiki_pages_path provided
      })

      // Mock jQuery functions
      $.flashMessage = jest.fn()
      $.Deferred = function () {
        const dfd = {
          resolve: jest.fn(),
          reject: jest.fn(),
          promise: jest.fn().mockReturnThis(),
        }
        return dfd
      }

      // Mock the dialog element and close method
      dialog.$el = {
        disableWhileLoading: jest.fn(dfd => dfd),
      }
      dialog.close = jest.fn()

      dialog.submit()

      expect(redirectWithHorizonParams).not.toHaveBeenCalled()
      expect($.flashMessage).toHaveBeenCalled()
    })
  })
})
