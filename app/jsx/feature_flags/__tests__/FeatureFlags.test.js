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
import {render, wait} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import FeatureFlags from '../FeatureFlags'
import sampleData from './sampleData.json'

const rows = [
  sampleData.allowedOnFeature,
  sampleData.allowedFeature,
  sampleData.onFeature,
  sampleData.offFeature
]

describe('feature_flags::FeatureFlags', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  beforeEach(() => {
    ENV.CONTEXT_BASE_URL = '/accounts/1'
    const route = `/api/v1${ENV.CONTEXT_BASE_URL}/features?hide_inherited_enabled=true&per_page=50`
    fetchMock.getOnce(route, JSON.stringify(rows))
  })

  it('Renders all the appropriate sections', async () => {
    const {getAllByText, queryByText} = render(<FeatureFlags />)
    await wait(() => expect(getAllByText('Account')[0]).toBeInTheDocument())
    expect(getAllByText('Course')[0]).toBeInTheDocument()
    expect(getAllByText('User')[0]).toBeInTheDocument()
    expect(queryByText('Site Admin')).not.toBeInTheDocument()
  })
})
