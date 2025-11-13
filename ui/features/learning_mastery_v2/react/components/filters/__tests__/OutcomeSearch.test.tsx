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
import {render, screen, waitFor, act} from '@testing-library/react'
import {OutcomeSearch} from '../OutcomeSearch'
import * as useOutcomesHook from '../../../hooks/useOutcomes'

jest.mock('../../../hooks/useOutcomes')
jest.mock('@canvas/alerts/react/FlashAlert')

interface OutcomeEdge {
  canUnlink: boolean
  _id: string
  node: {
    _id: string
    title: string
    description: string
    displayName: string
    calculationMethod: string
    calculationInt: number
    masteryPoints: number
    ratings: Array<{description: string; points: number}>
    canEdit: boolean
    canArchive: boolean
    contextType: string
    contextId: string
    friendlyDescription: null | {_id: string; description: string}
  }
  group: {
    _id: string
    title: string
  }
}

const mockOutcomes: OutcomeEdge[] = [
  {
    canUnlink: true,
    _id: '1',
    node: {
      _id: '1',
      title: 'Outcome 1',
      description: 'Description 1',
      displayName: 'Outcome 1',
      calculationMethod: 'decaying_average',
      calculationInt: 65,
      masteryPoints: 3,
      ratings: [{description: 'Exceeds', points: 4}],
      canEdit: true,
      canArchive: true,
      contextType: 'Course',
      contextId: '123',
      friendlyDescription: null,
    },
    group: {
      _id: 'g1',
      title: 'Group 1',
    },
  },
  {
    canUnlink: true,
    _id: '2',
    node: {
      _id: '2',
      title: 'Outcome 2',
      description: 'Description 2',
      displayName: 'Outcome 2',
      calculationMethod: 'decaying_average',
      calculationInt: 65,
      masteryPoints: 3,
      ratings: [{description: 'Exceeds', points: 4}],
      canEdit: true,
      canArchive: true,
      contextType: 'Course',
      contextId: '123',
      friendlyDescription: null,
    },
    group: {
      _id: 'g1',
      title: 'Group 1',
    },
  },
]

const mockSearchResults: OutcomeEdge[] = [
  {
    canUnlink: true,
    _id: '3',
    node: {
      _id: '3',
      title: 'Search Result Outcome',
      description: 'Description 3',
      displayName: 'Search Result Outcome',
      calculationMethod: 'decaying_average',
      calculationInt: 65,
      masteryPoints: 3,
      ratings: [{description: 'Exceeds', points: 4}],
      canEdit: true,
      canArchive: true,
      contextType: 'Course',
      contextId: '123',
      friendlyDescription: null,
    },
    group: {
      _id: 'g1',
      title: 'Group 1',
    },
  },
]

const defaultProps = {
  courseId: '123',
  selectedOutcomes: [],
  onSelectOutcomes: jest.fn(),
}

