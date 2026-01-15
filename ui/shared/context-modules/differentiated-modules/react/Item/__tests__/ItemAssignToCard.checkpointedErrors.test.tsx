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
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

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

describe('ItemAssignToCard - Checkpointed Errors', () => {
  const ASSIGNMENT_OVERRIDES_URL = `/api/v1/courses/1/modules/2/assignment_overrides`
  const COURSE_SETTINGS_URL = `/api/v1/courses/1/settings`

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
    fakeENV.setup({
      HAS_GRADING_PERIODS: false,
      active_grading_periods: [],
      current_user_is_admin: false,
    })
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
    server.resetHandlers()
    fakeENV.teardown()
  })

  afterAll(() => {
    server.close()
  })

  it('stops displaying "Unlock date cannot be after reply to topic due date" error when isCheckpointed is set to false', async () => {
    // Provide props that will trigger the error when isCheckpointed is true:
    // In this case, reply_to_topic_due_at is earlier than unlock_at, which triggers the error.
    const errorProps: Partial<ItemAssignToCardProps> = {
      isCheckpointed: true,
      reply_to_topic_due_at: '2024-05-05T00:00:00-06:00',
      unlock_at: '2024-05-06T00:00:00-06:00',
    }
    const {getAllByText, queryByText, rerender} = render(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(
        getAllByText(/Unlock date cannot be after reply to topic due date/i)[0],
      ).toBeInTheDocument()
    })

    // Rerender the component with isCheckpointed set to false.
    rerender(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} isCheckpointed={false} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(
        queryByText(/Unlock date cannot be after reply to topic due date/i),
      ).not.toBeInTheDocument()
    })
  })

  it('stops displaying "Unlock date cannot be after due date" error when isCheckpointed is set to true', async () => {
    const errorProps: Partial<ItemAssignToCardProps> = {
      isCheckpointed: true,
      due_at: '2024-05-05T00:00:00-06:00',
      unlock_at: '2024-05-06T00:00:00-06:00',
    }
    const {getAllByText, queryByText, rerender} = render(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} isCheckpointed={false} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(getAllByText(/Unlock date cannot be after due date/i)[0]).toBeInTheDocument()
    })

    // Rerender the component with isCheckpointed set to false.
    rerender(
      <MockedQueryProvider>
        <ItemAssignToCard {...props} {...errorProps} isCheckpointed={true} />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(queryByText(/Unlock date cannot be after due date/i)).not.toBeInTheDocument()
    })
  })
})
