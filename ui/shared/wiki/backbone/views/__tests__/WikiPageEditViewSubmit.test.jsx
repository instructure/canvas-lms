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

import fakeENV from '@canvas/test-utils/fakeENV'
import {screen} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
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

const createView = (container, opts) => {
  const view = new WikiPageEditView({
    model: new WikiPage({editor: 'block_editor'}),
    wiki_pages_path: '/courses/1/pages',
    ...opts,
  })
  view.$el.appendTo(container)
  return view.render()
}

describe('WikiPageEditView submit functionality', () => {
  let container
  let user

  beforeEach(() => {
    // Use fake timers that allow userEvent to work properly
    vi.useFakeTimers({shouldAdvanceTime: true})
    user = userEvent.setup({advanceTimers: vi.advanceTimersByTime})

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

  test('should only make 1 request when save & publish is clicked', async () => {
    const submitSpy = vi
      .spyOn(WikiPageEditView.prototype, 'submit')
      .mockImplementation(function (e) {
        // stops not implemented error from cluttering logs
        e?.preventDefault()
      })

    createView(container, {WIKI_RIGHTS: {publish_page: true}})
    await user.click(screen.getByRole('button', {name: 'Save & Publish'}))

    expect(submitSpy.mock.calls).toHaveLength(1)
  })
})
