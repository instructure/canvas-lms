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

import {CloseButton} from '@instructure/ui-buttons'
import {DiscussionEdit} from '../../components/DiscussionEdit/DiscussionEdit'
import {BackButton} from '../../components/BackButton/BackButton'
import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import I18n from 'i18n!discussion_topics_post'
import {IsolatedThreadsContainer} from '../IsolatedThreadsContainer/IsolatedThreadsContainer'
import {PostMessageContainer} from '../PostMessageContainer/PostMessageContainer'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import theme from '@instructure/canvas-theme'
import {ThreadActions} from '../../components/ThreadActions/ThreadActions'
import {ThreadingToolbar} from '../../components/ThreadingToolbar/ThreadingToolbar'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'

export const mockThreads = {
  discussionEntry: DiscussionEntry.mock()
}

export const ISOLATED_VIEW_MODES = {
  VIEW_ROOT_ENTRY: 1,
  REPLY_TO_ROOT_ENTRY: 2
}

export const IsolatedViewContainer = props => {
  const [showTray, setShowTray] = useState(true)

  const threadActions = []

  if (props.discussionEntry.permissions.reply) {
    threadActions.push(
      <ThreadingToolbar.Reply
        key={`reply-${props.discussionEntry.id}`}
        authorName={props.discussionEntry.author.name}
        delimiterKey={`reply-delimiter-${props.discussionEntry.id}`}
        onClick={() => {
          if (props.onReply) {
            props.onReply()
          }
        }}
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
        isReadOnly
        isExpanded={false}
        onClick={() => {}}
      />
    )
  }

  return (
    <Tray
      open={showTray}
      placement="end"
      size="medium"
      offset="large"
      label="Isolated View"
      shouldCloseOnDocumentClick
      onDismiss={e => {
        // When the RCE is open, it stills the mouse position when using it and we do this trick
        // to avoid the whole Tray getting closed because of a click inside the RCE area.
        if (
          props.mode == ISOLATED_VIEW_MODES.REPLY_TO_ROOT_ENTRY &&
          e.clientY - e.target.offsetTop == 0
        ) {
          return
        }

        if (props.onClose) {
          props.onClose()
        }

        setShowTray(false)
      }}
    >
      <Flex>
        <Flex.Item shouldGrow shouldShrink>
          <Heading margin="medium medium medium" theme={{h2FontWeight: 700}}>
            Thread
          </Heading>
        </Flex.Item>
        <Flex.Item>
          <CloseButton
            placement="end"
            offset="small"
            screenReaderLabel="Close"
            onClick={() => {
              setShowTray(false)

              if (props.onClose) {
                props.onClose()
              }
            }}
          />
        </Flex.Item>
      </Flex>
      {props.discussionEntry.rootEntry && (
        <div
          style={{
            paddingLeft: '0.50rem',
            paddingRight: '0.50rem',
            paddingBottom: '0.50rem'
          }}
        >
          <BackButton />
        </div>
      )}
      <div
        style={{
          marginLeft: theme.variables.spacing.medium,
          paddingLeft: '0.75rem',
          paddingRight: '0.75rem'
        }}
      >
        <Flex>
          <Flex.Item shouldShrink shouldGrow>
            <PostMessageContainer
              discussionEntry={props.discussionEntry}
              threadActions={threadActions}
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
                onEdit={() => {}}
                onOpenInSpeedGrader={props.onOpenInSpeedGrader}
                goToParent={() => {}}
                goToTopic={() => {}}
              />
            </Flex.Item>
          )}
        </Flex>
        {props.mode == ISOLATED_VIEW_MODES.REPLY_TO_ROOT_ENTRY && (
          <View
            display="block"
            background="primary"
            borderWidth="none none none none"
            padding="none none small none"
            margin="none none x-small none"
          >
            <DiscussionEdit
              onSubmit={text => {
                if (props.onReplySubmit) {
                  props.onReplySubmit(text)
                }
              }}
              onCancel={() => {
                if (props.onClose) {
                  props.onClose()
                }
              }}
            />
          </View>
        )}
      </div>
      {props.mode != ISOLATED_VIEW_MODES.REPLY_TO_ROOT_ENTRY && (
        <IsolatedThreadsContainer discussionEntryId={props.discussionEntry.id} />
      )}
    </Tray>
  )
}

IsolatedViewContainer.propTypes = {
  discussionEntry: DiscussionEntry.shape,
  mode: PropTypes.number,
  onClose: PropTypes.func,
  onToggleRating: PropTypes.func,
  onToggleUnread: PropTypes.func,
  onDelete: PropTypes.func,
  onOpenInSpeedGrader: PropTypes.func,
  onReply: PropTypes.func,
  onReplySubmit: PropTypes.func
}
IsolatedViewContainer.defaultProps = {
  mode: ISOLATED_VIEW_MODES.VIEW_ROOT_ENTRY
}

export default IsolatedViewContainer
