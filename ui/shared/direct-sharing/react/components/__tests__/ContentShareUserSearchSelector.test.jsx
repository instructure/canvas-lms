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
import {render, fireEvent, act} from '@testing-library/react'
import useContentShareUserSearchApi from '../../effects/useContentShareUserSearchApi'
import ContentShareUserSearchSelector from '../ContentShareUserSearchSelector'

jest.mock('../../effects/useContentShareUserSearchApi')

describe('ContentShareUserSearchSelector', () => {
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

  it('initially searches with an empty search term', () => {
    render(<ContentShareUserSearchSelector courseId="42" onUserSelected={() => {}} />)
    expect(useContentShareUserSearchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        courseId: '42',
        params: {},
      })
    )
  })

  it('renders a loading spinner while searching', () => {
    useContentShareUserSearchApi.mockImplementationOnce(({loading}) => loading(true))
    const {getByText, getByLabelText} = render(
      <ContentShareUserSearchSelector courseId="42" onUserSelected={() => {}} />
    )
    fireEvent.click(getByLabelText(/send to/i))
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('renders a loading spinner and searches with a specific search term when typed', () => {
    const {getAllByText, getByLabelText} = render(
      <ContentShareUserSearchSelector courseId="42" onUserSelected={() => {}} />
    )
    const selectInput = getByLabelText(/send to/i)
    fireEvent.click(selectInput)
    fireEvent.change(selectInput, {target: {value: 'abc'}})
    useContentShareUserSearchApi.mockImplementationOnce(({loading}) => loading(true))
    act(() => jest.runAllTimers()) // let the debounce happen
    const loadingTexts = getAllByText(/loading/i)
    const loadingTextForSpinner = loadingTexts.find(loading => loading.closest('svg'))
    expect(loadingTextForSpinner).toBeInTheDocument()
    expect(useContentShareUserSearchApi).toHaveBeenCalledWith(
      expect.objectContaining({
        params: {search_term: 'abc'},
      })
    )
  })

  it('invokes onUserSelected when a user is chosen', () => {
    const handleUserSelected = jest.fn()
    const {getByText, getByLabelText} = render(
      <ContentShareUserSearchSelector courseId="42" onUserSelected={handleUserSelected} />
    )
    const selectInput = getByLabelText(/send to/i)
    fireEvent.click(selectInput)
    useContentShareUserSearchApi.mockImplementationOnce(({success}) =>
      success([{id: 'foo', name: 'shrek'}])
    )
    fireEvent.change(selectInput, {target: {value: 'shr'}})
    act(() => jest.runAllTimers()) // let the debounce happen
    fireEvent.click(getByText('shrek'))
    expect(handleUserSelected).toHaveBeenCalledWith({id: 'foo', name: 'shrek'})
  })

  it('hides already-selected users from search result options', () => {
    const alreadySelectedUsers = [{id: 'bar', name: 'extra shrek'}]
    const {getByText, getByLabelText, queryByText} = render(
      <ContentShareUserSearchSelector
        courseId="42"
        onUserSelected={() => {}}
        selectedUsers={alreadySelectedUsers}
      />
    )
    const selectInput = getByLabelText(/send to/i)
    fireEvent.click(selectInput)
    useContentShareUserSearchApi.mockImplementationOnce(({success}) =>
      success([
        {id: 'foo', name: 'shrek'},
        {id: 'bar', name: 'extra shrek'},
      ])
    )
    fireEvent.change(selectInput, {target: {value: 'shr'}})
    act(() => jest.runAllTimers()) // let the debounce happen
    expect(getByText('shrek')).toBeInTheDocument()
    expect(queryByText('extra shrek')).not.toBeInTheDocument()
  })
})
