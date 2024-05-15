/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import CanvasMediaRecorder from './react/components/MediaRecorder'

export default function renderCanvasMediaRecorder(element, onSaveFile) {
  const fromSpeedGrader = window.location.href.includes('/speed_grader')

  let indicatorBarMountPointId = null
  let onModalShowToggle = null

  if (fromSpeedGrader) {
    indicatorBarMountPointId = 'screen-capture-indicator-mount-point'

    onModalShowToggle = disabled => {
      // disable media comment button and next/prev student buttons when recording
      ;[
        'media_comment_button',
        'next-student-button',
        'prev-student-button',
        'comment_submit_button',
      ].forEach(id => {
        const element = document.getElementById(id)
        if (element) {
          element.disabled = disabled
        }
      })

      // disables the student picker dropdown when recording
      const studentPicker = document.getElementById('combo_box_container')
      if (studentPicker) {
        studentPicker.style.pointerEvents = disabled ? 'none' : 'auto'
      }
    }
  }

  ReactDOM.render(
    <CanvasMediaRecorder
      onSaveFile={onSaveFile}
      onModalShowToggle={onModalShowToggle}
      indicatorBarMountPointId={indicatorBarMountPointId}
    />,
    element
  )
}
