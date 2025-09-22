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

import {render} from '@testing-library/react'
import {BlockContentEditor} from '../BlockContentEditor'
import {useBlockContentEditorContext} from '../BlockContentEditorContext'

const mockPreviewComponent = jest.fn()
jest.mock('../Preview/BlockContentPreview', () => ({
  BlockContentPreview: (props: any) => mockPreviewComponent(props),
}))

const mockEditorContentComponent = jest.fn()
jest.mock('../BlockContentEditorContent', () => ({
  BlockContentEditorContent: (props: any) => mockEditorContentComponent(props),
}))

jest.mock('../layout/BlockContentEditorLayout', () => ({
  BlockContentEditorLayout: ({editor}: {editor: React.ReactNode}) => (
    <div data-testid="block-content-editor-layout">{editor}</div>
  ),
}))

jest.mock('../Toolbar', () => ({
  Toolbar: () => null,
}))

jest.mock('../BlockContentEditorContext', () => ({
  __esModule: true,
  BlockContentEditorContext: ({children}: {children: React.ReactNode}) => <div>{children}</div>,
  useBlockContentEditorContext: jest.fn(),
}))

function setupMockContext(mode: string = 'default') {
  ;(useBlockContentEditorContext as jest.Mock).mockReturnValue({
    editor: {
      mode,
      setMode: jest.fn(),
    },
    addBlockModal: {
      isOpen: false,
      openModal: jest.fn(),
      closeModal: jest.fn(),
    },
    settingsTray: {
      isOpen: false,
      openTray: jest.fn(),
      closeTray: jest.fn(),
    },
  })
}

describe('BlockContentEditor', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    setupMockContext()
  })

  it('does not break when onInit is null', () => {
    expect(() => {
      render(
        <BlockContentEditor
          data={null}
          onInit={null}
          aiAltTextGenerationURL="/api/v1/courses/1/pages/ai/alt_text"
        />,
      )
    }).not.toThrow()
  })

  describe('when editor mode is "default"', () => {
    beforeEach(() => {
      setupMockContext('default')
    })

    it('renders the BlockContentEditorContent component', () => {
      render(<BlockContentEditor data={null} onInit={null} aiAltTextGenerationURL={null} />)
      expect(mockEditorContentComponent).toHaveBeenCalled()
    })
  })

  describe('when editor mode is "preview"', () => {
    beforeEach(() => {
      setupMockContext('preview')
    })

    it('renders the BlockContentPreview component', () => {
      render(<BlockContentEditor data={null} onInit={null} aiAltTextGenerationURL={null} />)
      expect(mockPreviewComponent).toHaveBeenCalled()
    })
  })
})
