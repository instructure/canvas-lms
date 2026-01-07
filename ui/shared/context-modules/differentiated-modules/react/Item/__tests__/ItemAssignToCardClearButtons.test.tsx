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
import {render, screen} from '@testing-library/react'
import ItemAssignToCard, {type ItemAssignToCardProps} from '../ItemAssignToCard'
import {SECTIONS_DATA, STUDENTS_DATA} from '../../__tests__/mocks'
import fetchMock from 'fetch-mock'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'

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

const renderComponent = (overrides: Partial<ItemAssignToCardProps> = {}) =>
  render(
    <MockedQueryProvider>
      <ItemAssignToCard {...props} {...overrides} />
    </MockedQueryProvider>,
  )

describe('ItemAssignToCard Clear Buttons', () => {
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
    fakeENV.setup({
      HAS_GRADING_PERIODS: false,
      active_grading_periods: [],
      current_user_is_admin: false,
    })
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA)
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, [])
    fetchMock.get(COURSE_SETTINGS_URL, {hide_final_grades: false})
  })

  afterEach(() => {
    fetchMock.restore()
    fakeENV.teardown()
  })

  it('labels the clear buttons on cards with no pills', () => {
    renderComponent()
    const labels = [
      'Clear due date/time',
      'Clear available from date/time',
      'Clear until date/time',
    ]
    labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
  })

  it('labels the clear buttons on cards with 1 pill', () => {
    renderComponent({
      customAllOptions: [{id: 'student-1', value: 'John'}],
      selectedAssigneeIds: ['student-1'],
    })
    const labels = [
      'Clear due date/time for John',
      'Clear available from date/time for John',
      'Clear until date/time for John',
    ]
    labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
  })

  it('labels the clear buttons on cards with 2 pills', () => {
    renderComponent({
      customAllOptions: [
        {id: 'student-1', value: 'John'},
        {id: 'student-2', value: 'Alice'},
      ],
      selectedAssigneeIds: ['student-1', 'student-2'],
    })
    const labels = [
      'Clear due date/time for John and Alice',
      'Clear available from date/time for John and Alice',
      'Clear until date/time for John and Alice',
    ]
    labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
  })

  it('labels the clear buttons on cards with 3 pills', () => {
    renderComponent({
      customAllOptions: [
        {id: 'student-1', value: 'John'},
        {id: 'student-2', value: 'Alice'},
        {id: 'student-3', value: 'Linda'},
      ],
      selectedAssigneeIds: ['student-1', 'student-2', 'student-3'],
    })
    const labels = [
      'Clear due date/time for John, Alice, and Linda',
      'Clear available from date/time for John, Alice, and Linda',
      'Clear until date/time for John, Alice, and Linda',
    ]
    labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
  })

  it('labels the clear buttons on cards with more than 3 pills', () => {
    renderComponent({
      customAllOptions: [
        {id: 'student-1', value: 'John'},
        {id: 'student-2', value: 'Alice'},
        {id: 'student-3', value: 'Linda'},
        {id: 'student-4', value: 'Bob'},
      ],
      selectedAssigneeIds: ['student-1', 'student-2', 'student-3', 'student-4'],
    })
    const labels = [
      'Clear due date/time for John, Alice, and 2 others',
      'Clear available from date/time for John, Alice, and 2 others',
      'Clear until date/time for John, Alice, and 2 others',
    ]
    labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
  })

  describe('isCheckpointed is true', () => {
    beforeEach(() => {
      window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
    })

    afterEach(() => {
      window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = false
    })

    it('labels the clear buttons on cards with no pills', () => {
      renderComponent({isCheckpointed: true})
      const labels = ['Clear reply to topic due date/time', 'Clear required replies due date/time']
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with 1 pill', () => {
      renderComponent({
        customAllOptions: [{id: 'student-1', value: 'John'}],
        selectedAssigneeIds: ['student-1'],
        isCheckpointed: true,
      })
      const labels = [
        'Clear reply to topic due date/time for John',
        'Clear required replies due date/time for John',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with 2 pills', () => {
      renderComponent({
        customAllOptions: [
          {id: 'student-1', value: 'John'},
          {id: 'student-2', value: 'Alice'},
        ],
        selectedAssigneeIds: ['student-1', 'student-2'],
        isCheckpointed: true,
      })
      const labels = [
        'Clear reply to topic due date/time for John and Alice',
        'Clear required replies due date/time for John and Alice',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with 3 pills', () => {
      renderComponent({
        customAllOptions: [
          {id: 'student-1', value: 'John'},
          {id: 'student-2', value: 'Alice'},
          {id: 'student-3', value: 'Linda'},
        ],
        selectedAssigneeIds: ['student-1', 'student-2', 'student-3'],
        isCheckpointed: true,
      })
      const labels = [
        'Clear reply to topic due date/time for John, Alice, and Linda',
        'Clear required replies due date/time for John, Alice, and Linda',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })

    it('labels the clear buttons on cards with more than 3 pills', () => {
      renderComponent({
        customAllOptions: [
          {id: 'student-1', value: 'John'},
          {id: 'student-2', value: 'Alice'},
          {id: 'student-3', value: 'Linda'},
          {id: 'student-4', value: 'Bob'},
        ],
        selectedAssigneeIds: ['student-1', 'student-2', 'student-3', 'student-4'],
        isCheckpointed: true,
      })
      const labels = [
        'Clear reply to topic due date/time for John, Alice, and 2 others',
        'Clear required replies due date/time for John, Alice, and 2 others',
      ]
      labels.forEach(label => expect(screen.getByText(label)).toBeInTheDocument())
    })
  })
})
