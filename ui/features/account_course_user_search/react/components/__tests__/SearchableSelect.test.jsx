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
  <Subject.Option key="1" id="1" value="1">
    one is lonely
  </Subject.Option>,
  <Subject.Option key="2" id="2" value="2">
    two for real
  </Subject.Option>,
  <Subject.Option key="3" id="3" value="3">
    three on a match
  </Subject.Option>,
  <Subject.Option key="4" id="4" value="4">
    {'    four score and seven'}
  </Subject.Option>,
]
function makeProps(isLoading) {
  return {
    id: 'device-under-test',
    isLoading,
    onChange: jest.fn(),
    label: LABEL,
  }
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

  function renderSubject(isLoading = false) {
    const subjectProps = makeProps(isLoading)
    const results = render(<Subject {...subjectProps}>{options}</Subject>)
    const input = results.getByLabelText(LABEL)
    return {subjectProps, input, ...results}
  }

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
    const {getByPlaceholderText} = renderSubject(false)
    expect(getByPlaceholderText('Begin typing to search')).toBeInTheDocument()
  })

  it('responds to a click by showing the whole list of options', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    options.forEach(opt => {
      expect(getByText(opt.props.children.trim())).toBeInTheDocument()
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

  it('shows a no matches message if nothing matches the typing', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'will not match'}})
    expect(getByText('No matches to your search')).toBeInTheDocument()
  })

  it('shows a no results message if no children are provided', () => {
    const {getByText} = render(<Subject {...makeProps()} />)
    expect(getByText('No results')).toBeInTheDocument()
  })

  it('calls onChange with the right id when an option is clicked', () => {
    const {subjectProps, input, getByText} = renderSubject()
    fireEvent.click(input)
    const opt = getByText('three on a match')
    fireEvent.click(opt)
    expect(subjectProps.onChange).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({id: '3'})
    )
  })

  it('does not call onChange when blurring after typing if results are ambiguous', () => {
    const {subjectProps, input, getByDisplayValue} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 't'}})
    fireEvent.blur(input)
    expect(getByDisplayValue('t')).toBeInTheDocument()
    expect(subjectProps.onChange).not.toHaveBeenCalled()
  })

  it('keeps the no matches message after blurring', () => {
    const {input, queryByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'will not match'}})
    fireEvent.blur(input)
    expect(queryByText('No matches to your search')).toBeVisible()
  })

  it('sets the input value and calls onChange when blurring after typing if no ambiguity', () => {
    const {subjectProps, input, getByDisplayValue} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'two'}})
    fireEvent.blur(input)
    expect(getByDisplayValue('two for real')).toBeInTheDocument()
    expect(subjectProps.onChange).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({id: '2'})
    )
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

const groupOptions = [
  <Subject.Group key="g1" id="g1" label="group1">
    <Subject.Option id="g1o1" value="g1o1">
      grp 1 option 1
    </Subject.Option>
    <Subject.Option id="g1o2" value="g1o2">
      grp 1 option 2
    </Subject.Option>
  </Subject.Group>,
  <Subject.Group key="g2" id="g2" label="group2">
    <Subject.Option id="g2o1" value="g2o1">
      grp 2 option 1
    </Subject.Option>
    <Subject.Option id="g2o2" value="g2o2">
      grp 2 option 2
    </Subject.Option>
  </Subject.Group>,
]

describe('SearchableSelect::Groups', () => {
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

  function renderSubject(otherProps = {}) {
    const subjectProps = makeProps(false)
    const results = render(
      <Subject {...subjectProps} {...otherProps}>
        {groupOptions}
      </Subject>
    )
    const input = results.getByLabelText(LABEL)
    return {subjectProps, input, ...results}
  }

  it('renders both groups and options', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    expect(getByText('group1')).toBeInTheDocument()
    expect(getByText('group2')).toBeInTheDocument()
    expect(getByText('grp 1 option 1')).toBeInTheDocument()
    expect(getByText('grp 1 option 2')).toBeInTheDocument()
    expect(getByText('grp 2 option 1')).toBeInTheDocument()
    expect(getByText('grp 2 option 2')).toBeInTheDocument()
  })

  it('always renders the group headings even on a search', () => {
    const {input, getByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'grp 1 option 1'}})
    expect(getByText('group1')).toBeInTheDocument()
    expect(getByText('group2')).toBeInTheDocument()
  })

  it('renders error message and no option list on failed search', () => {
    const {input, getByText, queryByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'xxx'}})
    expect(queryByText('xxx')).toBeNull() // do not show that placeholder!
    expect(getByText('No matches to your search')).toBeInTheDocument()
  })

  it('keeps selection if matched to single result after blurring', () => {
    const {input, queryByText} = renderSubject()
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'grp 1 option 2'}})
    fireEvent.blur(input)
    fireEvent.click(input)
    expect(queryByText('No matches to your search')).toBeNull()
    expect(input.value).toBe('grp 1 option 2')
  })

  it('does not misbehave when clicking back in after blurring', () => {
    const {input, getByText} = renderSubject({value: 'g1o1'})
    fireEvent.click(input)
    fireEvent.input(input, {target: {value: 'xxx'}})
    fireEvent.blur(input)
    fireEvent.click(input)
    expect(input.value).toBe('xxx')
    expect(getByText('No matches to your search')).toBeInTheDocument()
  })
})
