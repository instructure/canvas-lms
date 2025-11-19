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
import {Provider} from '../../utilities/fastContext'
import {createStore} from '../../store'
import {useEditorMode} from '../../hooks/useEditorMode'

const mockSetMode = jest.fn()

function renderToolbar(toolbarReorder = false) {
  return render(
    <Provider
      store={createStore({
        aiAltTextGenerationURL: null,
        toolbarReorder,
      })}
    >
      <Editor>
        <Toolbar />
      </Editor>
    </Provider>,
  )
}

const mockStore = jest.fn()
jest.mock('react', () => {
  const ActualReact = jest.requireActual('react')
  return {
    ...ActualReact,
    useContext: (context: React.Context<any>) => {
      const result = ActualReact.useContext(context)
      if (context.displayName === 'FastContext') {
        return {
          ...result,
          get: () => mockStore(),
        }
      }
      return result
    },
  }
})

jest.mock('../../hooks/useEditorMode', () => ({
  useEditorMode: () => {
    return {mode: mockStore().editor.mode, setMode: mockSetMode}
  },
}))

describe('Toolbar', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })
  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('when toolbar is in default mode', () => {
    beforeEach(() => {
      mockStore.mockReturnValue({
        editor: {mode: 'default'},
        accessibility: {
          a11yIssues: new Map(),
        },
      })
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
      mockStore.mockReturnValue({
        editor: {mode: 'preview'},
      })
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
    beforeEach(() => {
      mockStore.mockReturnValue({
        editor: {mode: 'default'},
        accessibility: {
          a11yIssues: new Map(),
        },
        toolbarReorder: false,
      })
    })

    it('does not show reorder button when feature flag is false', () => {
      const {queryByTestId} = renderToolbar(false)
      expect(queryByTestId('reorder-blocks-button')).not.toBeInTheDocument()
    })

    it('shows reorder button when feature flag is true', () => {
      mockStore.mockReturnValue({
        editor: {mode: 'default'},
        accessibility: {
          a11yIssues: new Map(),
        },
        toolbarReorder: true,
      })

      const {getByTestId} = renderToolbar(true)
      expect(getByTestId('reorder-blocks-button')).toBeInTheDocument()
    })

    it('does not show reorder button in preview mode', () => {
      mockStore.mockReturnValue({
        editor: {mode: 'preview'},
        toolbarReorder: true,
      })

      const {queryByTestId} = renderToolbar(true)
      expect(queryByTestId('reorder-blocks-button')).not.toBeInTheDocument()
    })

    it('shows reorder button after undo/redo buttons', () => {
      mockStore.mockReturnValue({
        editor: {mode: 'default'},
        accessibility: {
          a11yIssues: new Map(),
        },
        toolbarReorder: true,
      })

      const {getByTestId} = renderToolbar(true)
      const undoButton = getByTestId('undo-button')
      const redoButton = getByTestId('redo-button')
      const reorderButton = getByTestId('reorder-blocks-button')

      expect(undoButton).toBeInTheDocument()
      expect(redoButton).toBeInTheDocument()
      expect(reorderButton).toBeInTheDocument()
    })

    it('shows reorder button before accessibility checker', () => {
      mockStore.mockReturnValue({
        editor: {mode: 'default'},
        accessibility: {
          a11yIssues: new Map(),
        },
        toolbarReorder: true,
      })

      const {getByTestId} = renderToolbar(true)
      const reorderButton = getByTestId('reorder-blocks-button')
      const a11yButton = getByTestId('accessibility-button')

      expect(reorderButton).toBeInTheDocument()
      expect(a11yButton).toBeInTheDocument()
    })
  })
})
