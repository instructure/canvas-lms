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
import UnassessedAssignment from '../UnassessedAssignment'

it('properly renders the UnassessedAssignment component', () => {
  const props = {assignment: {id: 1, title: 'example', url: 'www.example.com'}}
  const {container} = render(<UnassessedAssignment {...props} />)
  expect(container).toHaveTextContent(/example \(not yet assessed\)/i)
})

it('properly renders with a quiz icon when submission type is online quiz', () => {
  const props = {
    assignment: {
      id: 1,
      title: 'example',
      url: 'www.example.com',
      submission_types: ['online_quiz'],
    },
  }
  const {container} = render(<UnassessedAssignment {...props} />)
  expect(container.querySelector('svg[name="IconQuiz"]')).toBeInTheDocument()
})
