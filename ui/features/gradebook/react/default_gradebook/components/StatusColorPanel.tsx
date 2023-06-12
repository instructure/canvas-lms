// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect, useState, useRef} from 'react'
import {func, shape, string} from 'prop-types'
import {statuses} from '../constants/statuses'
import StatusColorListItem from './StatusColorListItem'

const colorPickerButtons = {}
const colorPickerContents = {}

export default function StatusColorPanel({colors: initialColors, onColorsUpdated}) {
  const [colors, setColors] = useState({...initialColors})
  const [openPopover, setOpenPopover] = useState(null)
  const lastSelectedStatusRef = useRef<string>()

  const bindColorPickerButton = status => button => {
    colorPickerButtons[status] = button
  }

  const bindColorPickerContent = status => content => {
    colorPickerContents[status] = content
  }

  const updateStatusColors = status => color => {
    const newColors = {...colors, [status]: color}
    setColors(newColors)
    setOpenPopover(null)
    onColorsUpdated(newColors)
  }

  const handleOnToggle = status => toggle => {
    setOpenPopover(toggle ? status : null)
  }

  const handleColorPickerAfterClose = _status => () => {
    setOpenPopover(null)
  }

  useEffect(() => {
    if (openPopover == null) {
      colorPickerButtons[lastSelectedStatusRef.current || '']?.focus()
    } else {
      lastSelectedStatusRef.current = openPopover
    }
  }, [openPopover])

  return (
    <ul className="Gradebook__StatusModalList">
      {statuses.map(status => (
        <StatusColorListItem
          key={status}
          status={status}
          color={colors[status]}
          isColorPickerShown={openPopover === status}
          colorPickerOnToggle={handleOnToggle(status)}
          colorPickerButtonRef={bindColorPickerButton(status)}
          colorPickerContentRef={bindColorPickerContent(status)}
          colorPickerAfterClose={handleColorPickerAfterClose(status)}
          afterSetColor={updateStatusColors(status)}
        />
      ))}
    </ul>
  )
}

StatusColorPanel.propTypes = {
  colors: shape({
    late: string.isRequired,
    missing: string.isRequired,
    resubmitted: string.isRequired,
    dropped: string.isRequired,
    excused: string.isRequired,
  }).isRequired,
  onColorsUpdated: func.isRequired,
}
