/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import SelectButton from '../select-button'

const defaultProps = () => ({
  isSelected: false,
  isDisabled: false,
  onSelect: jest.fn(),
})

describe('SelectButton', () => {
  it('renders the button component', () => {
    const props = defaultProps()
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    expect(button).toBeInTheDocument()
  })

  it('renders as primary button when not selected or disabled', () => {
    const props = defaultProps()
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    expect(button).toHaveClass('btn-primary')
  })

  it('shows selected state when selected', () => {
    const props = defaultProps()
    props.isSelected = true
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    expect(button).toHaveClass('cmp-button__selected')
  })

  it('shows disabled state when disabled', () => {
    const props = defaultProps()
    props.isDisabled = true
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    expect(button).toHaveClass('cmp-button__disabled')
  })

  it('calls onSelect when clicked', () => {
    const props = defaultProps()
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    fireEvent.click(button)
    expect(props.onSelect).toHaveBeenCalled()
  })

  it('does not call onSelect when disabled', () => {
    const props = defaultProps()
    props.isDisabled = true
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    fireEvent.click(button)
    expect(props.onSelect).not.toHaveBeenCalled()
  })

  it('has correct text content when selected', () => {
    const props = defaultProps()
    props.isSelected = true
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    expect(button).toHaveTextContent('Selected')
  })

  it('has correct text content when not selected', () => {
    const props = defaultProps()
    const {getByTestId} = render(<SelectButton {...props} />)

    const button = getByTestId('select-button')
    expect(button).toHaveTextContent('Select')
  })
})
