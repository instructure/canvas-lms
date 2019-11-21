/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import React from 'react'

import SingleSelect from '../shared/SingleSelect'

function makeProps() {
  return {
    liveRegion: () => document.getElementById('flash_screenreader_holder'),
    options: [{id: '1', label: 'foo'}, {id: '2', label: 'bar'}, {id: '3', label: 'baz'}],
    selectedOption: () => {},
    renderLabel: <>Test Label</>
  }
}

describe('SingleSelect', () => {
  beforeAll(() => {
    const node = document.createElement('div')
    node.setAttribute('role', 'alert')
    node.setAttribute('id', 'flash_screenreader_holder')
    document.body.appendChild(node)
  })

  it('renders the first item by default', () => {
    const {getByDisplayValue} = render(<SingleSelect {...makeProps()} />)
    expect(getByDisplayValue('foo')).toBeInTheDocument()
  })

  it('renders the select list when clicked', () => {
    const {getByDisplayValue, getByText} = render(<SingleSelect {...makeProps()} />)
    fireEvent.click(getByDisplayValue('foo'))
    expect(getByText('foo')).toBeInTheDocument()
    expect(getByText('bar')).toBeInTheDocument()
    expect(getByText('baz')).toBeInTheDocument()
  })

  it('changes the selected on click', () => {
    const props = makeProps()
    const callback = jest.fn()
    props.selectedOption = callback
    const {getByDisplayValue, getByText} = render(<SingleSelect {...props} />)
    fireEvent.click(getByDisplayValue('foo'))
    fireEvent.click(getByText('bar'))
    expect(getByDisplayValue('bar')).toBeInTheDocument()
    expect(callback).toHaveBeenCalledTimes(1)
    expect(callback).toHaveBeenCalledWith({selectedOptionId: '2', inputValue: 'bar'})
  })
})
