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
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import {Highlight} from '../../components/Highlight/Highlight'
import I18n from 'i18n!discussion_topics_post'
import {PostMessageContainer} from '../PostMessageContainer/PostMessageContainer'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
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
        authorName={props.discussionEntry.author.name}
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
        authorName={props.discussionEntry.author.name}
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
        expandText={I18n.t(
          {one: '%{count} reply, %{unread} unread', other: '%{count} replies, %{unread} unread'},
          {
            count: props.discussionEntry.rootEntryParticipantCounts?.repliesCount,
            unread: props.discussionEntry.rootEntryParticipantCounts?.unreadCount
          }
        )}
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
            paddingLeft: '0.50rem',
            paddingRight: '0.50rem',
            paddingBottom: '0.50rem'
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
          paddingLeft: '0.75rem',
          paddingRight: '0.75rem',
          paddingBottom: '0.375rem'
        }}
      >
        <Highlight isHighlighted={props.isHighlighted}>
          <Flex>
            <Flex.Item shouldShrink shouldGrow>
              <PostMessageContainer
                discussionEntry={props.discussionEntry}
                threadActions={threadActions}
                isEditing={isEditing}
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
              <Flex.Item align="stretch">
                <ThreadActions
                  id={props.discussionEntry.id}
                  isUnread={!props.discussionEntry.read}
                  onToggleUnread={() => {
                    if (props.onToggleUnread) {
                      props.onToggleUnread()
                    }
                  }}
                  onDelete={props.onDelete}
                  onEdit={
                    props.discussionEntry.permissions?.update
                      ? () => {
                          setIsEditing(true)
                        }
                      : null
                  }
                  onOpenInSpeedGrader={props.onOpenInSpeedGrader}
                  goToTopic={() => {}}
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
  isHighlighted: PropTypes.bool
}
