// /*
//  * Copyright (C) 2020 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

import React from 'react'
import {render, act, fireEvent} from '@testing-library/react'

import FeatureFlagTable from '../FeatureFlagTable'
import sampleData from './sampleData.json'

const rows = {
  feature_option: [
    sampleData.allowedOnFeature,
    sampleData.betaFeature,
    sampleData.onFeature,
    sampleData.offFeature,
    sampleData.pendingEnforcementOnFeature,
    sampleData.pendingEnforcementOffFeature
  ],
  setting: [sampleData.allowedFeature]
}
const title = 'Section 123'

describe('feature_flags::FeatureFlagTable', () => {
  beforeEach(() => {
    window.ENV = {FEATURES: {feature_flag_filters: true}}
  })

  afterEach(() => {
    window.ENV = {}
  })

  it('Shows the title', () => {
    const {getByTestId} = render(<FeatureFlagTable rows={rows} title={title} showTitle />)

    expect(getByTestId('ff-table-heading')).toHaveTextContent(title)
  })

  it('Sorts the features within groups', () => {
    const {getAllByTestId} = render(<FeatureFlagTable rows={rows} title={title} />)

    // Feature option
    expect(getAllByTestId('ff-table-row')[0]).toHaveTextContent('Beta Feature')
    expect(getAllByTestId('ff-table-row')[1]).toHaveTextContent('Feature 2')
    expect(getAllByTestId('ff-table-row')[2]).toHaveTextContent('Feature 3')
    expect(getAllByTestId('ff-table-row')[3]).toHaveTextContent('Feature 4')
    expect(getAllByTestId('ff-table-row')[4]).toHaveTextContent(
      'Feature with Pending Enforcement Off'
    )
    expect(getAllByTestId('ff-table-row')[5]).toHaveTextContent(
      'Feature with Pending Enforcement On'
    )
    // Setting
    expect(getAllByTestId('ff-table-row')[6]).toHaveTextContent('Feature 1')
  })

  it('Includes the descriptions, respecting autoexpand', () => {
    const {queryByText} = render(<FeatureFlagTable rows={rows} title={title} />)

    expect(queryByText('This does great feature1y things')).not.toBeInTheDocument()
    expect(queryByText('This does great feature4y things')).toBeInTheDocument()
  })

  it('Includes the enable_at date if pending_enforcement is enabled', () => {
    const {getByText} = render(<FeatureFlagTable rows={rows} title={title} />)
    const featureToggle = getByText('Feature with Pending Enforcement On')
    act(() => {
      fireEvent.click(featureToggle)
    })
    expect(getByText('Pending Enforcement')).toBeInTheDocument()
    expect(getByText('Aug 23, 2021')).toBeInTheDocument()
    expect(getByText('This feature has pending enforcement on')).toBeInTheDocument()
  })

  it('does not show the enable_at date if pending_enforcement is disabled', () => {
    const {getByText, queryByText} = render(<FeatureFlagTable rows={rows} title={title} />)
    const featureToggle = getByText('Feature with Pending Enforcement Off')
    act(() => {
      fireEvent.click(featureToggle)
    })
    expect(queryByText('Aug 23, 2021')).not.toBeInTheDocument()
    expect(getByText('This feature has pending enforcement off')).toBeInTheDocument()
  })

  it('includes tooltips for active development and pending enforcement', () => {
    const {getByText} = render(<FeatureFlagTable rows={rows} title={title} />)
    expect(
      getByText(
        'Features in active development — opting in includes ongoing updates outside the regular release schedule'
      )
    ).toBeInTheDocument()
    expect(
      getByText(
        'Features no longer in active development that include a date when they will be turned on by default'
      )
    ).toBeInTheDocument()
  })
})
