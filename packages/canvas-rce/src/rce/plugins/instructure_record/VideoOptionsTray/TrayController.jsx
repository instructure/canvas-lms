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
import {asVideoElement, findMediaPlayerIframe} from '../../shared/ContentSelection'
import VideoOptionsTray from '.'
import {isStudioEmbeddedMedia, parseStudioOptions} from '../../shared/StudioLtiSupportUtils'
import RCEGlobals from '../../../RCEGlobals'

export const CONTAINER_ID = 'instructure-video-options-tray-container'

export const VIDEO_SIZE_DEFAULT = {height: '225px', width: '400px'} // AKA "LARGE"
export const AUDIO_PLAYER_SIZE = {width: '320px', height: '14.25rem'}

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
    this.$videoContainer = findMediaPlayerIframe(editor.selection.getNode())
    this._shouldOpen = true

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

  _applyVideoOptions(videoOptions) {
    if (this.$videoContainer?.tagName === 'IFRAME') {
      const $tinymceIframeShim = this.$videoContainer.parentElement
      if (videoOptions.displayAs === 'embed') {
        const isVertical = videoOptions.appliedHeight > videoOptions.appliedWidth
        // player v5 requires more space for the CC button
        // TODO: remove when using v7
        const minWidth = videoOptions.subtitles?.length ? 400 : 320
        const styl = {
          height: `${videoOptions.appliedHeight}px`,
          width: `${Math.max(
            minWidth,
            isVertical ? videoOptions.appliedHeight : videoOptions.appliedWidth
          )}px`,
        }
        this._editor.dom.setStyles($tinymceIframeShim, styl)
        this._editor.dom.setStyles(this.$videoContainer, styl)

        const title = videoOptions.titleText
        this._editor.dom.setAttrib($tinymceIframeShim, 'data-mce-p-title', title)
        this._editor.dom.setAttrib(
          $tinymceIframeShim,
          'data-mce-p-data-titleText',
          videoOptions.titleText
        )
        this._editor.dom.setAttrib(this.$videoContainer, 'title', title)
        this._editor.dom.setAttrib(this.$videoContainer, 'data-titleText', videoOptions.titleText)

        // tell tinymce so the context toolbar resets
        this._editor.fire('ObjectResized', {
          target: this.$videoContainer,
          width: videoOptions.appliedWidth,
          height: videoOptions.appliedHeight,
        })
      } else {
        const href = this._editor.dom.getAttrib($tinymceIframeShim, 'data-mce-p-src')
        const title =
          videoOptions.titleText || this._editor.dom.getAttrib(this.$videoContainer, 'title')
        const link = document.createElement('a')
        link.setAttribute('href', href)
        link.setAttribute('target', '_blank')
        link.setAttribute('rel', 'noreferrer noopener')
        link.textContent = title
        this._editor.dom.replace(link, $tinymceIframeShim)
        this._editor.selection.select(link)
        this.$videoContainer = null
      }

      const data = {
        media_object_id: videoOptions.media_object_id,
        title: videoOptions.titleText,
        subtitles: videoOptions.subtitles,
      }

      if (RCEGlobals.getFeatures().media_links_use_attachment_id) {
        data.attachment_id = videoOptions.attachment_id
      }

      // If the video just edited came from a file uploaded to canvas
      // and not notorious, we probably don't have a media_object_id.
      // If not, we can't update the MediaObject in the canvas db.
      if (videoOptions.media_object_id && videoOptions.media_object_id !== 'undefined' && !videoOptions.editLocked) {
        videoOptions
          .updateMediaObject(data)
          .then(_r => {
            if (this.$videoContainer && videoOptions.displayAs === 'embed') {
              this.$videoContainer.contentWindow.postMessage(
                {subject: 'reload_media', media_object_id: videoOptions.media_object_id},
                bridge.canvasOrigin
              )
            }
          })
          .catch(ex => {
            console.error('failed updating video captions', ex) // eslint-disable-line no-console
          })
      }
    }
    this._dismissTray()
  }

  _dismissTray() {
    if (this.$videoContainer) {
      this._editor?.selection?.select(this.$videoContainer)
    }
    this._shouldOpen = false
    this._renderTray()
    this._editor = null
  }

  requestSubtitlesFromIframe(cb) {
    if (!bridge.canvasOrigin) return

    this._subtitleListener = new AbortController()
    window.addEventListener('message', (event) => {
      if (event?.data?.subject === "media_tracks_response") {
        cb(event?.data?.payload)
      }
    }, {signal: this._subtitleListener.signal})

    this.$videoContainer?.contentWindow?.postMessage(
      {subject: 'media_tracks_request'},
      bridge.canvasOrigin
    )
  }

  _renderTray(trayProps) {
    let vo = {}

    if (this._shouldOpen) {
      /*
       * When the tray is being opened again, it should be rendered fresh
       * (clearing the internal state) so that the currently-selected video can
       * be used for initial video options.
       */
      this._renderId++
      vo = asVideoElement(this.$videoContainer) || {}
    }

    const element = (
      <VideoOptionsTray
        id="video-options-tray"
        key={this._renderId}
        videoOptions={vo}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={() => {
          bridge.focusActiveEditor(false)
          this._isOpen = false
          this._subtitleListener?.abort()
        }}
        onSave={videoOptions => {
          this._applyVideoOptions(videoOptions)
        }}
        onRequestClose={() => this._dismissTray()}
        open={this._shouldOpen}
        trayProps={trayProps}
        studioOptions={
          isStudioEmbeddedMedia(this.$videoContainer)
            ? parseStudioOptions(this.$videoContainer)
            : null
        }
        requestSubtitlesFromIframe={(cb) => this.requestSubtitlesFromIframe(cb)}
      />
    )
    ReactDOM.render(element, this.$container)
  }
}
