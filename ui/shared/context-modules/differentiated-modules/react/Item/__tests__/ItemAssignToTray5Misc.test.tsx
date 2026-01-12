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

import {cleanup, screen, waitFor} from '@testing-library/react'
import {
  clearQueryCache,
  FIRST_GROUP_CATEGORY_ID,
  OVERRIDES,
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  teardownEnv,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Module Overrides', () => {
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
    server.listen({onUnhandledRequest: 'bypass'})
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    teardownEnv()
    clearQueryCache()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('shows module cards if they are not overridden', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
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
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
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
  let sectionsFetched: ReturnType<typeof vi.fn>
  let overridesFetched: ReturnType<typeof vi.fn>

  beforeAll(() => {
    setupFlashHolder()
    server.listen({onUnhandledRequest: 'bypass'})
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
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
        overridesFetched()
        return HttpResponse.json({})
      }),
    )
    ENV.IN_PACED_COURSE = true
    ENV.FEATURES ||= {}
    ENV.FEATURES.course_pace_pacing_with_mastery_paths = true
  })

  afterEach(() => {
    ENV.IN_PACED_COURSE = false
    if (ENV.FEATURES) {
      ENV.FEATURES.course_pace_pacing_with_mastery_paths = false
    }
    server.resetHandlers()
    teardownEnv()
    clearQueryCache()
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

describe('ItemAssignToTray - Group Set Handling', () => {
  beforeAll(() => {
    setupFlashHolder()
    server.listen({onUnhandledRequest: 'bypass'})
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    teardownEnv()
    clearQueryCache()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('handles deleted group set gracefully without closing the tray', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
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
      http.get(`/api/v1/group_categories/${FIRST_GROUP_CATEGORY_ID}/groups`, () => {
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
