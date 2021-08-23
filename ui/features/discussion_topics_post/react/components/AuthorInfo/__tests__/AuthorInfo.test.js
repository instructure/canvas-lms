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

import {AuthorInfo} from '../AuthorInfo'
import {render} from '@testing-library/react'
import React from 'react'
import {SearchContext} from '../../../utils/constants'
import {User} from '../../../../graphql/User'

const setup = ({
  author = User.mock({displayName: 'Harry Potter', courseRoles: ['Student', 'TA']}),
  editor = User.mock({_id: '1', displayName: 'Severus Snape'}),
  isUnread = false,
  isForcedRead = false,
  isIsolatedView = false,
  timingDisplay = 'Jan 1 1:00pm',
  editedTimingDisplay = 'Feb 2 2:00pm',
  lastReplyAtDisplay = 'Mar 3 3:00pm',
  showCreatedAsTooltip = false,
  searchTerm = ''
} = {}) =>
  render(
    <SearchContext.Provider value={{searchTerm}}>
      <AuthorInfo
        author={author}
        editor={editor}
        isUnread={isUnread}
        isForcedRead={isForcedRead}
        isIsolatedView={isIsolatedView}
        timingDisplay={timingDisplay}
        editedTimingDisplay={editedTimingDisplay}
        lastReplyAtDisplay={lastReplyAtDisplay}
        showCreatedAsTooltip={showCreatedAsTooltip}
      />
    </SearchContext.Provider>
  )

describe('AuthorInfo', () => {
  it('renders the avatar when there is an author', () => {
    const container = setup()
    expect(container.getByTestId('author_avatar')).toBeInTheDocument()
  })

  it('renders the author name when there is an author', () => {
    const container = setup()
    expect(container.getByText('Harry Potter')).toBeInTheDocument()
  })

  it('renders the author roles when there is an author', () => {
    const container = setup()
    expect(container.getByTestId('pill-container')).toBeInTheDocument()
    expect(container.getByTestId('pill-Student')).toBeInTheDocument()
    expect(container.getByTestId('pill-TA')).toBeInTheDocument()
  })

  it('does not render the avatar when there is no author', () => {
    const container = setup({author: null})
    expect(container.queryByTestId('author_avatar')).toBeNull()
  })

  it('does not render the author name when there is no author', () => {
    const container = setup({author: null})
    expect(container.queryByTestId('author_name')).toBeNull()
  })

  it('does not render roles when there is no author', () => {
    const container = setup({author: null})
    expect(container.queryByTestId('pill-container')).toBeNull()
  })

  it('renders the unread badge when isUnread is true', () => {
    const container = setup({isUnread: true})
    expect(container.getByTestId('is-unread')).toBeInTheDocument()
  })

  it('does not render the unread badge when isUnread is false', () => {
    const container = setup()
    expect(container.queryByTestId('is-unread')).toBeNull()
  })

  it('sets the isForcedRead attribute when isForcedRead is true (the entry was manually marked as unread)', () => {
    const container = setup({isUnread: true, isForcedRead: true})
    expect(container.getByTestId('is-unread').getAttribute('data-isforcedread')).toBe('true')
  })

  it.skip('should highlight terms in the author name', () => {
    const container = setup({searchTerm: 'Harry'})
    expect(container.getByTestId('highlighted-search-item')).toBeInTheDocument()
  })

  describe('timestamps', () => {
    it('renders the created date', () => {
      const container = setup()
      expect(container.getByText('Jan 1 1:00pm')).toBeInTheDocument()
    })

    it('renders the edited date', () => {
      const container = setup()
      expect(container.getByText('Edited by Severus Snape Feb 2 2:00pm')).toBeInTheDocument()
    })

    it('renders the last reply at date', () => {
      const container = setup()
      expect(container.getByText('Last reply Mar 3 3:00pm')).toBeInTheDocument()
    })

    it('renders the created tooltip if showCreatedAsTooltip is true', () => {
      const container = setup({showCreatedAsTooltip: true})
      expect(container.getByTestId('created-tooltip')).toBeInTheDocument()
      expect(container.getByText('Created Jan 1 1:00pm')).toBeInTheDocument()
      expect(container.queryByText('Jan 1 1:00pm')).toBeNull()
    })

    it('renders the created date if showCreatedAsTooltip is true but there is no edit info', () => {
      const container = setup({editedTimingDisplay: null, editor: null})
      expect(container.getByText('Jan 1 1:00pm')).toBeInTheDocument()
    })
  })
})
