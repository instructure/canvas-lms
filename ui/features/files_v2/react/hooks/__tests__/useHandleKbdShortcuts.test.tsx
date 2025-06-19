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

import {render} from '@testing-library/react'
import userEvent, {UserEvent} from '@testing-library/user-event'
import {useHandleKbdShortcuts} from '../useHandleKbdShortcuts'

const renderDummyComponent = (handler: () => void) => {
  const DummyComponent = () => {
    useHandleKbdShortcuts(handler)
    return (
      <div>
        <textarea name="dummy" id="dummy-textarea"></textarea>
        <input type="text" name="dummy-input" id="dummy-input" />
        <div role="dialog" id="dummy-dialog">
          <input type="checkbox" id="dialog-item" />
        </div>
      </div>
    )
  }

  render(<DummyComponent />)
}

describe('useHandleKbdShortcuts', () => {
  let user: UserEvent
  let handler: jest.Mock

  beforeEach(() => {
    handler = jest.fn()
    user = userEvent.setup()
    renderDummyComponent(handler)
  })

  describe('when Ctrl+A or Cmd+A is pressed', () => {
    it('should call the select all handler when Ctrl+A is pressed', async () => {
      await user.keyboard('{Control>}{a}')
      expect(handler).toHaveBeenCalled()
    })

    it('should not call the handler when Ctrl+A is pressed in an input or textarea', async () => {
      const textarea = document.getElementById('dummy-textarea') as HTMLTextAreaElement
      await user.click(textarea)
      await user.keyboard('{Control>}{a}')
      expect(handler).not.toHaveBeenCalled()
    })

    it('should not call the handler when Ctrl+A is pressed in a text input', async () => {
      const input = document.getElementById('dummy-input') as HTMLInputElement
      await user.click(input)
      await user.keyboard('{Control>}{a}')
      expect(handler).not.toHaveBeenCalled()
    })

    it('should not call the handler when Ctrl+A is pressed in a dialog', async () => {
      const dialogItem = document.getElementById('dialog-item') as HTMLInputElement
      await user.click(dialogItem)
      await user.keyboard('{Control>}{a}')
      expect(handler).not.toHaveBeenCalled()
    })
  })

  describe('when nothing is pressed', () => {
    it('should not call the select all handler', async () => {
      expect(handler).not.toHaveBeenCalled()
    })
  })
})
