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

const renderComponent = (overrides: Partial<ItemAssignToCardProps> = {}) =>
  render(
    <MockedQueryProvider>
      <ItemAssignToCard {...props} {...overrides} />
    </MockedQueryProvider>,
  )

describe('ItemAssignToCard - Rendering', () => {
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
    fetchMock.get(SECTIONS_URL, SECTIONS_DATA)
    queryClient.setQueryData(['students', props.courseId, {per_page: 100}], STUDENTS_DATA)
    fetchMock.get(ASSIGNMENT_OVERRIDES_URL, [])
    fetchMock.get(COURSE_SETTINGS_URL, {hide_final_grades: false})
  })

  afterEach(() => {
    fetchMock.restore()
    fakeEnv.teardown()
  })

  it('renders', () => {
    const {getByLabelText, getAllByLabelText, getByTestId, queryByRole} = renderComponent()
    expect(getByTestId('item-assign-to-card')).toBeInTheDocument()
    expect(queryByRole('button', {name: 'Delete'})).not.toBeInTheDocument()
    expect(getByLabelText('Due Date')).toBeInTheDocument()
    expect(getAllByLabelText('Time')).toHaveLength(3)
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
  })

  it('renders checkpoints fields and not Due Date', () => {
    fakeEnv.setup({DISCUSSION_CHECKPOINTS_ENABLED: true})
    const {getByLabelText, getAllByLabelText} = renderComponent({
      isCheckpointed: true,
    })
    expect(getByLabelText('Reply to Topic Due Date')).toBeInTheDocument()
    expect(getByLabelText('Required Replies Due Date')).toBeInTheDocument()
    expect(getByLabelText('Available from')).toBeInTheDocument()
    expect(getByLabelText('Until')).toBeInTheDocument()
    // rather than query for not due date, notice length remains 4
    expect(getAllByLabelText('Time')).toHaveLength(4)
  })

  it('renders with the given dates', () => {
    const due_at = '2023-10-05T12:00:00Z'
    const unlock_at = '2023-10-03T12:00:00Z'
    const lock_at = '2023-10-10T12:00:00Z'
    const {getByLabelText} = renderComponent({due_at, unlock_at, lock_at})
    expect(getByLabelText('Due Date')).toHaveValue('Oct 5, 2023')
    expect(getByLabelText('Available from')).toHaveValue('Oct 3, 2023')
    expect(getByLabelText('Until')).toHaveValue('Oct 10, 2023')
  })

  it('does not render the due date input if removeDueDateInput is set', () => {
    const {queryByLabelText} = renderComponent({removeDueDateInput: true})
    expect(queryByLabelText('Due Date')).not.toBeInTheDocument()
  })

  it('does not render the reply to topic input if removeDueDateInput is set & isCheckpointed is not set', () => {
    const {queryByLabelText} = renderComponent({removeDueDateInput: true, isCheckpointed: false})
    expect(queryByLabelText('Reply to Topic Due Date')).not.toBeInTheDocument()
  })

  it('does not render the required replies input if removeDueDateInput is set & isCheckpointed is not set', () => {
    const {queryByLabelText} = renderComponent({removeDueDateInput: true, isCheckpointed: false})
    expect(queryByLabelText('Required Replies Due Date')).not.toBeInTheDocument()
  })

  it('renders the delete button when onDelete is provided', () => {
    const onDelete = vi.fn()
    const {getByTestId} = renderComponent({onDelete})
    expect(getByTestId('delete-card-button')).toBeInTheDocument()
  })

  it('disables blueprint-locked date inputs', () => {
    const {getByLabelText, getAllByLabelText} = renderComponent({
      blueprintDateLocks: ['availability_dates', 'due_dates'],
    })
    expect(getByLabelText('Due Date')).toBeDisabled()
    expect(getByLabelText('Available from')).toBeDisabled()
    getAllByLabelText('Time').forEach(t => expect(t).toBeDisabled())
  })

  it('calls onDelete when delete button is clicked', () => {
    const onDelete = vi.fn()
    const {getByTestId} = renderComponent({onDelete})
    getByTestId('delete-card-button').click()
    expect(onDelete).toHaveBeenCalledWith('assign-to-card-001')
  })

  it('renders context module link', () => {
    renderComponent({contextModuleId: '2', contextModuleName: 'My fabulous module'})
    expect(screen.getByText('Inherited from')).toBeInTheDocument()
    const link = screen.getByRole('link', {name: 'My fabulous module'})
    expect(link).toHaveAttribute('href', '/courses/1/modules#2')
    expect(link).toHaveAttribute('target', '_blank')
  })
})
