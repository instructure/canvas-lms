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

import React from 'react'
import {Editor} from '@craftjs/core'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Toolbox} from '../Toolbox'
import {type ToolboxProps} from '../types'
import {TemplateEditor} from '../../../../types'
import {testTemplates} from './testTemplates'

const user = userEvent.setup()

const defaultProps: ToolboxProps = {
  toolboxShortcutManager: {
    defaultFocusRef: {current: null},
    keyDownHandler: _e => {},
  },
  open: true,
  container: document.createElement('div'),
  templateEditor: TemplateEditor.NONE,
  templates: testTemplates,
  onDismiss: () => {},
  onOpened: () => {},
}

const renderComponent = (props: Partial<ToolboxProps> = {}) => {
  return render(
    <Editor>
      <Toolbox {...defaultProps} {...props} />
    </Editor>,
  )
}

describe('Toolbox', () => {
  beforeEach(() => {
    const bee = document.createElement('div')
    bee.classList.add('block-editor-editor')
    document.body.appendChild(bee)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()

    expect(getByText('Add Content')).toBeInTheDocument()
    expect(getByText('Close')).toBeInTheDocument()
    expect(getByText('Sections')).toBeInTheDocument()
    expect(getByText('Blocks')).toBeInTheDocument()
  })

  it('renders the Sections tab by default', () => {
    const {getByText} = renderComponent()

    expect(getByText('Sections')).toHaveAttribute('aria-selected', 'true')
  })

  it('renders the sections', () => {
    const {getByText} = renderComponent()

    expect(getByText('Blank')).toBeInTheDocument()
    expect(getByText('A blank template')).toBeInTheDocument()
    expect(getByText('Another Section')).toBeInTheDocument()
    expect(getByText('Another section template')).toBeInTheDocument()
  })

  it('renders the blocks when the Blocks tab is clicked', async () => {
    const {getByText} = renderComponent({templates: testTemplates})

    await user.click(getByText('Blocks'))

    expect(getByText('Blocks')).toHaveAttribute('aria-selected', 'true')
    expect(getByText('A block template')).toBeInTheDocument()
    expect(getByText('block template 2')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', async () => {
    const onDismiss = jest.fn()
    const {getByText} = renderComponent({onDismiss})

    await user.click(getByText('Close').closest('button') as HTMLButtonElement)

    expect(onDismiss).toHaveBeenCalled()
  })

  describe('when editing templates', () => {
    it('dispatches DeleteTemplateEvent when delete button is clicked', async () => {
      window.confirm = jest.fn(() => true)
      const blockeditoreditor = document.querySelector('.block-editor-editor') as HTMLElement
      const dispatchEvent = jest.spyOn(blockeditoreditor, 'dispatchEvent')

      const {getByText} = renderComponent({templateEditor: TemplateEditor.LOCAL})

      await user.click(getByText('Delete Template').closest('button') as HTMLButtonElement)

      expect(dispatchEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: '2',
        }),
      )
    })

    it('shows EditTemplateModal when edit template button is clicked', async () => {
      const {getByLabelText, getByDisplayValue, getByText} = renderComponent({
        templates: testTemplates,
        templateEditor: TemplateEditor.LOCAL,
      })

      await user.click(getByText('Edit Template').closest('button') as HTMLButtonElement)

      const dialog = getByLabelText('Edit Template')
      expect(dialog).toBeInTheDocument()
      expect(dialog).toHaveAttribute('role', 'dialog')
      expect(getByDisplayValue('Another Section')).toBeInTheDocument()
    })
  })

  // the rest is drag and drop and will be tested in the e2e tests
})
