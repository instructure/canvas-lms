/*
 * Copyright (C) 2019 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 *
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
import {getByText as domGetByText, queryByText as domQueryByText} from '@testing-library/dom'
import CanvasAsyncSelect from '../AsyncSelect'

function selectElement({options = [], ...props} = {}) {
  return (
    <CanvasAsyncSelect renderLabel="choose one" {...props}>
      {options.map(option => (
        <CanvasAsyncSelect.Option key={option.id} id={option.id}>
          {option.label}
        </CanvasAsyncSelect.Option>
      ))}
    </CanvasAsyncSelect>
  )
}

function renderSelect(props = {}, container) {
  const results = render(selectElement(props), {container})
  const input = results.getByLabelText(props.renderLabel || 'choose one')
  return {input, ...results}
}

describe('CanvasAsyncSelect', () => {
  let ariaLive

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  it('renders the no options state', () => {
    const {input, getByText} = renderSelect({noOptionsLabel: 'testing no options'})
    fireEvent.click(input)
    expect(getByText('testing no options')).toBeInTheDocument()
  })

  it('renders the loading state', () => {
    const {input, getByText} = renderSelect({isLoading: true})
    fireEvent.click(input)
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('announces the loading state when it has focus and isLoading becomes true', () => {
    const {input, rerender} = renderSelect({isLoading: false})
    fireEvent.focus(input)
    rerender(selectElement({isLoading: true}))
    expect(domGetByText(ariaLive, /loading/i)).toBeInTheDocument()
  })

  it('announces loading complete with the number of options', () => {
    const {input, rerender} = renderSelect({isLoading: true})
    fireEvent.focus(input)
    rerender(
      selectElement({
        isLoading: false,
        options: [
          {id: 'foo', label: 'bar'},
          {id: 'baz', label: 'bing'},
        ],
      })
    )
    expect(domGetByText(ariaLive, /2 options loaded/i)).toBeInTheDocument()
  })

  it('does not do announcements if it does not have focus', () => {
    const {input, rerender} = renderSelect({isLoading: false})
    fireEvent.focus(input)
    fireEvent.blur(input)
    rerender(selectElement({isLoading: true}))
    expect(domQueryByText(ariaLive, /loading/i)).toBe(null)
    rerender(
      selectElement({
        isLoading: false,
        options: [
          {id: 'foo', label: 'bar'},
          {id: 'baz', label: 'bing'},
        ],
      })
    )
    expect(domQueryByText(ariaLive, /options loaded/i)).toBe(null)
  })

  it('shows the options on input change', () => {
    const handleInputChange = jest.fn()
    const {input, getByText} = renderSelect({onInputChange: handleInputChange})
    fireEvent.change(input, {target: {value: 'abc'}})
    expect(getByText('---')).toBeInTheDocument()
  })

  it('reports changes to the input', () => {
    const handleInputChange = jest.fn()
    const {input} = renderSelect({onInputChange: handleInputChange})
    fireEvent.change(input, {target: {value: 'abc'}})
    expect(handleInputChange).toHaveBeenCalledWith(expect.anything(), 'abc')
  })

  it('displays the specified options and reports selections', () => {
    const handleOptionSelected = jest.fn()
    const {input, getByText} = renderSelect({
      onOptionSelected: handleOptionSelected,
      options: [{id: 'foo', label: 'bar'}],
    })
    fireEvent.click(input)
    const option = getByText('bar')
    fireEvent.click(option)
    expect(handleOptionSelected).toHaveBeenCalledWith(expect.anything(), 'foo')
  })

  it('announces the selected option', () => {
    const {input, getByText} = renderSelect({
      options: [{id: 'foo', label: 'bar'}],
    })
    fireEvent.click(input)
    const option = getByText('bar')
    fireEvent.click(option)
    expect(domGetByText(ariaLive, /option selected.+bar.+list collapsed/i)).toBeInTheDocument()
  })
})
