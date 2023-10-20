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

import {scoreDistributionRow} from '../ScoreDistributionRow'
import {Assignment} from '../../../../graphql/Assignment'
import {Table} from '@instructure/ui-table'

const defaultProps = {
  assignment: Assignment.mock(),
  setOpenAssignmentDetailIds: () => {},
  openAssignmentDetailIds: [],
}

const setup = (props = defaultProps) => {
  return render(
    <Table caption="Score Distribution Row - Jest Test Table">
      <Table.Body>
        {scoreDistributionRow(
          props.assignment,
          props.setOpenAssignmentDetailIds,
          props.openAssignmentDetailIds
        )}
      </Table.Body>
    </Table>
  )
}

describe('ScoreDistributionGraph', () => {
  it('renders', () => {
    const {getByText, getByTestId} = setup()
    expect(getByText('Score Details')).toBeInTheDocument()
    expect(getByText('Mean: 1')).toBeInTheDocument()
    expect(getByText('Median: 1')).toBeInTheDocument()
    expect(getByText('Upper Quartile: 1')).toBeInTheDocument()
    expect(getByText('Lower Quartile: 1')).toBeInTheDocument()
    expect(getByText('High: 1')).toBeInTheDocument()
    expect(getByText('Low: 1')).toBeInTheDocument()
    expect(getByTestId('scoreDistributionGraph')).toBeInTheDocument()
  })
})
