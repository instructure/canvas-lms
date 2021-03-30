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
import {Flex} from '@instructure/ui-flex'
import React, {useState} from 'react'
import PropTypes from 'prop-types'
import {PostMessage} from '../PostMessage/PostMessage'
import {ThreadActions} from '../ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../ThreadingToolbar/ThreadingToolbar'
import {View} from '@instructure/ui-view'
import {CollapseReplies} from '../CollapseReplies/CollapseReplies'

export const mockThreads = {
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
}

export const mockThreadsNoReplies = {
  id: '432',
  authorName: 'Jeffrey Johnson',
  avatarUrl: 'someURL',
  timingDisplay: 'Jan 1st, 2021',
  message:
    'This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. This is the post that never ends. It goes on and on my friends. ',
  pillText: 'Author',
  isUnread: false,
  replies: []
}

export const DiscussionThread = props => {
  const [expandReplies, setExpandReplies] = useState(false)

  const marginDepth = 4 * props.depth

  const threadActions = [
    <ThreadingToolbar.Reply key={`reply-${props.id}`} onReply={() => {}} />,
    <ThreadingToolbar.Like key={`like-${props.id}`} onClick={() => {}} />
  ]

  if (props.depth === 0 && props.replies?.length > 0) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.id}`}
        expandText="4 replies, 2 unread"
        onClick={() => setExpandReplies(!expandReplies)}
      />
    )
  }

  return (
    <>
      <div style={{marginLeft: marginDepth + 'rem'}}>
        <Flex>
          <Flex.Item shroudGrow shouldShrink>
            <PostMessage {...props}>
              <ThreadingToolbar>{threadActions}</ThreadingToolbar>
            </PostMessage>
          </Flex.Item>
          <Flex.Item align="stretch">
            <ThreadActions id={props.id} />
          </Flex.Item>
        </Flex>
      </div>
      {(expandReplies || props.depth > 0) &&
        props.replies?.length !== 0 &&
        props.replies?.map(r => {
          return (
            <DiscussionThread key={`discussion-thread-${r.id}`} depth={props.depth + 1} {...r} />
          )
        })}
      {expandReplies && props.depth === 0 && props.replies?.length !== 0 && (
        <div
          style={{'margin-left': '4rem'}}
          width="100%"
          key={`discussion-thread-collapse-${props.id}`}
        >
          <View
            background="primary"
            borderWidth="none none small none"
            padding="none none small none"
            display="block"
            width="100%"
            margin="none none medium none"
          >
            <CollapseReplies onClick={() => setExpandReplies(false)} />
          </View>
        </div>
      )}
    </>
  )
}

DiscussionThread.propTypes = {
  id: PropTypes.string,
  authorName: PropTypes.string,
  avatarUrl: PropTypes.string,
  timingDisplay: PropTypes.string,
  message: PropTypes.string,
  pillTest: PropTypes.string,
  isUnread: PropTypes.bool,
  replies: PropTypes.array,
  depth: PropTypes.number
}

DiscussionThread.defaultProps = {
  depth: 0
}

export default DiscussionThread
