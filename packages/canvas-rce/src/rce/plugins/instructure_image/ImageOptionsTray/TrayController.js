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

import ImageOptionsTray from '.'

export const CONTAINER_ID = 'instructure-image-options-tray-container'

export default class TrayController {
  constructor() {
    this._editor = null
    this._isOpen = false
    this._shouldOpen = false
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
    this._shouldOpen = true
    this._renderTray()
  }

  hideTrayForEditor(editor) {
    if (this._editor === editor) {
      this._dismissTray()
    }
  }

  _dismissTray() {
    this._shouldOpen = false
    this._renderTray()
    this._editor = null
  }

  _renderTray() {
    const $img = this._editor.selection.getNode()

    const element = (
      <ImageOptionsTray
        imageElement={$img}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={() => {
          this._isOpen = false
        }}
        onRequestClose={() => this._dismissTray()}
        open={this._shouldOpen}
      />
    )
    ReactDOM.render(element, this.$container)
  }
}
