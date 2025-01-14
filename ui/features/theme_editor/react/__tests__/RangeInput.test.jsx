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
import {createRoot} from 'react-dom/client'
import RangeInput from '../RangeInput'

const ok = value => expect(value).toBeTruthy()
const equal = (value, expected) => expect(value).toEqual(expected)

let elem, props

describe('RangeInput Component', () => {
  beforeEach(() => {
    elem = document.createElement('div')
    props = {
      min: 1,
      max: 10,
      defaultValue: 5,
      labelText: 'Input Label',
      name: 'input_name',
      formatValue: jest.fn(),
      onChange: jest.fn(),
    }
  })

  test('renders range input', () => {
    const ref = React.createRef()
    const root = createRoot(elem)
    root.render(<RangeInput {...props} ref={ref} />)
    const input = ref.current.rangeInput
    equal(input.type, 'range', 'renders range input')
    equal(String(input.value), String(props.defaultValue), 'renders default value')
    equal(input.name, props.name, 'renders with name from props')
  })

  test('renders formatted output', done => {
    const ref = React.createRef()
    const root = createRoot(elem)
    root.render(<RangeInput {...props} ref={ref} />)
    const expected = 47
    const expectedFormatted = '47%'
    props.formatValue.mockReturnValue(expectedFormatted)
    ref.current.setState({value: 47}, () => {
      const output = ref.current.outputElement
      ok(output, 'renders the output element')
      expect(props.formatValue).toHaveBeenCalledWith(expected)
      equal(output.textContent, expectedFormatted, 'outputs value')
      done()
    })
  })

  test('handleChange', () => {
    const ref = React.createRef()
    const root = createRoot(elem)
    root.render(<RangeInput {...props} ref={ref} />)
    jest.spyOn(ref.current, 'setState')
    const event = {target: {value: 8}}
    ref.current.handleChange(event)
    expect(ref.current.setState).toHaveBeenCalledWith({value: event.target.value})
    expect(props.onChange).toHaveBeenCalledWith(event.target.value)
  })
})
