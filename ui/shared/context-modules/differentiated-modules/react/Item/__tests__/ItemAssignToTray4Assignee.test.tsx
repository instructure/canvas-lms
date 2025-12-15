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

import {act, cleanup, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {
  OVERRIDES,
  OVERRIDES_URL,
  renderComponent,
  SECTIONS_URL,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - AssigneeSelector', () => {
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

  it('does not render everyone option if the assignment is set to overrides only', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: null,
        unlock_at: null,
        lock_at: null,
        only_visible_to_overrides: true,
        visible_to_everyone: false,
        overrides: OVERRIDES,
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId, getAllByTestId} = renderComponent()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    const cards = getAllByTestId('item-assign-to-card')
    // only cards for overrides are rendered
    expect(cards).toHaveLength(OVERRIDES.length)
    expect(selectedOptions).toHaveLength(1)
    // UI shows the override title when present
    expect(selectedOptions[0]).toHaveTextContent(OVERRIDES[0].title)
  })

  it('renders everyone option if there are no overrides', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [],
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId} = renderComponent()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Everyone'))
  })

  // TODO: flaky in Vitest - intermittently times out
  it.skip('renders everyone option for item with course and module overrides', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: true,
        visible_to_everyone: true,
        overrides: [
          {
            due_at: null,
            id: undefined,
            lock_at: null,
            course_id: 1,
            unlock_at: null,
          },
          {
            due_at: null,
            id: undefined,
            lock_at: null,
            context_module_id: 1,
            unlock_at: null,
          },
        ],
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId} = renderComponent()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Everyone'))
  })

  it('renders mastery paths option for noop 1 overrides', async () => {
    fetchMock.get(
      '/api/v1/courses/1/settings',
      {conditional_release: true},
      {overwriteRoutes: true},
    )
    fetchMock.get(
      OVERRIDES_URL,
      {
        overrides: [
          {
            due_at: null,
            id: undefined,
            lock_at: null,
            noop_id: 1,
            unlock_at: null,
          },
        ],
      },
      {overwriteRoutes: true},
    )
    const {findAllByTestId} = renderComponent()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Mastery Paths'))
  })

  it('calls onDismiss when an error occurs while fetching data', async () => {
    fetchMock.getOnce(SECTIONS_URL, 500, {overwriteRoutes: true})
    const onDismiss = vi.fn()
    renderComponent({onDismiss})
    await waitFor(() => expect(onDismiss).toHaveBeenCalledTimes(1))
  })

  // TODO: flaky in Vitest - intermittently times out
  it.skip('adds a card when add button is clicked', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [],
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(1)
    act(() => getAllByTestId('add-card')[0].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  // TODO: flaky in Vitest - times out
  it.skip('shows top add button if more than 3 cards exist', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [
          {
            id: '2',
            assignment_id: '23',
            course_section_id: '4',
          },
          {
            id: '3',
            assignment_id: '23',
            course_section_id: '5',
          },
          {
            id: '4',
            assignment_id: '23',
            course_section_id: '6',
          },
        ],
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(4)
    expect(getAllByTestId('add-card')).toHaveLength(2)
    act(() => getAllByTestId('add-card')[0].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(5)
  })
})
