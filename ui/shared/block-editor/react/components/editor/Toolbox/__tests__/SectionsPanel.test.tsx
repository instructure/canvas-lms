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
import {SectionsPanel} from '../SectionsPanel'
import {TemplateEditor, type BlockTemplate} from '../../../../types'
import {testTemplates} from './testTemplates'

const user = userEvent.setup()

const mockAddNodeTree = jest.fn()
const mockCreate = jest.fn((_ref, cb) => {
  cb()
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
          node: jest.fn(() => {
            return {
              toSerializedNode: jest.fn(() => ({})),
            }
          }),
        },
      }
    }),
  }
})

const renderComponent = (props = {}) => {
  return render(
    <SectionsPanel
      templateEditor={TemplateEditor.NONE}
      templates={testTemplates}
      onDeleteTemplate={() => {}}
      onEditTemplate={() => {}}
      {...props}
    />,
  )
}

describe('SectionsPanel', () => {
  it('should render', () => {
    const {container, getByText, queryByText} = renderComponent()
    expect(getByText('Blank')).toBeInTheDocument()
    expect(getByText('A blank template')).toBeInTheDocument()
    expect(container.querySelector('#section_template-1 img')).toHaveAttribute('src', 'thumbnail1')
    expect(getByText('Another Section')).toBeInTheDocument()
    expect(getByText('Another section template')).toBeInTheDocument()
    expect(container.querySelector('#section_template-2 img')).toHaveAttribute('src', 'thumbnail2')
    expect(queryByText('A block template')).not.toBeInTheDocument()
  })

  it('should render templates in alpha order, with Blank first', () => {
    const {container} = renderComponent()
    const sections = container.querySelectorAll('.toolbox-item')
    expect(sections[0]).toHaveTextContent('Blank')
    expect(sections[1]).toHaveTextContent('Another Section')
  })

  it('should call addNodeTree when a section is clicked', async () => {
    const {container} = renderComponent()
    const sections = container.querySelectorAll('.toolbox-item')
    await user.click(sections[0])
    expect(mockAddNodeTree).toHaveBeenCalled()
    // expect(mockAddNodeTree).toHaveBeenCalledWith(
    //   expect.objectContaining({
    //     nodes: expect.objectContaining({
    //       [expect.any(String)]: expect.objectContaining({
    //         data: expect.objectContaining({
    //           displayName: 'BlankSection',
    //         }),
    //       }),
    //     }),
    //   }),
    //   'ROOT'
    // )
  })

  describe('keyboard navigation', () => {
    it('stops at each section template on TAB', async () => {
      const {container} = renderComponent()
      const sections = container.querySelectorAll('.toolbox-item')
      ;(sections[0] as HTMLElement).focus()
      await user.tab()
      expect(sections[1]).toHaveFocus()
    })

    it('stops on the edit and delete buttons of the user is a template editor', async () => {
      const {container, getByText} = renderComponent({templateEditor: TemplateEditor.LOCAL})
      const sections = container.querySelectorAll('.toolbox-item')
      ;(sections[0] as HTMLElement).focus()
      await user.tab()
      expect(sections[1]).toHaveFocus()
      await user.tab()
      expect(getByText('Edit Template').closest('button')).toHaveFocus()
      await user.tab()
      expect(getByText('Delete Template').closest('button')).toHaveFocus()
    })
  })
})
