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

import {Editor} from '@craftjs/core'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Toolbar} from '../Toolbar'

const mockSetMode = jest.fn()
const mockUseAppSelector = jest.fn()

jest.mock('../../store', () => ({
  useAppSelector: (selector: (state: any) => any) => mockUseAppSelector(selector),
}))

jest.mock('../../hooks/useEditorMode', () => ({
  useEditorMode: () => {
    const store = mockUseAppSelector((state: any) => state)
    return {mode: store.editor.mode, setMode: mockSetMode}
  },
}))

jest.mock('../../hooks/useEditHistory', () => ({
  useEditHistory: () => ({
    undo: jest.fn(),
    redo: jest.fn(),
    canUndo: true,
    canRedo: true,
  }),
}))

jest.mock('../../hooks/useGetBlocksCount', () => ({
  useGetBlocksCount: () => ({blocksCount: 3}),
}))

function renderToolbar() {
  return render(
    <Editor>
      <Toolbar />
    </Editor>,
  )
}

describe('Toolbar', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('when toolbar is in default mode', () => {
    beforeEach(() => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'default'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: false,
        }),
      )
    })

    it('should switch to preview mode when clicked', async () => {
      const user = userEvent.setup()
      const {getByRole} = renderToolbar()
      const previewButton = getByRole('button', {name: /preview/i})

      await user.click(previewButton)

      expect(mockSetMode).toHaveBeenCalledWith('preview')
    })
  })

  describe('when toolbar is in preview mode', () => {
    beforeEach(() => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'preview'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: false,
        }),
      )
    })

    it('should switch to default mode when clicked', async () => {
      const user = userEvent.setup()
      const {getByRole} = renderToolbar()
      const previewButton = getByRole('button', {name: /preview/i})

      await user.click(previewButton)

      expect(mockSetMode).toHaveBeenCalledWith('default')
    })
  })

  describe('reorder blocks button', () => {
    it('does not show reorder button when feature flag is false', () => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'default'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: false,
        }),
      )
      const {queryByTestId} = renderToolbar()
      expect(queryByTestId('reorder-blocks-button')).not.toBeInTheDocument()
    })

    it('shows reorder button when feature flag is true', () => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'default'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: true,
        }),
      )
      const {getByTestId} = renderToolbar()
      expect(getByTestId('reorder-blocks-button')).toBeInTheDocument()
    })

    it('does not show reorder button in preview mode', () => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'preview'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: true,
        }),
      )
      const {queryByTestId} = renderToolbar()
      expect(queryByTestId('reorder-blocks-button')).not.toBeInTheDocument()
    })

    it('shows reorder button after undo/redo buttons', () => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'default'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: true,
        }),
      )
      const {getByTestId} = renderToolbar()
      const undoButton = getByTestId('undo-button')
      const redoButton = getByTestId('redo-button')
      const reorderButton = getByTestId('reorder-blocks-button')

      expect(undoButton).toBeInTheDocument()
      expect(redoButton).toBeInTheDocument()
      expect(reorderButton).toBeInTheDocument()
    })

    it('shows reorder button before accessibility checker', () => {
      mockUseAppSelector.mockImplementation((selector: (state: any) => any) =>
        selector({
          editor: {mode: 'default'},
          accessibility: {
            a11yIssueCount: 0,
            a11yIssues: new Map(),
          },
          toolbarReorder: true,
        }),
      )
      const {getByTestId} = renderToolbar()
      const reorderButton = getByTestId('reorder-blocks-button')
      const a11yButton = getByTestId('accessibility-button')

      expect(reorderButton).toBeInTheDocument()
      expect(a11yButton).toBeInTheDocument()
    })
  })
})
