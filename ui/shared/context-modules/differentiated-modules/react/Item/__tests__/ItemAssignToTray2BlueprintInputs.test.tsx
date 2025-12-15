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

import {cleanup, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {renderComponent, setupBaseMocks, setupEnv, setupFlashHolder} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Blueprint Input Controls', () => {
  const originalLocation = window.location

  beforeAll(() => {
    setupFlashHolder()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    fetchMock.resetHistory()
    fetchMock.restore()
    cleanup()
  })

  it('disables due date input and assignee selector when due_dates are blueprint-locked', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      id: '31',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      visible_to_everyone: true,
      overrides: [],
      blueprint_date_locks: ['due_dates'],
    })
    const {getByTestId, findByTestId, findAllByText, getByLabelText} = renderComponent({
      itemContentId: '31',
    })
    await findAllByText('Locked:')
    expect(getByTestId('differentiated_modules_save_button')).not.toBeDisabled()
    const assigneeSelector = await findByTestId('assignee_selector')
    expect(assigneeSelector).toBeDisabled()
    const dueDateInput = getByLabelText('Due Date')
    expect(dueDateInput).toBeDisabled()
    const availableFromInput = getByLabelText('Available from')
    expect(availableFromInput).not.toBeDisabled()
    const availableToInput = getByLabelText('Until')
    expect(availableToInput).not.toBeDisabled()
  })

  it('disables availability date inputs and assignee selector when availability_dates are blueprint-locked', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      id: '31',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      visible_to_everyone: true,
      overrides: [],
      blueprint_date_locks: ['availability_dates'],
    })
    const {getByTestId, findByTestId, findAllByText, getByLabelText} = renderComponent({
      itemContentId: '31',
    })
    await findAllByText('Locked:')
    expect(getByTestId('differentiated_modules_save_button')).not.toBeDisabled()
    const assigneeSelector = await findByTestId('assignee_selector')
    expect(assigneeSelector).toBeDisabled()
    const dueDateInput = getByLabelText('Due Date')
    expect(dueDateInput).not.toBeDisabled()
    const availableFromInput = getByLabelText('Available from')
    expect(availableFromInput).toBeDisabled()
    const availableToInput = getByLabelText('Until')
    expect(availableToInput).toBeDisabled()
  })

  it('does not disable save button or assignee selector if blueprint locks are not date-related', async () => {
    fetchMock.get('/api/v1/courses/1/assignments/31/date_details?per_page=100', {
      id: '31',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: false,
      visible_to_everyone: true,
      overrides: [],
      blueprint_date_locks: ['content', 'points'],
    })
    const {getByTestId, findByTestId} = renderComponent({itemContentId: '31'})
    const assigneeSelector = await findByTestId('assignee_selector')
    await waitFor(() => {
      expect(getByTestId('differentiated_modules_save_button')).not.toBeDisabled()
      expect(assigneeSelector).not.toBeDisabled()
    })
  })

  it('shows blueprint locking info when ENV contains master_course_restrictions', async () => {
    ENV.MASTER_COURSE_DATA = {
      is_master_course_child_content: true,
      restricted_by_master_course: true,
      master_course_restrictions: {
        availability_dates: true,
        content: true,
        due_dates: false,
        points: false,
      },
    }

    const {getAllByText} = renderComponent({
      itemType: 'quiz',
      iconType: 'quiz',
      defaultCards: [],
    })

    expect(
      getAllByText((_, e) => e?.textContent === 'Locked: Availability Dates')[0],
    ).toBeInTheDocument()
  })

  it('does not show banner if in a blueprint source course', async () => {
    ENV.MASTER_COURSE_DATA = {
      is_master_course_master_content: true,
      restricted_by_master_course: true,
      master_course_restrictions: {
        availability_dates: true,
        content: true,
        due_dates: false,
        points: false,
      },
    }

    const {queryByText} = renderComponent({
      itemType: 'quiz',
      iconType: 'quiz',
      defaultCards: [],
    })

    expect(queryByText('Locked:')).not.toBeInTheDocument()
  })
})
