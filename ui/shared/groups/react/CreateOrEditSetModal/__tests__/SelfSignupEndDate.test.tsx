/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import SelfSignupEndDate from '../SelfSignupEndDate'

const onDatechangeMock = jest.fn()
const component = (overrides = {}) => {
  const props = {
    initialEndDate: '',
    onDateChange: onDatechangeMock,
    breakpoints: {},
    ...overrides,
  }
  return <SelfSignupEndDate {...props} />
}

describe('CreateOrEditSetModal::SelfSignup::', () => {
  beforeEach(() => {
    onDatechangeMock.mockReset()
  })

  it('fires handler for Self Signup click', async () => {
    const {getByLabelText, findByText} = render(component())
    const dateInput = getByLabelText('Self Sign-up Deadline')
    fireEvent.change(dateInput, {target: {value: 'Oct 30, 2024'}})

    const option = await findByText(/30 October 2024/i)
    option.click()

    await waitFor(() => {
      expect(onDatechangeMock).toHaveBeenCalled()
    });
  })
})
