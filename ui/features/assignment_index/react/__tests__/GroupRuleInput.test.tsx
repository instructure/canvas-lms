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
import { render, screen, fireEvent } from '@testing-library/react'
import GroupRuleInput, { GroupRuleInputProps } from '../GroupRuleInput'

const setup = (props?: Partial<GroupRuleInputProps>) => {
  const defaultProps: GroupRuleInputProps = {
    groupId: 1,
    type: 'drop_lowest',
    initialValue: '5',
    onBlur: jest.fn(),
    onChange: jest.fn()
  }
  return render(<GroupRuleInput {...defaultProps} {...props} />)
}

describe('GroupRuleInput', () => {
  test('sets initial value correctly', () => {
    setup({ initialValue: '3' })
    const input = screen.getByTestId('ag_1_drop_lowest') as HTMLInputElement
    expect(input.value).toBe('3')
  })

  test('calls onChange when input value changes', () => {
    const onChangeMock = jest.fn()
    setup({ onChange: onChangeMock })
    const input = screen.getByTestId('ag_1_drop_lowest') as HTMLInputElement

    fireEvent.change(input, { target: { value: '10' } })
    expect(onChangeMock).toHaveBeenCalled()
    expect(input.value).toBe('10')
  })

  test('calls onBlur when input loses focus', () => {
    const onBlurMock = jest.fn()
    setup({ onBlur: onBlurMock })
    const input = screen.getByTestId('ag_1_drop_lowest')

    fireEvent.blur(input)
    expect(onBlurMock).toHaveBeenCalled()
  })
})
