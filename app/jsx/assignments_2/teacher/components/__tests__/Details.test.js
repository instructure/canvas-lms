/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render} from 'react-testing-library'
import {mockAssignment, mockOverride} from '../../test-utils'
import Details from '../Details'

const override1 = {lid: '18', title: 'Section A', set: {sectionName: 'Section A'}}
const override2 = {lid: '19', title: 'Section B', set: {sectionName: 'Section B'}}

function renderDetails(assignment, props = {}) {
  return render(
    <Details
      assignment={assignment}
      onChangeAssignment={() => {}}
      onValidate={() => true}
      invalidMessage={() => undefined}
      {...props}
    />
  )
}
describe('Assignent Details', () => {
  it('renders', () => {
    const assignment = mockAssignment()
    const {getByText, getByTestId} = renderDetails(assignment)

    expect(getByTestId('AssignmentDescription')).toBeInTheDocument()
    expect(getByText('Everyone')).toBeInTheDocument()
    expect(getByText('Due:', {exact: false})).toBeInTheDocument()
    expect(getByText('Available', {exact: false})).toBeInTheDocument()
  })

  it('renders an override', () => {
    const assignment = mockAssignment({
      assignmentOverrides: {
        nodes: [mockOverride()]
      }
    })
    const {getByText} = renderDetails(assignment)
    expect(getByText('Section A')).toBeInTheDocument()
    expect(getByText('Everyone else')).toBeInTheDocument()
  })

  it('renders all the overrides', () => {
    const assignment = mockAssignment({
      dueAt: null,
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)]
      }
    })
    const {getByText, queryAllByText} = renderDetails(assignment)

    expect(getByText('Section A')).toBeInTheDocument()
    expect(getByText('Section B')).toBeInTheDocument()
    expect(queryAllByText('Everyone', {exact: false})).toHaveLength(1)
  })

  it('renders the Add Override button if !readOnly', () => {
    const assignment = mockAssignment({
      dueAt: null,
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)]
      }
    })
    const {getByTestId} = renderDetails(assignment)

    expect(getByTestId('AddHorizontalRuleButton')).toBeInTheDocument()
  })

  it('does notrender the Add Override button if readOnly', () => {
    const assignment = mockAssignment({
      dueAt: null,
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)]
      }
    })
    const {queryByTestId} = renderDetails(assignment, {readOnly: true})

    expect(queryByTestId('AddHorizontalRuleButton')).toBeNull()
  })
})
