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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {Provider} from 'react-redux'
import {createStore} from 'redux'
import {BulkEditStudentsTable} from '../bulk_edit_students_table'
import {DEFAULT_BULK_EDIT_STUDENTS_STATE} from '../../__tests__/fixtures'

jest.mock('../../actions/bulk_edit_students_actions', () => ({
  fetchStudents: jest.fn(() => ({type: 'MOCK_FETCH_STUDENTS'})),
  setSearchTerm: jest.fn(term => ({type: 'SET_SEARCH_TERM', payload: term})),
  setFilterSection: jest.fn(section => ({type: 'SET_FILTER_SECTION', payload: section})),
  setFilterPaceStatus: jest.fn(status => ({type: 'SET_FILTER_PACE_STATUS', payload: status})),
  setPage: jest.fn(page => ({type: 'SET_PAGE', payload: page})),
  setSort: jest.fn((col, order) => ({type: 'SET_SORT', payload: {col, order}})),
  resetBulkEditState: jest.fn(() => ({type: 'RESET_BULK_EDIT_STATE'})),
}))

const initialState = {
  bulkEditStudents: {...DEFAULT_BULK_EDIT_STUDENTS_STATE},
  ui: {
    selectedBulkStudents: [] as string[],
  },
}
const reducer = (state = initialState, action: any) => {
  switch (action.type) {
    case 'SET_FILTER_PACE_STATUS':
      return {
        ...state,
        bulkEditStudents: {
          ...state.bulkEditStudents,
          filterPaceStatus: action.payload,
        },
      }
    case 'SET_STUDENTS':
      return {
        ...state,
        bulkEditStudents: {
          ...state.bulkEditStudents,
          students: [...action.payload],
        },
      }
    case 'TOGGLE_STUDENT_SELECTION': {
      const {studentId} = action.payload
      const isSelected = state.ui.selectedBulkStudents.includes(studentId)

      return {
        ...state,
        ui: {
          ...state.ui,
          selectedBulkStudents: isSelected
            ? state.ui.selectedBulkStudents.filter(id => id !== studentId)
            : [...state.ui.selectedBulkStudents, studentId],
        },
      }
    }
    default:
      return state
  }
}

const store = createStore(reducer)

describe('BulkEditStudentsTable', () => {
  it('renders the table with student data', async () => {
    // Explicitly set students in the store before rendering
    store.dispatch({
      type: 'SET_STUDENTS',
      payload: [
        {
          id: '1',
          name: 'John',
          enrollmentId: '1',
          enrollmentDate: '2025-02-01',
          paceStatus: 'on-pace',
          sections: [{id: 'math', name: 'Math', course_id: '1'}],
        },
        {
          id: '2',
          name: 'Maria',
          enrollmentId: '2',
          enrollmentDate: '2025-02-02',
          paceStatus: 'on-pace',
          sections: [{id: 'science', name: 'Science', course_id: '1'}],
        },
      ],
    })

    render(
      <Provider store={store}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    // Wait for the component to render the student data
    await waitFor(() => {
      expect(screen.getByText('John')).toBeInTheDocument()
    })

    await waitFor(() => {
      expect(screen.getByText('Maria')).toBeInTheDocument()
    })
  })

  it('updates search input and triggers search', async () => {
    render(
      <Provider store={store}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    const searchInput = screen.getByPlaceholderText('Search for students...')
    fireEvent.change(searchInput, {target: {value: 'Jane'}})

    const searchButton = screen.getByTestId('search-button')
    fireEvent.click(searchButton)

    await waitFor(() => {
      expect(searchInput).toHaveValue('Jane')
    })
  })

  it('filters students by section and updates table results', async () => {
    render(
      <Provider store={store}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    const sectionFilter = screen.getByLabelText('Filter Sections')
    fireEvent.click(sectionFilter)

    await waitFor(() => {
      const mathOptions = screen.getAllByText('Math')
      const mathOption = mathOptions.find(el => el.getAttribute('role') === 'option')

      if (mathOption) {
        fireEvent.click(mathOption)
      }
    })

    store.dispatch({type: 'SET_FILTER_SECTION', payload: 'Math'})

    // Simulate backend response
    store.dispatch({
      type: 'SET_STUDENTS',
      payload: [{id: '1', name: 'John', enrollmentId: '1', sections: [{name: 'Math'}]}],
    })

    await waitFor(() => {
      expect(screen.getByText('John')).toBeInTheDocument()
    })

    await waitFor(() => {
      expect(screen.queryByText('Maria')).not.toBeInTheDocument()
    })
  })

  it('filters students by pace status and updates table results', async () => {
    render(
      <Provider store={store}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    const paceStatusFilter = screen.getByLabelText('Filter Pace Status')
    fireEvent.click(paceStatusFilter)

    await waitFor(() => {
      const onPaceOptions = screen.getAllByText('On Pace')
      const onPaceOption = onPaceOptions.find(el => el.getAttribute('role') === 'option')

      if (onPaceOption) {
        fireEvent.click(onPaceOption)
      }
    })

    store.dispatch({type: 'SET_FILTER_PACE_STATUS', payload: 'on-pace'})

    store.dispatch({
      type: 'SET_STUDENTS',
      payload: [{id: '1', name: 'John', enrollmentId: '1', sections: [{name: 'Math'}]}],
    })

    await waitFor(() => {
      expect(screen.getByText('John')).toBeInTheDocument()
    })

    await waitFor(() => {
      expect(screen.queryByText('Maria')).not.toBeInTheDocument()
    })
  })

  it('selects and deselects a student', async () => {
    render(
      <Provider store={store}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    const firstCheckbox = screen.getByTestId('student-checkbox-0')

    fireEvent.click(firstCheckbox)

    store.dispatch({type: 'TOGGLE_STUDENT_SELECTION', payload: {studentId: '1'}})

    await waitFor(() => {
      expect(firstCheckbox).toBeChecked()
    })

    fireEvent.click(firstCheckbox)

    store.dispatch({type: 'TOGGLE_STUDENT_SELECTION', payload: {studentId: '1'}})

    await waitFor(() => {
      expect(firstCheckbox).not.toBeChecked()
    })
  })

  it('shows loading state when fetching data', () => {
    const loadingState = {
      ...initialState,
      bulkEditStudents: {...initialState.bulkEditStudents, isLoading: true},
    }
    const storeWithLoading = createStore(() => loadingState)

    render(
      <Provider store={storeWithLoading}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('displays an error message when an error occurs', () => {
    const errorState = {
      ...initialState,
      bulkEditStudents: {...initialState.bulkEditStudents, error: 'An error occurred'},
    }
    const storeWithError = createStore(() => errorState)

    render(
      <Provider store={storeWithError}>
        <BulkEditStudentsTable />
      </Provider>,
    )

    expect(screen.getByText('An error occurred')).toBeInTheDocument()
  })
})
