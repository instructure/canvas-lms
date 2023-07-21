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

import LatePolicyStatusDisplay from '../LatePolicyStatusDisplay/index'
import React from 'react'
import {render} from '@testing-library/react'

describe('LatePolicyStatusDisplay', () => {
  it('renders -3 points for tooltip launch', () => {
    const {getByTestId, getByText} = render(
      <LatePolicyStatusDisplay
        attempt={1}
        grade="5"
        gradingType="points"
        originalGrade="8"
        pointsDeducted={3}
        pointsPossible={32}
      />
    )

    const latePolicyContainer = getByTestId('late-policy-container')

    expect(latePolicyContainer).toContainElement(getByText('Late Policy: minus 3 Points'))
    expect(latePolicyContainer).toContainElement(getByText('-3 Points'))
  })

  it('renders tip content correctly', () => {
    const {getByTestId, getByText} = render(
      <LatePolicyStatusDisplay
        attempt={2}
        grade="5"
        gradingType="points"
        originalGrade="8"
        pointsDeducted={3}
        pointsPossible={32}
      />
    )

    const tooltipContent = getByTestId('late-policy-tip-content')
    expect(tooltipContent).toContainElement(getByText('Attempt 2'))
    expect(tooltipContent).toContainElement(getByText('8/32'))
    expect(tooltipContent).toContainElement(getByText('Late Penalty'))
    expect(tooltipContent).toContainElement(getByText('-3'))
    expect(tooltipContent).toContainElement(getByText('Grade'))
    expect(tooltipContent).toContainElement(getByText('5/32'))
  })

  it('renders accessible tip content correctly', () => {
    const {getByTestId, getByText} = render(
      <LatePolicyStatusDisplay
        attempt={2}
        grade="5"
        originalGrade="8"
        gradingType="points"
        pointsDeducted={3}
        pointsPossible={32}
      />
    )

    const tooltipContent = getByTestId('late-policy-accessible-tip-content')
    expect(tooltipContent).toContainElement(
      getByText('Attempt 2: 8/32Late Penalty: minus 3 PointsGrade: 5/32')
    )
  })

  it('defaults to "None" if no value is given for pointsDeducted', () => {
    const {getByTestId, getByText} = render(
      <LatePolicyStatusDisplay
        attempt={2}
        grade="8"
        originalGrade="8"
        gradingType="points"
        pointsPossible={32}
      />
    )

    const tooltipContent = getByTestId('late-policy-accessible-tip-content')
    expect(tooltipContent).toContainElement(
      getByText('Attempt 2: 8/32Late Penalty: NoneGrade: 8/32')
    )
  })
})
