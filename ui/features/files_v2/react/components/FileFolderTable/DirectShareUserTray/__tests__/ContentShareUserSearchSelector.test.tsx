/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import ContentShareUserSearchSelector from '../ContentShareUserSearchSelector'
import {render, fireEvent, act, waitFor} from '@testing-library/react'
import useContentShareUserSearchApi from '@canvas/direct-sharing/react/effects/useContentShareUserSearchApi'

jest.mock('@canvas/direct-sharing/react/effects/useContentShareUserSearchApi')

const defaultProps = {
  courseId: '1',
  onUserSelected: jest.fn(),
  selectedUsers: [],
}

const renderComponent = (props?: any) =>
  render(<ContentShareUserSearchSelector {...defaultProps} {...props} />)

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

  it('renders', () => {
    const {getByLabelText} = renderComponent()
    fireEvent.click(getByLabelText(/select at least one person/i))
  })

  it('renders loading spinner while searching', () => {
    ;(useContentShareUserSearchApi as jest.Mock).mockImplementationOnce(({loading}) =>
      loading(true),
    )
    const {getByText, getByLabelText} = renderComponent()
    fireEvent.click(getByLabelText(/select at least one person/i))
    expect(getByText(/loading/i)).toBeInTheDocument()
  })

  it('performs fetch with a specific search term when typed', async () => {
    const {getAllByText, getByLabelText} = renderComponent()
    const selectInput = getByLabelText(/select at least one person/i)
    fireEvent.click(selectInput)
    fireEvent.change(selectInput, {target: {value: 'abc'}})
    ;(useContentShareUserSearchApi as jest.Mock).mockImplementationOnce(({loading}) =>
      loading(true),
    )
    const loadingTexts = getAllByText(/loading/i)
    const loadingTextForSpinner = loadingTexts.find(loading => loading.closest('svg'))
    expect(loadingTextForSpinner).toBeInTheDocument()
    await waitFor(() => {
      expect(useContentShareUserSearchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          params: {search_term: 'abc'},
        }),
      )
    })
  })

  it('calls onUserSelected when a user is chosen', () => {
    const {getByText, getByLabelText} = renderComponent()
    const selectInput = getByLabelText(/select at least one person/i)
    fireEvent.click(selectInput)
    ;(useContentShareUserSearchApi as jest.Mock).mockImplementationOnce(({success}) =>
      success([{id: 'foo', name: 'shrek'}]),
    )
    fireEvent.change(selectInput, {target: {value: 'shr'}})
    act(() => {
      jest.runAllTimers()
    }) // let the debounce happen
    fireEvent.click(getByText('shrek'))
    expect(defaultProps.onUserSelected).toHaveBeenCalledWith({id: 'foo', name: 'shrek'})
  })

  it('hides already-selected users from search result options', () => {
    const alreadySelectedUsers = [{id: 'bar', name: 'extra shrek'}]
    const {getByText, getByLabelText, queryByText} = render(
      <ContentShareUserSearchSelector
        courseId="42"
        onUserSelected={() => {}}
        selectedUsers={alreadySelectedUsers}
      />,
    )
    const selectInput = getByLabelText(/select at least one person/i)
    fireEvent.click(selectInput)
    ;(useContentShareUserSearchApi as jest.Mock).mockImplementationOnce(({success}) =>
      success([
        {id: 'foo', name: 'shrek'},
        {id: 'bar', name: 'extra shrek'},
      ]),
    )
    fireEvent.change(selectInput, {target: {value: 'shr'}})
    act(() => {
      jest.runAllTimers()
    }) // let the debounce happen
    expect(getByText('shrek')).toBeInTheDocument()
    expect(queryByText('extra shrek')).not.toBeInTheDocument()
  })
})
