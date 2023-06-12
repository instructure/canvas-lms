// @ts-nocheck
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
import {render, fireEvent} from '@testing-library/react'
import MultiSelectSearchInput from '../MultiSelectSearchInput'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('MultiSelectSearchInput', () => {
  let props

  beforeEach(() => {
    props = {
      id: 'my-multi-select',
      label: 'Delicious Vegetables',
      disabled: false,
      onChange: jest.fn(),
      options: [
        {id: '1', text: 'Broccoli'},
        {id: '2', text: 'Cucumber'},
      ],
      placeholder: 'Select a veggie',
    }
  })

  it('renders a menu option for each provided option', () => {
    const {getByLabelText, getByRole} = render(<MultiSelectSearchInput {...props} />)
    const menu = getByLabelText('Delicious Vegetables')
    fireEvent.click(menu)
    expect(getByRole('option', {name: 'Broccoli'})).toBeInTheDocument()
    expect(getByRole('option', {name: 'Cucumber'})).toBeInTheDocument()
  })

  it('displays a removable tag for selected options', () => {
    const {getByLabelText, getByRole, getByTitle} = render(<MultiSelectSearchInput {...props} />)
    const menu = getByLabelText('Delicious Vegetables')
    fireEvent.click(menu)
    const broccoliOption = getByRole('option', {name: 'Broccoli'})
    fireEvent.click(broccoliOption)
    const tag = getByTitle('Remove Broccoli')
    expect(tag).toBeInTheDocument()
  })

  it('calls onChange when an option is selected', () => {
    const {getByLabelText, getByRole} = render(<MultiSelectSearchInput {...props} />)
    const menu = getByLabelText('Delicious Vegetables')
    fireEvent.click(menu)
    const broccoliOption = getByRole('option', {name: 'Broccoli'})
    fireEvent.click(broccoliOption)
    expect(props.onChange).toHaveBeenLastCalledWith(['1'])
  })

  it('calls onChange when an option is deselected', () => {
    const {getByLabelText, getByRole, getByTitle} = render(<MultiSelectSearchInput {...props} />)
    const menu = getByLabelText('Delicious Vegetables')
    fireEvent.click(menu)
    const broccoliOption = getByRole('option', {name: 'Broccoli'})
    fireEvent.click(broccoliOption)
    fireEvent.click(menu)
    const cucumberOption = getByRole('option', {name: 'Cucumber'})
    fireEvent.click(cucumberOption)
    const tag = getByTitle('Remove Broccoli')
    fireEvent.click(tag)
    expect(props.onChange).toHaveBeenLastCalledWith(['2'])
  })

  it('disables the menu when passed disabled: true', () => {
    props.disabled = true
    const {getByLabelText} = render(<MultiSelectSearchInput {...props} />)
    const menu = getByLabelText('Delicious Vegetables')
    expect(menu).toBeDisabled()
  })
})
