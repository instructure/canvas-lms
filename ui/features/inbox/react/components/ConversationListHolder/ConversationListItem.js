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
  IconEmptySolid
} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import {colors} from '@instructure/canvas-theme'

const I18n = useI18nScope('conversations_2')

export const ConversationListItem = ({...props}) => {
  const [isHovering, setIsHovering] = useState(false)
  const {setMessageOpenEvent, isSubmissionCommentsType} = useContext(ConversationContext)

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
    props.onStar(!props.isStarred, props.conversation._id)
  }

  return (
    <div
      style={{
        // TODO: Move these styles to a stylesheet once we are moved to the app/ directory
        boxShadow: isHovering && 'inset -4px 0px 0px rgb(0, 142, 226)',
        backgroundColor: props.isSelected && 'rgb(229,242,248)'
      }}
    >
      <View
        data-testid="conversation"
        as="div"
        borderWidth="none none small none"
        padding="small x-small"
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
                      {props.isSelected ? I18n.t('selected') : I18n.t('not selected')}
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
                count={props.conversation.messages.length}
                countUntil={99}
                standalone
                theme={{
                  colorPrimary: colors.backgroundDarkest,
                  borderRadius: '0.25rem',
                  fontSize: '0.8125rem',
                  fontWeight: '700'
                }}
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0">
                <IconButton
                  color="primary"
                  data-testid={props.isUnread ? 'unread-badge' : 'read-badge'}
                  margin="x-small"
                  onClick={() =>
                    props.readStateChangeConversationParticipants({
                      variables: {
                        conversationIds: [props.conversation._id],
                        workflowState: props.isUnread ? 'read' : 'unread'
                      }
                    })
                  }
                  screenReaderLabel={props.isUnread ? I18n.t('Unread') : I18n.t('Read')}
                  size="small"
                  withBackground={false}
                  withBorder={false}
                >
                  {props.isUnread ? <IconEmptySolid /> : <IconEmptyLine />}
                </IconButton>
              </View>
            </Grid.Col>
            <Grid.Col>
              <Text weight="bold" size={props.textSize}>
                <TruncateText>{props.conversation.participantString}</TruncateText>
              </Text>
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0" />
            </Grid.Col>
            <Grid.Col>
              <Text weight="normal" size={props.textSize}>
                <TruncateText>{props.conversation.subject}</TruncateText>
              </Text>
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0" />
            </Grid.Col>
            <Grid.Col>
              <Text color="secondary" size={props.textSize}>
                <TruncateText>{props.conversation.lastMessageContent}</TruncateText>
              </Text>
            </Grid.Col>
            <Grid.Col width="auto">
              {!isSubmissionCommentsType && (
                <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0">
                  <Focusable>
                    {({focused}) => {
                      return (
                        <div>
                          {focused || isHovering || props.isStarred ? (
                            <IconButton
                              size="small"
                              withBackground={false}
                              withBorder={false}
                              renderIcon={props.isStarred ? IconStarSolid : IconStarLightLine}
                              screenReaderLabel={
                                props.isStarred ? I18n.t('starred') : I18n.t('not starred')
                              }
                              onClick={handleConversationStarClick}
                              data-testid="visible-star"
                            />
                          ) : (
                            <ScreenReaderContent>
                              <IconButton
                                size="small"
                                withBackground={false}
                                withBorder={false}
                                renderIcon={props.isStarred ? IconStarSolid : IconStarLightLine}
                                screenReaderLabel={
                                  props.isStarred ? I18n.t('starred') : I18n.t('not starred')
                                }
                                onClick={handleConversationStarClick}
                              />
                            </ScreenReaderContent>
                          )}
                        </div>
                      )
                    }}
                  </Focusable>
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
                      display="block"
                      textAlign="center"
                      size="small"
                      onClick={e => {
                        setMessageOpenEvent(true) // Required to redirect focus into message
                        handleConversationClick(e)
                      }}
                    >
                      {I18n.t('Open Conversation')}
                    </Button>
                  ) : (
                    <ScreenReaderContent tabIndex="0">
                      {I18n.t('Open Conversation')}
                    </ScreenReaderContent>
                  )
                }}
              </Focusable>
            </Grid.Col>
          </Grid.Row>
        </Grid>
      </View>
    </div>
  )
}

ConversationListItem.propTypes = {
  conversation: PropTypes.object,
  submissionComments: PropTypes.object,
  id: PropTypes.string,
  isSelected: PropTypes.bool,
  isStarred: PropTypes.bool,
  isUnread: PropTypes.bool,
  onSelect: PropTypes.func,
  onStar: PropTypes.func,
  readStateChangeConversationParticipants: PropTypes.func,
  textSize: PropTypes.string
}
