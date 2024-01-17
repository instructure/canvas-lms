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
import {fireEvent, render, act} from '@testing-library/react'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'
import Library from '../Library'

jest.useFakeTimers()

describe('Library', () => {
  let setCommentMock, setFocusToTextAreaMock

  const comments = [
    {
      _id: '1',
      comment: 'great comment',
    },
    {
      _id: '2',
      comment: 'great comment 2',
    },
  ]

  const defaultProps = (props = {}) => {
    return {
      comments,
      setComment: setCommentMock,
      onAddComment: () => {},
      onDeleteComment: () => {},
      isAddingComment: false,
      searchResults: [],
      showSuggestions: true,
      setShowSuggestions: () => {},
      setFocusToTextArea: setFocusToTextAreaMock,
      updateComment: () => {},
      suggestionsRef: document.body,
      setRemovedItemIndex: () => {},
      ...props,
    }
  }

  beforeEach(() => {
    setCommentMock = jest.fn()
    setFocusToTextAreaMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('should open the tray when the link is clicked', () => {
    const {getByText, queryByText} = render(<Library {...defaultProps()} />)
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
    fireEvent.click(getByText('2'))
    expect(getByText('Manage Comment Library')).toBeInTheDocument()
  })

  it('calls setComment and hides the tray when a tray comment is clicked', async () => {
    const {getByText, queryByText} = render(<Library {...defaultProps()} />)
    fireEvent.click(getByText('2'), {detail: 1})
    fireEvent.click(getByText('great comment 2'), {detail: 1})
    expect(setCommentMock).toHaveBeenCalledWith('great comment 2')
    await act(async () => jest.advanceTimersByTime(1000))
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
  })

  it('closes the tray when the close IconButton is clicked', async () => {
    const {getByText, queryByText} = render(<Library {...defaultProps()} />)
    fireEvent.click(getByText('2'))
    fireEvent.click(getByText('Close comment library'))
    await act(async () => jest.advanceTimersByTime(1000))
    expect(queryByText('Manage Comment Library')).not.toBeInTheDocument()
  })

  describe('search results', () => {
    it('renders search results', () => {
      const {getByText} = render(<Library {...defaultProps({searchResults: comments})} />)
      expect(getByText('Insert Comment from Library')).toBeInTheDocument()
      expect(getByText('great comment')).toBeInTheDocument()
    })

    it('hides results and calls setComment when a result is clicked', () => {
      const {getByText, queryByText} = render(
        <Library {...defaultProps({searchResults: comments})} />
      )
      fireEvent.click(getByText('great comment'))
      expect(queryByText('great comment')).not.toBeInTheDocument()
      expect(setCommentMock).toHaveBeenCalledWith('great comment')
    })

    it('shows results again after being closed if there are new results', () => {
      const {getByText, queryByText, rerender} = render(
        <Library {...defaultProps({searchResults: comments})} />
      )
      fireEvent.click(getByText('Close suggestions'))
      expect(queryByText('great comment')).not.toBeInTheDocument()
      rerender(<Library {...defaultProps({searchResults: [{comment: 'new result!', _id: '3'}]})} />)
      expect(getByText('new result!')).toBeInTheDocument()
    })

    // EVAL-3907 - remove or rewrite to remove spies on imports
    it.skip('renders a flash alert when new results are available', () => {
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      const {rerender} = render(<Library {...defaultProps()} />)

      rerender(<Library {...defaultProps({searchResults: comments})} />)

      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        srOnly: true,
        message:
          'There are new comment suggestions available. Press Tab to access the suggestions menu.',
      })
    })

    it('hides the menu if there are no results', () => {
      const {queryByText, rerender} = render(
        <Library {...defaultProps({searchResults: comments})} />
      )
      rerender(<Library {...defaultProps({searchResults: []})} />)
      expect(queryByText('Insert Comment from Library')).not.toBeInTheDocument()
    })

    it('does not render results if showSuggestions is false', () => {
      const {queryByText} = render(
        <Library {...defaultProps({searchResults: comments, showSuggestions: false})} />
      )
      expect(queryByText('Insert Comment from Library')).not.toBeInTheDocument()
      expect(queryByText('great comment')).not.toBeInTheDocument()
    })

    it('does not render suggestions if suggestionsRef is not provided', () => {
      const {queryByText} = render(
        <Library {...defaultProps({searchResults: comments, suggestionsRef: null})} />
      )
      expect(queryByText('Insert Comment from Library')).not.toBeInTheDocument()
    })

    it('calls setFocusToTextArea when suggestions are closed', () => {
      const {getByText} = render(<Library {...defaultProps({searchResults: comments})} />)
      fireEvent.click(getByText('Close suggestions'))
      expect(setFocusToTextAreaMock).toHaveBeenCalled()
    })

    it('calls addEventListener to the suggestionsRef.parentNode on mount', () => {
      document.body.innerHTML = '<div id="parent"><div id="library-suggestions"/></div>'
      const spy = jest.spyOn(document.getElementById('parent'), 'addEventListener')
      render(
        <Library
          {...defaultProps({
            searchResults: comments,
            suggestionsRef: document.getElementById('library-suggestions'),
          })}
        />
      )
      expect(spy).toHaveBeenCalled()
    })

    it('calls removeEventListener on library-suggestions.parentNode on unmount', () => {
      document.body.innerHTML = '<div id="parent"><div id="library-suggestions"/></div>'
      const spy = jest.spyOn(document.getElementById('parent'), 'removeEventListener')
      const {unmount} = render(
        <Library
          {...defaultProps({
            searchResults: comments,
            suggestionsRef: document.getElementById('library-suggestions'),
          })}
        />
      )
      unmount()
      expect(spy).toHaveBeenCalled()
    })

    it('hides results if the suggestionsRef.parentNode lose focus', () => {
      const {getByText, queryByText} = render(
        <Library {...defaultProps({searchResults: comments})} />
      )
      expect(getByText('Insert Comment from Library')).toBeInTheDocument()
      getByText('Close suggestions').closest('button').focus()
      fireEvent.focusOut(document.activeElement)
      expect(queryByText('Insert Comment from Library')).not.toBeInTheDocument()
    })
  })

  it('renders a tooltip when showSuggestions is false', () => {
    const {getByText} = render(<Library {...defaultProps({showSuggestions: false})} />)
    fireEvent.focus(getByText('2'))
    expect(getByText('Comment Library (Suggestions Disabled)')).toBeInTheDocument()
  })
})
