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
import {render} from '@testing-library/react'

import FeatureFlagTable from '../FeatureFlagTable'
import sampleData from './sampleData.json'

const rows = [
  sampleData.allowedOnFeature,
  sampleData.allowedFeature,
  sampleData.onFeature,
  sampleData.offFeature
]
const title = 'Section 123'

describe('feature_flags::FeatureFlagTable', () => {
  it('Shows the title', () => {
    const {getByTestId} = render(<FeatureFlagTable rows={rows} title={title} />)

    expect(getByTestId('ff-table-heading')).toHaveTextContent(title)
  })

  it('Sorts the features', () => {
    const {getAllByTestId} = render(<FeatureFlagTable rows={rows} title={title} />)

    expect(getAllByTestId('ff-table-row')[0]).toHaveTextContent('Feature 1')
    expect(getAllByTestId('ff-table-row')[1]).toHaveTextContent('Feature 2')
    expect(getAllByTestId('ff-table-row')[2]).toHaveTextContent('Feature 3')
    expect(getAllByTestId('ff-table-row')[3]).toHaveTextContent('Feature 4')
  })

  it('Includes the descriptions, respecting autoexpand', () => {
    const {queryByText} = render(<FeatureFlagTable rows={rows} title={title} />)

    expect(queryByText('This does great feature1y things')).not.toBeInTheDocument()
    expect(queryByText('This does great feature4y things')).toBeInTheDocument()
  })
})
