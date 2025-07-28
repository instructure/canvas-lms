/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jquery-migrate'
import 'jqueryui/menu'
import LongTextEditor from '../slickgrid.long_text_editor'
import {screen} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'

describe('LongTextEditor', () => {
  let editor
  let container

  const editorArgs = () => ({
    maxLength: 255,
    position: {
      top: 5,
      left: 5,
    },
    column: {
      field: 'default',
    },
    alt_container: document.getElementById('fixtures'),
    grid: {
      navigatePrev: jest.fn(),
      navigateNext: jest.fn(),
    },
    commitChanges: jest.fn(),
    cancelChanges: jest.fn(),
  })

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
    editor = new LongTextEditor(editorArgs())
    editor.show()
  })

  afterEach(() => {
    editor.destroy()
    container.remove()
  })

  describe('basic functionality', () => {
    it('renders a textarea', () => {
      expect(screen.getByRole('textbox')).toBeInTheDocument()
    })

    it('renders a Save button', () => {
      expect(screen.getByRole('button', {name: 'Save'})).toBeInTheDocument()
    })

    it('renders a Cancel button', () => {
      expect(screen.getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    })

    it('focuses the textarea on initial render', () => {
      expect(screen.getByRole('textbox')).toHaveFocus()
    })
  })

  describe('keyboard navigation', () => {
    let args
    let user

    beforeEach(() => {
      user = userEvent.setup()
      args = editorArgs()
      editor.destroy()
      editor = new LongTextEditor(args)
      editor.show()
    })

    it('navigates to previous cell when Shift+Tab is pressed on textarea', async () => {
      const event = $.Event('keydown', {which: $.ui.keyCode.TAB, shiftKey: true})
      $(screen.getByRole('textbox')).trigger(event)
      expect(args.grid.navigatePrev).toHaveBeenCalled()
    })

    it('does not navigate to next cell when Tab is pressed on textarea', async () => {
      await user.tab()
      expect(args.grid.navigateNext).not.toHaveBeenCalled()
    })

    it('focuses Save button when Tab is pressed on textarea', async () => {
      await user.tab()
      expect(screen.getByRole('button', {name: 'Save'})).toHaveFocus()
    })

    it('focuses textarea when Shift+Tab is pressed on Save button', async () => {
      await user.tab() // Move to Save button
      await user.tab({shift: true})
      expect(screen.getByRole('textbox')).toHaveFocus()
    })

    it('focuses Cancel button when Tab is pressed on Save button', async () => {
      await user.tab() // Move to Save button
      await user.tab()
      expect(screen.getByRole('button', {name: 'Cancel'})).toHaveFocus()
    })

    it('focuses Save button when Shift+Tab is pressed on Cancel button', async () => {
      await user.tab() // Move to Save button
      await user.tab() // Move to Cancel button
      await user.tab({shift: true})
      expect(screen.getByRole('button', {name: 'Save'})).toHaveFocus()
    })

    it('navigates to next cell when Tab is pressed on Cancel button', async () => {
      const event = $.Event('keydown', {which: $.ui.keyCode.TAB, shiftKey: false})
      $(screen.getByRole('button', {name: 'Cancel'})).trigger(event)
      expect(args.grid.navigateNext).toHaveBeenCalled()
    })
  })
})
