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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Editor, useEditor} from '@craftjs/core'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Toolbox, type ToolboxProps} from '../Toolbox'
import {TemplateEditor} from '../../../types'

const user = userEvent.setup()

const mockCreate = jest.fn()

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        connectors: {
          create: mockCreate,
        },
      }
    }),
  }
})

const defaultProps: ToolboxProps = {
  open: true,
  container: document.createElement('div'),
  templates: [],
  templateEditor: TemplateEditor.NONE,
  onClose: () => {},
}

const renderComponent = (props: Partial<ToolboxProps> = {}) => {
  return render(
    <Editor enabled={true}>
      <Toolbox {...defaultProps} {...props} />
    </Editor>
  )
}

const blockList = [
  'Button',
  'Text',
  'RCE',
  'Icon',
  'Heading',
  'Resource Card',
  'Image',
  'Group',
  'Tabs',
]

describe('Toolbox', () => {
  beforeEach(() => {
    mockCreate.mockClear()
    const bee = document.createElement('div')
    bee.classList.add('block-editor-editor')
    document.body.appendChild(bee)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()

    expect(getByText('Blocks')).toBeInTheDocument()
    for (const block of blockList) {
      expect(getByText(block)).toBeInTheDocument()
    }
  })

  it('calls onClose when close button is clicked', async () => {
    const onClose = jest.fn()
    const {getByText} = renderComponent({onClose})

    await user.click(getByText('Close').closest('button') as HTMLButtonElement)

    expect(onClose).toHaveBeenCalled()
  })

  describe('with templates', () => {
    it('renders template boxes', () => {
      const templates = [
        {
          id: '1',
          context_type: 'Course',
          context_id: '1',
          name: 'Template 1',
          editor_version: '0.2',
          template_type: 'block' as const,
          workflow_state: 'active' as const,
          node_tree: {rootNodeId: '0', nodes: {}},
        },
        {
          id: '2',
          context_type: 'Course',
          context_id: '1',
          name: 'Template 2',
          editor_version: '0.2',
          template_type: 'block' as const,
          workflow_state: 'unpublished' as const,
          node_tree: {rootNodeId: '0', nodes: {}},
        },
      ]
      const {getByText} = renderComponent({templates})

      expect(getByText('Template 1')).toBeInTheDocument()
      expect(getByText('Template 1').closest('.toolbox-item')).toHaveStyle(
        'border-color: transparent'
      )
      expect(getByText('Template 2')).toBeInTheDocument()
      expect(getByText('Template 2').closest('.toolbox-item')).toHaveStyle('border-color: #FC5E13') // rgb(252, 94, 19)
    })

    it('dispatches DeleteTemplateEvent when delete button is clicked', async () => {
      window.confirm = jest.fn(() => true)
      const blockeditoreditor = document.querySelector('.block-editor-editor') as HTMLElement
      const dispatchEvent = jest.spyOn(blockeditoreditor, 'dispatchEvent')

      const templates = [
        {
          id: '1',
          context_type: 'Course',
          context_id: '1',
          name: 'Template 1',
          editor_version: '0.2',
          template_type: 'block' as const,
          workflow_state: 'active' as const,
          node_tree: {rootNodeId: '0', nodes: {}},
        },
      ]
      const {getByText} = renderComponent({templates, templateEditor: TemplateEditor.LOCAL})

      await user.click(getByText('Delete Template').closest('button') as HTMLButtonElement)

      expect(dispatchEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: '1',
        })
      )
    })

    it('shows EditTemplateModal when edit template button is clicked', async () => {
      const templates = [
        {
          id: '1',
          context_type: 'Course',
          context_id: '1',
          name: 'Template 1',
          editor_version: '0.2',
          template_type: 'block' as const,
          workflow_state: 'active' as const,
          node_tree: {rootNodeId: '0', nodes: {}},
        },
      ]
      const {getByLabelText, getByDisplayValue, getByText} = renderComponent({
        templates,
        templateEditor: TemplateEditor.LOCAL,
      })

      await user.click(getByText('Edit Template').closest('button') as HTMLButtonElement)

      const dialog = getByLabelText('Edit Template')
      expect(dialog).toBeInTheDocument()
      expect(dialog).toHaveAttribute('role', 'dialog')
      expect(getByDisplayValue('Template 1')).toBeInTheDocument()
    })
  })

  // the rest is drag and drop and will be tested in the e2e tests
})
