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
import {mockAssignment} from './test-utils'
import AssignmentHeader from '../AssignmentHeader'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'

const setUp = (propOverrides = {}) => {
  const assignment = mockAssignment()
  const props = {
    type: 'saved',
    assignment,
    breakpoints: {},
    ...propOverrides,
  }
  return render(
    <MockedQueryClientProvider client={new QueryClient()}>
      <AssignmentHeader {...props} />
    </MockedQueryClientProvider>,
  )
}

describe('AssignmentHeader', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('title', () => {
    it('for create assignment view', () => {
      const {queryByTestId} = setUp({type: 'create'})
      expect(queryByTestId('assignment-heading')).toHaveTextContent('Create Assignment')
    })

    it('for edit assignment view', () => {
      const {queryByTestId} = setUp({type: 'edit'})
      expect(queryByTestId('assignment-heading')).toHaveTextContent('Edit Assignment')
    })

    it('for saved assignment view', () => {
      const {queryByTestId} = setUp()
      expect(queryByTestId('assignment-heading')).toBeInTheDocument()
      // @ts-expect-error
      expect(queryByTestId('assignment-heading')).toHaveTextContent(mockAssignment().name)
    })
  })

  describe('status pill', () => {
    it('does not render status pill if there are no submissions', () => {
      const {queryByTestId} = setUp()
      expect(queryByTestId('assignment-status-pill')).not.toBeInTheDocument()
    })

    it('renders status pill for saved view if there are submissions', () => {
      const {queryByTestId} = setUp({
        assignment: {...mockAssignment(), hasSubmittedSubmissions: true},
      })
      expect(queryByTestId('assignment-status-pill')).toBeInTheDocument()
    })

    it('does not render status pill in edit view', () => {
      const {queryByTestId} = setUp({
        type: 'edit',
        assignment: {...mockAssignment(), hasSubmittedSubmissions: true},
      })
      expect(queryByTestId('assignment-status-pill')).not.toBeInTheDocument()
    })
  })

  describe('edit button', () => {
    it('renders in saved view', () => {
      const {queryByTestId} = setUp()
      expect(queryByTestId('edit-button')).toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const {queryByTestId} = setUp({type: 'create'})
      expect(queryByTestId('edit-button')).not.toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const {queryByTestId} = setUp({type: 'edit'})
      expect(queryByTestId('edit-button')).not.toBeInTheDocument()
    })
  })

  describe('assign to button', () => {
    it('renders assign to button in saved view', () => {
      const {queryByTestId} = setUp()
      expect(queryByTestId('assign-to-button')).toBeInTheDocument()
    })

    it('does not render assign to button in edit view', () => {
      const {queryByTestId} = setUp({type: 'edit'})
      expect(queryByTestId('assign-to-button')).not.toBeInTheDocument()
    })

    it('does not render assign to button in create view', () => {
      const {queryByTestId} = setUp({type: 'create'})
      expect(queryByTestId('assign-to-button')).not.toBeInTheDocument()
    })
  })

  describe('speedgrader button', () => {
    it('renders if assignment is published and in saved view', () => {
      const {queryByTestId} = setUp()
      expect(queryByTestId('speedgrader-button')).toBeInTheDocument()
    })

    it('does not render if assignment is not published and in saved view', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp({assignment: {...assignment, state: 'unpublished'}})
      expect(queryByTestId('speedgrader-button')).not.toBeInTheDocument()
    })

    it('does not render in edit view', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp({
        type: 'edit',
        assignment: {...assignment, state: 'unpublished'},
      })
      expect(queryByTestId('speedgrader-button')).not.toBeInTheDocument()
    })

    it('does not render in create view', () => {
      const assignment = mockAssignment()
      const {queryByTestId} = setUp({
        type: 'create',
        assignment: {...assignment, state: 'unpublished'},
      })
      expect(queryByTestId('speedgrader-button')).not.toBeInTheDocument()
    })
  })
})
