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
import RCEGlobals from '../../../RCEGlobals'
import {asAudioElement} from '../../shared/ContentSelection'
import {findMediaPlayerIframe} from '../../shared/iframeUtils'
import AudioOptionsTray from '.'

export const CONTAINER_ID = 'instructure-audio-options-tray-container'

export default class TrayController {
  constructor() {
    this._isOpen = false
    this._shouldOpen = false
    this._editor = null
    this._audioContainer = null
    this._captionsModified = false
    this.requestSubtitlesFromIframe = this.requestSubtitlesFromIframe.bind(this)
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
    this._captionsModified = false
    this._isPlayerReady = false

    if (bridge.focusedEditor) {
      // Dismiss any content trays that may already be open
      bridge.hideTrays()
    }

    this._renderTray()

    const audioOptions = asAudioElement(this._audioContainer)
    // Clean broadcast listeners for any existing trays which are not shown (if not cleaned automatically)
    this._iframeLoadingListener?.abort()
    this._listenForPlayerIframeToLoad(audioOptions.id)
  }

  hideTrayForEditor(editor) {
    if (this._editor === editor) {
      this._dismissTray()
    }
  }

  _listenForPlayerIframeToLoad(currentMediaId) {
    if (!bridge.canvasOrigin) return

    this._iframeLoadingListener = new AbortController()

    // Wait for player iframe to be loaded
    window.addEventListener(
      'message',
      event => {
        // If tray was opened before player iframe was ready it will catch ready event.
        // If not it will request it later and catch it here anyway.
        if (
          event.data?.subject === 'media_player.iframe_ready' &&
          event.data?.mediaId === currentMediaId
        ) {
          this._iframeLoadingListener.abort()
          this._isPlayerReady = true
          this._renderTray()
        }
      },
      {signal: this._iframeLoadingListener.signal},
    )

    // If tray was opened after player was loaded we need to request iframe_ready state
    this._audioContainer?.contentWindow?.postMessage(
      {subject: 'media_player.get_ready_state'},
      bridge.canvasOrigin,
    )
  }

  _reloadAudioPlayer() {
    if (this._audioContainer?.contentWindow?.location) {
      this._audioContainer.contentWindow.location.reload()
    }
  }

  _dismissTray() {
    const isCaptionImprovements = RCEGlobals.getFeatures()?.rce_asr_captioning_improvements || false

    // Reload if captions were modified AND feature flag enabled
    if (isCaptionImprovements && this._captionsModified && this._audioContainer) {
      this._reloadAudioPlayer()
    }

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
    this._iframeLoadingListener?.abort()
    const elem = document.getElementById(CONTAINER_ID)
    return elem.parentNode.removeChild(elem)
  }

  _applyAudioOptions(audioOptions) {
    const hasAttachmentId = audioOptions.attachment_id

    if (
      !hasAttachmentId &&
      (!audioOptions.media_object_id || audioOptions.media_object_id === 'undefined')
    ) {
      return
    }
    const container = this._audioContainer

    const isCaptionImprovements = RCEGlobals.getFeatures()?.rce_asr_captioning_improvements || false

    const data = {
      media_object_id: audioOptions.media_object_id,
      attachment_id: audioOptions.attachment_id,
      subtitles: audioOptions.subtitles,
      skipCaptionUpdate: isCaptionImprovements,
    }

    return audioOptions
      .updateMediaObject(data)
      .then(() => container?.contentWindow.location.reload())
      .catch(ex => {
        console.error('Failed updating audio captions', ex)
      })
  }

  requestSubtitlesFromIframe(cb) {
    if (!bridge.canvasOrigin) return

    this._subtitleListener = new AbortController()

    window.addEventListener(
      'message',
      event => {
        if (event?.data?.subject === 'media_tracks_response') {
          cb(event?.data?.payload)
        }
      },
      {signal: this._subtitleListener.signal},
    )

    this._audioContainer?.contentWindow?.postMessage(
      {subject: 'media_tracks_request'},
      bridge.canvasOrigin,
    )
  }

  _renderTray() {
    const audioOptions = asAudioElement(this._audioContainer) || {}

    const element = (
      <AudioOptionsTray
        key={audioOptions.id}
        audioOptions={audioOptions}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={() => {
          bridge.focusActiveEditor(false)
          this._isOpen = false
          this._subtitleListener?.abort()
          this._iframeLoadingListener?.abort()
          this._isPlayerReady = false
        }}
        onSave={options => {
          this._applyAudioOptions(options)
          this._dismissTray()
        }}
        onDismiss={() => this._dismissTray()}
        onCaptionsModified={() => {
          this._captionsModified = true
        }}
        open={this._shouldOpen}
        trayProps={bridge.trayProps.get(this._editor)}
        requestSubtitlesFromIframe={this.requestSubtitlesFromIframe}
        isLoading={!this._isPlayerReady}
      />
    )
    ReactDOM.render(element, this.container)
  }
}
