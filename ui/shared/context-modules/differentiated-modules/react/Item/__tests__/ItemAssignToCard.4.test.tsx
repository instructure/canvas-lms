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
import {render, screen, waitFor, act} from '@testing-library/react'
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {queryClient} from '@instructure/platform-query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

const server = setupServer()

const props: ItemAssignToCardProps = {
  courseId: '1',
  disabledOptionIdsRef: {current: []},
  selectedAssigneeIds: [],
  onCardAssignmentChange: () => {},
  cardId: 'assign-to-card-001',
  due_at: '2024-11-20T23:59:00Z',
  original_due_at: '2024-11-20T23:59:00Z',
  unlock_at: null,
  lock_at: null,
  peer_review_available_from: null,
  peer_review_available_to: null,
  peer_review_due_at: null,
  onDelete: undefined,
  removeDueDateInput: false,
  isCheckpointed: false,
  onValidityChange: () => {},
  required_replies_due_at: null,
  reply_to_topic_due_at: null,
}

const renderComponent = (overrides: Partial<ItemAssignToCardProps> = {}) =>
  render(
    <MockedQueryProvider>
      <ItemAssignToCard {...props} {...overrides} />
    </MockedQueryProvider>,
  )

describe('ItemAssignToCard - PeerReviewSelector Integration', () => {
  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/1/modules/2/assignment_overrides`
  const COURSE_SETTINGS_URL = `/api/v1/courses/1/settings`

  let mockCheckbox: HTMLInputElement
  const originalENV = window.ENV
  const originalRequestAnimationFrame = window.requestAnimationFrame

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
    server.listen()
  })

  beforeEach(() => {
    // jsdom doesn't execute requestAnimationFrame callbacks
    window.requestAnimationFrame = (callback: FrameRequestCallback) => {
      callback(0)
      return 0
    }

    window.ENV = {
      ...originalENV,
      PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED: true,
      HAS_GRADING_PERIODS: false,
      active_grading_periods: [],
      current_user_is_admin: false,
      VALID_DATE_RANGE: {
        start_at: {date: '2025-02-09T00:00:00-06:00', date_context: 'course'},
        end_at: {date: '2025-04-22T23:59:59-06:00', date_context: 'course'},
      },
      LOCALE: 'en',
      TIMEZONE: 'UTC',
    }

    // Create and add checkbox to DOM
    mockCheckbox = document.createElement('input')
    mockCheckbox.type = 'checkbox'
    mockCheckbox.id = 'assignment_peer_reviews_checkbox'
    mockCheckbox.checked = true
    document.body.appendChild(mockCheckbox)

    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        return HttpResponse.json(SECTIONS_DATA)
      }),
      http.get(ASSIGNMENT_OVERRIDES_URL, () => {
        return HttpResponse.json([])
      }),
      http.get(COURSE_SETTINGS_URL, () => {
        return HttpResponse.json({hide_final_grades: false})
      }),
    )
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
  })

  afterEach(() => {
    window.ENV = originalENV
    window.requestAnimationFrame = originalRequestAnimationFrame
    server.resetHandlers()
    if (mockCheckbox && mockCheckbox.parentNode) {
      document.body.removeChild(mockCheckbox)
    }
  })

  afterAll(() => {
    server.close()
  })

  describe('PeerReviewSelector visibility', () => {
    it('renders peer review inputs when PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED is true and checkbox is checked', () => {
      renderComponent()
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
      expect(screen.queryByText('Reviewing Starts')).not.toBeInTheDocument()
    })

    it('does not render peer review inputs when PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED is false', () => {
      window.ENV.PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED = false
      renderComponent()
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('does not render peer review inputs when checkbox is not checked', () => {
      mockCheckbox.checked = false
      renderComponent()
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })

    it('does not render peer review inputs when checkbox does not exist in DOM', () => {
      document.body.removeChild(mockCheckbox)
      renderComponent()
      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
    })
  })

  describe('PeerReviewSelector disabled state', () => {
    it('disables peer review inputs when assignment due date is null', () => {
      const {container} = renderComponent({due_at: null})
      const clearButton = container.querySelector('[data-testid="peer_review_due_at_clear_button"]')
      expect(clearButton).toBeInTheDocument()
      expect(clearButton).toBeDisabled()
    })

    it('enables peer review inputs when assignment due date is set', () => {
      const {container} = renderComponent({due_at: '2024-11-20T23:59:00Z'})
      const clearButton = container.querySelector('[data-testid="peer_review_due_at_clear_button"]')
      expect(clearButton).toBeInTheDocument()
      expect(clearButton).not.toBeDisabled()
    })
  })

  describe('PeerReviewSelector with dates', () => {
    it('renders with peer review due date', () => {
      renderComponent({
        peer_review_due_at: '2024-11-18T00:00:00Z',
      })
      const input = screen.getByLabelText('Review Due Date')
      expect(input).toBeInTheDocument()
    })

    it('renders with all peer review dates set', () => {
      renderComponent({
        peer_review_available_from: '2024-11-10T00:00:00Z',
        peer_review_available_to: '2024-11-25T23:59:00Z',
        peer_review_due_at: '2024-11-18T00:00:00Z',
      })

      expect(screen.getByLabelText('Review Due Date')).toBeInTheDocument()
      // Available from and available to are auto-synced, not rendered as inputs
      expect(screen.queryByLabelText('Reviewing Starts')).not.toBeInTheDocument()
    })
  })

  describe('PeerReviewSelector checkbox interaction', () => {
    it('shows peer review inputs when checkbox is checked', async () => {
      mockCheckbox.checked = false
      const {rerender} = renderComponent()

      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()

      act(() => {
        mockCheckbox.checked = true
        mockCheckbox.dispatchEvent(new Event('change'))
      })

      rerender(
        <MockedQueryProvider>
          <ItemAssignToCard {...props} />
        </MockedQueryProvider>,
      )

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).toBeInTheDocument()
      })
    })

    it('hides peer review inputs when checkbox is unchecked', async () => {
      const {rerender} = renderComponent()

      expect(screen.getByText('Review Due Date')).toBeInTheDocument()

      act(() => {
        mockCheckbox.checked = false
        mockCheckbox.dispatchEvent(new Event('change'))
      })

      rerender(
        <MockedQueryProvider>
          <ItemAssignToCard {...props} />
        </MockedQueryProvider>,
      )

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()
      })
    })
  })

  describe('PeerReviewSelector message event', () => {
    it('responds to ASGMT.togglePeerReviews message', async () => {
      mockCheckbox.checked = false
      const {rerender} = renderComponent()

      expect(screen.queryByText('Review Due Date')).not.toBeInTheDocument()

      await act(async () => {
        mockCheckbox.checked = true
        window.postMessage({subject: 'ASGMT.togglePeerReviews', enabled: true}, '*')
        await new Promise(resolve => setTimeout(resolve, 10))
      })

      rerender(
        <MockedQueryProvider>
          <ItemAssignToCard {...props} />
        </MockedQueryProvider>,
      )

      await waitFor(() => {
        expect(screen.queryByText('Review Due Date')).toBeInTheDocument()
      })
    })
  })

  describe('PeerReviewSelector clear button labels', () => {
    it('uses correct clear button labels for no assignees', () => {
      renderComponent({selectedAssigneeIds: []})
      // Only the peer review due date clear button is rendered
      expect(screen.getByText('Clear peer review due date/time')).toBeInTheDocument()
      expect(
        screen.queryByText('Clear peer review available from date/time'),
      ).not.toBeInTheDocument()
      expect(screen.queryByText('Clear peer review available to date/time')).not.toBeInTheDocument()
    })

    it('uses correct clear button labels for one assignee', () => {
      renderComponent({
        selectedAssigneeIds: ['student-1'],
      })
      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
    })
  })

  describe('PeerReviewSelector validation integration', () => {
    it('passes validation errors to peer review inputs', () => {
      renderComponent({
        peer_review_due_at: '2024-11-18T00:00:00Z',
        peer_review_available_from: '2024-11-10T00:00:00Z',
        peer_review_available_to: '2024-11-25T23:59:00Z',
      })

      expect(screen.getByText('Review Due Date')).toBeInTheDocument()
    })

    it('integrates with card validity tracking for peer review dates', () => {
      const onValidityChange = vi.fn()
      renderComponent({
        onValidityChange,
        peer_review_due_at: '2024-11-18T00:00:00Z',
      })

      // onValidityChange should be called when validity state changes
      expect(onValidityChange).toHaveBeenCalled()
    })
  })

  describe('PeerReviewSelector callback integration', () => {
    it('calls onCardDatesChange when peer review due date changes', () => {
      const onCardDatesChange = vi.fn()
      renderComponent({
        onCardDatesChange,
        peer_review_due_at: '2024-11-18T00:00:00Z',
      })

      // Component should integrate with the parent's date change handling
      expect(onCardDatesChange).toHaveBeenCalledWith(
        'assign-to-card-001',
        'peer_review_due_at',
        '2024-11-18T00:00:00Z',
      )
    })
  })

  describe('PeerReviewSelector refs integration', () => {
    it('manages date and time input refs for peer review fields', () => {
      const {container} = renderComponent({
        peer_review_due_at: '2024-11-18T00:00:00Z',
      })

      // Only the peer review due date input is rendered
      expect(
        container.querySelector('[data-testid="peer_review_due_at_input"]'),
      ).toBeInTheDocument()
      expect(
        container.querySelector('[data-testid="peer_review_available_from_input"]'),
      ).not.toBeInTheDocument()
      expect(
        container.querySelector('[data-testid="peer_review_available_to_input"]'),
      ).not.toBeInTheDocument()
    })
  })

  describe('PeerReviewSelector rendering order', () => {
    it('renders peer review due date after assignment due date and before availability dates', () => {
      const {container} = renderComponent()

      const dateInputs = container.querySelectorAll('[data-testid*="_input"]')
      const testIds = Array.from(dateInputs).map(el => el.getAttribute('data-testid'))

      const dueDateIndex = testIds.indexOf('due_at_input')
      const peerReviewDueIndex = testIds.indexOf('peer_review_due_at_input')
      const unlockAtIndex = testIds.indexOf('unlock_at_input')

      expect(peerReviewDueIndex).toBeGreaterThan(dueDateIndex)
      expect(peerReviewDueIndex).toBeLessThan(unlockAtIndex)
    })
  })
})
