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
import RangeInput from '../RangeInput'

describe('RangeInput Component', () => {
  const defaultProps = {
    min: 1,
    max: 10,
    defaultValue: 5,
    labelText: 'Input Label',
    name: 'input_name',
    formatValue: jest.fn(value => `${value}%`),
    onChange: jest.fn(),
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders with default props', () => {
    const {getByLabelText, getByText} = render(<RangeInput {...defaultProps} />)

    const slider = getByLabelText(defaultProps.labelText)
    expect(slider).toBeInTheDocument()
    expect(slider).toHaveAttribute('type', 'range')
    expect(slider).toHaveAttribute('name', defaultProps.name)
    expect(slider).toHaveAttribute('value', String(defaultProps.defaultValue))

    expect(getByText('5%')).toBeInTheDocument()
  })

  it('updates value and calls onChange when slider value changes', () => {
    const {getByLabelText} = render(<RangeInput {...defaultProps} />)

    const slider = getByLabelText(defaultProps.labelText)
    fireEvent.change(slider, {target: {value: '8'}})

    expect(defaultProps.onChange).toHaveBeenCalledWith('8')
    expect(defaultProps.formatValue).toHaveBeenCalledWith('8')
  })

  it('formats the output value correctly', () => {
    const {getByText} = render(<RangeInput {...defaultProps} />)
    expect(getByText('5%')).toBeInTheDocument()
  })

  it('applies min, max, and step constraints', () => {
    const props = {
      ...defaultProps,
      step: 2,
    }
    const {getByLabelText} = render(<RangeInput {...props} />)

    const slider = getByLabelText(props.labelText)
    expect(slider).toHaveAttribute('min', String(props.min))
    expect(slider).toHaveAttribute('max', String(props.max))
    expect(slider).toHaveAttribute('step', String(props.step))
  })
})
