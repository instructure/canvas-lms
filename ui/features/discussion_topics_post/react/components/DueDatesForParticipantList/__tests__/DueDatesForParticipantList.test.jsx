/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {AdhocStudents, Student} from '../../../../graphql/AdhocStudents'
import {AssignmentOverride} from '../../../../graphql/AssignmentOverride'
import {DueDatesForParticipantList} from '../DueDatesForParticipantList'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'

const setup = props => {
  return render(<DueDatesForParticipantList {...props} />)
}

describe('DueDatesForParticipantList', () => {
  it('truncates the student names if there are more than 10', () => {
    const students = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(val =>
      Student.mock({shortName: `Student${val}`})
    )
    const {getByText} = setup({
      assignmentOverride: AssignmentOverride.mock({
        adhocStudents: AdhocStudents.mock({
          students,
        }),
      }),
    })
    expect(
      getByText(
        students
          .slice(0, 5)
          .map(student => student.shortName)
          .join(', ')
      )
    ).toBeInTheDocument()
    expect(getByText('...')).toBeInTheDocument()
    expect(getByText('6 more')).toBeInTheDocument()
  })

  it('allows expanding the student names if there are more than 10', () => {
    const students = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(val =>
      Student.mock({shortName: `Student${val}`})
    )
    const {getByText} = setup({
      assignmentOverride: AssignmentOverride.mock({
        adhocStudents: AdhocStudents.mock({
          students,
        }),
      }),
    })
    fireEvent.click(getByText('6 more'))
    expect(getByText(students.map(student => student.shortName).join(', '))).toBeInTheDocument()
    expect(getByText('6 less')).toBeInTheDocument()
  })
})
