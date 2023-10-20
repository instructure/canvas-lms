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
import bridge from '../../../../../bridge'
import {isOnlyTextSelected, getAnchorElement} from '../../../../contentInsertionUtils'
import LinkOptionsDialog from './index'

export const CONTAINER_ID = 'instructure-link-options-tray-container'
export const CREATE_LINK = 'create'
export const EDIT_LINK = 'edit'
export default class LinkOptionsDialogController {
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

  showDialogForEditor(editor, op) {
    this._editor = editor
    this._shouldOpen = true
    this._op = op
    this._renderDialog()
  }

  hideDialog() {
    this._dismissDialog()
  }

  _applyLinkOptions(linkOptions) {
    this._dismissDialog()
    bridge.insertLink(linkOptions)
  }

  _dismissDialog = () => {
    this._shouldOpen = false
    this._renderDialog()
  }

  _hasClosed = () => {
    bridge.focusActiveEditor(false)
    this._isOpen = false
    this._editor.focus(false)
    this._editor = null
  }

  _renderDialog() {
    let html, onlyText, anchorElm, url, text

    if (this._shouldOpen) {
      html = this._editor.selection.getContent()
      onlyText = isOnlyTextSelected(html)
      text = onlyText && this._editor.selection.getContent({format: 'text'})
      anchorElm = getAnchorElement(this._editor, this._editor.selection.getNode())
      url = anchorElm?.getAttribute('href')

      /*
       * When the dialog is being opened again, it should be rendered fresh
       * (clearing the internal state) so that the currently-selected content
       * can be used for initial options.
       */
      this._renderId++
    }
    const element = (
      <LinkOptionsDialog
        key={this._renderId}
        size="medium"
        showText={onlyText}
        text={text}
        url={url}
        operation={this._op}
        onEntered={() => {
          this._isOpen = true
        }}
        onExited={this._hasClosed}
        onRequestClose={this._dismissDialog}
        onSave={linkOptions => {
          bridge.focusEditor(this._editor.rceWrapper)
          this._applyLinkOptions(linkOptions)
        }}
        open={this._shouldOpen}
      />
    )
    ReactDOM.render(element, this.$container)
  }
}
