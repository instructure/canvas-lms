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
import $ from 'jquery'
import React from 'react'
import {render} from '@testing-library/react'
import AssignmentInformation, {AssignmentInformationComponentProps} from '..'
import {assignmentInfoDefaultProps} from './fixtures'

describe('Assignment Information Tests', () => {
  beforeEach(() => {
    $.subscribe = jest.fn()
  })
  const renderAssignmentInformation = (props: AssignmentInformationComponentProps) => {
    return render(<AssignmentInformation {...props} />)
  }
  describe('render tests', () => {
    it('displayed default text when an assignment has not been selected', () => {
      const props = {...assignmentInfoDefaultProps, assignment: undefined}
      const {getByText} = renderAssignmentInformation(props)
      expect(
        getByText('Select an assignment to view additional information here.')
      ).toBeInTheDocument()
    })

    it('displays the assignment name', () => {
      const {name = ''} = assignmentInfoDefaultProps.assignment ?? {}
      const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
      const assignmentNameNode = getByTestId('assignment-information-name')
      expect(assignmentNameNode).toHaveAttribute(
        'href',
        assignmentInfoDefaultProps.assignment?.htmlUrl
      )
      expect(assignmentNameNode).toHaveTextContent(name)
    })

    it('displays the assignment speedgrader link', () => {
      const {getByTestId} = renderAssignmentInformation(assignmentInfoDefaultProps)
      const speedGraderUrl = '/courses/1/gradebook/speed_grader?assignment_id=1'
      const speedGraderUrlNode = getByTestId('assignment-speedgrader-link')
      expect(speedGraderUrlNode).toHaveAttribute('href', speedGraderUrl)
      expect(speedGraderUrlNode).toHaveTextContent('See this assignment in speedgrader')
    })

    it("displays the assignment's submission types", () => {
      const {getByTestId} = renderAssignmentInformation({...assignmentInfoDefaultProps})
      expect(getByTestId('assignment-submission-info')).toHaveTextContent('Online text entry')
      expect(getByTestId('assignment-submission-info')).toHaveTextContent('Online upload')
    })

    it('does not display the message students who button when the selected assignment is anonymous', () => {
      const {queryByTestId} = renderAssignmentInformation({
        ...assignmentInfoDefaultProps,
        assignment: assignmentInfoDefaultProps.assignment
          ? {
              ...assignmentInfoDefaultProps.assignment,
              anonymizeStudents: true,
            }
          : undefined,
      })
      expect(queryByTestId('message-students-who-button')).toBeNull()
    })
  })
})
