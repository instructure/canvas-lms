/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {mockAssignment} from '../../test-utils'
import AssignmentHeader from '../AssignmentHeader'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

const setUp = (propOverrides = {}) => {
  const assignment = mockAssignment()
  const props = {
    assignment,
    breakpoints: {},
    ...propOverrides,
  }
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <AssignmentHeader {...props} />
    </QueryClientProvider>
  )
}

describe('AssignmentHeader - assignment enhancement teacher view header', () => {
  it('renders assignment name', () => {
    const {queryByTestId} = setUp()
    expect(queryByTestId('assignment-name')).toBeInTheDocument()
    expect(queryByTestId('assignment-name')).toHaveTextContent(mockAssignment().name)
  })

  it('assignment status pill does not render', () => {
    const {queryByTestId} = setUp()
    expect(queryByTestId('assignment-status-pill')).not.toBeInTheDocument()
  })

  it('renders assignment status pill', () => {
    const {queryByTestId} = setUp({
      assignment: {...mockAssignment(), hasSubmittedSubmissions: true},
    })
    expect(queryByTestId('assignment-status-pill')).toBeInTheDocument()
  })

  it('renders edit button', () => {
    const {queryByTestId} = setUp()
    expect(queryByTestId('edit-button')).toBeInTheDocument()
  })

  it('renders assign to button', () => {
    const {queryByTestId} = setUp()
    expect(queryByTestId('assign-to-button')).toBeInTheDocument()
  })

  it('renders speedgrader button', () => {
    const {queryByTestId} = setUp()
    expect(queryByTestId('speedgrader-button')).toBeInTheDocument()
  })

  it('speedgrader does not render', () => {
    const assignment = mockAssignment()
    const {queryByTestId} = setUp({assignment: {...assignment, state: 'unpublished'}})
    expect(queryByTestId('speedgrader-button')).not.toBeInTheDocument()
  })
})
