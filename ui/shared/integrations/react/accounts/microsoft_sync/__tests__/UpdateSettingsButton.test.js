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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import UpdateSettingsButton from '../components/UpdateSettingsButton'

describe('UpdateSettingsButton', () => {
  const handleClickMock = jest.fn()

  const setup = () => {
    return render(<UpdateSettingsButton handleClick={handleClickMock} />)
  }
  it('renders without errors', () => {
    const container = setup()
    expect(container.error).toBeFalsy()
  })

  it('calls the passed in function when clicked', () => {
    const container = setup()
    fireEvent.click(container.getByText(/update settings/i))
    expect(handleClickMock).toHaveBeenCalledTimes(1)
  })
})
