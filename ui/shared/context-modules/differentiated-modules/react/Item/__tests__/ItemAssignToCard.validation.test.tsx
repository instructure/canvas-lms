/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'
import fetchMock from 'fetch-mock'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeEnv from '@canvas/test-utils/fakeENV'

const props: ItemAssignToCardProps = {
  courseId: '1',
  disabledOptionIdsRef: {current: []},
  selectedAssigneeIds: [],
  onCardAssignmentChange: () => {},
  cardId: 'assign-to-card-001',
  due_at: null,
  original_due_at: null,
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

const renderComponent = (overrides: Partial<ItemAssignToCardProps> = {}) => {
  return render(
    <MockedQueryProvider>
      <ItemAssignToCard {...props} {...overrides} />
    </MockedQueryProvider>,
  )
}

describe('ItemAssignToCard - Validation', () => {
  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/1/modules/2/assignment_overrides?per_page=100`
  const COURSE_SETTINGS_URL = `/api/v1/courses/1/settings`
  const SECTIONS_URL = /\/api\/v1\/courses\/.+\/sections\?per_page=\d+/

  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  beforeEach(() => {
    fakeEnv.setup({
      PEER_REVIEW_ALLOCATION_AND_GRADING_ENABLED: true,
    })
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA)
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, [])
    fetchMock.get(COURSE_SETTINGS_URL, {hide_final_grades: false})

    const checkbox = document.createElement('input')
    checkbox.type = 'checkbox'
    checkbox.id = 'assignment_peer_reviews_checkbox'
    checkbox.checked = true
    document.body.appendChild(checkbox)
  })

  afterEach(() => {
    fetchMock.restore()
    fakeEnv.teardown()

    const checkbox = document.getElementById('assignment_peer_reviews_checkbox')
    if (checkbox) {
      checkbox.remove()
    }
  })

  it('show error when date field is blank and time field has value on blur', async () => {
    const {getAllByLabelText, getAllByText} = renderComponent()
    const timeInput = getAllByLabelText('Time')[0]

    await userEvent.type(timeInput, '3:30 PM')
    await userEvent.tab()

    await waitFor(async () => {
      expect(timeInput).toHaveValue('3:30 PM')
      expect(await getAllByText('Invalid date')[0]).toBeInTheDocument()
    })
  })

  it('clears date field and time field when date field is manually cleared on blur', async () => {
    const due_at = '2023-10-05T12:00:00Z'
    const {getAllByLabelText, getByLabelText} = renderComponent({due_at})
    const dateInput = getByLabelText('Due Date')
    const timeInput = getAllByLabelText('Time')[0]

    await userEvent.clear(dateInput)
    await userEvent.tab()

    await waitFor(async () => {
      expect(dateInput).toHaveValue('')
      expect(timeInput).toHaveValue('')
    })
  })

  describe('Peer Review Date Validation', () => {
    it('shows error when peer review due date has invalid time without date', async () => {
      const {getAllByLabelText, getAllByText} = renderComponent({
        due_at: '2023-10-05T12:00:00Z',
        peer_review_due_at: null,
      })
      const timeInputs = getAllByLabelText('Time')
      const peerReviewDueTimeInput = timeInputs[1]

      await userEvent.type(peerReviewDueTimeInput, '3:30 PM')
      await userEvent.tab()

      await waitFor(() => {
        expect(peerReviewDueTimeInput).toHaveValue('3:30 PM')
        expect(getAllByText('Invalid date')[0]).toBeInTheDocument()
      })
    })

    it('shows error when peer review available from date has invalid time without date', async () => {
      const {getAllByLabelText, getAllByText} = renderComponent({
        due_at: '2023-10-05T12:00:00Z',
        peer_review_available_from: null,
      })
      const timeInputs = getAllByLabelText('Time')
      const peerReviewAvailableFromTimeInput = timeInputs[2]

      await userEvent.type(peerReviewAvailableFromTimeInput, '3:30 PM')
      await userEvent.tab()

      await waitFor(async () => {
        expect(peerReviewAvailableFromTimeInput).toHaveValue('3:30 PM')
        expect(await getAllByText('Invalid date')[0]).toBeInTheDocument()
      })
    })

    it('shows error when peer review available to date has invalid time without date', async () => {
      const {getAllByLabelText, getAllByText} = renderComponent({
        due_at: '2023-10-05T12:00:00Z',
        peer_review_available_to: null,
      })
      const timeInputs = getAllByLabelText('Time')
      const peerReviewAvailableToTimeInput = timeInputs[3]

      await userEvent.type(peerReviewAvailableToTimeInput, '3:30 PM')
      await userEvent.tab()

      await waitFor(async () => {
        expect(peerReviewAvailableToTimeInput).toHaveValue('3:30 PM')
        expect(await getAllByText('Invalid date')[0]).toBeInTheDocument()
      })
    })

    it('clears peer review due date field when date is manually cleared', async () => {
      const due_at = '2023-10-05T12:00:00Z'
      const peer_review_due_at = '2023-10-10T12:00:00Z'
      const {findByLabelText, findAllByLabelText} = renderComponent({due_at, peer_review_due_at})

      const peerReviewDueDateInput = await findByLabelText('Review Due Date')
      const timeInputs = await findAllByLabelText('Time')
      const peerReviewDueTimeInput = timeInputs[1]

      await userEvent.clear(peerReviewDueDateInput)
      await userEvent.tab()

      await waitFor(async () => {
        expect(peerReviewDueDateInput).toHaveValue('')
        expect(peerReviewDueTimeInput).toHaveValue('')
      })
    })
  })
})
