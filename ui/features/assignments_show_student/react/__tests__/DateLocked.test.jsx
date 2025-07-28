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
import {render} from '@testing-library/react'
import DateLocked from '../DateLocked'

describe('DateLocked', () => {
  it('renders normally', () => {
    const container = render(<DateLocked date="TEST" type="assignment" />)
    const element = container.getByTestId('assignments-2-date-locked')
    expect(element).toBeInTheDocument()
  })

  it('includes date in lock reason text', () => {
    const container = render(<DateLocked date="2020-07-04T19:30:00-01:00" type="assignment" />)
    expect(
      container.getByText('This assignment is locked until Jul 4, 2020 at 8:30pm.')
    ).toBeInTheDocument()
  })
})
