/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import registerEditToolbar, {
  shouldShowEditButton,
  EDIT_ALT_TEXT_BUTTON_ID,
} from '../registerEditToolbar'
import {BUTTON_ID, TOOLBAR_ID} from '../svg/constants'

let editor, onAction

beforeEach(() => {
  editor = {
    ui: {
      registry: {
        addButton: jest.fn(),
        addAltTextButton: jest.fn(),
        addContextToolbar: jest.fn(),
      },
    },
  }
  onAction = jest.fn()
})

afterEach(() => jest.restoreAllMocks())

describe('registerEditToolbar()', () => {
  const subject = () => registerEditToolbar(editor, onAction)

  beforeEach(() => subject())

  it('adds the edit button', () => {
    expect(editor.ui.registry.addButton).toHaveBeenCalledWith(BUTTON_ID, {
      onAction,
      text: 'Edit Icon',
      tooltip: 'Edit Existing Icon Maker Icon',
    })
  })

  it('adds the icon options button', () => {
    expect(editor.ui.registry.addButton).toHaveBeenCalledWith(
      EDIT_ALT_TEXT_BUTTON_ID,
      expect.objectContaining({
        text: 'Icon Options',
      })
    )
  })

  it('adds the context toolbar with the button', () => {
    expect(editor.ui.registry.addContextToolbar).toHaveBeenCalledWith(TOOLBAR_ID, {
      items: `${BUTTON_ID} ${EDIT_ALT_TEXT_BUTTON_ID}`,
      position: 'node',
      scope: 'node',
      predicate: expect.any(Function),
    })
  })
})

describe('shouldShowEditButton()', () => {
  let node

  const subject = () => shouldShowEditButton(node)

  describe('when the node contains the icon maker attr', () => {
    beforeEach(() => (node = {getAttribute: () => true}))

    it('returns true', () => {
      expect(subject()).toEqual(true)
    })
  })

  describe('when the node does not contain the icon maker attr', () => {
    beforeEach(() => (node = {getAttribute: () => false}))

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })
})
