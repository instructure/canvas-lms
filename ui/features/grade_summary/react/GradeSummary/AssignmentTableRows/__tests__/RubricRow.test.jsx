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

import {rubricRow} from '../RubricRow'
import {Assignment} from '../../../../graphql/Assignment'
import {Table} from '@instructure/ui-table'

const defaultProps = {
  assignment: Assignment.mock(),
  setOpenRubricDetailIds: () => {},
  openRubricDetailIds: [],
}

const setup = (props = defaultProps) => {
  return render(
    <Table caption="Rubric Row - Jest Test Table">
      <Table.Body>
        {rubricRow(props.assignment, props.setOpenRubricDetailIds, props.openRubricDetailIds)}
      </Table.Body>
    </Table>
  )
}

describe('RubricRow', () => {
  it('renders', () => {
    const {getByText} = setup()
    expect(getByText('Rubric Row - Jest Test Table')).toBeInTheDocument()
    expect(getByText('Assessment by Assessor Display Name')).toBeInTheDocument()
    expect(getByText('Criterion Description')).toBeInTheDocument()
    expect(getByText('Rating Description')).toBeInTheDocument()
    expect(getByText('1 pts')).toBeInTheDocument()
    expect(getByText('Rating Long Description')).toBeInTheDocument()
    expect(getByText('1 / 6 pts')).toBeInTheDocument()
    expect(getByText('Total Points: 10')).toBeInTheDocument()
  })
})
