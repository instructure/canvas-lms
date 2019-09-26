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
import ManagedCourseSelector from '../ManagedCourseSelector'
import useManagedCourseSearchApi from 'jsx/shared/effects/useManagedCourseSearchApi'
import {render, fireEvent, act} from '@testing-library/react'

jest.mock('jsx/shared/effects/useManagedCourseSearchApi')

describe('ManagedCourseSelector', () => {
  beforeAll(() => {
    const ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    const elt = document.getElementById('flash_screenreader_holder')
    if (elt) elt.remove()
  })

  beforeEach(() => {
    jest.useFakeTimers()
  })

  it('initially searches for all managed courses', () => {
    render(<ManagedCourseSelector />)
    expect(useManagedCourseSearchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        params: {}
      })
    )
  })

  it('renders a loading spinner in the combo box while searching', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({loading}) => loading(true))
    const {getByText, getByLabelText} = render(<ManagedCourseSelector />)
    fireEvent.click(getByLabelText(/select a course/i))
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('renders a loading spinner and searches with a specific search term when typed', () => {
    const {getAllByText, getByLabelText} = render(<ManagedCourseSelector />)
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.change(selectInput, {target: {value: 'abc'}})
    useManagedCourseSearchApi.mockImplementationOnce(({loading}) => loading(true))
    act(() => jest.runAllTimers()) // let the debounce happen
    const loadingTexts = getAllByText(/loading/i)
    const loadingTextForSpinner = loadingTexts.find(loading => loading.closest('svg'))
    expect(loadingTextForSpinner).toBeInTheDocument()
    expect(useManagedCourseSearchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        params: {term: 'abc'}
      })
    )
  })

  it('updates select and invokes onCourseSelected when a course is chosen', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) =>
      success([{id: 'foo', name: 'bar'}])
    )
    const handleCourseSelected = jest.fn()
    const {getByText, getByLabelText} = render(
      <ManagedCourseSelector onCourseSelected={handleCourseSelected} />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.click(getByText('bar'))
    expect(selectInput.value).toBe('bar')
    expect(handleCourseSelected).toHaveBeenCalledWith({id: 'foo', name: 'bar'})
  })

  it('invokes onCourseSelected with null when the user searches after a course has already been selected', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) =>
      success([{id: 'foo', name: 'bar'}])
    )
    const handleCourseSelected = jest.fn()
    const {getByText, getByLabelText} = render(
      <ManagedCourseSelector onCourseSelected={handleCourseSelected} />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.click(getByText('bar'))
    expect(selectInput.value).toBe('bar')
    fireEvent.change(selectInput, {target: {value: 'other'}})
    expect(handleCourseSelected).toHaveBeenCalledWith(null)
  })

  it('renders no results if search comes back empty', () => {
    useManagedCourseSearchApi.mockImplementationOnce(({success}) => success([]))
    const {getByText} = render(<ManagedCourseSelector />)
    fireEvent.click(getByText(/select a course/i))
    expect(getByText(/no results/i)).toBeInTheDocument()
  })

  // not sure how to suppress the error output this creates. oh well.
  it('throws errors for handling by an ErrorBoundary', () => {
    const testError = new Error('test error')
    useManagedCourseSearchApi.mockImplementationOnce(({error}) => error(testError))
    expect(() => render(<ManagedCourseSelector />)).toThrow(testError)
  })
})
