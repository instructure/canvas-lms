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

import {PostContainer} from '../PostContainer'
import {PostToolbar} from '../../../components/PostToolbar/PostToolbar'
import React from 'react'
import {render} from '@testing-library/react'
import {responsiveQuerySizes} from '../../../utils'
import {User} from '../../../../graphql/User'

jest.mock('../../../utils')

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn()
    }
  })
})

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'}
  }))
})

describe('PostContainer', () => {
  const topicPostUtilities = () => (
    <PostToolbar
      isPublished
      isSubscribed
      repliesCount={24}
      unreadCount={4}
      onTogglePublish={() => {}}
      onToggleSubscription={() => {}}
      onReadAll={() => {}}
    />
  )

  const defaultProps = ({
    isTopic = true,
    postUtilities = topicPostUtilities(),
    author = User.mock({displayName: 'Harry Potter', avatarUrl: ''}),
    children = null,
    title = 'This is an amazing title',
    message = 'This is an amazing message',
    isEditing = false,
    onSave = () => {},
    onCancel = () => {},
    isIsolatedView = false,
    editor = User.mock({_id: '5', displayName: 'George Weasley'}),
    isUnread = false,
    isForcedRead = false,
    timingDisplay = 'Jan 1 1:00pm',
    editedTimingDisplay = 'Feb 2 2:00pm',
    lastReplyAtDisplay = null
  } = {}) => ({
    isTopic,
    postUtilities,
    author,
    children,
    title,
    message,
    isEditing,
    onSave,
    onCancel,
    isIsolatedView,
    editor,
    isUnread,
    isForcedRead,
    timingDisplay,
    editedTimingDisplay,
    lastReplyAtDisplay
  })

  const setup = props => {
    return render(<PostContainer {...props} />)
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  describe('discussion topic', () => {
    it('should render the title', () => {
      const container = setup(defaultProps())
      expect(container.getByText('This is an amazing title')).toBeInTheDocument()
    })

    it('should render the message', () => {
      const container = setup(defaultProps())
      expect(container.getByText('This is an amazing message')).toBeInTheDocument()
    })

    it('should render the author name', () => {
      const container = setup(defaultProps())
      expect(container.getByText('Harry Potter')).toBeInTheDocument()
    })

    it('should render the reply info', () => {
      const container = setup(defaultProps())
      expect(container.getAllByText('24 replies, 4 unread').length).toBe(2)
    })

    it('should render the created timestamp', () => {
      const container = setup(defaultProps())
      expect(container.getByText('Jan 1 1:00pm')).toBeInTheDocument()
    })

    it('should render the edited timestamp', () => {
      const container = setup(defaultProps())
      expect(container.getByText('Edited by George Weasley Feb 2 2:00pm')).toBeInTheDocument()
    })
  })
})
