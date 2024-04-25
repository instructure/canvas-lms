/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import LatePolicyGrade from '../LatePolicyGrade'

describe('LatePolicyGrade', () => {
  const subject = (
    enterGradesAs: 'points' | 'percent' | 'passFail' | 'gradingScheme' = 'percent',
    score = 7.345,
    grade = '7.345'
  ) => {
    const defaultProps = {
      assignment: {
        pointsPossible: 100,
      },
      submission: {
        score,
        grade,
        pointsDeducted: 3,
        excused: false,
        extended: false,
        late: false,
        missing: false,
        resubmitted: false,
        dropped: false,
      },
      enterGradesAs,
      gradingScheme: [
        ['A', 90],
        ['B', 80],
        ['C', 70],
      ],
      pointsBasedGradingScheme: false,
    }
    return render(<LatePolicyGrade {...defaultProps} />)
  }

  test('includes the late penalty as a negative value and rounds the final grade when a decimal value', () => {
    const wrapper = subject()
    expect(wrapper.container.querySelector('#late-penalty-value > span')!.innerHTML).toEqual('-3')
    expect(wrapper.container.querySelector('#final-grade-value > span')!.innerHTML).toEqual('7.35%')
  })

  test('formats the final grade as points when enterGradesAs is set to points', () => {
    const wrapper = subject('points')
    expect(wrapper.container.querySelector('#final-grade-value > span')!.innerHTML).toEqual('7.35')
  })

  test('formats the final grade as a letter grade when enterGradesAs is set to gradingScheme', () => {
    const wrapper = subject('gradingScheme')
    expect(wrapper.container.querySelector('#final-grade-value > span')!.innerHTML).toEqual('C')
  })

  test('formats the final grade as "Complete" when enterGradesAs is set to passFail and score > 0', () => {
    const wrapper = subject('passFail')
    expect(wrapper.container.querySelector('#final-grade-value > span')!.innerHTML).toEqual(
      'Complete'
    )
  })

  test('formats the final grade as "Incomplete" when enterGradesAs is set to passFail and score == 0', () => {
    const wrapper = subject('passFail', 0, '0')
    expect(wrapper.container.querySelector('#final-grade-value > span')!.innerHTML).toEqual(
      'Incomplete'
    )
  })
})
