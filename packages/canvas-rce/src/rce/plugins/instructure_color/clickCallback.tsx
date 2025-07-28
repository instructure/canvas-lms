/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {createRoot} from 'react-dom/client'
import {Editor} from 'tinymce'
import tinycolor from 'tinycolor2'
import {ColorPopup} from './components/ColorPopup'
import {type ColorSpec} from './components/ColorPicker'

const CONTAINER_ID = 'instructure-color-popup-container'

declare global {
  interface HTMLElement {
    _reactRoot?: any
  }
}

export default function (editor: Editor) {
  let container = document.getElementById(CONTAINER_ID)
  if (container == null) {
    container = document.createElement('div')
    container.id = CONTAINER_ID
    document.body.appendChild(container)
  }

  const handleDismiss = () => {
    if (container) {
      container._reactRoot?.unmount()
      container._reactRoot = null
    }
  }

  const handleChange = (newcolors: ColorSpec) => {
    editor.undoManager.transact(() => {
      if (newcolors.fgcolor) {
        editor.execCommand('forecolor', false, newcolors.fgcolor)
      }
      if (newcolors.bgcolor) {
        editor.execCommand('hilitecolor', false, newcolors.bgcolor)
      }
      if (newcolors.fgcolor || newcolors.bgcolor) {
        editor.nodeChanged()
      }
      handleDismiss()
    })
  }

  if (container?._reactRoot) {
    handleDismiss()
    document.removeEventListener('rce-text-block-popup-close', handleDismiss)
    return
  }

  document.addEventListener('rce-text-block-popup-close', handleDismiss)

  const defaultTextColor = window
    .getComputedStyle(editor.getBody())
    .getPropertyValue('--ic-brand-font-color-dark')
    .toLowerCase()

  const styl = window.getComputedStyle(editor.selection.getNode())
  const textColor = tinycolor(styl.getPropertyValue('color')).toHexString()

  const bgColor_ = tinycolor(styl.getPropertyValue('background-color'))
  const bgColor = bgColor_.getAlpha() === 1 ? bgColor_.toHexString() : bgColor_.toHex8String()

  const target = document.querySelector('svg[data-id="color-button"]') as HTMLElement
  const root = createRoot(container)
  container._reactRoot = root
  root.render(
    <ColorPopup
      tabs={{
        foreground: {
          color: textColor,
          default: defaultTextColor,
        },
        background: {
          color: bgColor,
          default: '#ffffff',
        },
        effectiveBgColor: '#ffffff',
      }}
      open={true}
      positionTarget={target}
      onCancel={handleDismiss}
      onChange={handleChange}
    />,
  )
}
