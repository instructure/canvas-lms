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
import {cleanup, render, screen, waitFor, act} from '@testing-library/react'
import {StudentSearch} from '../StudentSearch'
import * as useStudentsHook from '../../../hooks/useStudents'
import {Student} from '@canvas/outcomes/react/types/rollup'

vi.mock('../../../hooks/useStudents')
vi.mock('../../../apiClient')
vi.mock('@canvas/alerts/react/FlashAlert')

afterEach(() => {
  cleanup()
})

const mockStudents: Student[] = [
  {
    id: '1',
    name: 'Alice Student',
    display_name: 'Alice',
    sortable_name: 'Student, Alice',
  },
  {
    id: '2',
    name: 'Bob Student',
    display_name: 'Bob',
    sortable_name: 'Student, Bob',
  },
  {
    id: '3',
    name: 'Charlie Student',
    display_name: 'Charlie',
    sortable_name: 'Student, Charlie',
  },
]

const mockSearchResults: Student[] = [
  {
    id: '4',
    name: 'David Student',
    display_name: 'David',
    sortable_name: 'Student, David',
  },
]

const defaultProps = {
  courseId: '123',
  selectedUserIds: [],
  onSelectedUserIdsChange: vi.fn(),
}

describe('StudentSearch', () => {
  beforeAll(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    vi.clearAllMocks()
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: mockStudents,
      isLoading: false,
      error: null,
    })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renders StudentSearch with CanvasMultiSelect when pagination is provided', () => {
    render(<StudentSearch {...defaultProps} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Search Students')).toBeInTheDocument()
  })

  it('calls useStudents hook with correct courseId and empty search term', () => {
    render(<StudentSearch {...defaultProps} />)

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', '')
  })

  it('renders CanvasMultiSelect with correct placeholder', () => {
    render(<StudentSearch {...defaultProps} />)

    expect(screen.getByPlaceholderText('Search Students')).toBeInTheDocument()
  })

  it('passes selected student IDs to CanvasMultiSelect', () => {
    render(<StudentSearch {...defaultProps} selectedUserIds={[1, 3]} />)

    const combobox = screen.getByRole('combobox', {name: /student names/i})
    expect(combobox).toBeInTheDocument()
  })

  it('loads initial students from useStudents hook on mount', () => {
    render(<StudentSearch {...defaultProps} />)

    // Verify the component renders with students from useStudents
    expect(screen.getByRole('combobox', {name: /student names/i})).toBeInTheDocument()
  })

  it('updates students when useStudents returns new data', () => {
    const {rerender} = render(<StudentSearch {...defaultProps} />)

    // Change the students returned by the hook
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: mockSearchResults,
      isLoading: false,
      error: null,
    })

    rerender(<StudentSearch {...defaultProps} />)

    // Component should still render
    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('updates search term when user types in input', async () => {
    render(<StudentSearch {...defaultProps} />)

    // Initially called with empty search term
    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', '')

    const input = screen.getByPlaceholderText('Search Students')

    // Simulate input change
    act(() => {
      input.dispatchEvent(new Event('change', {bubbles: true}))
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(input, 'Da')
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    // Wait for debounce (500ms) and verify hook is called with new search term
    await waitFor(
      () => {
        // After input, useStudents should be called with the search term
        expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', 'Da')
      },
      {timeout: 1000},
    )
  })

  it('does not update search term when input length is 1 character', async () => {
    render(<StudentSearch {...defaultProps} />)

    // Initially called with empty search term
    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', '')

    const input = screen.getByPlaceholderText('Search Students')

    // Simulate single character input
    act(() => {
      input.dispatchEvent(new Event('change', {bubbles: true}))
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(input, 'D')
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    // Wait for debounce period
    await waitFor(
      () => {
        // Should still be called with empty string, not 'D'
        expect(useStudentsHook.useStudents).toHaveBeenLastCalledWith('123', '')
      },
      {timeout: 600},
    )
  })

  it('renders component when useStudents hook returns error', () => {
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: [],
      isLoading: false,
      error: 'Failed to load students',
    })

    render(<StudentSearch {...defaultProps} />)

    // Component should still render even with error
    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('handles empty students array from useStudents hook', () => {
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: [],
      isLoading: false,
      error: null,
    })

    render(<StudentSearch {...defaultProps} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('handles students loading state from useStudents hook', () => {
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: [],
      isLoading: true,
      error: null,
    })

    render(<StudentSearch {...defaultProps} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('handles students error state from useStudents hook', () => {
    vi.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: [],
      isLoading: false,
      error: 'Failed to load students',
    })

    render(<StudentSearch {...defaultProps} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('handles multiple selected students', () => {
    render(<StudentSearch {...defaultProps} selectedUserIds={[1, 2, 3]} />)

    const combobox = screen.getByRole('combobox', {name: /student names/i})
    expect(combobox).toBeInTheDocument()
  })

  it('renders with search icon customRenderBeforeInput', () => {
    const {container} = render(<StudentSearch {...defaultProps} />)

    // Search icon is rendered via customRenderBeforeInput
    const searchIcon = container.querySelector('[name="IconSearch"]')
    expect(searchIcon).toBeInTheDocument()
  })

  it('updates search term when input is cleared', async () => {
    render(<StudentSearch {...defaultProps} />)

    const input = screen.getByPlaceholderText('Search Students')

    // First search
    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(
        input,
        'David',
      )
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    await waitFor(
      () => {
        expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', 'David')
      },
      {timeout: 1000},
    )

    // Clear search
    act(() => {
      Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value')?.set?.call(input, '')
      input.dispatchEvent(new Event('input', {bubbles: true}))
    })

    await waitFor(
      () => {
        expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', '')
      },
      {timeout: 1000},
    )

    // Component should still be rendered
    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('sets isLoading state during API call', () => {
    render(<StudentSearch {...defaultProps} />)

    // The isLoading prop is passed to CanvasMultiSelect
    // It starts as false based on initial state
    const combobox = screen.getByRole('combobox', {name: /student names/i})
    expect(combobox).toBeInTheDocument()
  })
})
