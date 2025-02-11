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
import { render, screen } from '@testing-library/react'
import { Provider } from 'react-redux'
import { createStore } from 'redux'
import BulkEditStudentPaces from '../bulk_edit_students'

// Define a simple reducer that mimics the expected state shape
const reducer = (state = { ui: { bulkEditModalOpen: false, selectedBulkStudents: [] } }) => state
const store = createStore(reducer)

const openModal = jest.fn()
const closeModal = jest.fn()
const setSelectedPaceContext = jest.fn()
const handleContextSelect = jest.fn()

const defaultProps = {
  openModal,
  closeModal,
  setSelectedPaceContext,
  handleContextSelect,
  bulkEditModalOpen: false,
  selectedBulkStudents: [],
}

describe('BulkEditStudentPaces', () => {
  it('renders placeholder text for student_enrollment context', () => {
    render(
      <Provider store={store}>
        <BulkEditStudentPaces {...defaultProps} />
      </Provider>
    )

    const bulkEditButton = screen.getByTestId('bulk-edit-student-paces-button')
    expect(bulkEditButton).toBeInTheDocument()
  })
})
