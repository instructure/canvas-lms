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
import {
  DEFAULT_PROPS,
  OVERRIDES_URL,
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Rendering', () => {
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

  it('renders basic elements', () => {
    const {getByText, getByLabelText, container} = renderComponent()
    expect(getByText('Item Name')).toBeInTheDocument()
    expect(getByText('Assignment | 10 pts')).toBeInTheDocument()
    expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
    expect(container.querySelector('#manage-assign-to-container')).toBeInTheDocument()
  })

  it('renders icon correctly', async () => {
    const {getByTestId, findAllByTestId} = renderComponent()
    // Wait for cards to load
    await findAllByTestId('item-assign-to-card')
    const icon = getByTestId('icon-assignment')
    expect(icon).toBeInTheDocument()
  })

  it('does not render header or footer if not a tray', async () => {
    const {queryByText, queryByLabelText, findAllByTestId, container} = renderComponent({
      isTray: false,
    })
    expect(queryByText('Item Name')).not.toBeInTheDocument()
    expect(queryByText('Assignment | 10 pts')).not.toBeInTheDocument()
    expect(queryByLabelText('Edit assignment Item Name')).not.toBeInTheDocument()
    expect(queryByText('Save')).not.toBeInTheDocument()
    expect(container.querySelector('#manage-assign-to-container')).toBeInTheDocument()
    // the tray is mocking an api response that makes 2 cards
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(2)
  })

  it('renders a quiz', () => {
    const {getByTestId, getByText} = renderComponent({itemType: 'quiz', iconType: 'quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-quiz')
    expect(icon).toBeInTheDocument()
  })

  it('renders a new quiz', () => {
    const {getByTestId, getByText} = renderComponent({itemType: 'lti-quiz', iconType: 'lti-quiz'})
    expect(getByText('Quiz | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-lti-quiz')
    expect(icon).toBeInTheDocument()
  })

  it('renders a discussion', () => {
    const {getByTestId, getByText} = renderComponent({
      itemType: 'discussion',
      iconType: 'discussion',
    })
    expect(getByText('Discussion | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-discussion')
    expect(icon).toBeInTheDocument()
  })

  it('renders a page', () => {
    const {getByTestId, getByText} = renderComponent({itemType: 'page', iconType: 'page'})
    expect(getByText('Page | 10 pts')).toBeInTheDocument()
    const icon = getByTestId('icon-page')
    expect(icon).toBeInTheDocument()
  })

  it('renders Save button', () => {
    const {getByText} = renderComponent({useApplyButton: false})
    expect(getByText('Save')).toBeInTheDocument()
  })

  it("renders Save button when it hasn't been passed", () => {
    const {getByText} = renderComponent()
    expect(getByText('Save')).toBeInTheDocument()
  })

  it('renders Apply button', () => {
    const {getByText} = renderComponent({useApplyButton: true})
    expect(getByText('Apply')).toBeInTheDocument()
  })

  describe('pointsPossible display', () => {
    it('does not render points display if undefined', () => {
      const {getByText, queryByText, getByLabelText} = renderComponent({pointsPossible: undefined})
      expect(getByText('Item Name')).toBeInTheDocument()
      expect(getByText('Assignment')).toBeInTheDocument()
      expect(getByLabelText('Edit assignment Item Name')).toBeInTheDocument()
      expect(queryByText('pts')).not.toBeInTheDocument()
      expect(queryByText('pt')).not.toBeInTheDocument()
    })

    it('renders with 0 points', () => {
      const {getByText} = renderComponent({pointsPossible: 0})
      expect(getByText('Assignment | 0 pts')).toBeInTheDocument()
    })

    it('renders singular with 1 point', () => {
      const {getByText} = renderComponent({pointsPossible: 1})
      expect(getByText('Assignment | 1 pt')).toBeInTheDocument()
    })

    it('renders fractional points', () => {
      const {getByText} = renderComponent({pointsPossible: 100.5})
      expect(getByText('Assignment | 100.5 pts')).toBeInTheDocument()
    })

    it('renders a normal amount of points', () => {
      const {getByText} = renderComponent({pointsPossible: 25})
      expect(getByText('Assignment | 25 pts')).toBeInTheDocument()
    })
  })

  it('calls onClose when close button is clicked', () => {
    const onClose = vi.fn()
    const {getByRole} = renderComponent({onClose})
    getByRole('button', {name: 'Close'}).click()
    expect(onClose).toHaveBeenCalled()
  })

  it('calls onDismiss when the cancel button is clicked', () => {
    const onDismiss = vi.fn()
    const {getByRole} = renderComponent({onDismiss})
    getByRole('button', {name: 'Cancel'}).click()
    expect(onDismiss).toHaveBeenCalled()
  })

  it('fetches assignee options when defaultCards are passed', async () => {
    const overridesFetched = vi.fn()
    server.use(
      http.get(OVERRIDES_URL, () => {
        overridesFetched()
        return HttpResponse.json({
          id: '23',
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          only_visible_to_overrides: false,
          visible_to_everyone: true,
          overrides: [],
        })
      }),
    )
    renderComponent({defaultCards: []})
    await waitFor(() => {
      expect(overridesFetched).toHaveBeenCalledTimes(1)
    })
  })

  // TODO: flaky in Vitest - times out waiting for cards to load
  it.skip('calls customAddCard if passed when a card is added', async () => {
    const customAddCard = vi.fn()
    const {getAllByTestId, findAllByTestId} = renderComponent({onAddCard: customAddCard})

    // Wait for cards to load first
    await findAllByTestId('item-assign-to-card')

    getAllByTestId('add-card')[0].click()
    expect(customAddCard).toHaveBeenCalled()
  })

  describe('in a paced course', () => {
    let overridesFetched: ReturnType<typeof vi.fn>

    beforeEach(() => {
      ENV.IN_PACED_COURSE = true
      ENV.FEATURES ||= {}
      ENV.FEATURES.course_pace_pacing_with_mastery_paths = true
      overridesFetched = vi.fn()
      server.use(
        http.get(OVERRIDES_URL, () => {
          overridesFetched()
          return HttpResponse.json({})
        }),
      )
    })

    afterEach(() => {
      ENV.IN_PACED_COURSE = false
      ENV.FEATURES.course_pace_pacing_with_mastery_paths = false
    })

    it('shows the course pacing notice', () => {
      const {getByTestId} = renderComponent()
      expect(getByTestId('CoursePacingNotice')).toBeInTheDocument()
    })

    it('does not request existing overrides', async () => {
      renderComponent()
      // Wait a tick to ensure no async fetch would have been triggered
      await new Promise(resolve => setTimeout(resolve, 50))
      expect(overridesFetched).not.toHaveBeenCalled()
    })
  })
})
