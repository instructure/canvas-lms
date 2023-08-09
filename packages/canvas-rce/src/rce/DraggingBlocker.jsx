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

import React from 'react'
import {bool} from 'prop-types'

// The purpose of the dragging blocker is to keep the TinyMCE iframe from
// intercepting and swallowing the mouse events if the mouse winds up over the
// iframe while performing the drag. This is what TinyMCE itself does with its
// own resize handle.
export default function DraggingBlocker(props) {
  if (props.dragging) {
    return (
      <div
        style={{
          cursor: 'ns-resize',
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100%',
          height: '100%',
          zIndex: '1000000000000',
        }}
      />
    )
  } else {
    return null
  }
}

DraggingBlocker.propTypes = {
  dragging: bool.isRequired,
}
