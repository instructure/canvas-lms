/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import Suggestions from '../Suggestions'

describe('Suggestions', () => {
  let setCommentMock, closeSuggestionsMock
  const defaultProps = (props = {}) => {
    return {
      searchResults: [{_id: '1', comment: 'searched comment'}],
      showResults: true,
      setComment: setCommentMock,
      closeSuggestions: closeSuggestionsMock,
      suggestionsRef: document.getElementById('suggestions'),
      ...props,
    }
  }

  beforeEach(() => {
    document.body.innerHTML = '<div id="suggestions"/>'
    setCommentMock = jest.fn()
    closeSuggestionsMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('doesnt render the menu when showResults is false', () => {
    const {queryByText} = render(<Suggestions {...defaultProps({showResults: false})} />)
    expect(queryByText('Insert Comment from Library')).not.toBeInTheDocument()
  })

  it('renders suggestions within the menu when open', () => {
    const {getByText} = render(<Suggestions {...defaultProps()} />)
    expect(getByText('Insert Comment from Library')).toBeInTheDocument()
    expect(getByText('searched comment')).toBeInTheDocument()
  })

  it('calls setComment when a suggestion is clicked', () => {
    const {getByText} = render(<Suggestions {...defaultProps()} />)
    fireEvent.click(getByText('searched comment'))
    expect(setCommentMock).toHaveBeenCalled()
  })

  it('calls closeSuggestions when the menu is closed', () => {
    const {getByText} = render(<Suggestions {...defaultProps()} />)
    fireEvent.click(getByText('Close suggestions'))
    expect(closeSuggestionsMock).toHaveBeenCalled()
  })

  it('renders suggestions within the suggestionsRef element', () => {
    render(<Suggestions {...defaultProps()} />)
    const div = document.getElementById('suggestions')
    expect(div.textContent).toMatch(/Insert Comment/)
  })

  it('changes the suggestionsRef element visibility based on showResults', () => {
    const {rerender} = render(<Suggestions {...defaultProps({showResults: false})} />)
    const div = document.getElementById('suggestions')
    expect(div.style.visibility).toBe('hidden')
    rerender(<Suggestions {...defaultProps()} />)
    expect(div.style.visibility).toBe('visible')
  })
})
