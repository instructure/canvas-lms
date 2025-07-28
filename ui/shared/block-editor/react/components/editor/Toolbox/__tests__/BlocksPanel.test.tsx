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
import {BlocksPanel, type BlocksPanelProps} from '../BlocksPanel'
import {TemplateEditor} from '../../../../types'
import {testTemplates} from './testTemplates'

const user = userEvent.setup()

// from the View theme props
const borderColorPrimary = '#d7dade'
const borderColorWarning = '#cf4a00'

const mockAddNodeTree = jest.fn()
const mockCreate = jest.fn((_ref, cb) => {
  if (typeof cb === 'function') {
    cb()
  }
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        actions: {
          addNodeTree: mockAddNodeTree,
        },
        connectors: {
          create: mockCreate,
        },
        query: {
          parseSerializedNode: jest.fn(n => {
            return {
              toNode: jest.fn(_n => n),
            }
          }),
          parseFreshNode: jest.fn(n => ({
            toNode: jest.fn(_n => n),
          })),
          parseReactElement: jest.fn(() => ({
            toNodeTree: jest.fn(() => ({
              nodes: {xxx: {}},
              rootNodeId: 'xxx',
            })),
          })),
          node: jest.fn(() => {
            return {
              isCanvas: jest.fn(() => true),
              isLinkedNode: jest.fn(() => true),
              toSerializedNode: jest.fn(() => ({})),
            }
          }),
        },
        selected: new Set(['ROOT']),
      }
    }),
  }
})

const onDeleteTemplateMock = jest.fn()
const onEditTemplateMock = jest.fn()

const defaultProps: BlocksPanelProps = {
  templateEditor: TemplateEditor.NONE,
  templates: [],
  onDeleteTemplate: onDeleteTemplateMock,
  onEditTemplate: onEditTemplateMock,
}

const renderComponent = (props: Partial<BlocksPanelProps> = {}) => {
  return render(<BlocksPanel {...defaultProps} {...props} />)
}

const blockList = ['Button', 'Text', 'Icon', 'Image', 'Group', 'Tabs', 'Divider']

describe('Toolbox', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders', () => {
    const {getByText} = renderComponent()

    for (const block of blockList) {
      expect(getByText(block)).toBeInTheDocument()
    }
  })

  it('calls addNodeTree when a block is clicked', async () => {
    const {container} = renderComponent()
    const blocks = container.querySelectorAll('.toolbox-item.item-block')
    await user.click(blocks[0])
    expect(mockAddNodeTree).toHaveBeenCalled()
  })

  describe('with templates', () => {
    it('renders template boxes', () => {
      const {getByText} = renderComponent({templates: testTemplates})

      expect(getByText('A block template')).toBeInTheDocument()
      expect(getByText('A block template').closest('.toolbox-item')).toHaveStyle(
        `border-color: ${borderColorPrimary}`,
      )
      expect(getByText('block template 2')).toBeInTheDocument()
      expect(getByText('block template 2').closest('.toolbox-item')).toHaveStyle(
        `border-color: ${borderColorWarning}`,
      )
    })

    it('calls onDeleteTemplate when delete button is clicked', async () => {
      window.confirm = jest.fn(() => true)

      const {getAllByText} = renderComponent({
        templates: testTemplates,
        templateEditor: TemplateEditor.LOCAL,
      })

      await user.click(getAllByText('Delete Template')[0].closest('button') as HTMLButtonElement)

      expect(onDeleteTemplateMock).toHaveBeenCalledWith('3')
    })

    it('calls onEditTemplate when edit template button is clicked', async () => {
      const {getAllByText} = renderComponent({
        templates: testTemplates,
        templateEditor: TemplateEditor.LOCAL,
      })

      await user.click(getAllByText('Edit Template')[0].closest('button') as HTMLButtonElement)

      expect(onEditTemplateMock).toHaveBeenCalledWith('3')
    })

    it('calls addNodeTree when a template is clicked', async () => {
      const {container} = renderComponent({templates: testTemplates})
      const templates = container.querySelectorAll('.toolbox-item.item-template-block')
      await user.click(templates[0])
      expect(mockAddNodeTree).toHaveBeenCalled()
    })
  })

  // the rest is drag and drop and will be tested in the e2e tests
})
