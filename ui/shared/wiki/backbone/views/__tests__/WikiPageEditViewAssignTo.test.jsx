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
import 'jquery-migrate'
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

const createView = (container, opts) => {
  const view = new WikiPageEditView({
    model: new WikiPage({editor: 'block_editor'}),
    wiki_pages_path: '/courses/1/pages',
    ...opts,
  })
  view.$el.appendTo(container)
  return view.render()
}

describe('WikiPageEditView renderAssignToTray integration', () => {
  let container

  beforeEach(() => {
    vi.useFakeTimers({shouldAdvanceTime: true})
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    fakeENV.setup({
      COURSE_ID: '1',
      WIKI_RIGHTS: {manage_assign_to: true},
    })

    const mountPoint = document.createElement('div')
    mountPoint.id = 'assign-to-mount-point-edit-page'
    container.appendChild(mountPoint)
    renderAssignToTray.mockClear()
  })

  afterEach(async () => {
    await vi.runAllTimersAsync()
    vi.useRealTimers()

    container.remove()
    fakeENV.teardown()
    vi.restoreAllMocks()
  })

  test('remaps model.id of 0 (number) to undefined when calling renderAssignToTray', () => {
    const model = new WikiPage({
      page_id: 0,
      title: 'Test Page',
      editor: 'block_editor',
    })

    createView(container, {model})

    expect(renderAssignToTray).toHaveBeenCalledWith(
      expect.any(HTMLElement),
      expect.objectContaining({
        pageId: undefined,
        pageName: 'Test Page',
        onSync: expect.any(Function),
      }),
    )
  })

  test('remaps model.id of "0" (string) to undefined when calling renderAssignToTray', () => {
    const model = new WikiPage({
      page_id: '0',
      title: 'Test Page',
      editor: 'block_editor',
    })

    createView(container, {model})

    expect(renderAssignToTray).toHaveBeenCalledWith(
      expect.any(HTMLElement),
      expect.objectContaining({
        pageId: undefined,
        pageName: 'Test Page',
        onSync: expect.any(Function),
      }),
    )
  })

  test('passes through valid model.id unchanged when calling renderAssignToTray', () => {
    const model = new WikiPage({
      page_id: '123',
      title: 'Test Page',
      editor: 'block_editor',
    })

    createView(container, {model})

    expect(renderAssignToTray).toHaveBeenCalledWith(
      expect.any(HTMLElement),
      expect.objectContaining({
        pageId: '123',
        pageName: 'Test Page',
        onSync: expect.any(Function),
      }),
    )
  })
})
