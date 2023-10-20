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

import {render} from '@testing-library/react'
import React from 'react'
import Essay from '../essay'

describe('canvas_quizzes/statistics/views/questions/essay', () => {
  it('renders', () => {
    render(<Essay />)
  })

  it('renders a link to speedgrader', function () {
    const speedGraderUrl = 'http://localhost/courses/1/gradebook/speed_grader?assignment_id=10'
    const {getByText} = render(<Essay speedGraderUrl={speedGraderUrl} />)
    const link = getByText('View in SpeedGrader')

    expect(link.href).toBe(speedGraderUrl)
    expect(link.target).toBe('_blank')
  })

  it('does not render a link to speed grader when url is absent', () => {
    const {getByText} = render(<Essay />)

    try {
      getByText('View in SpeedGrader')
      expect(false).toBe(true)
    } catch (e) {
      // no-op
    }
  })
})
