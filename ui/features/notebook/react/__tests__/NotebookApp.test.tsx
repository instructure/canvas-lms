/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import NotebookApp from '../NotebookApp'

const mockOpenTray = vi.fn()
const mockCloseTray = vi.fn()
const mockSelectNote = vi.fn()
const mockClearSelectedNote = vi.fn()
let mockIsTrayOpen = false
let mockSelectedNoteId: string | null = null

vi.mock('@instructure/platform-notebook', () => ({
  NotebookProvider: ({children}: {children: React.ReactNode}) => (
    <div data-testid="notebook-provider">{children}</div>
  ),
  NotebookTray: ({children}: {children: React.ReactNode}) => (
    <div data-testid="notebook-tray">{children}</div>
  ),
  NotesListView: ({onNoteSelect}: {onNoteSelect?: (id: string) => void}) => (
    <button data-testid="select-note-btn" onClick={() => onNoteSelect?.('note-1')}>
      select note
    </button>
  ),
  ContentWithNoteWrapper: () => <div data-testid="content-with-note-wrapper" />,
  useNotebook: () => ({
    api: {},
    objectId: 'my-page',
    objectType: 'Page',
    courseId: '42',
    selectedNoteId: mockSelectedNoteId,
    selectNote: mockSelectNote,
    clearSelectedNote: mockClearSelectedNote,
    isTrayOpen: mockIsTrayOpen,
    openTray: mockOpenTray,
    closeTray: mockCloseTray,
  }),
  useGetNotes: () => ({data: {notes: [], pageInfo: {}}, isLoading: false, isError: false}),
  useUpdateNote: () => ({mutate: vi.fn()}),
  useDeleteNote: () => ({mutate: vi.fn()}),
  REACTION_TYPE: {IMPORTANT: 'Important', CONFUSING: 'Confusing'},
}))

vi.mock('../../api/CanvasNotebookApi', () => ({
  CanvasNotebookApi: vi.fn(),
}))

describe('NotebookApp', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockIsTrayOpen = false
    mockSelectedNoteId = null
    window.ENV = {
      ...window.ENV,
      JOURNEY_URL: 'https://journey.test',
      current_user_id: 'user-1',
      WIKI_PAGE_ID: 'my-page',
      WIKI_PAGE_UPDATED_AT: '2026-01-01T00:00:00Z',
      COURSE_ID: '42',
      FEATURES: {notebook: true},
    } as typeof window.ENV
  })

  it('renders nothing when JOURNEY_URL is not set', () => {
    window.ENV.JOURNEY_URL = undefined
    const {container} = render(<NotebookApp />)
    expect(container.innerHTML).toBe('')
  })

  it('renders the notebook button', () => {
    render(<NotebookApp />)
    expect(screen.getByTestId('notebook-button')).toBeInTheDocument()
  })

  it('wraps content in NotebookProvider', () => {
    render(<NotebookApp />)
    expect(screen.getByTestId('notebook-provider')).toBeInTheDocument()
  })

  it('renders the NotebookTray', () => {
    render(<NotebookApp />)
    expect(screen.getByTestId('notebook-tray')).toBeInTheDocument()
  })

  it('opens the tray when the button is clicked', async () => {
    const user = userEvent.setup()
    render(<NotebookApp />)

    await user.click(screen.getByTestId('notebook-button'))
    expect(mockOpenTray).toHaveBeenCalledTimes(1)
  })

  it('closes the tray when the button is clicked while open', async () => {
    mockIsTrayOpen = true
    const user = userEvent.setup()
    render(<NotebookApp />)

    await user.click(screen.getByTestId('notebook-button'))
    expect(mockCloseTray).toHaveBeenCalledTimes(1)
  })

  it('renders ContentWithNoteWrapper when wiki content container exists', () => {
    const contentEl = document.createElement('div')
    contentEl.className = 'show-content user_content'
    document.body.appendChild(contentEl)

    render(<NotebookApp />)
    expect(screen.getByTestId('content-with-note-wrapper')).toBeInTheDocument()

    document.body.removeChild(contentEl)
  })

  it('does not render ContentWithNoteWrapper when wiki content container is missing', () => {
    render(<NotebookApp />)
    expect(screen.queryByTestId('content-with-note-wrapper')).not.toBeInTheDocument()
  })

  it('renders ContentWithNoteWrapper when wiki content container is added after mount', async () => {
    render(<NotebookApp />)
    expect(screen.queryByTestId('content-with-note-wrapper')).not.toBeInTheDocument()

    const contentEl = document.createElement('div')
    contentEl.className = 'show-content user_content'
    document.body.appendChild(contentEl)

    try {
      await waitFor(() => {
        expect(screen.getByTestId('content-with-note-wrapper')).toBeInTheDocument()
      })
    } finally {
      document.body.removeChild(contentEl)
    }
  })

  it('calls selectNote on the context when a note is selected', async () => {
    const user = userEvent.setup()
    render(<NotebookApp />)

    await user.click(screen.getByTestId('select-note-btn'))
    expect(mockSelectNote).toHaveBeenCalledWith('note-1')
    expect(mockClearSelectedNote).not.toHaveBeenCalled()
  })

  it('calls clearSelectedNote when the active note is selected again', async () => {
    mockSelectedNoteId = 'note-1'
    const user = userEvent.setup()
    render(<NotebookApp />)

    await user.click(screen.getByTestId('select-note-btn'))
    expect(mockClearSelectedNote).toHaveBeenCalled()
    expect(mockSelectNote).not.toHaveBeenCalled()
  })
})
