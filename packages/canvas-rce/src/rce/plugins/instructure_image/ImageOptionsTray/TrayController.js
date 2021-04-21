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
import ReactDOM from 'react-dom'

import bridge from '../../../../bridge'
import {asImageEmbed} from '../../shared/ContentSelection'
import {renderLink} from '../../../contentRendering'
import ImageOptionsTray from '.'

export const CONTAINER_ID = 'instructure-image-options-tray-container'

export default class TrayController {
  constructor() {
    this._editor = null
    this._isOpen = false
    this._shouldOpen = false
    this._renderId = 0
  }

  get $container() {
    let $container = document.getElementById(CONTAINER_ID)
    if ($container == null) {
      $container = document.createElement('div')
      $container.id = CONTAINER_ID
      document.body.appendChild($container)
    }
    return $container
  }

  get isOpen() {
    return this._isOpen
  }

  showTrayForEditor(editor) {
    this._editor = editor
    this.$img = editor.selection.getNode()
    this._shouldOpen = true

    if (bridge.focusedEditor) {
      // Dismiss any content trays that may already be open
      bridge.hideTrays()
    }

    this._renderTray()
  }

  hideTrayForEditor(editor) {
    if (this._editor === editor) {
      this._dismissTray()
    }
  }

  _applyImageOptions(imageOptions) {
    const editor = this._editor
    const {$img} = this

    if (imageOptions.displayAs === 'embed') {
      editor.dom.setAttribs($img, {
        alt: imageOptions.altText,
        role: imageOptions.isDecorativeImage ? 'presentation' : null,
        width: imageOptions.appliedWidth,
        height: imageOptions.appliedHeight,
        'data-decorative': imageOptions.isDecorativeImage ? true : null // should be replaced by role=presentation once a11y-checker supports it
      })

      // tell tinymce so the context toolbar resets
      editor.fire('ObjectResized', {
        target: $img,
        width: imageOptions.appliedWidth,
        height: imageOptions.appliedHeight
      })
    } else {
      const link = renderLink({
        href: $img.src,
        text: imageOptions.altText || $img.src,
        target: '_blank'
      })
      editor.selection.setContent(link)
    }
    this._dismissTray()
    editor.focus()
  }

  _dismissTray() {
    this._shouldOpen = false
    this._renderTray()
    this.$img = null
    this._editor = null
  }

  _renderTray() {
    if (this._shouldOpen) {
      /*
       * When the tray is being opened again, it should be rendered fresh
       * (clearing the internal state) so that the currently-selected image can
       * be used for initial image options.
       */
      this._renderId++
    }
    const io = asImageEmbed(this.$img)
    io.isLinked = this._editor.selection.getSel().anchorNode.tagName === 'A'

    const element = (
      <ImageOptionsTray
        key={this._renderId}
        imageOptions={io}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={() => {
          bridge.focusActiveEditor(false)
          this._isOpen = false
        }}
        onSave={imageOptions => {
          this._applyImageOptions(imageOptions)
        }}
        onRequestClose={() => this._dismissTray()}
        open={this._shouldOpen}
      />
    )
    ReactDOM.render(element, this.$container)
  }
}
