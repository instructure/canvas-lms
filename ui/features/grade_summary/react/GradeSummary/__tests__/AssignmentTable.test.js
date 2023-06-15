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

import React from 'react'
import {render} from '@testing-library/react'

import AssignmentTable from '../AssignmentTable'

import {Assignment} from '../../../graphql/Assignment'
import {AssignmentGroup} from '../../../graphql/AssignmentGroup'
import {GradingStandard} from '../../../graphql/GradingStandard'

const defaultProps = {
  queryData: {
    name: 'Course Name',
    _id: '1',
    assignmentsConnection: {nodes: [Assignment.mock()]},
    assignmentGroupsConnection: {nodes: [AssignmentGroup.mock()]},
    gradingStandard: GradingStandard.mock(),
  },
  layout: 'fixed',
  setShowTray: () => {},
  setSelectedSubmission: () => {},
}

describe('AssignmentTable', () => {
  it('renders', () => {
    const {getByText} = render(<AssignmentTable {...defaultProps} />)
    expect(getByText(Assignment.mock().name)).toBeInTheDocument()
  })
})
