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
import {mockAssignment} from '../../test-utils'
import Header from '../Header'

it('renders basic assignment information', () => {
  const assignment = mockAssignment()
  const {container, getByTestId} = render(<Header assignment={mockAssignment()} />)
  expect(container).toHaveTextContent(assignment.name)
  expect(container).toHaveTextContent(assignment.pointsPossible.toString())
  expect(getByTestId('teacher-toolbox')).toBeInTheDocument()
})
