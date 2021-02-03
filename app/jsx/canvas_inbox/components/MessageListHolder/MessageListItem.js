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
import {Focusable} from '@instructure/ui-focusable'
import {Grid} from '@instructure/ui-grid'
import {IconStarLightLine, IconStarSolid} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React, {useState} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import I18n from 'i18n!conversations_2'

export const MessageListItem = ({...props}) => {
  const [selected, setSelected] = useState(false)
  const [isHovering, setIsHovering] = useState(false)
  const [isStarred, setIsStarred] = useState(props.isStarred)

  const handleSelectionChange = () => {
    setSelected(!selected)
    props.onSelect(props.conversation)
  }

  const handleMessageClick = e => {
    e.stopPropagation()
    props.onOpen()
  }

  const handleMessageStarClick = e => {
    e.stopPropagation()
    props.onStar(!isStarred)
    setIsStarred(!isStarred)
  }

  const formatParticipants = () => {
    const participantsStr = props.conversation.conversationParticipantsConnection.nodes
      .filter(
        p => p.user.name !== props.conversation.conversationMessagesConnection.nodes[0].author.name
      )
      .reduce((prev, curr) => {
        return prev + ', ' + curr.user.name
      }, '')

    return (
      <Text>
        <TruncateText>
          <b>{props.conversation.conversationMessagesConnection.nodes[0].author.name}</b>
          {participantsStr}
        </TruncateText>
      </Text>
    )
  }

  const formatDate = rawDate => {
    const date = new Date(rawDate)
    return date.toDateString()
  }

  return (
    <div
      style={{
        // TODO: Move these styles to a stylesheet once we are moved to the app/ directory
        boxShadow: isHovering && 'inset -4px 0px 0px rgb(0, 142, 226)',
        backgroundColor: selected && 'rgb(229,242,248)'
      }}
    >
      <View
        data-testid="conversation"
        as="div"
        borderWidth="none none small none"
        padding="small x-small"
      >
        <Grid
          vAlign="middle"
          colSpacing="none"
          rowSpacing="none"
          onMouseEnter={() => {
            setIsHovering(true)
          }}
          onMouseLeave={() => {
            setIsHovering(false)
          }}
          onClick={handleMessageClick}
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
                  label={
                    <ScreenReaderContent>
                      {selected ? I18n.t('selected') : I18n.t('not selected')}
                    </ScreenReaderContent>
                  }
                  checked={selected}
                  onChange={handleSelectionChange}
                />
              </View>
            </Grid.Col>
            <Grid.Col>
              <Text color="brand">
                {formatDate(props.conversation.conversationMessagesConnection.nodes[0]?.createdAt)}
              </Text>
            </Grid.Col>
            <Grid.Col width="auto">
              <Badge
                count={props.conversation.conversationMessagesConnection.nodes?.length}
                countUntil={99}
                standalone
              />
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0">
                {props.isUnread && (
                  <Badge
                    type="notification"
                    standalone
                    margin="x-small"
                    formatOutput={() => {
                      return <ScreenReaderContent>{I18n.t('Unread')}</ScreenReaderContent>
                    }}
                  />
                )}
              </View>
            </Grid.Col>
            <Grid.Col>{formatParticipants()}</Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0" />
            </Grid.Col>
            <Grid.Col>
              <Text weight="light">
                <TruncateText>{props.conversation.subject}</TruncateText>
              </Text>
            </Grid.Col>
          </Grid.Row>
          <Grid.Row>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0" />
            </Grid.Col>
            <Grid.Col>
              <Text color="secondary">
                <TruncateText>
                  {props.conversation.conversationMessagesConnection.nodes[0]?.body}
                </TruncateText>
              </Text>
            </Grid.Col>
            <Grid.Col width="auto">
              <View textAlign="center" as="div" width={30} height={30} margin="0 small 0 0">
                <Focusable>
                  {({focused}) => {
                    return (
                      <div>
                        {focused || isHovering || isStarred ? (
                          <IconButton
                            size="small"
                            withBackground={false}
                            withBorder={false}
                            renderIcon={isStarred ? IconStarSolid : IconStarLightLine}
                            screenReaderLabel={
                              isStarred ? I18n.t('starred') : I18n.t('not starred')
                            }
                            onClick={handleMessageStarClick}
                            data-testid="visible-star"
                          />
                        ) : (
                          <ScreenReaderContent>
                            <IconButton
                              size="small"
                              withBackground={false}
                              withBorder={false}
                              renderIcon={isStarred ? IconStarSolid : IconStarLightLine}
                              screenReaderLabel={
                                isStarred ? I18n.t('starred') : I18n.t('not starred')
                              }
                              onClick={handleMessageStarClick}
                            />
                          </ScreenReaderContent>
                        )}
                      </div>
                    )
                  }}
                </Focusable>
              </View>
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
                      onClick={handleMessageClick}
                    >
                      {I18n.t('Open Message')}
                    </Button>
                  ) : (
                    <ScreenReaderContent tabIndex="0">{I18n.t('Open Message')}</ScreenReaderContent>
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

const participantProp = PropTypes.shape({name: PropTypes.string})

const conversaionMessageProp = PropTypes.shape({
  author: participantProp,
  participants: PropTypes.arrayOf(participantProp),
  created_at: PropTypes.string,
  body: PropTypes.string
})

export const conversationProp = PropTypes.shape({
  subject: PropTypes.string,
  participants: PropTypes.arrayOf(participantProp),
  conversationMessages: PropTypes.arrayOf(conversaionMessageProp)
})

MessageListItem.propTypes = {
  conversation: conversationProp,
  isStarred: PropTypes.bool,
  isUnread: PropTypes.bool,
  onOpen: PropTypes.func,
  onSelect: PropTypes.func,
  onStar: PropTypes.func
}
