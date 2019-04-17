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
import {func, oneOf, string} from 'prop-types'
import {linkShape} from './propTypes'
import {StyleSheet, css} from "aphrodite";
import formatMessage from '../../../../format-message';
import {renderLink as renderLinkHtml} from "../../../../rce/contentRendering";
import dragHtml from "../../../../sidebar/dragHtml";
import {AccessibleContent} from '@instructure/ui-a11y'
import {Flex, FlexItem, View} from '@instructure/ui-layout'
import {Text} from '@instructure/ui-elements'
import IconDragHandle from '@instructure/ui-icons/lib/Line/IconDragHandle'
import IconAssignment from '@instructure/ui-icons/lib/Line/IconAssignment'
import IconDiscussion from '@instructure/ui-icons/lib/Line/IconDiscussion'
import IconModule from '@instructure/ui-icons/lib/Line/IconModule'
import IconQuiz from '@instructure/ui-icons/lib/Line/IconQuiz'
import IconAnnouncement from '@instructure/ui-icons/lib/Line/IconAnnouncement'
import IconPublish from '@instructure/ui-icons/lib/Solid/IconPublish'
import IconUnpublished from '@instructure/ui-icons/lib/Solid/IconUnpublished'
import IconUnknown from '@instructure/ui-icons/lib/Line/IconQuestion'
import {SVGIcon} from '@instructure/ui-svg-images'

function getIcon(type) {
  switch(type) {
    case 'assignments':
      return IconAssignment
    case 'discussions':
      return IconDiscussion
    case 'modules':
      return IconModule
    case 'quizzes':
      return IconQuiz
    case 'announcements':
      return IconAnnouncement
    case 'wikiPages': // waiting on an answer from design
    default:
      return IconUnknown
  }
}

export default function Link(props) {
  const [isHovering, setIsHovering] = useState(false)
  const {title, published, date, date_type} = props.link
  const Icon = getIcon(props.type)
  const color = published ? 'success' : 'primary'
  let dateString = null
  if (date) {
    if (date === 'multiple' ) {
      dateString = formatMessage('Due: Multiple Dates')
    } else {
      const when = formatMessage.date(Date.parse(date), 'long')
      switch(date_type) {
        case 'todo':
          dateString = formatMessage('To Do: {when}', {when})
          break
        case 'published':
          dateString = formatMessage('Published: {when}', {when})
          break;
        case 'posted':
          dateString = formatMessage('Posted: {when}', {when})
          break;
        case 'delayed_post':
          dateString = formatMessage('To Be Posted: {when}', {when})
          break;
        case 'due':
        default:
          dateString = formatMessage('Due: {when}', {when})
          break
      }
    }
  }
  const publishedMsg = props.link.published ? formatMessage('published') : formatMessage('unpublished')

  function handleLinkClick(e) {
    e.preventDefault();
    props.onClick(props.link);
  }

  function handleDragStart(e) {
    dragHtml(e, renderLinkHtml(props.link));
  }

  function handleHover(e) {
    setIsHovering(e.type === 'mouseenter')
  }

  return (
    <div
      data-testid="instructure_links-Link"
      draggable
      onDragStart={handleDragStart}
      onMouseEnter={handleHover}
      onMouseLeave={handleHover}
    >
      <View
        className={css(styles.link)}
        as="button"
        background="default"
        display="block"
        width="100%"
        borderWidth="0 0 small 0"
        padding="x-small"
        aria-describedby={props.describedByID}
        onClick={handleLinkClick}
        elementRef={props.elementRef}
      >
        <div style={{pointerEvents: 'none'}}>
          <Flex>
            <FlexItem margin="0 xx-small 0 0" size="1.125rem">
              {isHovering ? <IconDragHandle size="x-small"/> : null}
            </FlexItem>
            <FlexItem grow>
              <Flex>
                <FlexItem padding="0 x-small 0 0">
                  <Text color={color}>
                    <Icon size="x-small"/>
                  </Text>
                </FlexItem>
                <FlexItem padding="0 x-small 0 0" grow textAlign="start">
                  <View as="div" margin="0">{title}</View>
                  {dateString ? (<View as="div" margin="xx-small 0 0 0">{dateString}</View>) : null}
                </FlexItem>
                {'published' in props.link && (
                  <FlexItem>
                    <AccessibleContent alt={publishedMsg}>
                      <Text color={color}>
                        {published ? <IconPublish/> : <IconUnpublished/>}
                      </Text>
                    </AccessibleContent>
                  </FlexItem>
                )}
              </Flex>
            </FlexItem>
          </Flex>
        </div>
      </View>
    </div>
  )
}

Link.propTypes = {
  link: linkShape.isRequired,
  type: oneOf([
    'assignments', 'discussions', 'modules', 'quizzes',
    'announcements', 'wikiPages', 'navigation'
  ]).isRequired,
  onClick: func.isRequired,
  describedByID: string.isRequired,
  elementRef: func
}

const styles = StyleSheet.create({
  link: {
    ':focus': {
      'outline-offset': '-4px'
    }
  }
});