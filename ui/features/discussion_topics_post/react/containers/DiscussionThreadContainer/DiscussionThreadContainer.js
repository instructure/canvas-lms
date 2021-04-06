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
import PropTypes from 'prop-types'
import {DiscussionThread} from '../../DiscussionThread/DiscussionThread'

export const mockThreads = [
  {
    id: '432',
    authorName: 'Jeffrey Johnson',
    avatarUrl: 'someURL',
    timingDisplay: 'Jan 1st, 2021',
    message:
      'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',
    pillText: 'Author',
    isUnread: false,
    replies: [
      {
        id: '532',
        authorName: 'Jeffrey Johnson2',
        avatarUrl: 'someURL',
        timingDisplay: 'Jan 1st, 2021',
        message:
          'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

        isUnread: false,
        replies: [
          {
            id: '533',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: true
          },
          {
            id: '534',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: false
          },
          {
            id: '535',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: false
          }
        ]
      }
    ]
  },
  {
    id: '433',
    authorName: 'Jeffrey Johnson',
    avatarUrl: 'someURL',
    timingDisplay: 'Jan 1st, 2021',
    message:
      'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

    isUnread: false,
    replies: [
      {
        id: '536',
        authorName: 'Jeffrey Johnson2',
        avatarUrl: 'someURL',
        timingDisplay: 'Jan 1st, 2021',
        message:
          'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

        isUnread: false,
        replies: [
          {
            id: '537',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: true
          },
          {
            id: '538',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: false
          },
          {
            id: '539',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: false
          }
        ]
      }
    ]
  },
  {
    id: '434',
    authorName: 'Jeffrey Johnson',
    avatarUrl: 'someURL',
    timingDisplay: 'Jan 1st, 2021',
    message:
      'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

    isUnread: false,
    replies: [
      {
        id: '540',
        authorName: 'Jeffrey Johnson2',
        avatarUrl: 'someURL',
        timingDisplay: 'Jan 1st, 2021',
        message:
          'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

        isUnread: false,
        replies: [
          {
            id: '541',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: true
          },
          {
            id: '542',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: false
          },
          {
            id: '543',
            authorName: 'Jeffrey Johnson3',
            avatarUrl: 'someURL',
            timingDisplay: 'Jan 1st, 2021',
            message:
              'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',

            isUnread: false
          }
        ]
      }
    ]
  }
]

export const DiscussionThreadContainer = props => {
  return (
    <div
      style={{
        maxWidth: '55.625rem'
      }}
    >
      {props.threads?.map(r => {
        return <DiscussionThread key={`discussion-thread-${r.id}`} {...r} />
      })}
    </div>
  )
}

DiscussionThreadContainer.propTypes = {
  threads: PropTypes.array.isRequired
}

export default DiscussionThreadContainer
