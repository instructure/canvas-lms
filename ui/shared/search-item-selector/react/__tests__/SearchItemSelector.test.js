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
import SearchItemSelector from '../SearchItemSelector'
import {render, fireEvent, act} from '@testing-library/react'

const testSearchFunction = jest.fn()

describe('SearchItemSelector', () => {
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

  it('initially sends no search term', () => {
    render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={() => {}}
        renderLabel="Select a course"
      />
    )
    expect(testSearchFunction).toHaveBeenCalledWith(
      expect.objectContaining({
        params: {},
      })
    )
  })

  it('renders a loading spinner in the combo box while searching', () => {
    testSearchFunction.mockImplementationOnce(({loading}) => loading(true))
    const {getByText, getByLabelText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={() => {}}
        renderLabel="Select a course"
      />
    )
    fireEvent.click(getByLabelText(/select a course/i))
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('renders a loading spinner and searches with a specific search term when typed', () => {
    const {getAllByText, getByLabelText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={() => {}}
        renderLabel="Select a course"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.change(selectInput, {target: {value: 'abc'}})
    testSearchFunction.mockImplementationOnce(({loading}) => loading(true))
    act(() => jest.runAllTimers()) // let the debounce happen
    const loadingTexts = getAllByText(/loading/i)
    const loadingTextForSpinner = loadingTexts.find(loading => loading.closest('svg'))
    expect(loadingTextForSpinner).toBeInTheDocument()
    expect(testSearchFunction).toHaveBeenCalledWith(
      expect.objectContaining({
        params: {term: 'abc', search_term: 'abc'},
      })
    )
  })

  it('updates select and invokes onItemSelected when an item is chosen', () => {
    testSearchFunction.mockImplementationOnce(({success}) => success([{id: 'foo', name: 'bar'}]))
    const handleCourseSelected = jest.fn()
    const {getByText, getByLabelText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={handleCourseSelected}
        renderLabel="Select a course"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.click(getByText('bar'))
    expect(selectInput.value).toBe('bar')
    expect(handleCourseSelected).toHaveBeenCalledWith({id: 'foo', name: 'bar'})
  })

  it('invokes onItemSelected with null when the user searches after an item has already been selected', () => {
    testSearchFunction.mockImplementationOnce(({success}) => success([{id: 'foo', name: 'bar'}]))
    const handleCourseSelected = jest.fn()
    const {getByText, getByLabelText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={handleCourseSelected}
        renderLabel="Select a course"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.click(getByText('bar'))
    expect(selectInput.value).toBe('bar')
    fireEvent.change(selectInput, {target: {value: 'other'}})
    expect(handleCourseSelected).toHaveBeenCalledWith(null)
  })

  it("doesn't trigger onItemSelected when changing a manualSelection", () => {
    testSearchFunction.mockImplementationOnce(({success}) => success([{id: 'foo', name: 'bar'}]))
    const handleCourseSelected = jest.fn()
    const {getByLabelText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={handleCourseSelected}
        renderLabel="Select a course"
        manualSelection="bar"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.change(selectInput, {target: {value: 'barn'}})
    expect(handleCourseSelected).not.toHaveBeenCalled()
  })

  it('renders no results if search comes back empty', async () => {
    testSearchFunction.mockImplementationOnce(({success}) => success([]))
    const {getByLabelText, findByText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={() => {}}
        renderLabel="Select a course"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.change(selectInput, {target: {value: 'nothing'}})
    expect(await findByText(/no results/i)).toBeInTheDocument()
  })

  it('removes the existing input if the contextId changes', () => {
    testSearchFunction.mockImplementationOnce(({success}) => success([{id: 'foo', name: 'bar'}]))
    const handleCourseSelected = jest.fn()
    const {getByText, getByLabelText, rerender} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={handleCourseSelected}
        renderLabel="Select a course"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    fireEvent.click(selectInput)
    fireEvent.click(getByText('bar'))
    expect(selectInput.value).toBe('bar')
    rerender(
      <SearchItemSelector
        contextId="1"
        itemSearchFunction={testSearchFunction}
        onItemSelected={handleCourseSelected}
        renderLabel="Select a course"
      />
    )
    expect(selectInput.value).toBe('')
  })

  it('supports prepopulating search text (which can be changed by the user)', () => {
    const handleCourseSelected = jest.fn()
    const {getByLabelText} = render(
      <SearchItemSelector
        itemSearchFunction={testSearchFunction}
        onItemSelected={handleCourseSelected}
        renderLabel="Select a course"
        manualSelection="bar"
      />
    )
    const selectInput = getByLabelText(/select a course/i)
    expect(selectInput.value).toBe('bar')
    expect(testSearchFunction).toHaveBeenLastCalledWith(
      expect.objectContaining({
        params: {},
      })
    )

    fireEvent.click(selectInput)
    fireEvent.change(selectInput, {target: {value: 'baz'}})
    act(() => jest.runAllTimers())
    expect(testSearchFunction).toHaveBeenLastCalledWith(
      expect.objectContaining({
        params: {term: 'baz', search_term: 'baz'},
      })
    )
  })

  // not sure how to suppress the error output this creates. oh well.
  it('throws errors for handling by an ErrorBoundary', () => {
    const testError = new Error('test error')
    testSearchFunction.mockImplementationOnce(({error}) => error(testError))
    expect(() =>
      render(
        <SearchItemSelector
          itemSearchFunction={testSearchFunction}
          onItemSelected={() => {}}
          renderLabel="Select a course"
        />
      )
    ).toThrow(testError)
  })
})
