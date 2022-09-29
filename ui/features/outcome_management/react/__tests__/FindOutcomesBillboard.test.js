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

import React from 'react'
import {render as realRender} from '@testing-library/react'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import FindOutcomesBillboard from '../FindOutcomesBillboard'

describe('FindOutcomesBillboard', () => {
  const render = (children, {contextType = 'Course', contextId = '1'} = {}) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        {children}
      </OutcomesContext.Provider>
    )
  }

  it('renders correct message and icon when context is Course', () => {
    const {getByText, queryByTestId} = render(<FindOutcomesBillboard />)
    expect(getByText(/Save yourself a lot of time by only/)).toBeInTheDocument()
    expect(queryByTestId('clipboard-checklist-icon')).toBeInTheDocument()
  })

  it('renders correct message and icon when context is Account', () => {
    const {getByText, queryByTestId} = render(<FindOutcomesBillboard />, {
      contextType: 'Account',
    })
    expect(getByText(/Select a group to reveal outcomes here/)).toBeInTheDocument()
    expect(queryByTestId('outcomes-icon')).toBeInTheDocument()
  })
})
