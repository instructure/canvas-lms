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

import {BackButton} from '../../components/BackButton/BackButton'
import {Discussion} from '../../../graphql/Discussion'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import {PostMessageContainer} from '../PostMessageContainer/PostMessageContainer'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {ReplyInfo} from '../../components/ReplyInfo/ReplyInfo'
import theme from '@instructure/canvas-theme'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'

export const IsolatedParent = props => {
  const [isEditing, setIsEditing] = useState(false)
  const threadActions = []

  if (props.discussionEntry.permissions.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${props.discussionEntry.id}`}
        authorName={props.discussionEntry.author.displayName}
        delimiterKey={`reply-delimiter-${props.discussionEntry.id}`}
        onClick={() => props.setRCEOpen(true)}
        isReadOnly={props.RCEOpen}
      />
    )
  }

  if (
    props.discussionEntry.permissions.viewRating &&
    (props.discussionEntry.permissions.rate || props.discussionEntry.ratingSum > 0)
  ) {
    threadActions.push(
      <ThreadingToolbar.Like
        key={`like-${props.discussionEntry.id}`}
        delimiterKey={`like-delimiter-${props.discussionEntry.id}`}
        onClick={() => {
          if (props.onToggleRating) {
            props.onToggleRating()
          }
        }}
        authorName={props.discussionEntry.author.displayName}
        isLiked={props.discussionEntry.rating}
        likeCount={props.discussionEntry.ratingSum || 0}
        interaction={props.discussionEntry.permissions.rate ? 'enabled' : 'disabled'}
      />
    )
  }

  if (props.discussionEntry.lastReply) {
    threadActions.push(
      <ThreadingToolbar.Expansion
        key={`expand-${props.discussionEntry.id}`}
        delimiterKey={`expand-delimiter-${props.discussionEntry.id}`}
        expandText={
          <ReplyInfo
            replyCount={props.discussionEntry.rootEntryParticipantCounts?.repliesCount}
            unreadCount={props.discussionEntry.rootEntryParticipantCounts?.unreadCount}
          />
        }
        isReadOnly={!props.RCEOpen}
        isExpanded={false}
        onClick={() => props.setRCEOpen(false)}
      />
    )
  }

  return (
    <>
      {props.discussionEntry.parent && (
        <div
          style={{
            paddingLeft: theme.variables.spacing.xSmall,
            paddingRight: theme.variables.spacing.xSmall,
            paddingBottom: theme.variables.spacing.xSmall
          }}
        >
          <BackButton
            onClick={() => props.onOpenIsolatedView(props.discussionEntry.parent.id, false)}
          />
        </div>
      )}
      <div
        style={{
          marginLeft: theme.variables.spacing.medium,
          paddingRight: theme.variables.spacing.small,
          paddingBottom: theme.variables.spacing.xxSmall
        }}
      >
        <Highlight isHighlighted={props.isHighlighted}>
          <Flex>
            <Flex.Item shouldShrink shouldGrow>
              <PostMessageContainer
                discussionEntry={props.discussionEntry}
                isIsolatedView
                threadActions={threadActions}
                isEditing={isEditing}
                padding="small 0 medium small"
                onCancel={() => {
                  setIsEditing(false)
                }}
                onSave={message => {
                  if (props.onSave) {
                    props.onSave(props.discussionEntry, message)
                    setIsEditing(false)
                  }
                }}
              />
            </Flex.Item>
            {!props.discussionEntry.deleted && (
              <Flex.Item align="stretch" padding="small 0 0 0">
                <ThreadActions
                  id={props.discussionEntry.id}
                  isUnread={!props.discussionEntry.read}
                  onToggleUnread={props.onToggleUnread}
                  onDelete={props.discussionEntry.permissions?.delete ? props.onDelete : null}
                  onEdit={
                    props.discussionEntry.permissions?.update
                      ? () => {
                          setIsEditing(true)
                        }
                      : null
                  }
                  goToTopic={props.goToTopic}
                  onOpenInSpeedGrader={
                    props.discussionTopic.permissions?.speedGrader
                      ? props.onOpenInSpeedGrader
                      : null
                  }
                />
              </Flex.Item>
            )}
          </Flex>
          {props.children}
        </Highlight>
      </div>
    </>
  )
}

IsolatedParent.propTypes = {
  discussionTopic: Discussion.shape,
  discussionEntry: DiscussionEntry.shape,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onToggleRating: PropTypes.func,
  onSave: PropTypes.func,
  children: PropTypes.node,
  onOpenIsolatedView: PropTypes.func,
  RCEOpen: PropTypes.bool,
  setRCEOpen: PropTypes.func,
  isHighlighted: PropTypes.bool,
  goToTopic: PropTypes.func
}
