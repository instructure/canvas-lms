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

import {assignmentRow} from '../AssignmentRow'
import {Assignment} from '../../../../graphql/Assignment'
import {Submission} from '../../../../graphql/Submission'
import {Table} from '@instructure/ui-table'

const defaultProps = {
  assignment: Assignment.mock(),
  setOpenAssignmentDetailIds: () => {},
  openAssignmentDetailIds: [],
}

const setup = (props = defaultProps) => {
  return render(
    <Table caption="Assignment Row - Jest Test Table">
      <Table.Body>
        {assignmentRow(
          props.assignment,
          props.setOpenAssignmentDetailIds,
          props.openAssignmentDetailIds
        )}
      </Table.Body>
    </Table>
  )
}

describe('AssignmentRow', () => {
  it('renders', () => {
    const {getByText} = setup()
    expect(getByText(defaultProps.assignment.name)).toBeInTheDocument()
    expect(getByText('Jan 1, 2020 at 12am')).toBeInTheDocument()
    expect(getByText('Graded')).toBeInTheDocument()
  })

  describe('Custom Status', () => {
    it('renders custom status', () => {
      const assignment = Assignment.mock({
        submissionsConnection: {
          nodes: [
            Submission.mock({
              customGradeStatus: 'Ridiculous',
            }),
          ],
        },
      })
      const {getByText} = setup({...defaultProps, assignment})
      expect(getByText('Ridiculous')).toBeInTheDocument()
    })
  })
})
