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
import BlockEditor from '../BlockEditor'

const user = userEvent.setup()

const PAGE_WITH_BLANK_SECTION_AND_TEXT_BLOCK = `{
  "ROOT": {
    "type": {
      "resolvedName": "PageBlock"
    },
    "isCanvas": true,
    "props": {},
    "displayName": "Page",
    "custom": {},
    "hidden": false,
    "nodes": [
      "_H17VRi7hL"
    ],
    "linkedNodes": {}
  },
  "_H17VRi7hL": {
    "type": {
      "resolvedName": "BlankSection"
    },
    "isCanvas": false,
    "props": {},
    "displayName": "Blank Section",
    "custom": {
      "isSection": true
    },
    "parent": "ROOT",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {
      "blank-section_nosection1": "eXJDI6Ex1I"
    }
  },
  "eXJDI6Ex1I": {
    "type": {
      "resolvedName": "NoSections"
    },
    "isCanvas": true,
    "props": {
      "className": "blank-section__inner"
    },
    "displayName": "NoSections",
    "custom": {
      "noToolbar": true
    },
    "parent": "_H17VRi7hL",
    "hidden": false,
    "nodes": [
      "a7y-qnd2V8"
    ],
    "linkedNodes": {}
  },
  "a7y-qnd2V8": {
    "type": {
      "resolvedName": "TextBlock"
    },
    "isCanvas": false,
    "props": {
      "fontSize": "12pt",
      "textAlign": "initial",
      "color": "var(--ic-brand-font-color-dark)",
      "text": "this is text."
    },
    "displayName": "Text",
    "custom": {},
    "parent": "eXJDI6Ex1I",
    "hidden": false,
    "nodes": [],
    "linkedNodes": {}
  }
}`

function renderEditor(props = {}) {
  const container = document.createElement('div')
  container.id = 'drawer-layout-content'
  container.scrollTo = () => {}
  document.body.appendChild(container)

  return render(
    <BlockEditor
      container={container}
      version="1"
      content={JSON.stringify({
        ROOT: {
          type: {
            resolvedName: 'PageBlock',
          },
          isCanvas: true,
          props: {},
          displayName: 'Page',
          custom: {},
          hidden: false,
          nodes: [],
          linkedNodes: {},
        },
      })}
      onCancel={() => {}}
      {...props}
    />,
    {container}
  )
}

describe('BlockEditor', () => {
  beforeAll(() => {
    window.alert = jest.fn()
  })

  it('renders', () => {
    const {getByText, getByLabelText} = renderEditor()
    expect(getByText('Preview')).toBeInTheDocument()
    expect(getByText('Undo')).toBeInTheDocument()
    expect(getByText('Redo')).toBeInTheDocument()
    expect(getByLabelText('Block Toolbox')).not.toBeChecked()
  })

  it('warns on content version mismatch', () => {
    renderEditor({version: '2'})
    expect(window.alert).toHaveBeenCalledWith('wrong version, mayhem may ensue')
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

    it('creates a new page when the stepper is completed', async () => {
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
      expect(getByText('Blank Section')).toBeInTheDocument()
      expect(container.querySelector('.section-menu')).toBeInTheDocument()
      expect(screen.queryByLabelText('Toolbox')).toHaveAttribute('role', 'dialog')
    })
  })

  describe('Preview', () => {
    it('toggles the preview', async () => {
      // rebnder a page with a blank section containing a text block
      const {getByText} = renderEditor({
        content: PAGE_WITH_BLANK_SECTION_AND_TEXT_BLOCK,
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
        content: PAGE_WITH_BLANK_SECTION_AND_TEXT_BLOCK,
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
})
