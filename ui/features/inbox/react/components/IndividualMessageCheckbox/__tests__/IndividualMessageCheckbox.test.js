/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import {IndividualMessageCheckbox} from '../IndividualMessageCheckbox'

const setup = props => {
  const utils = render(<IndividualMessageCheckbox onChange={() => {}} {...props} />)
  const individualCheckbox = utils.container.querySelector('input')
  return {individualCheckbox}
}

describe('Button', () => {
  it('renders', () => {
    const {individualCheckbox} = setup()
    expect(individualCheckbox).toBeTruthy()
  })

  it('should call onChange when typing occurs', () => {
    const onChangeMock = jest.fn()
    const {individualCheckbox} = setup({
      onChange: onChangeMock
    })
    fireEvent.click(individualCheckbox)
    expect(onChangeMock.mock.calls.length).toBe(1)
  })

  it('should show checkbox as checked when prop is present', () => {
    const {individualCheckbox} = setup({
      checked: true
    })
    expect(individualCheckbox.checked).toBe(true)
  })

  it('should not show checkbox as checked when prop is missing', () => {
    const {individualCheckbox} = setup()
    expect(individualCheckbox.checked).toBe(false)
  })
})
