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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import Subject from '../SearchableSelect'

const LABEL = 'Start typing, fool'

const options = [
  {id: '1', name: 'one is lonely'},
  {id: '2', name: 'two for real'},
  {id: '3', name: 'three on a match'},
  {id: '4', name: '   four score and seven'}
]

function makeProps(isLoading) {
  return {
    options,
    isLoading,
    onChange: jest.fn(),
    label: LABEL
  }
}

function renderSubject(isLoading = false) {
  const subjectProps = makeProps(isLoading)
  const results = render(<Subject {...subjectProps} />)
  const input = results.getByLabelText(LABEL)
  return {subjectProps, input, ...results}
}

describe('SearchableSelect', () => {
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

  it('renders a Select with the proper label', () => {
    const {getByText} = renderSubject()
    const result = getByText(LABEL)
    expect(result).toBeInTheDocument()
    expect(result.tagName).toBe('SPAN')
  })

  it('respects isLoading', () => {
    const {input, getByText} = renderSubject(true)
    fireEvent.click(input)
    expect(getByText(/Loading options/)).toBeInTheDocument()
  })

  it('renders a placeholder for the input', () => {
    const {getByPlaceholderText} = render(<Subject {...makeProps()} />)
    expect(getByPlaceholderText('Begin typing to search')).toBeInTheDocument()
  })

  it('responds to a click by showing the whole list of options', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    options.forEach(opt => {
      expect(getByText(opt.name.trim())).toBeInTheDocument()
    })
  })

  it('controls the input value properly', () => {
    const {input, getByDisplayValue} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'something'}})
    expect(getByDisplayValue('something')).toBeInTheDocument()
  })

  it('filters the results based on typing', () => {
    const {input, queryByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 't'}})
    expect(queryByText('one is lonely')).toBeNull()
    expect(queryByText('two for real')).toBeInTheDocument()
    expect(queryByText('three on a match')).toBeInTheDocument()
    expect(queryByText('four score and seven')).toBeNull()
  })

  it('shows a no results message if nothing matches the typing', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'will not match'}})
    expect(getByText('No matches to your search')).toBeInTheDocument()
  })

  it('calls onChange with the right id when an option is clicked', () => {
    const {subjectProps, input, getByText} = renderSubject()
    fireEvent.click(input)
    const opt = getByText('three on a match')
    fireEvent.click(opt)
    expect(subjectProps.onChange).toHaveBeenCalledWith(expect.anything(), '3')
  })

  it('does not call onChange when blurring after typing if results are ambiguous', () => {
    const {subjectProps, input, getByDisplayValue} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 't'}})
    fireEvent.blur(input)
    expect(getByDisplayValue('t')).toBeInTheDocument()
    expect(subjectProps.onChange).not.toHaveBeenCalled()
  })

  it('sets the input value and calls onChange when blurring after typing if no ambiguity', () => {
    const {subjectProps, input, getByDisplayValue} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'two'}})
    fireEvent.blur(input)
    expect(getByDisplayValue('two for real')).toBeInTheDocument()
    expect(subjectProps.onChange).toHaveBeenCalledWith(expect.anything(), '2')
  })

  it('does matching only on initial text', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'score'}})
    expect(getByText('No matches to your search')).toBeInTheDocument()
  })

  it('ignores leading spaces when matching', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'four score'}})
    expect(getByText('four score and seven')).toBeInTheDocument()
  })
})
