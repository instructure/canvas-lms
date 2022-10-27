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

import React from 'react'
import ReactDOM from 'react-dom'

import bridge from '../../../../bridge'
import {asAudioElement, findMediaPlayerIframe} from '../../shared/ContentSelection'
import AudioOptionsTray from '.'

export const CONTAINER_ID = 'instructure-audio-options-tray-container'

export default class TrayController {
  constructor() {
    this._isOpen = false
    this._shouldOpen = false
    this._editor = null
    this._audioContainer = null
  }

  get container() {
    let _container = document.getElementById(CONTAINER_ID)
    if (_container == null) {
      _container = document.createElement('div')
      _container.id = CONTAINER_ID
      document.body.appendChild(_container)
    }
    return _container
  }

  get isOpen() {
    return this._isOpen
  }

  showTrayForEditor(editor) {
    this._shouldOpen = true
    this._editor = editor
    this._audioContainer = findMediaPlayerIframe(editor.selection.getNode())

    if (bridge.focusedEditor) {
      // Dismiss any content trays that may already be open
      bridge.hideTrays()
    }

    const trayProps = bridge.trayProps.get(editor)
    this._renderTray(trayProps)
  }

  hideTrayForEditor(editor) {
    if (this._editor === editor) {
      this._dismissTray()
    }
  }

  _dismissTray() {
    if (this._audioContainer) {
      this._editor.selection.select(this._audioContainer)
    }
    this._resetController()
  }

  _resetController() {
    this._shouldOpen = false
    this._renderTray()
    this._editor = null
    this._audioContainer = null
    const elem = document.getElementById(CONTAINER_ID)
    return elem.parentNode.removeChild(elem)
  }

  _applyAudioOptions(audioOptions) {
    if (!audioOptions.media_object_id || audioOptions.media_object_id === 'undefined') {
      return
    }
    const container = this._audioContainer
    return audioOptions
      .updateMediaObject({
        media_object_id: audioOptions.media_object_id,
        subtitles: audioOptions.subtitles,
      })
      .then(() => container?.contentWindow.location.reload())
      .catch(ex => {
        // eslint-disable-next-line no-console
        console.error('Failed updating audio captions', ex)
      })
  }

  _renderTray(trayProps) {
    let audioOptions = {}

    if (this._shouldOpen) {
      audioOptions = asAudioElement(this._audioContainer)
    }

    const element = (
      <AudioOptionsTray
        audioOptions={audioOptions}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={() => {
          bridge.focusActiveEditor(false)
          this._isOpen = false
        }}
        onSave={options => {
          this._applyAudioOptions(options)
          this._dismissTray()
        }}
        onDismiss={() => this._dismissTray()}
        open={this._shouldOpen}
        trayProps={trayProps}
      />
    )
    ReactDOM.render(element, this.container)
  }
}
