/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {screen, waitFor} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import $ from 'jquery'
import 'jquery-migrate'
import {BODY_MAX_LENGTH} from '../../../utils/constants'
import WikiPage from '../../models/WikiPage'
import WikiPageEditView from '../WikiPageEditView'
import {renderAssignToTray} from '../../../react/renderAssignToTray'

// Mock the horizon utils module
vi.mock('@canvas/horizon/utils', () => ({
  redirectWithHorizonParams: vi.fn(),
}))

// Mock the renderAssignToTray module
vi.mock('../../../react/renderAssignToTray', () => ({
  renderAssignToTray: vi.fn(),
}))

const createView = opts => {
  const view = new WikiPageEditView({
    model: new WikiPage({editor: 'block_editor'}),
    wiki_pages_path: '/courses/1/pages',
    ...opts,
  })
  view.$el.appendTo(document.getElementById('fixtures'))
  return view.render()
}

describe('WikiPageEditView', () => {
  let container

  beforeEach(() => {
    vi.useFakeTimers({shouldAdvanceTime: true})
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    fakeENV.setup()
  })

  afterEach(async () => {
    // Flush any pending timers before cleanup
    await vi.runAllTimersAsync()
    vi.useRealTimers()

    container.remove()
    fakeENV.teardown()
    vi.restoreAllMocks()
  })

  test('should render the view', () => {
    const view = createView()
    expect(view.$el).toBeDefined()
  })

  test('should show errors', () => {
    const view = createView()
    const errors = {
      body: [{type: 'too_long', message: 'Error...'}],
    }
    view.showErrors(errors)
    expect(view.$('.body_has_errors')).toBeDefined()
  })

  describe('validate form data', () => {
    test('should validate form data with body too long', () => {
      const view = createView()
      const data = {body: 'a'.repeat(BODY_MAX_LENGTH + 1)}
      const errors = view.validateFormData(data)
      expect(errors.body[0].type).toBe('too_long')
      expect(errors.body[0].message).toBe(
        'Input exceeds 500 KB limit. Please reduce the text size.',
      )
    })

    test('toggleBodyError hides error when called with null', () => {
      // Add required elements to the fixture container
      const editContent = document.createElement('div')
      editContent.className = 'edit-content has_body_errors'
      container.appendChild(editContent)

      const errorSpan = document.createElement('span')
      errorSpan.id = 'wiki_page_body_error'
      errorSpan.textContent = 'Input exceeds limit'
      container.appendChild(errorSpan)

      const view = createView()
      view.toggleBodyError(null)
      expect($('.edit-content').hasClass('has_body_errors')).toBe(false)
      expect($('#wiki_page_body_error').is(':visible')).toBe(false)
    })

    test('toggleBodyError shows error when called with error message', () => {
      // Add required elements to the fixture container
      const editContent = document.createElement('div')
      editContent.className = 'edit-content'
      container.appendChild(editContent)

      const statusbar = document.createElement('div')
      statusbar.id = 'wiki_page_body_statusbar'
      container.appendChild(statusbar)

      const view = createView()
      const error = {message: 'Input exceeds limit'}
      view.toggleBodyError(error)
      expect($('.edit-content').hasClass('has_body_errors')).toBe(true)
      expect($('#wiki_page_body_error').text()).toContain('Input exceeds limit')
    })
  })

  describe('getFormData', () => {
    test('assignment is included in form data', () => {
      const view = createView()
      const data = view.getFormData()
      expect(data.assignment).toBeDefined()
    })
  })
})
