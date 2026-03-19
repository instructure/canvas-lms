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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import CrosslistForm from '../CrosslistForm'

// Polyfill for Promise.withResolvers if not present (for older Node versions)
if (typeof Promise.withResolvers === 'undefined') {
  Promise.withResolvers = function <T>(): {
    promise: Promise<T>
    resolve: (value: T | PromiseLike<T>) => void
    reject: (reason?: unknown) => void
  } {
    let resolve!: (value: T | PromiseLike<T>) => void
    let reject!: (reason?: unknown) => void
    // eslint-disable-next-line promise/param-names
    const promise = new Promise<T>((res, rej) => {
      resolve = res
      reject = rej
    })
    return {promise, resolve, reject}
  }
}

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: vi.fn(() => vi.fn()),
}))

vi.mock('@canvas/rails-flash-notifications', () => ({
  addFlashNoticeForNextPage: vi.fn(),
}))

const server = setupServer()

describe('CrosslistForm', () => {
  const defaultProps = {
    sectionId: '456',
    isAlreadyCrosslisted: false,
    manageableCoursesUrl: '/api/v1/manageable_courses',
    confirmCrosslistUrl: '/api/v1/courses/:id/confirm_crosslist',
    crosslistUrl: '/api/v1/sections/456/crosslist',
  }

  beforeAll(() => server.listen())

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    vi.restoreAllMocks()
  })

  afterAll(() => server.close())

  describe('Rendering and Initial State', () => {
    it('renders the trigger button', () => {
      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)
      expect(getByTestId('crosslist-trigger-button')).toBeInTheDocument()
    })

    it('shows correct button text when not already crosslisted', () => {
      const {getByText} = render(<CrosslistForm {...defaultProps} isAlreadyCrosslisted={false} />)
      expect(getByText('Cross-List this Section')).toBeInTheDocument()
    })

    it('shows correct button text when already crosslisted', () => {
      const {getByText} = render(<CrosslistForm {...defaultProps} isAlreadyCrosslisted={true} />)
      expect(getByText('Re-Cross-List this Section')).toBeInTheDocument()
    })

    it('does not show modal initially', () => {
      const {queryByTestId} = render(<CrosslistForm {...defaultProps} />)
      expect(queryByTestId('crosslist-modal')).toBeNull()
    })
  })

  describe('Modal Behavior', () => {
    it('opens modal when trigger button is clicked', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      expect(getByText('Cross-List Section')).toBeInTheDocument()
      expect(getByTestId('crosslist-modal')).toBeInTheDocument()
    })

    it('closes modal when cancel button is clicked', async () => {
      const {getByTestId, queryByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      expect(queryByTestId('crosslist-modal')).toBeInTheDocument()

      await userEvent.click(getByTestId('crosslist-cancel-button'))

      await waitFor(() => {
        expect(queryByTestId('crosslist-modal')).toBeNull()
      })
    })

    it('closes modal when close button is clicked', async () => {
      const {getByTestId, getByText, queryByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      expect(queryByTestId('crosslist-modal')).toBeInTheDocument()

      const closeButtonText = getByText('Close')
      const closeButton = closeButtonText.closest('button')
      await userEvent.click(closeButton!)

      await waitFor(() => {
        expect(queryByTestId('crosslist-modal')).toBeNull()
      })
    })

    it('displays modal header and body content', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      expect(getByText('Cross-List Section')).toBeInTheDocument()
      expect(
        getByText(/Cross-listing allows you to create a section in one account/),
      ).toBeInTheDocument()
    })
  })

  describe('Course Search (Autocomplete)', () => {
    it('renders the course search input', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      expect(getByText('Search for Course')).toBeInTheDocument()
      expect(getByTestId('course-search-input')).toBeInTheDocument()
    })

    it('does not call API with less than three characters typed', async () => {
      let callCount = 0
      server.use(
        http.get('/api/v1/manageable_courses', () => {
          callCount++
          return HttpResponse.json([])
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'do')

      // Wait for debounce + extra time
      await new Promise(resolve => setTimeout(resolve, 800))

      expect(callCount).toBe(0)
    })

    it('does indeed call API with 3 characters', async () => {
      let callCount = 0
      server.use(
        http.get('/api/v1/manageable_courses', () => {
          callCount++
          return HttpResponse.json([])
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'dog')

      // Wait for debounce + extra time
      await waitFor(
        () => {
          expect(callCount).toBe(1)
        },
        {timeout: 2000},
      )
    })

    it('does not call API with whitespace-only input', async () => {
      let callCount = 0
      server.use(
        http.get('/api/v1/manageable_courses', () => {
          callCount++
          return HttpResponse.json([])
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, '   ')

      // Wait for debounce + extra time
      await new Promise(resolve => setTimeout(resolve, 800))

      expect(callCount).toBe(0)
    })

    it('shows hint message when modal opens (before typing)', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      expect(getByText('Enter at least 3 characters to search')).toBeInTheDocument()
    })

    it('shows hint message when typing less than 3 chars (firstUse=true)', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'e')

      expect(getByText('Enter at least 3 characters to search')).toBeInTheDocument()
    })

    it('shows error message when typing less than 3 chars after blur', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)

      // Initially shows as hint
      expect(getByText('Enter at least 3 characters to search')).toBeInTheDocument()

      // Blur the field
      await userEvent.tab()

      // Type less than 3 characters - should still show the message
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'en')

      // Should still show the message (now as error after blur)
      expect(getByText('Enter at least 3 characters to search')).toBeInTheDocument()
    })

    it('clears message when 3+ characters entered', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
      )

      const {getByTestId, getByText, queryByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'e')

      // Should show message with 1 character
      expect(getByText('Enter at least 3 characters to search')).toBeInTheDocument()

      // Type more characters
      await userEvent.type(searchInput, 'ng')

      // Message should be gone
      await waitFor(() => {
        expect(queryByText('Enter at least 3 characters to search')).toBeNull()
      })
    })

    it('shows an unauthorized crosslist as an error under the search box', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
        http.get('/api/v1/courses/101/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: false,
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      await userEvent.click(getByText('Biology 101'))

      // Wait for error message
      await waitFor(() => {
        expect(getByText(/Biology 101 not authorized for cross-listing/)).toBeInTheDocument()
      })
    })

    it('resets firstUse when modal reopens', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      // First interaction
      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)

      // Blur the field (sets firstUse=false)
      await userEvent.tab()

      // Close modal
      await userEvent.click(getByTestId('crosslist-cancel-button'))

      // Reopen modal
      await userEvent.click(getByTestId('crosslist-trigger-button'))

      // Should show hint again (not error) because firstUse was reset
      expect(getByText('Enter at least 3 characters to search')).toBeInTheDocument()
    })

    it('fetches course options when user types in search', async () => {
      let searchTerm = ''
      server.use(
        http.get('/api/v1/manageable_courses', ({request}) => {
          const url = new URL(request.url)
          searchTerm = url.searchParams.get('term') || ''
          return HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
            {
              id: '102',
              label: 'Chemistry 101',
              sis_id: 'CHEM101',
              term: 'Fall 2024',
            },
          ])
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Bio')

      // Verify search term in the API call
      await waitFor(
        () => {
          expect(searchTerm).toBe('Bio')
        },
        {timeout: 2000},
      )
    })

    it('debounces the search API call', async () => {
      let callCount = 0
      server.use(
        http.get('/api/v1/manageable_courses', () => {
          callCount++
          return HttpResponse.json([])
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown

      // Type multiple characters quickly
      await userEvent.type(searchInput, 'B')
      await userEvent.type(searchInput, 'i')
      await userEvent.type(searchInput, 'o')

      // Should only make one call after debounce period
      await waitFor(
        () => {
          expect(callCount).toBe(1)
        },
        {timeout: 2000},
      )
    })

    it('displays course options with SIS ID and term', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: '2718281828',
              term: 'Spring 2026',
            },
          ]),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Bio')

      // Wait for debounce (500ms) + API call + render
      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
          expect(getByText(/SIS ID: 2718281828.*Term: Spring 2026/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('displays course options without SIS ID', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              term: 'Intersession 1984',
            },
          ]),
        ),
      )

      const {getByTestId, getByText, queryByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
          expect(getByText('Term: Intersession 1984')).toBeInTheDocument()
          expect(queryByText(/SIS ID:/)).toBeNull()
        },
        {timeout: 2000},
      )
    })

    it('shows loading state while fetching courses', async () => {
      // Set up a way to "freeze" the API response so we can
      // test the state of the component while in flight.
      const {promise: searchPromise, resolve: resolveSearch} = Promise.withResolvers<void>()

      server.use(
        http.get('/api/v1/manageable_courses', async () => {
          await searchPromise // API call will hang until this resolves, so we can test in-flight behavior
          return HttpResponse.json([
            {
              id: '101',
              label: 'Aviation 130',
              sis_id: 'AVI130',
              term: 'Fall 2025',
            },
          ])
        }),
      )

      const {getByTestId, queryByText, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Bio')

      // During loading, results shouldn't be shown yet
      expect(queryByText('Aviation 130')).toBeNull()

      // Un-hang the API call to allow loading to complete
      resolveSearch()

      // After loading completes, results should appear
      await waitFor(
        () => {
          expect(getByText('Aviation 130')).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('handles empty search results', async () => {
      server.use(http.get('/api/v1/manageable_courses', () => HttpResponse.json([])))

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Nonexistent')

      await waitFor(
        () => {
          expect(getByText('No courses found')).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('clears course options when search is cleared', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Computer Science 257',
              sis_id: 'CS257',
              term: 'Spring 1983',
            },
          ]),
        ),
      )

      const {getByTestId, getByText, queryByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown

      // Type to get results
      await userEvent.type(searchInput, 'Com')
      await waitFor(
        () => {
          expect(getByText('Computer Science 257')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Clear the search
      await userEvent.clear(searchInput)

      await waitFor(() => {
        expect(queryByText('Computer Science 257')).toBeNull()
      })
    })

    it('triggers confirmation when course is selected from dropdown', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Aviation 130',
              sis_id: 'AVI130',
              term: 'Fall 2025',
            },
          ]),
        ),
        http.get('/api/v1/courses/101/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '101', name: 'Aviation 130', sis_source_id: 'AVI130'},
            account: {name: 'Institute of Aviation'},
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Avi')

      await waitFor(
        () => {
          expect(getByText('Aviation 130')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      await userEvent.click(getByText('Aviation 130'))

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
        expect(getByTestId('selected-course-name')).toHaveTextContent('Aviation 130')
      })
    })

    it('displays error message in search field when confirmation fails', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
        http.get('/api/v1/courses/101/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: false,
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      await userEvent.click(getByText('Biology 101'))

      await waitFor(() => {
        expect(getByText(/Biology 101 not authorized for cross-listing/)).toBeInTheDocument()
      })
    })

    it('clears search field when course ID input is used', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      // Type in search
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput) // Open dropdown
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Now type in course ID field
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '31337')

      // Search field should be cleared
      expect(searchInput).toHaveValue('')
    })
  })

  describe('Course ID Manual Input', () => {
    it('renders the course ID input field', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      expect(getByText("Or Enter the Course's ID")).toBeInTheDocument()
      expect(getByTestId('course-id-input')).toBeInTheDocument()
    })

    it('triggers confirmation when user blurs the input', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course', sis_source_id: 'SIS123'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab() // Blur the input

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
        expect(getByTestId('selected-course-name')).toHaveTextContent('Test Course')
      })
    })

    it('triggers confirmation when user presses Enter', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course', sis_source_id: 'SIS123'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.keyboard('{Enter}')

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
        expect(getByTestId('selected-course-name')).toHaveTextContent('Test Course')
      })
    })

    it('does not trigger confirmation for empty input', async () => {
      let confirmCalled = false
      server.use(
        http.get('/api/v1/courses/1/confirm_crosslist', () => {
          confirmCalled = true
          return HttpResponse.json({
            allowed: true,
            course: {id: '1', name: 'Test Course'},
          })
        }),
      )

      const {getByTestId, queryByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')

      // Focus and blur without typing
      await userEvent.click(courseIdInput)
      await userEvent.tab()

      // Wait a bit to ensure no API call is made
      await new Promise(resolve => setTimeout(resolve, 100))

      expect(confirmCalled).toBe(false)
      expect(queryByTestId('selected-course-display')).toBeNull()
    })

    it('clears course ID field when search autocomplete is used', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
        http.get('/api/v1/courses/101/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '101', name: 'Biology 101'},
            account: {name: 'Test Account'},
          }),
        ),
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course 2'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      // Type in course ID field first
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      expect(courseIdInput).toHaveValue('123')

      // Now search for a course
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Click on the search result
      await userEvent.click(getByText('Biology 101'))

      // Course ID field should be cleared
      expect(courseIdInput).toHaveValue('')
    })

    it('disables course ID input while submitting', async () => {
      // Set up a way to "freeze" the submit response so we can
      // test the state of the component while in flight.
      const {promise: submitPromise, resolve: resolveSubmit} = Promise.withResolvers<void>()

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', async () => {
          await submitPromise // API call will hang until this resolves, so we can test in-flight behavior
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      // Enter and confirm a course
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      // Click submit
      await userEvent.click(getByTestId('crosslist-submit-button'))

      // Course ID input should be disabled
      await waitFor(() => {
        expect(courseIdInput).toBeDisabled()
      })

      // Un-hang the API call to clean up
      resolveSubmit()
    })

    it('displays error message in course ID field when confirmation fails', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: false,
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(
        () => {
          expect(getByText(/Course ID "123" not authorized for cross-listing/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('clears previous confirmation when input value changes', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course 123'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId, queryByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')

      // Enter and confirm first course
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      // Submit button should be enabled
      const submitButton = getByTestId('crosslist-submit-button')
      expect(submitButton).not.toBeDisabled()

      // Start typing a new course ID
      await userEvent.clear(courseIdInput)
      await userEvent.type(courseIdInput, '4')

      // Selected course display should disappear
      expect(queryByTestId('selected-course-display')).toBeNull()

      // Submit button should still be enabled (no longer disabled based on course selection)
      expect(submitButton).not.toBeDisabled()
    })
  })

  describe('Course Confirmation', () => {
    it('shows confirming state when confirmation starts', async () => {
      // Set up a way to "freeze" the confirmation response so we can
      // test the state of the component while in flight.
      const {promise: confirmPromise, resolve: resolveConfirm} = Promise.withResolvers<void>()

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', async () => {
          await confirmPromise // API call will hang until this resolves, so we can test in-flight behavior
          return HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          })
        }),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      // Should show confirming state
      await waitFor(
        () => {
          expect(getByText(/Confirming/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Un-hang the API call to clean up
      resolveConfirm()
    })

    it('displays selected course details on successful confirmation', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Advanced Mathematics', sis_source_id: 'MATH301'},
            account: {name: 'Mathematics Department'},
          }),
        ),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
        expect(getByTestId('selected-course-name')).toHaveTextContent('Advanced Mathematics')
      })
    })

    it('displays SIS ID when available', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course', sis_source_id: 'SIS-12345'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(
        () => {
          expect(getByText(/SIS ID.*SIS-12345/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('displays account name when available', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Engineering Department'},
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(
        () => {
          expect(getByText(/Account.*Engineering Department/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('shows error when course is not authorized for crosslisting', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: false,
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(
        () => {
          expect(getByText(/not authorized for cross-listing/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('shows error when confirmation API fails', async () => {
      server.use(
        http.get(
          '/api/v1/courses/123/confirm_crosslist',
          () => new HttpResponse(null, {status: 500}),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(
        () => {
          expect(getByText(/Confirmation Failed/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('prevents duplicate confirmation calls for same input', async () => {
      let confirmCallCount = 0
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () => {
          confirmCallCount++
          return HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          })
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      // Try to blur again with the same value
      await userEvent.click(courseIdInput)
      await userEvent.tab()

      // Wait a bit
      await new Promise(resolve => setTimeout(resolve, 200))

      // Should only have been called once
      expect(confirmCallCount).toBe(1)
    })

    it('allows re-confirmation after input changes', async () => {
      let confirmCallCount = 0
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () => {
          confirmCallCount++
          return HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          })
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')

      // First confirmation
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      expect(confirmCallCount).toBe(1)

      // Change the value and confirm again
      await userEvent.clear(courseIdInput)
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(confirmCallCount).toBe(2)
      })
    })

    it('clears selected course when switching between inputs', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId, queryByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')

      // Confirm via course ID
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      // Now type in the search field - should clear the selection
      const searchInput = getByTestId('course-search-input')
      await userEvent.type(searchInput, 'Bio')

      expect(queryByTestId('selected-course-display')).toBeNull()
    })
  })

  describe('Form Submission', () => {
    it('submit button is enabled even without confirmed course', async () => {
      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      const submitButton = getByTestId('crosslist-submit-button')
      expect(submitButton).not.toBeDisabled()
    })

    it('submit button is disabled while submitting', async () => {
      // Set up a way to "freeze" the submit response so we can
      // test the state of the component while in flight.
      const {promise: submitPromise, resolve: resolveSubmit} = Promise.withResolvers<void>()

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', async () => {
          await submitPromise // API call will hang until this resolves, so we can test in-flight behavior
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      const submitButton = getByTestId('crosslist-submit-button')
      await userEvent.click(submitButton)

      // Submit button should be disabled during submission
      expect(submitButton).toBeDisabled()

      // Un-hang the API call to clean up
      resolveSubmit()
    })

    it('shows error alert when submit clicked without confirmed course', async () => {
      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      // Submit without selecting a course
      await userEvent.click(getByTestId('crosslist-submit-button'))

      // Should show error in selected course area
      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
        expect(
          getByText('Please select and confirm a course before submitting.'),
        ).toBeInTheDocument()
      })
    })

    it('clears submission error when course is selected', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId, getByText, queryByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))

      // Try to submit without course
      await userEvent.click(getByTestId('crosslist-submit-button'))

      await waitFor(() => {
        expect(
          getByText('Please select and confirm a course before submitting.'),
        ).toBeInTheDocument()
      })

      // Now select a course
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      // Error should be cleared
      await waitFor(() => {
        expect(queryByText('Please select and confirm a course before submitting.')).toBeNull()
      })
    })

    it('makes POST request with correct course ID on submit', async () => {
      let submittedCourseId: string | null = null
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', async ({request}) => {
          const body = (await request.json()) as {new_course_id: string}
          submittedCourseId = body.new_course_id
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      await userEvent.click(getByTestId('crosslist-submit-button'))

      await waitFor(() => {
        expect(submittedCourseId).toBe('123')
      })
    })

    it('shows loading text on submit button while submitting', async () => {
      // Set up a way to "freeze" the submit response so we can
      // test the state of the component while in flight.
      const {promise: submitPromise, resolve: resolveSubmit} = Promise.withResolvers<void>()

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', async () => {
          await submitPromise // API call will hang until this resolves, so we can test in-flight behavior
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      await userEvent.click(getByTestId('crosslist-submit-button'))

      expect(getByText('Cross-Listing Section...')).toBeInTheDocument()

      // Un-hang the API call to clean up
      resolveSubmit()
    })

    it('adds flash notice for next page on success', async () => {
      const {addFlashNoticeForNextPage} = await import('@canvas/rails-flash-notifications')

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', () => new HttpResponse(null, {status: 200})),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      await userEvent.click(getByTestId('crosslist-submit-button'))

      await waitFor(() => {
        expect(addFlashNoticeForNextPage).toHaveBeenCalledWith(
          'success',
          'Section successfully cross-listed!',
        )
      })
    })

    it('shows error flash on submission failure', async () => {
      const {showFlashError} = await import('@canvas/alerts/react/FlashAlert')

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', () => new HttpResponse(null, {status: 500})),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      await userEvent.click(getByTestId('crosslist-submit-button'))

      await waitFor(() => {
        expect(showFlashError).toHaveBeenCalledWith('Failed to cross-list section')
      })
    })

    it('re-enables submit button after submission failure', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', () => new HttpResponse(null, {status: 500})),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      const submitButton = getByTestId('crosslist-submit-button')
      await userEvent.click(submitButton)

      await waitFor(() => {
        expect(submitButton).not.toBeDisabled()
      })
    })

    it('disables cancel button while submitting', async () => {
      // Set up a way to "freeze" the submit response so we can
      // test the state of the component while in flight.
      const {promise: submitPromise, resolve: resolveSubmit} = Promise.withResolvers<void>()

      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
        http.post('/api/v1/sections/456/crosslist', async () => {
          await submitPromise // API call will hang until this resolves, so we can test in-flight behavior
          return new HttpResponse(null, {status: 200})
        }),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      await userEvent.click(getByTestId('crosslist-submit-button'))

      const cancelButton = getByTestId('crosslist-cancel-button')
      expect(cancelButton).toBeDisabled()

      // Un-hang the API call to clean up
      resolveSubmit()
    })
  })

  describe('Edge Cases', () => {
    it('handles API errors gracefully during course search', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () => new HttpResponse(null, {status: 500})),
      )

      const {getByTestId, queryByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'Bio')

      // Wait for the API call to complete
      await new Promise(resolve => setTimeout(resolve, 800))

      // Should not crash and should show no results
      expect(queryByText('No courses found')).toBeInTheDocument()
    })

    it('handles empty response from confirmation API', async () => {
      server.use(http.get('/api/v1/courses/123/confirm_crosslist', () => HttpResponse.json(null)))

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      // Should show an error
      await waitFor(
        () => {
          expect(getByText(/Confirmation Failed/)).toBeInTheDocument()
        },
        {timeout: 2000},
      )
    })

    it('clears course options when modal is closed', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
      )

      const {getByTestId, getByText, queryByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Close the modal
      await userEvent.click(getByTestId('crosslist-cancel-button'))

      await waitFor(() => {
        expect(queryByText('Biology 101')).toBeNull()
      })

      // Reopen and verify options are cleared
      await userEvent.click(getByTestId('crosslist-trigger-button'))
      expect(queryByText('Biology 101')).toBeNull()
    })

    it('resets all state when modal is closed', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId, queryByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      await waitFor(() => {
        expect(getByTestId('selected-course-display')).toBeInTheDocument()
      })

      // Close the modal
      await userEvent.click(getByTestId('crosslist-cancel-button'))

      await waitFor(() => {
        expect(queryByTestId('crosslist-modal')).toBeNull()
      })

      // Reopen and verify state is reset
      await userEvent.click(getByTestId('crosslist-trigger-button'))

      expect(queryByTestId('selected-course-display')).toBeNull()
      expect(courseIdInput).toHaveValue('')
      expect(getByTestId('crosslist-submit-button')).not.toBeDisabled()
    })

    it('handles confirmation from search with course name', async () => {
      server.use(
        http.get('/api/v1/manageable_courses', () =>
          HttpResponse.json([
            {
              id: '101',
              label: 'Biology 101',
              sis_id: 'BIO101',
              term: 'Fall 2024',
            },
          ]),
        ),
        http.get('/api/v1/courses/101/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '101', name: 'Biology 101', sis_source_id: 'BIO101'},
            account: {name: 'Science Department'},
          }),
        ),
      )

      const {getByTestId, getByText} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const searchInput = getByTestId('course-search-input')
      await userEvent.click(searchInput)
      await userEvent.type(searchInput, 'Bio')

      await waitFor(
        () => {
          expect(getByText('Biology 101')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      await userEvent.click(getByText('Biology 101'))

      // Should show selected course with the course name
      await waitFor(() => {
        expect(getByTestId('selected-course-name')).toHaveTextContent('Biology 101')
      })
    })

    it('handles confirmation from ID input without course name', async () => {
      server.use(
        http.get('/api/v1/courses/123/confirm_crosslist', () =>
          HttpResponse.json({
            allowed: true,
            course: {id: '123', name: 'Test Course'},
            account: {name: 'Test Account'},
          }),
        ),
      )

      const {getByTestId} = render(<CrosslistForm {...defaultProps} />)

      await userEvent.click(getByTestId('crosslist-trigger-button'))
      const courseIdInput = getByTestId('course-id-input')
      await userEvent.type(courseIdInput, '123')
      await userEvent.tab()

      // Should show selected course even though we didn't have a course name initially
      await waitFor(() => {
        expect(getByTestId('selected-course-name')).toHaveTextContent('Test Course')
      })
    })
  })
})
