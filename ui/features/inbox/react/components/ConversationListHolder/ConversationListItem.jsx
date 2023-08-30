/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {Badge} from '@instructure/ui-badge'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {ConversationContext} from '../../../util/constants'
import DateHelper from '@canvas/datetime/dateHelper'
import {Focusable} from '@instructure/ui-focusable'
import {Grid} from '@instructure/ui-grid'
import {
  IconStarLightLine,
  IconStarSolid,
  IconEmptyLine,
  IconEmptySolid,
} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React, {useContext, useState, useMemo} from 'react'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {colors} from '@instructure/canvas-theme'
import {Tooltip} from '@instructure/ui-tooltip'
import {Heading} from '@instructure/ui-heading'

const I18n = useI18nScope('conversations_2')

export const ConversationListItem = ({...props}) => {
  const [isHovering, setIsHovering] = useState(false)
  const {setMessageOpenEvent, isSubmissionCommentsType} = useContext(ConversationContext)

  // The Instui TruncateText component doesn't work well. it causes major Performance issues
  const truncateText = text => {
    if (text.length > props.truncateSize) {
      return text.slice(0, props.truncateSize) + '...'
    } else {
      return text
    }
  }

  const handleConversationClick = e => {
    e.nativeEvent.stopImmediatePropagation()
    e.stopPropagation()

    // Kind of a hack since our Checkbox doesn't support onChange or swallowing
    // events with ease. Removing aria-hidden elements from sending click events
    if (e.target.getAttribute('aria-hidden') === 'true') {
      return
    }

    if (e.metaKey || e.ctrlKey || e.shiftKey) {
      props.onSelect(e, props.id, true)
    } else {
      props.onSelect(e, props.id, false)
    }
  }

  const handleConversationStarClick = e => {
    e.nativeEvent.stopImmediatePropagation()
    e.stopPropagation()

    // Kind of a hack since our Checkbox doesn't support onChange or swallowing
    // events with ease. Removing aria-hidden elements from sending click events
    if (e.target.getAttribute('aria-hidden') === 'true') {
      return
    }
    props.onStar(!props.isStarred, [props.conversation])
  }

  const conversationParticipants = truncateText(props.conversation.participantString)
  const conversationSubject = truncateText(props.conversation.subject || I18n.t('(No subject)'))

  return useMemo(() => {
    return (
      <View
        key={`conversation-${props.conversation._id}`}
        elementRef={el => {
          if (props.isLast) {
            props.setRef(el)
          }
        }}
      >
        <div
          style={{
            // TODO: Move these styles to a stylesheet once we are moved to the app/ directory
            boxShadow: isHovering && 'inset -4px 0px 0px rgb(0, 142, 226)',
            backgroundColor: props.isSelected && 'rgb(229,242,248)',
          }}
        >
          <View
            data-testid="conversation"
            as="div"
            borderWidth="none none small none"
            padding="small medium small x-small"
          >
            <Grid
              data-testid="conversationListItem-Item"
              vAlign="middle"
              colSpacing="none"
              rowSpacing="none"
              onMouseEnter={() => {
                setIsHovering(true)
              }}
              onMouseLeave={() => {
                setIsHovering(false)
              }}
              onClick={handleConversationClick}
            >
              <Grid.Row>
                <Grid.Col width="auto">
                  <View
                    textAlign="center"
                    as="div"
                    width={30}
                    height={30}
                    padding="xx-small"
                    margin="0 small 0 0"
                  >
                    <Checkbox
                      data-testid="conversationListItem-Checkbox"
                      label={
                        <ScreenReaderContent>
                          {props.isSelected
                            ? I18n.t('%{subject} selected', {subject: conversationSubject})
                            : I18n.t('%{subject} not selected', {subject: conversationSubject})}
                        </ScreenReaderContent>
                      }
                      checked={props.isSelected}
                      onChange={e => {
                        e.stopPropagation()
                      }}
                    />
                  </View>
                </Grid.Col>
                <Grid.Col>
                  <Text color="brand" size={props.textSize}>
                    {DateHelper.formatDateForDisplay(props.conversation.lastMessageCreatedAt)}
                  </Text>
                </Grid.Col>
                <Grid.Col width="auto">
                  <Badge
                    count={props.conversation.count}
                    countUntil={99}
                    standalone={true}
                    themeOverride={{
                      colorPrimary: colors.backgroundDarkest,
                      borderRadius: '0.25rem',
                      fontSize: '0.8125rem',
                      fontWeight: '700',
                    }}
                    formatOutput={formattedCount => (
                      <AccessibleContent
                        alt={I18n.t(
                          {
                            one: '1 message',
                            other: '%{count} messages',
                          },
                          {count: props.conversation.count}
                        )}
                      >
                        {formattedCount}
                      </AccessibleContent>
                    )}
                  />
                </Grid.Col>
              </Grid.Row>
              <Grid.Row>
                <Grid.Col width="auto">
                  <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0">
                    <Tooltip
                      renderTip={props.isUnread ? I18n.t('Mark as Read') : I18n.t('Mark as Unread')}
                      placement="bottom"
                    >
                      <IconButton
                        color="primary"
                        data-testid={props.isUnread ? 'unread-badge' : 'read-badge'}
                        margin="x-small"
                        onClick={e => {
                          e.stopPropagation()
                          props.isUnread
                            ? props.onMarkAsRead(props.conversation)
                            : props.onMarkAsUnread(props.conversation)
                        }}
                        screenReaderLabel={
                          props.isUnread
                            ? I18n.t('%{subject} Mark as Read', {subject: conversationSubject})
                            : I18n.t('%{subject} Mark as Unread', {subject: conversationSubject})
                        }
                        size="small"
                        withBackground={false}
                        withBorder={false}
                      >
                        {props.isUnread ? <IconEmptySolid /> : <IconEmptyLine />}
                      </IconButton>
                    </Tooltip>
                  </View>
                </Grid.Col>
                <Grid.Col>
                  <Heading level="h2">
                    <Text weight="bold" size={props.textSize}>
                      {conversationParticipants}
                    </Text>
                  </Heading>
                </Grid.Col>
              </Grid.Row>
              <Grid.Row>
                <Grid.Col width="auto">
                  <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0" />
                </Grid.Col>
                <Grid.Col>
                  <Heading level="h3">
                    <Text weight="normal" size={props.textSize}>
                      {conversationSubject}
                    </Text>
                  </Heading>
                </Grid.Col>
              </Grid.Row>
              <Grid.Row>
                <Grid.Col width="auto">
                  <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0" />
                </Grid.Col>
                <Grid.Col>
                  <Text color="secondary" size={props.textSize} data-testid="last-message-content">
                    {truncateText(props.conversation.lastMessageContent)}
                  </Text>
                </Grid.Col>
                <Grid.Col width="auto">
                  {!isSubmissionCommentsType && (
                    <View textAlign="center" as="div" width={30} height={30}>
                      <div>
                        <IconButton
                          size="small"
                          withBackground={false}
                          withBorder={false}
                          renderIcon={props.isStarred ? IconStarSolid : IconStarLightLine}
                          screenReaderLabel={
                            props.isStarred
                              ? I18n.t('%{subject} starred', {subject: conversationSubject})
                              : I18n.t('%{subject} not starred', {subject: conversationSubject})
                          }
                          onClick={handleConversationStarClick}
                          data-testid={props.isStarred ? 'visible-starred' : 'visible-not-starred'}
                        />
                      </div>
                    </View>
                  )}
                </Grid.Col>
              </Grid.Row>
              <Grid.Row>
                <Grid.Col>
                  <Focusable>
                    {({focused}) => {
                      return focused ? (
                        <Button
                          data-testid={`open-conversation-for-${props.conversation._id}`}
                          display="block"
                          textAlign="center"
                          size="small"
                          onClick={e => {
                            setMessageOpenEvent(true) // Required to redirect focus into message
                            handleConversationClick(e)
                          }}
                          aria-label={I18n.t('Open Conversation %{subject}', {
                            subject: conversationSubject,
                          })}
                        >
                          {I18n.t('Open Conversation')}
                        </Button>
                      ) : (
                        <ScreenReaderContent
                          tabIndex="0"
                          data-testid={`open-conversation-for-${props.conversation._id}`}
                        >
                          {I18n.t('Open Conversation %{subject}', {subject: conversationSubject})}
                        </ScreenReaderContent>
                      )
                    }}
                  </Focusable>
                </Grid.Col>
              </Grid.Row>
            </Grid>
          </View>
        </div>
      </View>
    )
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    props.isSelected,
    isHovering,
    props.isStarred,
    props.textSize,
    props.isUnread,
    isSubmissionCommentsType,
    props.conversation._id,
    props.conversation.count,
    props.isLast,
    props.truncateSize,
  ])
}

ConversationListItem.propTypes = {
  conversation: PropTypes.object,
  id: PropTypes.string,
  isSelected: PropTypes.bool,
  isStarred: PropTypes.bool,
  isUnread: PropTypes.bool,
  onSelect: PropTypes.func,
  onStar: PropTypes.func,
  onMarkAsRead: PropTypes.func,
  onMarkAsUnread: PropTypes.func,
  textSize: PropTypes.string,
  truncateSize: PropTypes.number,
}
