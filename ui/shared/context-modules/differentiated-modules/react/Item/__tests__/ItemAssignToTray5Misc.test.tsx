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
import {render, cleanup, screen, waitFor} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import ItemAssignToTray from '../ItemAssignToTray'
import {
  DEFAULT_PROPS,
  FIRST_GROUP_CATEGORY_ID,
  FIRST_GROUP_CATEGORY_URL,
  OVERRIDES,
  OVERRIDES_URL,
  renderComponent,
  SECTIONS_URL,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
} from './ItemAssignToTrayTestUtils'

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

describe('ItemAssignToTray - Module Overrides', () => {
  const originalLocation = window.location

  const DATE_DETAILS_WITHOUT_OVERRIDES = {
    id: '23',
    due_at: '2023-10-05T12:00:00Z',
    unlock_at: '2023-10-01T12:00:00Z',
    lock_at: '2023-11-01T12:00:00Z',
    only_visible_to_overrides: false,
    overrides: [
      {
        id: '3',
        assignment_id: '23',
        title: 'Sally and Wally',
        due_at: '2023-10-02T12:00:00Z',
        all_day: false,
        all_day_date: '2023-10-02',
        unlock_at: null,
        lock_at: null,
        course_section_id: '4',
        context_module_id: 1,
        context_module_name: 'Test Module',
      },
    ],
  }

  const DATE_DETAILS_WITH_OVERRIDES = {
    ...DATE_DETAILS_WITHOUT_OVERRIDES,
    overrides: [...OVERRIDES, ...DATE_DETAILS_WITHOUT_OVERRIDES.overrides],
  }

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

  it('shows module cards if they are not overridden', async () => {
    fetchMock.get(OVERRIDES_URL, DATE_DETAILS_WITHOUT_OVERRIDES, {
      overwriteRoutes: true,
    })
    const {getByText, findAllByTestId, getByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(getByText('Inherited from')).toBeInTheDocument()
    expect(getByTestId('context-module-text')).toBeInTheDocument()
    expect(cards).toHaveLength(1)
  })

  it('does not show overridden module cards', async () => {
    fetchMock.get(OVERRIDES_URL, DATE_DETAILS_WITH_OVERRIDES, {
      overwriteRoutes: true,
    })
    const {queryByText, findAllByTestId, queryByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(queryByText('Inherited from')).not.toBeInTheDocument()
    expect(queryByTestId('context-module-text')).not.toBeInTheDocument()
    expect(cards).toHaveLength(1)
  })
})

describe('ItemAssignToTray - Paced Course with Mastery Paths', () => {
  const originalLocation = window.location

  beforeAll(() => {
    setupFlashHolder()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    ENV.IN_PACED_COURSE = true
    ENV.FEATURES ||= {}
    ENV.FEATURES.course_pace_pacing_with_mastery_paths = true
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    ENV.IN_PACED_COURSE = false
    ENV.FEATURES.course_pace_pacing_with_mastery_paths = false
    fetchMock.resetHistory()
    fetchMock.restore()
    cleanup()
  })

  it('does not fetch assignee options', () => {
    renderComponent()
    expect(fetchMock.calls(SECTIONS_URL)).toHaveLength(0)
  })

  describe('with mastery paths', () => {
    beforeEach(() => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    })

    afterEach(() => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    })

    it('requests the existing overrides', () => {
      renderComponent()
      expect(fetchMock.calls(OVERRIDES_URL)).toHaveLength(1)
    })

    it('shows the mastery path toggle', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('MasteryPathToggle')).toBeInTheDocument()
    })
  })
})

describe('ItemAssignToTray - Card Focus', () => {
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

  it('focuses on the add button when deleting a card', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findAllByTestId, getAllByTestId} = renderComponent()

    const deleteButton = (await findAllByTestId('delete-card-button'))[0]
    await user.click(deleteButton)

    const addButton = getAllByTestId('add-card')[0]
    await waitFor(() => expect(addButton).toHaveFocus())
  })

  it("focuses on the newly-created card's delete button when adding a card", async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const {findAllByTestId, getByTestId, getAllByTestId} = renderComponent()

    // wait for the cards to render
    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    const addButton = getAllByTestId('add-card')[0]
    await user.click(addButton)
    const deleteButtons = await findAllByTestId('delete-card-button')
    await waitFor(() =>
      expect(deleteButtons[deleteButtons.length - 1].closest('button')).toHaveFocus(),
    )
  })
})

describe('ItemAssignToTray - Pagination', () => {
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

  it('fetches and combines multiple pages of overrides', async () => {
    const page1 = {
      id: '23',
      overrides: [
        {id: '1', title: 'Override 1'},
        {id: '2', title: 'Override 2'},
      ],
    }
    const response1 = {
      body: page1,
      headers: {
        Link: '</api/v1/courses/1/assignments/23/date_details?page=2&per_page=100>; rel="next"',
      },
    }

    const page2 = {
      id: '23',
      overrides: [
        {id: '3', title: 'Override 3'},
        {id: '4', title: 'Override 4'},
      ],
    }
    const response2 = {
      body: page2,
      headers: {
        Link: '</api/v1/courses/1/assignments/23/date_details?page=3&per_page=100>; rel="next"',
      },
    }

    const page3 = {
      id: '23',
      overrides: [{id: '5', title: 'Override 5'}],
    }
    const response3 = {
      body: page3,
    }

    fetchMock.get(OVERRIDES_URL, response1, {overwriteRoutes: true})
    fetchMock.get(`/api/v1/courses/1/assignments/23/date_details?page=2&per_page=100`, response2)
    fetchMock.get(`/api/v1/courses/1/assignments/23/date_details?page=3&per_page=100`, response3)

    const {findAllByTestId} = renderComponent()

    await waitFor(async () => {
      expect(fetchMock.calls(OVERRIDES_URL)).toHaveLength(1)

      expect(
        fetchMock.calls(`/api/v1/courses/1/assignments/23/date_details?page=2&per_page=100`),
      ).toHaveLength(1)
      expect(
        fetchMock.calls(`/api/v1/courses/1/assignments/23/date_details?page=3&per_page=100`),
      ).toHaveLength(1)
      const cards = await findAllByTestId('item-assign-to-card')
      expect(cards).toHaveLength(5)
    })
  })
})

describe('ItemAssignToTray - Group Set Handling', () => {
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

  it('handles deleted group set gracefully without closing the tray', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        group_category_id: FIRST_GROUP_CATEGORY_ID,
        overrides: [],
      },
      {
        overwriteRoutes: true,
      },
    )

    fetchMock.get(FIRST_GROUP_CATEGORY_URL, 404, {
      overwriteRoutes: true,
    })

    const onCloseMock = vi.fn()
    const onDismissMock = vi.fn()

    const {findAllByTestId, queryByTestId} = renderComponent({
      onClose: onCloseMock,
      onDismiss: onDismissMock,
      defaultGroupCategoryId: FIRST_GROUP_CATEGORY_ID,
    })

    await waitFor(() => {
      expect(queryByTestId('cards-loading')).not.toBeInTheDocument()
    })

    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(1)

    expect(onDismissMock).not.toHaveBeenCalled()
    expect(onCloseMock).not.toHaveBeenCalled()

    expect(screen.getByTestId('module-item-edit-tray')).toBeInTheDocument()

    const alerts = screen.getAllByRole('alert')
    expect(alerts.length).toBeGreaterThanOrEqual(1)
  })
})
