/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {SearchWrapper} from '../SearchWrapper'
import * as useStudentsHook from '../../../hooks/useStudents'
import * as useOutcomesHook from '../../../hooks/useOutcomes'

vi.mock('../../../hooks/useStudents')
vi.mock('../../../hooks/useOutcomes')

const defaultProps = {
  courseId: '123',
  selectedUserIds: [],
  onSelectedUserIdsChange: vi.fn(),
  selectedOutcomes: [],
  onSelectOutcomes: vi.fn(),
}

describe('SearchWrapper', () => {
  let queryClient: QueryClient

  beforeAll(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    vi.clearAllMocks()
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: [],
      isLoading: false,
      error: null,
    })
    vi.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: [],
      outcomesCount: 0,
      isLoading: false,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  const renderWithQueryClient = (ui: React.ReactElement) => {
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('renders SearchWrapper with StudentSearch component', () => {
    renderWithQueryClient(<SearchWrapper {...defaultProps} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('passes courseId prop to StudentSearch', () => {
    renderWithQueryClient(<SearchWrapper {...defaultProps} courseId="456" />)

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('456', '')
  })

  it('passes selectedUserIds prop to StudentSearch', () => {
    renderWithQueryClient(<SearchWrapper {...defaultProps} selectedUserIds={[1, 2, 3]} />)

    const combobox = screen.getByRole('combobox', {name: /student names/i})
    expect(combobox).toBeInTheDocument()
  })

  it('passes onSelectedUserIdsChange prop to StudentSearch', () => {
    const onSelectedUserIdsChange = vi.fn()

    renderWithQueryClient(
      <SearchWrapper {...defaultProps} onSelectedUserIdsChange={onSelectedUserIdsChange} />,
    )

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('renders Flex container with correct styling', () => {
    const {container} = renderWithQueryClient(<SearchWrapper {...defaultProps} />)

    const flexContainer = container.querySelector('[dir="ltr"]')
    expect(flexContainer).toBeInTheDocument()
  })

  it('renders with empty selectedUserIds array', () => {
    renderWithQueryClient(<SearchWrapper {...defaultProps} selectedUserIds={[]} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('renders with multiple selected user IDs', () => {
    renderWithQueryClient(<SearchWrapper {...defaultProps} selectedUserIds={[1, 2, 3, 4, 5]} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('updates when props change', () => {
    const {rerender} = renderWithQueryClient(<SearchWrapper {...defaultProps} />)

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', '')

    rerender(
      <QueryClientProvider client={queryClient}>
        <SearchWrapper {...defaultProps} courseId="789" />
      </QueryClientProvider>,
    )

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('789', '')
  })

  it('maintains component structure with Flex wrapper', () => {
    const {container} = renderWithQueryClient(<SearchWrapper {...defaultProps} />)

    const flexWrapper = container.querySelector('[dir="ltr"]')
    expect(flexWrapper).toBeInTheDocument()
  })

  describe('OutcomeSearch integration', () => {
    it('renders SearchWrapper with OutcomeSearch component', () => {
      renderWithQueryClient(<SearchWrapper {...defaultProps} />)

      expect(screen.getByText('Outcomes')).toBeInTheDocument()
    })

    it('passes courseId prop to OutcomeSearch', () => {
      renderWithQueryClient(<SearchWrapper {...defaultProps} courseId="789" />)

      expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
        courseId: '789',
        searchTerm: '',
      })
    })

    it('passes selectedOutcomes prop to OutcomeSearch', () => {
      renderWithQueryClient(<SearchWrapper {...defaultProps} selectedOutcomes={['1', '2']} />)

      const combobox = screen.getByRole('combobox', {name: /outcomes/i})
      expect(combobox).toBeInTheDocument()
    })

    it('passes onSelectOutcomes prop to OutcomeSearch', () => {
      const onSelectOutcomes = vi.fn()

      renderWithQueryClient(<SearchWrapper {...defaultProps} onSelectOutcomes={onSelectOutcomes} />)

      expect(screen.getByText('Outcomes')).toBeInTheDocument()
    })

    it('renders with empty selectedOutcomes array', () => {
      renderWithQueryClient(<SearchWrapper {...defaultProps} selectedOutcomes={[]} />)

      expect(screen.getByText('Outcomes')).toBeInTheDocument()
    })

    it('renders with multiple selected outcomes', () => {
      renderWithQueryClient(<SearchWrapper {...defaultProps} selectedOutcomes={['1', '2', '3']} />)

      expect(screen.getByText('Outcomes')).toBeInTheDocument()
    })

    it('renders with undefined selectedOutcomes', () => {
      const {selectedOutcomes, ...propsWithoutOutcomes} = defaultProps
      renderWithQueryClient(
        <SearchWrapper {...propsWithoutOutcomes} selectedOutcomes={undefined} />,
      )

      expect(screen.getByText('Outcomes')).toBeInTheDocument()
    })

    it('calls useOutcomes hook with correct courseId and empty search term', () => {
      renderWithQueryClient(<SearchWrapper {...defaultProps} />)

      expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
        courseId: '123',
        searchTerm: '',
      })
    })

    it('updates when selectedOutcomes prop changes', () => {
      const {rerender} = renderWithQueryClient(<SearchWrapper {...defaultProps} />)

      expect(screen.getByText('Outcomes')).toBeInTheDocument()

      rerender(
        <QueryClientProvider client={queryClient}>
          <SearchWrapper {...defaultProps} selectedOutcomes={['1', '2']} />
        </QueryClientProvider>,
      )

      expect(screen.getByText('Outcomes')).toBeInTheDocument()
    })
  })
})
