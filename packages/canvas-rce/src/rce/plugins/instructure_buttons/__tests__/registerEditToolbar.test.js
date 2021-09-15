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

import registerEditToolbar, {shouldShowEditButton} from '../registerEditToolbar'

let editor, onAction

beforeEach(() => {
  editor = {
    ui: {
      registry: {
        addButton: jest.fn(),
        addContextToolbar: jest.fn()
      }
    }
  }
  onAction = jest.fn()
})

afterEach(() => jest.restoreAllMocks())

describe ('registerEditToolbar()', () => {
  const subject = () => registerEditToolbar(editor, onAction)

  beforeEach(() => subject())

  it('adds the edit button', () => {
    expect(editor.ui.registry.addButton).toHaveBeenCalledWith(
      'inst-button-and-icons-edit', {
        onAction,
        text: "Edit",
        tooltip: "Edit Existing Button / Icon"
      }
    )
  })

  it('adds the context toolbar with the button', () => {
    expect(editor.ui.registry.addContextToolbar).toHaveBeenCalledWith(
      'inst-button-and-icons-edit-toolbar', {
        items: 'inst-button-and-icons-edit',
        position: 'node',
        scope: 'node',
        predicate: expect.any(Function)
      }
    )
  })
})

describe('shouldShowEditButton()', () => {
  let node

  const subject = () => shouldShowEditButton(node)

  describe('when the node contains the buttons/icons attr', () => {
    beforeEach(() => node = { getAttribute: () => true })

    it('returns true', () => {
      expect(subject()).toEqual(true)
    })
  })

  describe('when the node does not contain the buttons/icons attr', () => {
    beforeEach(() => node = { getAttribute: () => false })

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })
})