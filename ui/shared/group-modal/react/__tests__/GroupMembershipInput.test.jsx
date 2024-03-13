// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import GroupMembershipInput from '../GroupMembershipInput'

describe('GroupMembershipInput', () => {
  it('handles input value change', () => {
    const onChange = jest.fn()
    const {getByLabelText} = render(<GroupMembershipInput onChange={onChange} value="" />)
    const input = getByLabelText(/Group Membership/i)
    fireEvent.input(input, {target: {value: '5'}})
    expect(onChange).toHaveBeenNthCalledWith(2, 5)
  })

  it('handles incrementing the number input', async () => {
    const onChange = jest.fn()
    const {container} = render(<GroupMembershipInput onChange={onChange} value="" />)
    const upArrow = container.querySelector("svg[name='IconArrowOpenUp']").parentElement
    await userEvent.click(upArrow)
    expect(onChange).toHaveBeenNthCalledWith(2, 1)
  })

  it('handles decrementing the number input', async () => {
    const onChange = jest.fn()
    const {container} = render(<GroupMembershipInput onChange={onChange} value="3" />)
    const downArrow = container.querySelector("svg[name='IconArrowOpenDown']").parentElement
    await userEvent.click(downArrow)
    expect(onChange).toHaveBeenNthCalledWith(2, 2)
  })

  it('allows deletion of input if value is less than 10', () => {
    const onChange = jest.fn()
    const {getByPlaceholderText} = render(<GroupMembershipInput onChange={onChange} value="" />)
    const input = getByPlaceholderText('Number')
    fireEvent.input(input, {target: {value: '9'}})
    fireEvent.keyDown(input, {key: 'Backspace', code: 8})
    expect(onChange).toHaveBeenNthCalledWith(4, '')
  })

  it('allows deletion of prior input if value is less than 10', () => {
    const onChange = jest.fn()
    const {getByPlaceholderText} = render(<GroupMembershipInput onChange={onChange} value="2" />)
    fireEvent.keyDown(getByPlaceholderText('Number'), {key: 'Backspace', code: 8})
    expect(onChange).toHaveBeenNthCalledWith(2, '')
  })

  describe('errors', () => {
    it('returns an error if input is greater than set maximum', () => {
      const onChange = jest.fn()
      const {getByText, getByLabelText} = render(
        <GroupMembershipInput onChange={onChange} value="" />
      )
      const input = getByLabelText(/Group Membership/i)
      fireEvent.input(input, {target: {value: '999999'}})
      expect(getByText(/Number must be between/i)).toBeInTheDocument()
    })

    it('returns an error if input is less than set minimum', () => {
      const onChange = jest.fn()
      const {getByText, getByLabelText} = render(
        <GroupMembershipInput onChange={onChange} value="" />
      )
      const input = getByLabelText(/Group Membership/i)
      fireEvent.input(input, {target: {value: '0'}})
      expect(getByText(/Number must be between/i)).toBeInTheDocument()
    })

    it('returns an error if input is not a number', () => {
      const onChange = jest.fn()
      const {getByText, getByLabelText} = render(
        <GroupMembershipInput onChange={onChange} value="" />
      )
      const input = getByLabelText(/Group Membership/i)
      fireEvent.input(input, {target: {value: 'F'}})
      expect(getByText(/not a valid number/i)).toBeInTheDocument()
    })
  })
})
