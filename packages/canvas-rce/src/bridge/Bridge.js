/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import K5Uploader from '@instructure/k5uploader'

/* eslint no-console: 0 */
export default class Bridge {
  constructor() {
    this.focusedEditor = null
    this.resolveEditorRendered = null

    this._editorRendered = new Promise(resolve => {
      this.resolveEditorRendered = resolve
    })

    this.trayProps = new WeakMap()
  }

  get editorRendered() {
    return this._editorRendered
  }

  get controller() {
    return this._controller
  }

  activeEditor() {
    return this.focusedEditor
  }

  focusEditor(editor) {
    this.focusedEditor = editor
  }

  focusActiveEditor(skipFocus = false) {
    this.getEditor()
      .mceInstance()
      .focus(skipFocus)
  }

  get mediaServerSession() {
    return this._mediaServerSession
  }

  get mediaServerUploader() {
    return this._mediaServerUploader
  }

  setMediaServerSession(session) {
    this._mediaServerSession = session
    if (this._mediaServerUploader) {
      this._mediaServerUploader.destroy()
      this._mediaServerUploader = null
    }
    this._mediaServerUploader = new K5Uploader(session)
  }

  detachEditor(editor) {
    if (editor === this.focusedEditor) {
      this.focusedEditor = null
    }
  }

  getEditor() {
    return this.focusedEditor
  }

  renderEditor(editor) {
    this.resolveEditorRendered()
    if (this.focusedEditor === null) {
      this.focusEditor(editor)
    }
  }

  attachController(controller) {
    this._controller = controller
  }

  detachController() {
    this._controller = null
  }

  showTrayForPlugin(plugin) {
    this._controller && this._controller.showTrayForPlugin(plugin)
  }

  existingContentToLink() {
    if (this.focusedEditor) {
      return this.focusedEditor.existingContentToLink()
    }
    return false
  }

  existingContentToLinkIsImg() {
    if (this.focusedEditor) {
      return this.focusedEditor.existingContentToLinkIsImg()
    }
    return false
  }

  insertLink = (link, fromTray = true) => {
    if (this.focusedEditor) {
      const {selection} = this.focusedEditor.props.tinymce.get(this.focusedEditor.props.textareaId)
      link.selectionDetails = {
        node: selection.getNode(),
        range: selection.getRng()
      }
      if (!link.text) {
        link.text = link.title || link.href
      }
      this.focusedEditor.insertLink(link)
      if (fromTray && this.controller) {
        this.controller.hideTray()
      }
    } else {
      console.warn('clicked sidebar link without a focused editor')
    }
  }

  insertImage(image) {
    if (this.focusedEditor) {
      this.focusedEditor.insertImage(image)
      if (this.controller) {
        this.controller.hideTray()
      }
    } else {
      console.warn('clicked sidebar image without a focused editor')
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    if (this.focusedEditor) {
      this.focusedEditor.insertImagePlaceholder(fileMetaProps)
    } else {
      console.warn('clicked sidebar image without a focused editor')
    }
  }

  removePlaceholders(name) {
    if (this.focusedEditor) {
      this.focusedEditor.removePlaceholders(name)
    }
  }

  embedImage = image => {
    if (this.existingContentToLink() && !this.existingContentToLinkIsImg()) {
      this.insertLink({
        title: image.display_name,
        href: image.href,
        embed: {type: 'image'}
      })
    } else {
      this.insertImage(image)
    }
  }

  embedMedia = media => {
    if (/video/.test(media.type || media.content_type)) {
      this.insertVideo(media)
    } else {
      this.insertAudio(media)
    }
  }

  insertVideo = video => {
    if (this.focusedEditor) {
      this.focusedEditor.insertVideo(video)
    }
    if (this.controller) {
      this.controller.hideTray()
    }
  }

  insertAudio = audio => {
    if (this.focusedEditor) {
      this.focusedEditor.insertAudio(audio)
    }
    if (this.controller) {
      this.controller.hideTray()
    }
  }
}
