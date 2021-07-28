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
import {fileOrMediaObjectShape} from '../../shared/fileShape'
import classnames from 'classnames'

import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconDragHandleLine, IconPublishSolid, IconUnpublishedSolid} from '@instructure/ui-icons'

import formatMessage from '../../../../format-message'
import {renderLink as renderLinkHtml} from '../../../contentRendering'
import dragHtml from '../../../../sidebar/dragHtml'
import {getIconFromType} from '../../shared/fileTypeUtils'
import {isPreviewable} from '../../shared/Previewable'

export default function Link(props) {
  const [isHovering, setIsHovering] = useState(false)
  const {filename, display_name, title, content_type, published, date} = props
  const Icon = getIconFromType(content_type)
  const color = published ? 'success' : 'primary'
  const dateString = formatMessage.date(Date.parse(date), 'long')
  const publishedMsg = published ? formatMessage('published') : formatMessage('unpublished')

  function linkAttrsFromDoc() {
    const canPreview = isPreviewable(props.content_type)
    const clazz = classnames('instructure_file_link', {
      instructure_scribd_file: canPreview,
      inline_disabled: true
    })

    const attrs = {
      id: props.id,
      href: props.href,
      target: '_blank',
      class: clazz,
      text: props.display_name || props.filename, // because onClick only takes a single object
      content_type: props.content_type, // files have this
      // media_objects have these
      title: props.title,
      type: props.type,
      embedded_iframe_url: props.embedded_iframe_url
    }
    if (canPreview) {
      attrs['data-canvas-previewable'] = true
    }
    return attrs
  }

  function handleLinkClick(e) {
    e.preventDefault()
    props.onClick(linkAttrsFromDoc())
  }

  function handleLinkKey(e) {
    // press the button on enter or space
    if (e.keyCode === 13 || e.keyCode === 32) {
      handleLinkClick(e)
    }
  }

  function handleDragStart(e) {
    const linkAttrs = linkAttrsFromDoc()
    dragHtml(e, renderLinkHtml(linkAttrs, linkAttrs.text))
  }

  function handleDragEnd(_e) {
    document.body.click()
  }

  function handleHover(e) {
    setIsHovering(e.type === 'mouseenter')
  }

  let elementRef = null
  if (props.focusRef) {
    elementRef = ref => (props.focusRef.current = ref)
  }

  return (
    <div
      data-testid="instructure_links-Link"
      draggable
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onMouseEnter={handleHover}
      onMouseLeave={handleHover}
      style={{position: 'relative'}}
    >
      <View
        as="div"
        role="button"
        position="relative"
        focusPosition="inset"
        focusColor="info"
        tabIndex="0"
        aria-describedby={props.describedByID}
        elementRef={elementRef}
        background="primary"
        borderWidth="0 0 small 0"
        padding="x-small"
        width="100%"
        onClick={handleLinkClick}
        onKeyDown={handleLinkKey}
      >
        <div style={{pointerEvents: 'none'}}>
          <Flex>
            <Flex.Item margin="0 xx-small 0 0" size="1.125rem">
              {isHovering ? <IconDragHandleLine size="x-small" inline={false} /> : null}
            </Flex.Item>
            <Flex.Item grow shrink>
              <Flex>
                <Flex.Item padding="0 x-small 0 0">
                  <Text color={color}>
                    <Icon size="x-small" />
                  </Text>
                </Flex.Item>
                <Flex.Item padding="0 x-small 0 0" grow shrink textAlign="start">
                  <View as="div" margin="0">
                    {display_name || title || filename}
                  </View>
                  {dateString ? <View as="div">{dateString}</View> : null}
                </Flex.Item>
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
  ...fileOrMediaObjectShape,
  onClick: func.isRequired
}

Link.defaultProps = {
  focusRef: null
}
