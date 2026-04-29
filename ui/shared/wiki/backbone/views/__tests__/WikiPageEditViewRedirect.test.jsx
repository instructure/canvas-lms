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
import 'jquery-migrate'
import WikiPage from '../../models/WikiPage'
import WikiPageEditView from '../WikiPageEditView'

// Mock the horizon utils module
vi.mock('@canvas/horizon/utils', () => ({
  redirectWithHorizonParams: vi.fn(),
}))

// Mock the renderAssignToTray module
vi.mock('../../../react/renderAssignToTray', () => ({
  renderAssignToTray: vi.fn(),
}))

describe('WikiPageEditView redirect functionality', () => {
  let container
  let originalLocation

  beforeEach(() => {
    vi.useFakeTimers({shouldAdvanceTime: true})
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    fakeENV.setup()

    originalLocation = window.location
    delete window.location
    window.location = {href: '', origin: 'https://canvas.instructure.com'}
    redirectWithHorizonParams.mockClear()
  })

  afterEach(async () => {
    await vi.runAllTimersAsync()
    vi.useRealTimers()

    window.location = originalLocation
    container.remove()
    fakeENV.teardown()
    vi.restoreAllMocks()
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
    fakeENV.setup({COURSE_ID: null})

    const model = new WikiPage({html_url: 'https://example.com/pages/test'})
    const view = new WikiPageEditView({
      model,
      wiki_pages_path: '/courses/1/pages',
    })

    view.trigger('success')

    expect(redirectWithHorizonParams).toHaveBeenCalledWith('https://example.com/pages/test')
  })
})
