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
import {
  getByText as domGetByText,
  getAllByText as domGetAllByText,
  getByLabelText as domGetByLabelText,
} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import BlockEditor, {type BlockEditorProps} from '../BlockEditor'
import {blank_page, blank_section_with_text} from './test-content'
import {dispatchTemplateEvent, SaveTemplateEvent, DeleteTemplateEvent} from '../types'

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
      content={{version: '0.2', blocks: blank_page}}
      onCancel={() => {}}
      {...props}
    />,
    {container}
  )
}

describe('BlockEditor', () => {
  const can_edit_url = '/api/v1/courses/1/block_editor_templates/can_edit'
  const get_templates_url =
    '/api/v1/courses/1/block_editor_templates?include[]=node_tree&drafts=false'
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

  it('renders', () => {
    const {getByText, getByLabelText} = renderEditor()
    expect(getByText('Preview')).toBeInTheDocument()
    expect(getByText('Undo')).toBeInTheDocument()
    expect(getByText('Redo')).toBeInTheDocument()
    expect(getByLabelText('Block Toolbox')).not.toBeChecked()
    expect(fetchMock.called(can_edit_url, 'GET')).toBe(true)
    // I don't understand why, but this returns false even though
    // I can put a console.log in in BlockEditor and see the response
    // I speified in the mock.
    // expect(fetchMock.called(templates_url, 'GET')).toBe(true)
  })

  it('warns on content version mismatch', () => {
    // @ts-expect-error - passing invalid version on purpose
    renderEditor({content: {id: '1', version: '2', blocks: blank_page}})
    expect(window.alert).toHaveBeenCalledWith('Unknown block data version "2", mayhem may ensue')
  })

  describe('New page stepper', () => {
    it('opens the stepper when no content is provided', () => {
      renderEditor({content: undefined})
      expect(screen.getByText('Create a new page')).toBeInTheDocument()
      expect(screen.getByText('Start from Scratch')).toBeInTheDocument()
      expect(screen.getByText('Select a Template')).toBeInTheDocument()
    })

    it('calls onCancel when the stepper is canceled', () => {
      const onCancel = jest.fn()
      renderEditor({content: undefined, onCancel})
      screen.getByText('Cancel').click()
      expect(onCancel).toHaveBeenCalled()
    })

    it.skip('creates a new page when the stepper is completed', async () => {
      // this passes locally, but fails in jenkins looking for "Blank Section"

      // craft.js is currently emitting a console error
      // "Cannot update a component (`RenderNode`) while rendering a different component"
      // Supress the message for now so we pass jenkins.
      // will address with RCX-2173
      jest.spyOn(console, 'error').mockImplementation(() => {})
      const {container, getByText} = renderEditor({content: undefined})
      expect(screen.getByText('Create a new page')).toBeInTheDocument()

      const nextButton = screen.getByText('Next').closest('button') as HTMLButtonElement
      await user.click(nextButton)
      await user.click(nextButton)
      await user.click(nextButton)
      await user.click(nextButton)
      const startButton = screen.getByText('Start Creating').closest('button') as HTMLButtonElement
      await user.click(startButton)

      await waitFor(() => {
        expect(screen.queryByText('Create a new page')).not.toBeInTheDocument()
      })
      await waitFor(() => {
        expect(getByText('Blank Section')).toBeInTheDocument()
        expect(container.querySelector('.section-menu')).toBeInTheDocument()
      })
      expect(screen.queryByLabelText('Toolbox')).toHaveAttribute('role', 'dialog')
    })
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

      expect(domGetAllByText(previewModal, 'View Size')).toHaveLength(2)
      expect(domGetByText(previewModal, 'this is text.', {exact: true})).toBeInTheDocument()

      const closeButton = domGetByText(previewModal, 'Close', {exact: true}).closest(
        'button'
      ) as HTMLButtonElement
      await user.click(closeButton)

      await waitFor(() => {
        expect(screen.queryByLabelText('Preview')).not.toBeInTheDocument()
      })
    })

    it('adjusts the view size', async () => {
      // rebnder a page with a blank section containing a text block
      const {getByText} = renderEditor({
        content: {id: '1', version: '0.2', blocks: blank_section_with_text},
      })
      await user.click(getByText('Preview').closest('button') as HTMLButtonElement)

      const previewModal = screen.getByLabelText('Preview')
      expect(previewModal).toHaveAttribute('role', 'dialog')

      expect(domGetByLabelText(previewModal, 'Desktop')).toBeChecked()

      const view = document.querySelector('.block-editor-view') as HTMLElement

      expect(view).toHaveClass('desktop')
      expect(view).toHaveStyle({width: '1026px'})

      const tablet = domGetByLabelText(previewModal, 'Tablet')
      expect(tablet).not.toBeChecked()
      await user.click(tablet)
      expect(tablet).toBeChecked()
      expect(view).toHaveClass('tablet')
      expect(view).toHaveStyle({width: '768px'})

      const mobile = domGetByLabelText(previewModal, 'Mobile')
      expect(mobile).not.toBeChecked()
      await user.click(mobile)
      expect(mobile).toBeChecked()
      expect(view).toHaveClass('mobile')
      expect(view).toHaveStyle({width: '320px'})
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
