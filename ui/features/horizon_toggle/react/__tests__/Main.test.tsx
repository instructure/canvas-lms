/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {Main} from '../Main'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('Main', () => {
  const setup = (propOverrides = {}) => {
    const props = {
      isAccountPage: false,
      courseId: '3',
      isHorizonCourse: false,
      isHorizonAccount: false,
      hasCourses: false,
      accountId: '123',
      horizonAccountLocked: false,
      ...propOverrides,
    }
    return render(<Main {...props} />)
  }

  it('renders account-specific content when isAccountPage is true', () => {
    setup({
      isAccountPage: true,
      hasCourses: true,
    })
    expect(screen.getByText(/Existing courses must be removed/)).toBeInTheDocument()
  })

  it('renders HorizonAccount when isHorizonAccount is false', () => {
    setup({
      isAccountPage: true,
      isHorizonAccount: false,
    })
    expect(screen.getByText(/Canvas Career is a new LMS experience/)).toBeInTheDocument()
    expect(screen.queryByText('Revert Sub Account')).not.toBeInTheDocument()
  })

  it('renders RevertAccount when isHorizonAccount is true', () => {
    setup({
      isAccountPage: true,
      isHorizonAccount: true,
    })
    const revertButton = screen
      .getAllByText('Revert Sub Account')
      .find(element => element.tagName === 'SPAN')

    expect(revertButton).not.toBeUndefined()
    expect(screen.queryByText(/Canvas Career is a new LMS experience/)).not.toBeInTheDocument()
  })
})
