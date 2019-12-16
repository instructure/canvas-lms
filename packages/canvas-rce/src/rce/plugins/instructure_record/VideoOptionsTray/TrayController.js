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
import {asVideoElement} from '../../shared/ContentSelection'
import VideoOptionsTray from '.'

export const CONTAINER_ID = 'instructure-video-options-tray-container'

export const VIDEO_SIZE_DEFAULT = {height: '225px', width: '400px'} // AKA "LARGE"
export const AUDIO_PLAYER_SIZE = {width: '300px', height: '2.813rem'}

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
    this.$videoContainer = editor.selection.getNode()
    this._shouldOpen = true
    this._renderTray()
  }

  hideTrayForEditor(editor) {
    if (this._editor === editor) {
      this._dismissTray()
    }
  }

  _applyVideoOptions(videoOptions) {
    if (this.$videoContainer && this.$videoContainer.firstElementChild?.tagName === 'IFRAME') {
      if (videoOptions.displayAs === 'embed') {
        const styl = {
          height: `${videoOptions.appliedHeight}px`,
          width: `${videoOptions.appliedWidth}px`
        }
        this._editor.dom.setStyles(this.$videoContainer, styl)
        this._editor.dom.setStyles(this.$videoContainer.firstElementChild, styl)

        const title = videoOptions.titleText
        this._editor.dom.setAttrib(this.$videoContainer, 'data-mce-p-title', title)
        this._editor.dom.setAttrib(
          this.$videoContainer,
          'data-mce-p-data-titleText',
          videoOptions.titleText
        )
        this._editor.dom.setAttrib(this.$videoContainer.firstElementChild, 'title', title)
        this._editor.dom.setAttrib(
          this.$videoContainer.firstElementChild,
          'data-titleText',
          videoOptions.titleText
        )

        // tell tinymce so the context toolbar resets
        this._editor.fire('ObjectResized', {
          target: this.$videoContainer,
          width: videoOptions.appliedWidth,
          height: videoOptions.appliedHeight
        })
      } else {
        const href = this._editor.dom.getAttrib(this.$videoContainer, 'data-mce-p-src')
        const title =
          videoOptions.titleText ||
          this._editor.dom.getAttrib(this.$videoContainer.firstElementChild, 'title')
        const link = document.createElement('a')
        link.setAttribute('href', href)
        link.setAttribute('target', '_blank')
        link.setAttribute('rel', 'noreferrer noopener')
        link.textContent = title
        this._editor.dom.replace(link, this.$videoContainer)
        this._editor.selection.select(link)
        this.$videoContainer = null
      }
    }
    this._dismissTray()
  }

  _dismissTray() {
    if (this.$videoContainer) {
      this._editor.selection.select(this.$videoContainer)
    }
    this._shouldOpen = false
    this._renderTray()
    this._editor = null
  }

  _renderTray() {
    let vo = {}
    if (this._shouldOpen) {
      /*
       * When the tray is being opened again, it should be rendered fresh
       * (clearing the internal state) so that the currently-selected video can
       * be used for initial video options.
       */
      this._renderId++
      vo = asVideoElement(this.$videoContainer)
    }

    const element = (
      <VideoOptionsTray
        key={this._renderId}
        videoOptions={vo}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={() => {
          bridge.focusActiveEditor(false)
          this._isOpen = false
        }}
        onSave={videoOptions => {
          this._applyVideoOptions(videoOptions)
        }}
        onRequestClose={() => this._dismissTray()}
        open={this._shouldOpen}
      />
    )
    ReactDOM.render(element, this.$container)
  }
}
