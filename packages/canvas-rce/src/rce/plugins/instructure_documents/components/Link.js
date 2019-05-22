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
import {func, instanceOf, shape} from 'prop-types'
import {fileShape} from './propTypes'
import {StyleSheet, css} from "aphrodite";
import formatMessage from '../../../../format-message';
import {renderDoc as renderDocHtml} from "../../../../rce/contentRendering";
import dragHtml from "../../../../sidebar/dragHtml";
import {AccessibleContent} from '@instructure/ui-a11y'
import {Flex, View} from '@instructure/ui-layout'
import {Text} from '@instructure/ui-elements'
import {
  IconDragHandleLine,
  IconPublishSolid,
  IconUnpublishedSolid,
  IconDocumentLine,
  IconMsExcelLine,
  IconMsPptLine,
  IconMsWordLine,
  IconPdfLine
} from '@instructure/ui-icons'

function getIcon(type) {
  switch(type) {
    case 'application/msword':
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return IconMsWordLine
    case 'application/vnd.ms-powerpoint':
    case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      return IconMsPptLine
    case 'application/pdf':
      return IconPdfLine
    case 'application/vnd.ms-excel':
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return IconMsExcelLine
    default:
      return IconDocumentLine
  }
}

export default function Link(props) {
  const [isHovering, setIsHovering] = useState(false)
  const {filename, display_name, content_type, published, date} = props
  const Icon = getIcon(content_type)
  const color = published ? 'success' : 'primary'
  let dateString = formatMessage.date(Date.parse(date), 'long')
  const publishedMsg = published ? formatMessage('published') : formatMessage('unpublished')

  function handleLinkClick(e) {
    e.preventDefault();
    props.onClick({
      title: props.display_name || props.filename,
      href: props.href
    });
  }

  function handleDragStart(e) {
    dragHtml(e, renderDocHtml(props));
  }

  function handleHover(e) {
    setIsHovering(e.type === 'mouseenter')
  }

  let elementRef = null
  if (props.focusRef) {
    elementRef = ref => props.focusRef.current = ref
  }

  return (
    <div
      data-testid="instructure_links-Link"
      draggable
      onDragStart={handleDragStart}
      onMouseEnter={handleHover}
      onMouseLeave={handleHover}
      style={{position: 'relative'}}
    >
      <View
        className={css(styles.link)}
        as="div"
        role="button"
        tabIndex="0"
        aria-describedby={props.describedByID}
        elementRef={elementRef}
        background="default"
        borderWidth="0 0 small 0"
        padding="x-small"
        width="100%"
        onClick={handleLinkClick}
      >
        <div style={{pointerEvents: 'none'}}>
          <Flex>
            <Flex.Item margin="0 xx-small 0 0" size="1.125rem">
              {isHovering ? <IconDragHandleLine size="x-small"/> : null}
            </Flex.Item>
            <Flex.Item grow shrink>
              <Flex>
                <Flex.Item padding="0 x-small 0 0">
                  <Text color={color}>
                    <Icon size="x-small"/>
                  </Text>
                </Flex.Item>
                <Flex.Item padding="0 x-small 0 0" grow shrink textAlign="start">
                  <View as="div" margin="0">{display_name || filename}</View>
                  {dateString ? (<View as="div" margin="xx-small 0 0 0">{dateString}</View>) : null}
                </Flex.Item>
                <Flex.Item>
                  <AccessibleContent alt={publishedMsg}>
                    <Text color={color}>
                      {published ? <IconPublishSolid/> : <IconUnpublishedSolid/>}
                    </Text>
                  </AccessibleContent>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </div>
      </View>
    </div>
  )
}

Link.propTypes = {
  focusRef: shape({
    current: instanceOf(Element)
  }),
  ...fileShape,
  onClick: func.isRequired,
}

Link.defaultProps = {
  focusRef: null
}

const styles = StyleSheet.create({
  link: {
    ':focus': {
      'outline-offset': '-4px'
    }
  }
});
