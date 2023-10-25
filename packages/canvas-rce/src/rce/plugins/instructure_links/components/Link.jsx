/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {bool, func, oneOf, string} from 'prop-types'
import {linkShape} from './propTypes'
import formatMessage from '../../../../format-message'
import {renderLink as renderLinkHtml} from '../../../contentRendering'
import dragHtml from '../../../../sidebar/dragHtml'
import {applyTimezoneOffsetToDate} from '../../shared/dateUtils'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Focusable} from '@instructure/ui-focusable'
import {IconDragHandleLine, IconPublishSolid, IconUnpublishedSolid} from '@instructure/ui-icons'
import RCEGlobals from '../../../RCEGlobals'
import {getIcon} from '../../shared/linkUtils'

export default function Link(props) {
  const internalLink = {...props.link}
  const [isHovering, setIsHovering] = useState(false)
  const {title, published, date, date_type} = props.link
  const type =
    props.type === 'quizzes' && props.link.quiz_type === 'quizzes.next'
      ? 'quizzes.next'
      : props.type
  internalLink['data-course-type'] = type
  // Only included published attr if it makes sense for the link type
  const publishable = !['navigation', 'announcements'].includes(type)
  internalLink['data-published'] = publishable ? published : null
  const Icon = getIcon(type)
  const color = published ? 'success' : 'primary'
  let dateString = null
  if (date) {
    if (date === 'multiple') {
      dateString = formatMessage('Due: Multiple Dates')
    } else {
      // Uses user locale and timezone
      const configuredTimezone = RCEGlobals.getConfig()?.timezone
      const when = formatMessage.date(applyTimezoneOffsetToDate(date, configuredTimezone), 'long')
      switch (date_type) {
        case 'todo':
          dateString = formatMessage('To Do: {when}', {when})
          break
        case 'published':
          dateString = formatMessage('Published: {when}', {when})
          break
        case 'posted':
          dateString = formatMessage('Posted: {when}', {when})
          break
        case 'delayed_post':
          dateString = formatMessage('To Be Posted: {when}', {when})
          break
        case 'due':
        default:
          dateString = formatMessage('Due: {when}', {when})
          break
      }
    }
  }
  const publishedMsg = props.link.published
    ? formatMessage('published')
    : formatMessage('unpublished')

  function handleLinkClick(e) {
    e.preventDefault()
    if (props.editing) {
      props.onEditClick({...internalLink, type})
    } else {
      props.onClick(internalLink)
    }
  }

  function handleLinkKey(e) {
    // press the button on enter or space
    if (e.keyCode === 13 || e.keyCode === 32) {
      handleLinkClick(e)
    }
  }

  function handleDragStart(e) {
    dragHtml(e, renderLinkHtml(internalLink, internalLink.title))
  }

  function handleDragEnd(_e) {
    document.body.click() // closes the tray
  }

  function handleHover(e) {
    setIsHovering(e.type === 'mouseenter')
  }

  return (
    <div
      data-testid="instructure_links-Link"
      draggable={!props.editing}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onMouseEnter={handleHover}
      onMouseLeave={handleHover}
      style={{position: 'relative'}}
    >
      <Focusable>
        {({focused}) => (
          <View
            withFocusOutline={focused}
            focusPosition="inset"
            position="relative"
            as="div"
            role="button"
            tabIndex={0}
            background="primary"
            display="block"
            width="100%"
            borderWidth="0 0 small 0"
            padding="x-small"
            aria-describedby={props.describedByID}
            onClick={handleLinkClick}
            onKeyDown={handleLinkKey}
            elementRef={props.elementRef}
          >
            <div style={{pointerEvents: 'none'}}>
              <Flex>
                <Flex.Item margin="0 xx-small 0 0" size="1.125rem">
                  {isHovering && !props.editing ? (
                    <IconDragHandleLine size="x-small" inline={false} />
                  ) : null}
                </Flex.Item>
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Flex>
                    <Flex.Item padding="0 x-small 0 0">
                      <Text color={color}>
                        <Icon size="x-small" inline={false} data-type={type} />
                      </Text>
                    </Flex.Item>
                    <Flex.Item
                      padding="0 x-small 0 0"
                      shouldGrow={true}
                      shouldShrink={true}
                      textAlign="start"
                    >
                      <View as="div" margin="0">
                        {title}
                        {props.isSelected && (
                          <ScreenReaderContent data-testid="selected-link-indicator">
                            {formatMessage('Selected')}
                          </ScreenReaderContent>
                        )}
                      </View>
                      {dateString ? <View as="div">{dateString}</View> : null}
                    </Flex.Item>
                    {'published' in props.link && (
                      <Flex.Item>
                        <AccessibleContent alt={publishedMsg}>
                          <Text color={color}>
                            {published ? (
                              <IconPublishSolid inline={false} />
                            ) : (
                              <IconUnpublishedSolid inline={false} />
                            )}
                          </Text>
                        </AccessibleContent>
                      </Flex.Item>
                    )}
                  </Flex>
                </Flex.Item>
              </Flex>
            </div>
          </View>
        )}
      </Focusable>
    </div>
  )
}

Link.propTypes = {
  link: linkShape.isRequired,
  type: oneOf([
    'assignments',
    'discussions',
    'modules',
    'quizzes',
    'announcements',
    'wikiPages',
    'navigation',
  ]).isRequired,
  onClick: func.isRequired,
  describedByID: string.isRequired,
  elementRef: func,
  editing: bool,
  onEditClick: func,
  isSelected: bool,
}
