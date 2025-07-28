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
import {getStatuses} from '../constants/statuses'
import StatusColorListItem from './StatusColorListItem'
import type {StatusColors} from '../constants/colors'

interface ColorPickerRefs {
  [key: string]: Element | null
}

const colorPickerButtons: ColorPickerRefs = {}
const colorPickerContents: ColorPickerRefs = {}

interface StatusColorPanelProps {
  colors: StatusColors
  onColorsUpdated: (colors: StatusColors) => void
}

export default function StatusColorPanel({
  colors: initialColors,
  onColorsUpdated,
}: StatusColorPanelProps) {
  const [colors, setColors] = useState<StatusColors>({...initialColors})
  const [openPopover, setOpenPopover] = useState<string | null>(null)
  const lastSelectedStatusRef = useRef<string>()

  const bindColorPickerButton = (status: string) => (button: Element | null) => {
    colorPickerButtons[status] = button
  }

  const bindColorPickerContent = (status: string) => (content: Element | null) => {
    colorPickerContents[status] = content
  }

  const updateStatusColors = (status: keyof StatusColors) => (color: string) => {
    const newColors = {...colors, [status]: color}
    setColors(newColors)
    setOpenPopover(null)
    onColorsUpdated(newColors)
  }

  const handleOnToggle = (status: string) => (toggle: boolean) => {
    setOpenPopover(toggle ? status : null)
  }

  const handleColorPickerAfterClose = (_status: string) => () => {
    setOpenPopover(null)
  }

  useEffect(() => {
    if (openPopover == null) {
      const button = colorPickerButtons[lastSelectedStatusRef.current || '']
      if (button instanceof HTMLElement) {
        button.focus()
      }
    } else {
      lastSelectedStatusRef.current = openPopover
    }
  }, [openPopover])

  return (
    <ul className="Gradebook__StatusModalList">
      {getStatuses().map(status => (
        <StatusColorListItem
          key={status}
          status={status}
          color={colors[status as keyof StatusColors]}
          isColorPickerShown={openPopover === status}
          colorPickerOnToggle={handleOnToggle(status)}
          colorPickerButtonRef={bindColorPickerButton(status)}
          colorPickerContentRef={bindColorPickerContent(status)}
          colorPickerAfterClose={handleColorPickerAfterClose(status)}
          afterSetColor={updateStatusColors(status as keyof StatusColors)}
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
    extended: string.isRequired,
  }).isRequired,
  onColorsUpdated: func.isRequired,
}
