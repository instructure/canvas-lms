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
import {func, string} from 'prop-types'
import {DraggableCore} from 'react-draggable'
import keycode from 'keycode'
import {Focusable} from '@instructure/ui-focusable'
import {View} from '@instructure/ui-layout'
import IconDragHandle from '@instructure/ui-icons/lib/Line/IconDragHandle'
import DraggingBlocker from './DraggingBlocker'
import formatMessage from '../format-message'

const RESIZE_STEP = 16

export default function ResizeHandle(props) {
  function handleKey(event) {
    if (event.keyCode === keycode.codes.up) {
      event.preventDefault()
      event.stopPropagation()
      props.onDrag(event, {deltaY: -RESIZE_STEP})
    } else if(event.keyCode === keycode.codes.down) {
      event.preventDefault()
      event.stopPropagation()
      props.onDrag(event, {deltaY: RESIZE_STEP})
    }
  }
  const [dragging, setDragging] = useState(false)

  return (
    <Focusable>
      {({focused}) => (
        <View
          aria-label={formatMessage("Drag handle. Use up and down arrows to resize")}
          as="span"
          borderRadius="medium"
          display="inline-block"
          focused={focused}
          padding="0 0 0 xx-small"
          position="relative"
          role="button"
          tabIndex={props.tabIndex}
          onKeyDown={handleKey}
        >
          <DraggableCore
            offsetParent={document.body}
            onDrag={props.onDrag}
            onStart={() => setDragging(true)}
            onStop={() => setDragging(false)}
          >
            <View cursor="ns-resize">
              <IconDragHandle />
            </View>
          </DraggableCore>
          <DraggingBlocker dragging={dragging} />
        </View>
      )}
    </Focusable>
  )
}

ResizeHandle.propTypes = {
  onDrag: func,
  tabIndex: string
}

ResizeHandle.defaultProps = {
  onDrag: () => {},
  tabIndex: '-1'
}
