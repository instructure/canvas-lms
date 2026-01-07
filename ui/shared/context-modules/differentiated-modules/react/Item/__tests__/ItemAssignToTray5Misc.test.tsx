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
import ItemAssignToTray from '../ItemAssignToTray'
import {
  DEFAULT_PROPS,
  FIRST_GROUP_CATEGORY_ID,
  FIRST_GROUP_CATEGORY_URL,
  OVERRIDES,
  OVERRIDES_URL,
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  http,
  HttpResponse,
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
    server.listen()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('shows module cards if they are not overridden', async () => {
    server.use(
      http.get(OVERRIDES_URL, () => {
        return HttpResponse.json(DATE_DETAILS_WITHOUT_OVERRIDES)
      }),
    )
    const {getByText, findAllByTestId, getByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(getByText('Inherited from')).toBeInTheDocument()
    expect(getByTestId('context-module-text')).toBeInTheDocument()
    expect(cards).toHaveLength(1)
  })

  it('does not show overridden module cards', async () => {
    server.use(
      http.get(OVERRIDES_URL, () => {
        return HttpResponse.json(DATE_DETAILS_WITH_OVERRIDES)
      }),
    )
    const {queryByText, findAllByTestId, queryByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(queryByText('Inherited from')).not.toBeInTheDocument()
    expect(queryByTestId('context-module-text')).not.toBeInTheDocument()
    expect(cards).toHaveLength(1)
  })
})

describe('ItemAssignToTray - Paced Course with Mastery Paths', () => {
  const originalLocation = window.location
  let sectionsFetched: ReturnType<typeof vi.fn>
  let overridesFetched: ReturnType<typeof vi.fn>

  beforeAll(() => {
    setupFlashHolder()
    server.listen()
  })

  beforeEach(() => {
    sectionsFetched = vi.fn()
    overridesFetched = vi.fn()
    setupEnv()
    setupBaseMocks()
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        sectionsFetched()
        return HttpResponse.json([])
      }),
      http.get(OVERRIDES_URL, () => {
        overridesFetched()
        return HttpResponse.json({})
      }),
    )
    ENV.IN_PACED_COURSE = true
    ENV.FEATURES ||= {}
    ENV.FEATURES.course_pace_pacing_with_mastery_paths = true
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    ENV.IN_PACED_COURSE = false
    ENV.FEATURES.course_pace_pacing_with_mastery_paths = false
    server.resetHandlers()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('does not fetch assignee options', async () => {
    renderComponent()
    // Wait a tick to ensure no async fetch would have been triggered
    await new Promise(resolve => setTimeout(resolve, 50))
    expect(sectionsFetched).not.toHaveBeenCalled()
  })

  describe('with mastery paths', () => {
    beforeEach(() => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true
    })

    afterEach(() => {
      ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = false
    })

    it('requests the existing overrides', async () => {
      renderComponent()
      await waitFor(() => {
        expect(overridesFetched).toHaveBeenCalledTimes(1)
      })
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
    server.listen()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  afterAll(() => {
    server.close()
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
    server.listen()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('fetches and combines multiple pages of overrides', async () => {
    const page1 = {
      id: '23',
      overrides: [
        {id: '1', title: 'Override 1'},
        {id: '2', title: 'Override 2'},
      ],
    }

    const page2 = {
      id: '23',
      overrides: [
        {id: '3', title: 'Override 3'},
        {id: '4', title: 'Override 4'},
      ],
    }

    const page3 = {
      id: '23',
      overrides: [{id: '5', title: 'Override 5'}],
    }

    let page1Fetched = false
    let page2Fetched = false
    let page3Fetched = false

    // Use a single handler that matches all requests to this endpoint
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', ({request}) => {
        const url = new URL(request.url)
        const page = url.searchParams.get('page')
        if (page === '2') {
          page2Fetched = true
          return new HttpResponse(JSON.stringify(page2), {
            headers: {
              'Content-Type': 'application/json',
              Link: '</api/v1/courses/1/assignments/23/date_details?page=3&per_page=100>; rel="next"',
            },
          })
        }
        if (page === '3') {
          page3Fetched = true
          return HttpResponse.json(page3)
        }
        // Default: page 1
        page1Fetched = true
        return new HttpResponse(JSON.stringify(page1), {
          headers: {
            'Content-Type': 'application/json',
            Link: '</api/v1/courses/1/assignments/23/date_details?page=2&per_page=100>; rel="next"',
          },
        })
      }),
    )

    const {findAllByTestId} = renderComponent()

    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(5)

    expect(page1Fetched).toBe(true)
    expect(page2Fetched).toBe(true)
    expect(page3Fetched).toBe(true)
  })
})

describe('ItemAssignToTray - Group Set Handling', () => {
  const originalLocation = window.location

  beforeAll(() => {
    setupFlashHolder()
    server.listen()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('handles deleted group set gracefully without closing the tray', async () => {
    server.use(
      http.get(OVERRIDES_URL, () => {
        return HttpResponse.json({
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          visible_to_everyone: true,
          group_category_id: FIRST_GROUP_CATEGORY_ID,
          overrides: [],
        })
      }),
      http.get(FIRST_GROUP_CATEGORY_URL, () => {
        return new HttpResponse(null, {status: 404})
      }),
    )

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
