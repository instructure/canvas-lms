/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import OriginalityReport from '../OriginalityReport'
import {render} from '@testing-library/react'
import React from 'react'

const props = {
  originalityData: {
    score: 75,
    state: 'problem',
    reporUrl: 'http://example.com',
    status: 'scored',
    data: '{}',
  },
}

describe('OriginalityReport', () => {
  it('renders originality report with given turnitin_data', async () => {
    const {getByTestId} = render(<OriginalityReport {...props} />)
    expect(getByTestId('originality_report')).toBeInTheDocument()
  })

  it('renders originality report with displayed originality score as a percent', async () => {
    const {getByTestId} = render(<OriginalityReport {...props} />)
    expect(getByTestId('originality_report').textContent).toBe('75%')
  })

  it('renders originality report_url linked', async () => {
    const {getByTestId} = render(<OriginalityReport {...props} />)
    expect(getByTestId('originality_report_url')).toBeInTheDocument()
  })
})
