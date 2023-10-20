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
import {SubjectInput} from '../SubjectInput'

const setup = props => {
  const utils = render(<SubjectInput onChange={() => {}} {...props} />)
  const subjectInput = utils.container.querySelector('input')
  return {subjectInput}
}

describe('Button', () => {
  it('renders', () => {
    const {subjectInput} = setup()
    expect(subjectInput).toBeTruthy()
  })

  it('should call onChange when typing occurs', () => {
    const onChangeMock = jest.fn()
    const {subjectInput} = setup({
      onChange: onChangeMock,
    })
    fireEvent.change(subjectInput, {target: {value: '42'}})
    expect(onChangeMock.mock.calls.length).toBe(1)
  })

  it('should call onBlur when blur event triggered', () => {
    const onBlurMock = jest.fn()
    const {subjectInput} = setup({
      onBlur: onBlurMock,
    })
    fireEvent.focus(subjectInput)
    fireEvent.blur(subjectInput)
    expect(onBlurMock.mock.calls.length).toBe(1)
  })

  it('should call onFocus when focus event triggered', () => {
    const onFocusMock = jest.fn()
    const {subjectInput} = setup({
      onFocus: onFocusMock,
    })
    fireEvent.focus(subjectInput)
    fireEvent.blur(subjectInput)
    expect(onFocusMock.mock.calls.length).toBe(1)
  })
})
