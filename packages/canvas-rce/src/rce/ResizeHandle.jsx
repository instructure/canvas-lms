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
import {func, string, number} from 'prop-types'
import {DraggableCore} from 'react-draggable'
import keycode from 'keycode'
import {View} from '@instructure/ui-view'
import {IconDragHandleLine} from '@instructure/ui-icons'
import DraggingBlocker from './DraggingBlocker'
import formatMessage from '../format-message'

const RESIZE_STEP = 16

export default function ResizeHandle(props) {
  function handleKey(event) {
    if (event.keyCode === keycode.codes.up) {
      event.preventDefault()
      event.stopPropagation()
      props.onDrag(event, {deltaY: -RESIZE_STEP})
    } else if (event.keyCode === keycode.codes.down) {
      event.preventDefault()
      event.stopPropagation()
      props.onDrag(event, {deltaY: RESIZE_STEP})
    }
  }

  function handleFocus(event) {
    setIsFocused(true)
    props.onFocus?.(event)
  }

  function handleBlur() {
    setIsFocused(false)
  }

  function handleDragStart(_e) {
    setDragging(true)
  }

  function handleDragStop(_e) {
    setDragging(false)
  }

  const [dragging, setDragging] = useState(false)
  // tracking isFocused rather than leveraging instui Focusable
  // because Focusable doesn't detect whan ResizeHandle gets focus
  const [isFocused, setIsFocused] = useState(false)

  return (
    <View
      aria-label={formatMessage('Drag handle. Use up and down arrows to resize')}
      title={formatMessage('Resize')}
      as="span"
      borderRadius="medium"
      display="inline-block"
      withFocusOutline={isFocused}
      padding="0 xx-small"
      position="relative"
      role="button"
      data-btn-id={props['data-btn-id']}
      tabIndex={props.tabIndex}
      onKeyDown={handleKey}
      onFocus={handleFocus}
      onBlur={handleBlur}
    >
      <DraggableCore
        offsetParent={document.body}
        onDrag={props.onDrag}
        onStart={handleDragStart}
        onStop={handleDragStop}
      >
        <View cursor="ns-resize">
          <IconDragHandleLine />
        </View>
      </DraggableCore>
      <DraggingBlocker dragging={dragging} />
    </View>
  )
}

ResizeHandle.propTypes = {
  onDrag: func,
  onFocus: func,
  tabIndex: number,
  'data-btn-id': string,
}

ResizeHandle.defaultProps = {
  onDrag: () => {},
  tabIndex: -1,
}
