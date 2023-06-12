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
import {fileEmbed} from '../common/mimeClass'

/* eslint no-console: 0 */
export default class Bridge {
  constructor() {
    this.focusedEditor = null // the RCEWrapper, not tinymce
    this.resolveEditorRendered = null

    this._editorRendered = new Promise(resolve => {
      this.resolveEditorRendered = resolve
    })

    this.trayProps = new WeakMap()
    this.userLocale = 'en'
    this._controller = {}
    this._uploadMediaTranslations = null
    this._canvasOrigin = ''
  }

  get editorRendered() {
    return this._editorRendered
  }

  controller(editorId) {
    return this._controller[editorId]
  }

  activeEditor() {
    return this.focusedEditor
  }

  focusEditor(editor) {
    if (this.focusedEditor !== editor) {
      this.hideTrays()
    }
    this.focusedEditor = editor
  }

  blurEditor(editor) {
    if (this.focusedEditor === editor) {
      this.hideTrays()
      this.focusedEditor = null
    }
  }

  focusActiveEditor(skipFocus = false) {
    this.focusedEditor?.mceInstance?.()?.focus(skipFocus)
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

  get canvasOrigin() {
    return this._canvasOrigin
  }

  set canvasOrigin(origin) {
    this._canvasOrigin = origin
  }

  // we have to defer importing mediaTranslations until they are asked for
  // or they get imported before the locale has been setup and all the strings
  // are in English
  get uploadMediaTranslations() {
    if (!this._uploadMediaTranslations) {
      const module = require('../rce/plugins/instructure_record/mediaTranslations')
      this._uploadMediaTranslations = module.default
    }
    return this._uploadMediaTranslations
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

  attachController(controller, editorId) {
    this._controller[editorId] = controller
  }

  detachController(editorId) {
    delete this._controller[editorId]
  }

  showTrayForPlugin(plugin, editorId) {
    this._controller[editorId]?.showTrayForPlugin(plugin)
  }

  hideTrays() {
    Object.keys(this._controller).forEach(eid => {
      this._controller[eid].hideTray(true)
    })
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

  insertLink = link => {
    if (this.focusedEditor) {
      const {selection} = this.focusedEditor.props.tinymce.get(this.focusedEditor.props.textareaId)
      link.selectionDetails = {
        node: selection.getNode(),
        range: selection.getRng(),
      }
      if (!link.text || link.text.trim().length === 0) {
        link.text = link.title || link.href
      }
      this.focusedEditor.insertLink(link)
      this.controller(this.focusedEditor.id)?.hideTray()
    } else {
      console.warn('clicked sidebar link without a focused editor')
    }
  }

  // insertFileLink is called from the FileBrowser when All files is chosen
  // vs the above insertLink which is called from the other CanvasContentTray panels.
  insertFileLink = link => {
    const embedData = fileEmbed(link)

    if (embedData.type === 'image') {
      return this.insertImage(link)
    } else if (embedData.type === 'video' || embedData.type === 'audio') {
      link.embedded_iframe_url = link.embedded_iframe_url || link.href
      return this.embedMedia(link)
    }
    return this.insertLink(link)
  }

  insertImage(image) {
    if (this.focusedEditor) {
      const result = this.focusedEditor.insertImage(image)
      this.controller(this.focusedEditor.id)?.hideTray()
      return result
    } else {
      console.warn('clicked sidebar image without a focused editor')
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    if (this.focusedEditor) {
      // don't insert a placeholder if the user has selected content, because in some cases the selected
      // content will be used as the content of a link
      if (!this.existingContentToLink()) {
        this.focusedEditor.insertImagePlaceholder(fileMetaProps)
      }
    } else {
      console.warn('clicked sidebar image without a focused editor')
    }
  }

  removePlaceholders(name) {
    if (this.focusedEditor) {
      this.focusedEditor.removePlaceholders(name)
    }
  }

  showError(err) {
    if (this.focusedEditor) {
      this.focusedEditor.addAlert({
        text: err.toString(),
        type: 'error',
      })
    }
  }

  embedImage = image => {
    if (this.existingContentToLink() && !this.existingContentToLinkIsImg()) {
      this.insertLink({
        title: image.display_name,
        href: image.href,
        embed: {type: 'image'},
      })
    } else {
      this.insertImage(image)
    }
  }

  embedMedia = media => {
    const embedData = fileEmbed(media)

    if (embedData.type === 'video') {
      this.insertVideo(media)
    } else {
      this.insertAudio(media)
    }
  }

  insertEmbedCode = embedCode => {
    this.focusedEditor.insertEmbedCode(embedCode)
  }

  insertVideo = video => {
    if (this.focusedEditor) {
      this.focusedEditor.insertVideo(video)
      this.controller(this.focusedEditor.id)?.hideTray()
    }
  }

  insertAudio = audio => {
    if (this.focusedEditor) {
      this.focusedEditor.insertAudio(audio)
      this.controller(this.focusedEditor.id)?.hideTray()
    }
  }
}
