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
import {render, screen, waitFor} from '@testing-library/react'
import {getByText as domGetByText} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import BlockEditor, {type BlockEditorProps} from '../BlockEditor'
import {blank_page, blank_section_with_text} from './test-content'
import {dispatchTemplateEvent, SaveTemplateEvent, DeleteTemplateEvent} from '../types'
import {LATEST_BLOCK_DATA_VERSION} from '../utils'

const user = userEvent.setup()

function renderEditor(props: Partial<BlockEditorProps> = {}) {
  const container = document.createElement('div')
  container.id = 'drawer-layout-content'
  container.scrollTo = () => {}
  document.body.appendChild(container)

  return render(
    <BlockEditor
      course_id="1"
      container={container}
      enableResizer={false} // jsdom doesn't render enough for BlockResizer to work
      content={{version: LATEST_BLOCK_DATA_VERSION, blocks: JSON.parse(blank_page)}}
      {...props}
    />,
    {container},
  )
}

describe('BlockEditor', () => {
  const can_edit_url = '/api/v1/courses/1/block_editor_templates/can_edit'
  const get_templates_url =
    '/api/v1/courses/1/block_editor_templates?include[]=node_tree&include[]=thumbnail&sort=name'
  const template_url = '/api/v1/courses/1/block_editor_templates'
  beforeAll(() => {
    window.alert = jest.fn()

    fetchMock.get(can_edit_url, {
      can_edit: false,
      can_edit_global: false,
    })
    fetchMock.get(get_templates_url, [{id: '1'}])
    fetchMock.post(template_url, {global_id: 'g1'})
    fetchMock.delete(`${template_url}/1`, 200)
  })

  afterEach(() => jest.clearAllMocks())

  it('renders', async () => {
    const {getByText, getByLabelText} = renderEditor()
    expect(getByText('Preview')).toBeInTheDocument()
    expect(getByText('Undo')).toBeInTheDocument()
    expect(getByText('Redo')).toBeInTheDocument()
    expect(getByLabelText('Block Toolbox')).toBeChecked()

    // Wait for all API calls to complete
    await waitFor(() => {
      expect(fetchMock.calls().length).toBeGreaterThan(0)
    })

    // Verify the first API call is the can_edit check
    const calls = fetchMock.calls().map(call => call[0])
    expect(calls[0]).toBe(can_edit_url)
  })

  it('warns on content version mismatch', () => {
    // @ts-expect-error - passing invalid version on purpose
    renderEditor({content: {id: '1', version: '2', blocks: blank_page}})
    expect(window.alert).toHaveBeenCalledWith('Unknown block data version "2", mayhem may ensue')
  })

  describe('data transformations', () => {
    it('can edit version 0.1 data', () => {
      renderEditor({
        content: {
          id: '1',
          version: '0.1',
          blocks: [{data: blank_section_with_text}],
        },
      })
      expect(screen.getByText('this is text.')).toBeInTheDocument()
    })
  })

  describe('Preview', () => {
    it('toggles the preview', async () => {
      // rebnder a page with a blank section containing a text block
      const {getByText} = renderEditor({
        content: {id: '1', version: '0.2', blocks: blank_section_with_text},
      })
      await user.click(getByText('Preview').closest('button') as HTMLButtonElement)

      const previewModal = screen.getByLabelText('Preview')
      expect(previewModal).toHaveAttribute('role', 'dialog')

      expect(domGetByText(previewModal, 'this is text.', {exact: true})).toBeInTheDocument()

      const closeButton = domGetByText(previewModal, 'Close', {exact: true}).closest(
        'button',
      ) as HTMLButtonElement
      await user.click(closeButton)

      await waitFor(() => {
        expect(screen.queryByLabelText('Preview')).not.toBeInTheDocument()
      })
    })
  })

  describe('saving templates', () => {
    it('saves a template', async () => {
      renderEditor({
        content: {id: '1', version: '0.2', blocks: blank_page},
      })
      const template = {
        name: 'test',
        node_tree: {
          rootNodeId: '1',
          nodes: {1: {custom: {displayName: 'foo'}}},
        },
      }
      const saveTemplateEvent = new CustomEvent(SaveTemplateEvent, {
        detail: {
          template,
          globalTemplate: false,
        },
      })
      dispatchTemplateEvent(saveTemplateEvent)

      expect(fetchMock.called(template_url, 'POST')).toBe(true)
    })

    it('deletes a template', async () => {
      window.confirm = jest.fn(() => true)
      renderEditor({
        content: {id: '1', version: '0.2', blocks: blank_page},
      })
      const deleteTemplateEvent = new CustomEvent(DeleteTemplateEvent, {
        detail: '1',
      })
      dispatchTemplateEvent(deleteTemplateEvent)

      expect(fetchMock.called(`${template_url}/1`, 'DELETE')).toBe(true)
    })
  })
})
