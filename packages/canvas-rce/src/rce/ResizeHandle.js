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
import {func} from 'prop-types'
import {DraggableCore} from 'react-draggable'
import {View} from '@instructure/ui-layout'
import IconDragHandle from '@instructure/ui-icons/lib/Line/IconDragHandle'
import DraggingBlocker from './DraggingBlocker'

export default function ResizeHandle(props) {
  const [dragging, setDragging] = useState(false)
  return (
    <>
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
    </>
  )
}

ResizeHandle.propTypes = {
  onDrag: func
}

ResizeHandle.defaultProps = {
  onDrag: () => {}
}
