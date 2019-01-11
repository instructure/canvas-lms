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
import ReactDOM from 'react-dom'
import $ from 'jquery'

import LatePolicyStatusDisplay from '../LatePolicyStatusDisplay'

describe('LatePolicyStatusDisplay', () => {
  beforeAll(() => {
    const found = document.getElementById('fixtures')
    if (!found) {
      const fixtures = document.createElement('div')
      fixtures.setAttribute('id', 'fixtures')
      document.body.appendChild(fixtures)
    }
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
  })

  it('renders -3 points for tooltip launch', () => {
    ReactDOM.render(
      <LatePolicyStatusDisplay
        grade="5"
        gradingType="points"
        originalGrade="8"
        pointsDeducted={3}
        pointsPossible={32}
      />,
      document.getElementById('fixtures')
    )
    const container = $('[data-test-id="late-policy-container"]')
    // This is due to the SR content.  One is being rendered for normal text and the other is SR text
    expect(container.text()).toEqual('Late Policy:Late Policy: minus 3 Points-3 Points')
  })

  it('renders tip content correctly', () => {
    ReactDOM.render(
      <LatePolicyStatusDisplay
        grade="5"
        gradingType="points"
        originalGrade="8"
        pointsDeducted={3}
        pointsPossible={32}
      />,
      document.getElementById('fixtures')
    )
    // This is what we would normally call if the tooltip was loaded in a portal
    // given that it is not the content is loaded onto the screen at load time
    // which means we have no decent way to test the tool tip actually launching
    // and showing within js.  We are testing the integration of the tooltip launching
    // within selenium and will test the content showing correctly here.
    //
    // const tooltipLaunchLink = $('[data-test-id="late-policy-container"] a').focus()

    const tooltipContent = $('[data-test-id="late-policy-tip-content"]')
    expect(tooltipContent.text()).toEqual('Attempt 18/32Late Penalty-3Grade5/32')
  })

  it('renders accessible tip content correctly', () => {
    ReactDOM.render(
      <LatePolicyStatusDisplay
        grade="5"
        originalGrade="8"
        gradingType="points"
        pointsDeducted={3}
        pointsPossible={32}
      />,
      document.getElementById('fixtures')
    )
    // This is what we would normally call if the tooltip was loaded in a portal
    // given that it is not the content is loaded onto the screen at load time
    // which means we have no decent way to test the tool tip actually launching
    // and showing within js.  We are testing the integration of the tooltip launching
    // within selenium and will test the content showing correctly here.
    //
    // const tooltipLaunchLink = $('[data-test-id="late-policy-container"] a').focus()

    const tooltipContent = $('[data-test-id="late-policy-accessible-tip-content"]')
    expect(tooltipContent.text()).toEqual('Attempt 1: 8/32Late Penalty: minus 3 PointsGrade: 5/32')
  })
})
