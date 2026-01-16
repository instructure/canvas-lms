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

import React from 'react'
import {render, screen, fireEvent, waitFor, cleanup} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import SyllabusRevisionsTray from '../SyllabusRevisionsTray'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import RichContentEditor from '@canvas/rce/RichContentEditor'

const server = setupServer()

vi.mock('@canvas/alerts/react/FlashAlert')
vi.mock('@canvas/rce/RichContentEditor', () => ({
  default: {
    callOnRCE: vi.fn(),
  },
}))

describe('SyllabusRevisionsTray', () => {
  const mockVersions = [
    {
      version: 3,
      created_at: '2025-01-03T00:00:00Z',
      syllabus_body: '<p>Current content</p>',
      edited_by: {
        id: 1,
        name: 'John Doe',
      },
    },
    {
      version: 2,
      created_at: '2025-01-02T00:00:00Z',
      syllabus_body: '<p>Previous content</p>',
      edited_by: {
        id: 2,
        name: 'Jane Smith',
      },
    },
    {
      version: 1,
      created_at: '2025-01-01T00:00:00Z',
      syllabus_body: '<p>Old content</p>',
    },
  ]

  const defaultProps = {
    courseId: '123',
    open: true,
    onDismiss: vi.fn(),
  }

  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    cleanup()
    document.body.innerHTML = ''
    vi.mocked(showFlashAlert).mockClear()
    vi.mocked(showFlashError).mockClear()
    vi.mocked(RichContentEditor.callOnRCE).mockClear()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    vi.mocked(showFlashError).mockReturnValue(vi.fn())
  })

  it('renders tray when open', () => {
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)
    expect(screen.getByTestId('syllabus-revisions-tray')).toBeInTheDocument()
  })

  it('fetches versions when tray opens', async () => {
    let requestMade = false
    server.use(
      http.get('/api/v1/courses/123', ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('include[]') === 'syllabus_versions') {
          requestMade = true
        }
        return HttpResponse.json({syllabus_versions: mockVersions})
      }),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(requestMade).toBe(true)
    })
  })

  it('displays versions in the list', async () => {
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('Latest revision')).toBeInTheDocument()
      expect(screen.getByTestId('version-2')).toBeInTheDocument()
      expect(screen.getByTestId('version-1')).toBeInTheDocument()
    })
  })

  it('shows restore button only when non-current version is selected', async () => {
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('current-version')).toBeInTheDocument()
    })

    expect(screen.queryByText('Restore this version')).not.toBeInTheDocument()

    fireEvent.click(screen.getByTestId('version-2'))

    await waitFor(() => {
      expect(screen.getByTestId('restore-version-2')).toBeInTheDocument()
    })
  })

  it('shows confirmation modal when restore is clicked', async () => {
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('version-2'))

    await waitFor(() => {
      expect(screen.getByTestId('restore-version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('restore-version-2'))

    await waitFor(() => {
      expect(screen.getByText('Confirm restore')).toBeInTheDocument()
    })
  })

  it('restores version when confirmed', async () => {
    let restoreRequested = false
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
      http.post('/api/v1/courses/123/restore/2', () => {
        restoreRequested = true
        return HttpResponse.json({})
      }),
    )

    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('version-2'))

    await waitFor(() => {
      expect(screen.getByTestId('restore-version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('restore-version-2'))

    await waitFor(() => {
      expect(screen.getByTestId('confirm-restore')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('confirm-restore'))

    await waitFor(() => {
      expect(restoreRequested).toBe(true)
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Revision successfully restored',
        type: 'success',
      })
    })
  })

  it('shows error when restore fails', async () => {
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
      http.post('/api/v1/courses/123/restore/2', () => {
        return HttpResponse.json({error: 'Restore failed'}, {status: 500})
      }),
    )

    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('version-2'))

    await waitFor(() => {
      expect(screen.getByTestId('restore-version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('restore-version-2'))

    await waitFor(() => {
      expect(screen.getByTestId('confirm-restore')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('confirm-restore'))

    await waitFor(
      () => {
        expect(showFlashError).toHaveBeenCalledWith('Failed to restore version')
      },
      {timeout: 3000},
    )
  })

  it('updates page syllabus content when version is clicked', async () => {
    document.body.innerHTML = '<div id="course_syllabus"></div>'
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('version-2'))

    const syllabusElement = document.getElementById('course_syllabus')
    expect(syllabusElement?.innerHTML).toBe('<p>Previous content</p>')
  })

  it('shows empty state when no versions available', async () => {
    server.use(http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: []})))
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText('No previous versions available')).toBeInTheDocument()
    })
  })

  it('restores current version when tray closes after viewing different version', async () => {
    document.body.innerHTML = '<div id="course_syllabus"><p>Current content</p></div>'
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    const {rerender} = render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('version-2')).toBeInTheDocument()
    })

    fireEvent.click(screen.getByTestId('version-2'))

    const syllabusElement = document.getElementById('course_syllabus')
    expect(syllabusElement?.innerHTML).toBe('<p>Previous content</p>')

    rerender(<SyllabusRevisionsTray {...defaultProps} open={false} />)

    expect(syllabusElement?.innerHTML).toBe('<p>Current content</p>')
  })

  it('does not restore content if it has not changed when tray closes', async () => {
    document.body.innerHTML = '<div id="course_syllabus"><p>Current content</p></div>'
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    const {rerender} = render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('current-version')).toBeInTheDocument()
    })

    const syllabusElement = document.getElementById('course_syllabus')
    const originalInnerHTML = syllabusElement?.innerHTML

    rerender(<SyllabusRevisionsTray {...defaultProps} open={false} />)

    expect(syllabusElement?.innerHTML).toBe(originalInnerHTML)
  })

  it('displays user name when edited_by is present', async () => {
    server.use(
      http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByText(/by John Doe/)).toBeInTheDocument()
      expect(screen.getByText(/by Jane Smith/)).toBeInTheDocument()
    })
  })

  it('does not display user name when edited_by is not present', async () => {
    const versionsWithoutUser = [
      {
        version: 1,
        created_at: '2025-01-01T00:00:00Z',
        syllabus_body: '<p>Old content</p>',
      },
    ]
    server.use(
      http.get('/api/v1/courses/123', () =>
        HttpResponse.json({syllabus_versions: versionsWithoutUser}),
      ),
    )
    render(<SyllabusRevisionsTray {...defaultProps} />)

    await waitFor(() => {
      expect(screen.getByTestId('current-version')).toBeInTheDocument()
    })

    expect(screen.queryByText(/by /)).not.toBeInTheDocument()
  })

  describe('edit mode behavior', () => {
    it('sets editor content when version clicked in edit mode', async () => {
      document.body.innerHTML = `
        <div id="course_syllabus"></div>
        <form id="edit_course_syllabus_form" style="display: block;">
          <textarea id="course_syllabus_body"></textarea>
        </form>
      `
      server.use(
        http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
      )
      render(<SyllabusRevisionsTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByTestId('version-2')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByTestId('version-2'))

      expect(RichContentEditor.callOnRCE).toHaveBeenCalledWith(
        expect.anything(),
        'set_code',
        '<p>Previous content</p>',
      )
    })

    it('does not update page syllabus when version clicked in edit mode', async () => {
      document.body.innerHTML = `
        <div id="course_syllabus"><p>Current content</p></div>
        <form id="edit_course_syllabus_form" style="display: block;">
          <textarea id="course_syllabus_body"></textarea>
        </form>
      `
      server.use(
        http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
      )
      render(<SyllabusRevisionsTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByTestId('version-2')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByTestId('version-2'))

      const syllabusElement = document.getElementById('course_syllabus')
      expect(syllabusElement?.innerHTML).toBe('<p>Current content</p>')
    })

    it('does not restore content when tray closes in edit mode', async () => {
      document.body.innerHTML = `
        <div id="course_syllabus"><p>Current content</p></div>
        <form id="edit_course_syllabus_form" style="display: block;">
          <textarea id="course_syllabus_body"></textarea>
        </form>
      `
      server.use(
        http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
      )
      const {rerender} = render(<SyllabusRevisionsTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByTestId('version-2')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByTestId('version-2'))

      const syllabusElement = document.getElementById('course_syllabus')
      const contentBeforeClose = syllabusElement?.innerHTML

      rerender(<SyllabusRevisionsTray {...defaultProps} open={false} />)

      expect(syllabusElement?.innerHTML).toBe(contentBeforeClose)
    })

    it('updates page syllabus when not in edit mode', async () => {
      document.body.innerHTML = `
        <div id="course_syllabus"><p>Current content</p></div>
        <form id="edit_course_syllabus_form" style="display: none;">
          <textarea id="course_syllabus_body"></textarea>
        </form>
      `
      server.use(
        http.get('/api/v1/courses/123', () => HttpResponse.json({syllabus_versions: mockVersions})),
      )
      render(<SyllabusRevisionsTray {...defaultProps} />)

      await waitFor(() => {
        expect(screen.getByTestId('version-2')).toBeInTheDocument()
      })

      fireEvent.click(screen.getByTestId('version-2'))

      const syllabusElement = document.getElementById('course_syllabus')
      expect(syllabusElement?.innerHTML).toBe('<p>Previous content</p>')
      expect(RichContentEditor.callOnRCE).not.toHaveBeenCalled()
    })
  })
})
