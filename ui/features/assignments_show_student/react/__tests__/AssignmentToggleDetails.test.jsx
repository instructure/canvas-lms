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
import {render} from '@testing-library/react'
import AssignmentToggleDetails from '../AssignmentToggleDetails'
import $ from 'jquery'

describe('AssignmentToggleDetails', () => {
  it('renders normally', async () => {
    const assignment = {
      name: 'an assignment',
      pointsPossible: 42,
      dueAt: 'some time',
      description: 'an assignment',
    }

    const container = render(<AssignmentToggleDetails description={assignment.description} />)
    const element = container.getByTestId('assignments-2-assignment-toggle-details-text')
    expect(element).toHaveTextContent(assignment.description)
  })

  it('renders normally an assignment with no content', async () => {
    const assignment = {
      name: 'an assignment',
      pointsPossible: 42,
      dueAt: 'some time',
    }

    const container = render(<AssignmentToggleDetails description={assignment.description} />)
    const element = container.getByTestId('assignments-2-assignment-toggle-details-text')
    expect(element).toHaveTextContent('No additional details were added for this assignment.')
  })
})
