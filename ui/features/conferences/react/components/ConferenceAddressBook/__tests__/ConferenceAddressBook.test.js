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
import {fireEvent, render} from '@testing-library/react'
import {ConferenceAddressBook} from '../ConferenceAddressBook'

describe('ConferenceAddressBook', () => {
  const menuItemList = [
    {displayName: 'Allison', id: '7'},
    {displayName: 'Caleb', id: '3'},
    {displayName: 'Chawn', id: '2'}
  ]

  const setup = (props = {}) => {
    return render(<ConferenceAddressBook menuItemList={menuItemList} {...props} />)
  }

  it('should render', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('should open when clicked', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    expect(item).toBeTruthy()
  })

  it('should filter when input is recieved', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    fireEvent.change(input, {target: {value: 'Caleb'}})
    const item = container.queryByText('Allison')
    expect(item).toBeFalsy()
  })

  it('should add tag when user is selected', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    item.click()
    const tag = container.getByTestId('address-tag')
    expect(tag).toBeTruthy()
  })

  it('should render initial tags when selectedIds is passed', () => {
    const container = setup({selectedIds: ['2']})
    const tag = container.getByTestId('address-tag')
    expect(tag).toBeTruthy()
  })

  it('should remove selected user when backspace is pressed and input is empty', () => {
    const container = setup()
    const input = container.getByTestId('address-input')
    input.click()
    const item = container.getByText('Allison')
    item.click()
    fireEvent.keyDown(input, {keyCode: '8'})
    const tag = container.queryByTestId('address-tag')
    expect(tag).toBeFalsy()
  })
})
