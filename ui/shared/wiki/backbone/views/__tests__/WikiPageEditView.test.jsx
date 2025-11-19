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
import {screen} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import $ from 'jquery'
import 'jquery-migrate'
import {BODY_MAX_LENGTH} from '../../../utils/constants'
import WikiPage from '../../models/WikiPage'
import WikiPageEditView from '../WikiPageEditView'

// Mock the horizon utils module
jest.mock('@canvas/horizon/utils', () => ({
  redirectWithHorizonParams: jest.fn(),
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
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    fakeENV.setup()
  })

  afterEach(() => {
    container.remove()
    fakeENV.teardown()
    jest.restoreAllMocks()
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

  test('should only make 1 request when save & publish is clicked', async () => {
    const submitSpy = jest
      .spyOn(WikiPageEditView.prototype, 'submit')
      .mockImplementation(function (e) {
        // stops not implemented error from cluttering logs
        e?.preventDefault()
      })
    createView({WIKI_RIGHTS: {publish_page: true}})
    await userEvent.click(screen.getByRole('button', {name: 'Save & Publish'}))
    expect(submitSpy.mock.calls).toHaveLength(1)
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
      document.body.innerHTML = `
        <div class="edit-content has_body_errors"></div>
        <span id="wiki_page_body_error">Input exceeds limit</span>
      `
      const view = createView()
      view.toggleBodyError(null)
      expect($('.edit-content').hasClass('has_body_errors')).toBe(false)
      expect($('#wiki_page_body_error').is(':visible')).toBe(false)
    })

    test('toggleBodyError shows error when called with error message', () => {
      document.body.innerHTML = `
        <div class="edit-content"></div>
        <div id="wiki_page_body_statusbar"></div>
      `
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

  describe('redirect functionality', () => {
    let originalLocation

    beforeEach(() => {
      originalLocation = window.location
      delete window.location
      window.location = {href: '', origin: 'https://canvas.instructure.com'}
      redirectWithHorizonParams.mockClear()
    })

    afterEach(() => {
      window.location = originalLocation
    })

    test('calls redirectWithHorizonParams when redirect callback is triggered', () => {
      const model = new WikiPage({html_url: 'https://example.com/pages/test'})
      const view = new WikiPageEditView({
        model,
        wiki_pages_path: '/courses/1/pages',
      })

      // Simulate the redirect callback being called
      view.trigger('success')

      expect(redirectWithHorizonParams).toHaveBeenCalledWith('https://example.com/pages/test')
    })

    test('redirect callback uses model html_url', () => {
      const testUrl = 'https://example.com/courses/1/pages/my-page'
      const model = new WikiPage({html_url: testUrl})
      const view = new WikiPageEditView({
        model,
        wiki_pages_path: '/courses/1/pages',
      })

      // Simulate the redirect callback being called
      view.trigger('success')

      expect(redirectWithHorizonParams).toHaveBeenCalledWith(testUrl)
    })

    test('redirect works with assign-to functionality disabled', () => {
      ENV.COURSE_ID = null // Disable assign-to
      const model = new WikiPage({html_url: 'https://example.com/pages/test'})
      const view = new WikiPageEditView({
        model,
        wiki_pages_path: '/courses/1/pages',
      })

      view.trigger('success')

      expect(redirectWithHorizonParams).toHaveBeenCalledWith('https://example.com/pages/test')
    })
  })
})