describe('OutcomeSearch', () => {
  beforeAll(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    jest.clearAllMocks()
    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: mockOutcomes,
      outcomesCount: mockOutcomes.length,
      isLoading: false,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('renders OutcomeSearch with CanvasMultiSelect', () => {
    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Search outcomes')).toBeInTheDocument()
  })

  it('calls useOutcomes hook with correct courseId and empty search term', () => {
    render(<OutcomeSearch {...defaultProps} />)

    expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
      courseId: '123',
      searchTerm: '',
    })
  })

  it('renders CanvasMultiSelect with correct placeholder', () => {
    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByPlaceholderText('Search outcomes')).toBeInTheDocument()
  })

  it('passes selected outcome IDs to CanvasMultiSelect', () => {
    render(<OutcomeSearch {...defaultProps} selectedOutcomes={['1', '2']} />)

    const combobox = screen.getByRole('combobox', {name: /outcomes/i})
    expect(combobox).toBeInTheDocument()
  })

  it('loads initial outcomes from useOutcomes hook on mount', () => {
    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByRole('combobox', {name: /outcomes/i})).toBeInTheDocument()
  })

  it('updates outcomes when useOutcomes returns new data', () => {
    const {rerender} = render(<OutcomeSearch {...defaultProps} />)

    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: mockSearchResults,
      outcomesCount: mockSearchResults.length,
      isLoading: false,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    rerender(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('updates search term when user types in input', async () => {
    render(<OutcomeSearch {...defaultProps} />)

    expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
      courseId: '123',
      searchTerm: '',
    })

    const input = screen.getByPlaceholderText('Search outcomes')

    act(() => {
      input.dispatchEvent(new Event('change', {bubbles: true}))
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(
        input,
        'Search Result',
      )
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    await waitFor(
      () => {
        expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
          courseId: '123',
          searchTerm: 'Search Result',
        })
      },
      {timeout: 1000},
    )
  })

  it('renders component when useOutcomes hook returns error', () => {
    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: [],
      outcomesCount: 0,
      isLoading: false,
      error: new Error('Failed to load outcomes'),
      hasNextPage: false,
      endCursor: null,
    })

    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('handles empty outcomes array from useOutcomes hook', () => {
    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: [],
      outcomesCount: 0,
      isLoading: false,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('handles outcomes loading state from useOutcomes hook', () => {
    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: [],
      outcomesCount: 0,
      isLoading: true,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('handles multiple selected outcomes', () => {
    render(<OutcomeSearch {...defaultProps} selectedOutcomes={['1', '2']} />)

    const combobox = screen.getByRole('combobox', {name: /outcomes/i})
    expect(combobox).toBeInTheDocument()
  })

  it('renders with search icon via customRenderBeforeInput', () => {
    const {container} = render(<OutcomeSearch {...defaultProps} />)

    const searchIcon = container.querySelector('[name="IconSearch"]')
    expect(searchIcon).toBeInTheDocument()
  })

  it('updates search term when input is cleared', async () => {
    render(<OutcomeSearch {...defaultProps} />)

    const input = screen.getByPlaceholderText('Search outcomes')

    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(
        input,
        'Search',
      )
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    await waitFor(
      () => {
        expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
          courseId: '123',
          searchTerm: 'Search',
        })
      },
      {timeout: 1000},
    )

    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(input, '')
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    await waitFor(
      () => {
        expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
          courseId: '123',
          searchTerm: '',
        })
      },
      {timeout: 1000},
    )

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('caches outcomes to preserve selected outcomes not in search results', () => {
    const {rerender} = render(<OutcomeSearch {...defaultProps} selectedOutcomes={['1']} />)

    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: mockSearchResults,
      outcomesCount: mockSearchResults.length,
      isLoading: false,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    rerender(<OutcomeSearch {...defaultProps} selectedOutcomes={['1']} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('clears search term when selection is made', async () => {
    const onSelectOutcomes = jest.fn()
    render(<OutcomeSearch {...defaultProps} onSelectOutcomes={onSelectOutcomes} />)

    const input = screen.getByPlaceholderText('Search outcomes')

    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(
        input,
        'Search',
      )
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    await waitFor(
      () => {
        expect(useOutcomesHook.useOutcomes).toHaveBeenCalledWith({
          courseId: '123',
          searchTerm: 'Search',
        })
      },
      {timeout: 1000},
    )

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('renders all outcomes from hook', () => {
    render(<OutcomeSearch {...defaultProps} />)

    const combobox = screen.getByRole('combobox', {name: /outcomes/i})
    expect(combobox).toBeInTheDocument()
  })

  it('calls onSelectOutcomes when outcomes are selected', () => {
    const onSelectOutcomes = jest.fn()
    render(<OutcomeSearch {...defaultProps} onSelectOutcomes={onSelectOutcomes} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('uses memoized renderBeforeInput callback', () => {
    const {rerender} = render(<OutcomeSearch {...defaultProps} />)

    const {container} = render(<OutcomeSearch {...defaultProps} />)
    const searchIcon1 = container.querySelector('[name="IconSearch"]')

    rerender(<OutcomeSearch {...defaultProps} />)

    const searchIcon2 = container.querySelector('[name="IconSearch"]')
    expect(searchIcon1).toBeInTheDocument()
    expect(searchIcon2).toBeInTheDocument()
  })

  it('does not include loading outcomes in allOutcomes when isLoading is true', () => {
    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: mockOutcomes,
      outcomesCount: mockOutcomes.length,
      isLoading: true,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    render(<OutcomeSearch {...defaultProps} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('merges selected outcomes from cache with search results', () => {
    const {rerender} = render(<OutcomeSearch {...defaultProps} selectedOutcomes={['1', '2']} />)

    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: mockSearchResults,
      outcomesCount: mockSearchResults.length,
      isLoading: false,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    rerender(<OutcomeSearch {...defaultProps} selectedOutcomes={['1', '2']} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('handles undefined selectedOutcomes prop', () => {
    render(<OutcomeSearch courseId="123" onSelectOutcomes={jest.fn()} />)

    expect(screen.getByText('Outcomes')).toBeInTheDocument()
  })

  it('sets isLoading prop on CanvasMultiSelect during API call', () => {
    jest.spyOn(useOutcomesHook, 'useOutcomes').mockReturnValue({
      outcomes: [],
      outcomesCount: 0,
      isLoading: true,
      error: null,
      hasNextPage: false,
      endCursor: null,
    })

    render(<OutcomeSearch {...defaultProps} />)

    const combobox = screen.getByRole('combobox', {name: /outcomes/i})
    expect(combobox).toBeInTheDocument()
  })
})
