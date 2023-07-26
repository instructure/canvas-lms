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

import React from 'react'
import {render as realRender, act} from '@testing-library/react'
import AlignmentSummary from '../index'
import {createCache} from '@canvas/apollo'
import {MockedProvider} from '@apollo/react-testing'
import {courseAlignmentStatsMocks} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'

describe('AlignmentSummary', () => {
  let cache

  beforeEach(() => {
    jest.useFakeTimers()
    cache = createCache()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {
      contextType = 'Course',
      contextId = '1',
      rootOutcomeGroup = {id: '1'},
      mocks = courseAlignmentStatsMocks(),
    } = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId, rootOutcomeGroup}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders single loader while loading data', () => {
    const {getByTestId, queryByTestId} = render(<AlignmentSummary />)
    expect(getByTestId('outcome-alignment-summary-loader')).toBeInTheDocument()
    expect(queryByTestId('outcome-item-list-loader')).not.toBeInTheDocument()
  })

  it('renders component after data is loaded', async () => {
    const {getByTestId} = render(<AlignmentSummary />)
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByTestId('outcome-alignment-summary')).toBeInTheDocument()
  })
})
