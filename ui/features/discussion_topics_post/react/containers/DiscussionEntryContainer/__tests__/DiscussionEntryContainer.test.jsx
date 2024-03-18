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

import {DiscussionEntryContainer} from '../DiscussionEntryContainer'
import {PostToolbar} from '../../../components/PostToolbar/PostToolbar'
import React from 'react'
import {render} from '@testing-library/react'
import {User} from '../../../../graphql/User'
import {Attachment} from '../../../../graphql/Attachment'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({
    desktop: {maxWidth: '1000px'},
  }),
}))

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

describe('DiscussionEntryContainer', () => {
  const topicPostUtilities = () => (
    <PostToolbar
      isPublished={true}
      isSubscribed={true}
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
    isSplitView = false,
    editor = User.mock({_id: '5', displayName: 'George Weasley'}),
    isUnread = false,
    isForcedRead = false,
    createdAt = '2021-01-01T13:00:00-07:00',
    updatedAt = '2021-02-02T14:00:00-07:00',
    timingDisplay = 'Jan 1 1:00pm',
    editedTimingDisplay = 'Feb 2 2:00pm',
    lastReplyAtDisplay = null,
    quotedEntry = null,
    attachment = null,
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
    isSplitView,
    editor,
    isUnread,
    isForcedRead,
    createdAt,
    updatedAt,
    timingDisplay,
    editedTimingDisplay,
    lastReplyAtDisplay,
    quotedEntry,
    attachment,
  })

  const setup = props => {
    return render(<DiscussionEntryContainer {...props} />)
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
      expect(container.getAllByText('24 Replies, 4 Unread').length).toBe(2)
    })

    it('should render the created timestamp', () => {
      const container = setup(defaultProps())
      expect(container.getByText('Jan 1 1:00pm')).toBeInTheDocument()
    })

    it('should render the edited timestamp', () => {
      const container = setup(defaultProps())
      const editedByTextElement = container.getByTestId('editedByText')
      expect(editedByTextElement.textContent).toEqual('Edited by George Weasley Feb 2 2:00pm')
    })

    it('should render the reply preview', () => {
      const container = setup(
        defaultProps({
          quotedEntry: {
            createdAt: '2021-08-10T12:10:38-06:00',
            previewMessage:
              'Differences of habit and language are nothing at all if our aims are identical and our hearts are open.',
            author: {
              shortName: 'Albus Dumbledore',
            },
            editor: {
              shortName: 'Albus Dumbledore',
            },
            deleted: false,
          },
        })
      )
      expect(container.getByTestId('reply-preview')).toBeInTheDocument()
    })

    it('should render the attachment when it exists', () => {
      const container = setup(defaultProps({attachment: Attachment.mock()}))
      expect(container.getByText('288777.jpeg')).toBeInTheDocument()
    })

    it('should not render the attachment when it does not exist', () => {
      const container = setup(defaultProps())
      expect(container.queryByText('288777.jpeg')).not.toBeInTheDocument()
    })
  })
})
