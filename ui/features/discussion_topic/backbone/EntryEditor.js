/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import EditorToggle from '@canvas/editor-toggle'
import apiUserContent from '@canvas/util/jquery/apiUserContent'

const I18n = useI18nScope('EntryEditor')

/*
xsslint safeString.property content
*/

// #
// Makes an EntryView's model message editable with TinyMCE
//
// ex:
//
//   editor = new EntryEditor(EntryView)
//   editor.edit()    # turns the content into a TinyMCE editor box
//   editor.display() # closes editor, saves model
//
export default class EntryEditor extends EditorToggle {
  // #
  // @param {EntryView} view
  constructor(view) {
    super(view.$('.message:first'), {switchViews: true, view})
    this.cancelButton = this.createCancelButton()
    this.$delAttachmentButton = this.createDeleteAttachmentButton()
    this.done.addClass('btn-small')
  }

  // #
  // Extends EditorToggle::display to save the model's message.
  //
  // @param {Bool} opts.cancel - doesn't submit
  // @api public
  display(opts) {
    super.display(opts)
    this.cancelButton.detach()
    this.$delAttachmentButton.detach()
    if ((opts && opts.cancel) !== true) {
      if (this.remove_attachment) {
        this.view.model.set('attachments', null)
        this.view.model.set('attachment', null)
      }

      this.view.model.set('updated_at', new Date().toISOString())
      this.view.model.set('editor', ENV.current_user)

      return this.view.model.save(
        {
          messageNotification: I18n.t('Saving...'),
          message: this.content,
        },
        {
          success: this.onSaveSuccess.bind(this),
          error: this.onSaveError.bind(this),
        }
      )
    } else {
      return this.getAttachmentElement().show() // may have been hidden if user deleted attachment then cancelled
    }
  }

  createCancelButton() {
    return (
      $('<a/>')
        .text(I18n.t('Cancel'))
        .css({marginLeft: '5px'})
        // eslint-disable-next-line no-script-url
        .attr('href', 'javascript:')
        .addClass('cancel_button')
        .click(() => {
          this.cancel()
          this.display({cancel: true})
        })
    )
  }

  createDeleteAttachmentButton() {
    return (
      $('<a/>')
        // eslint-disable-next-line no-script-url
        .attr('href', 'javascript:')
        .text('x')
        .addClass('cancel_button')
        .attr('aria-label', I18n.t('Remove Attachment'))
        // fontSize copied from discussions_edit so it looks like the main topic
        .css({
          float: 'none',
          marginLeft: '.5em',
          fontSize: '1.25rem',
        })
        .click(() => this.delAttachment())
    )
  }

  edit() {
    this.editingElement(this.view.$('.message:first'))
    super.edit(...arguments)
    this.cancelButton.insertAfter(this.done)
    return this.getAttachmentElement().append(this.$delAttachmentButton)
  }

  // #
  // sets a flag telling us to remove the entry's attachment
  // then hides the attachment's UI bits. We do this in lieu of removing
  delAttachment() {
    this.remove_attachment = true
    return this.getAttachmentElement().hide()
  }

  // #
  // Get the jQuery element on the attachment as shown in the entry
  //
  // @api private
  getAttachmentElement() {
    return this.view.$('article:first .comment_attachments > div')
  }

  // #
  // Overrides EditorToggle::getContent to get the content from the model
  // rather than the HTML of the element. This is because `enhanceUserContent`
  // in `instructure.js` manipulates the html and we need the raw html.
  //
  // @api private
  getContent() {
    return apiUserContent.convert(this.view.model.get('message'), {forEditing: true})
  }

  // #
  // Called when the model is successfully saved, provides user feedback
  //
  // @api private
  onSaveSuccess() {
    this.view.model.set('messageNotification', '')
    return this.view.render()
  }

  // #
  // Called when the model fails to save, provides user feedback
  //
  // @api private
  onSaveError() {
    this.view.model.set({
      messageNotification: I18n.t('Failed to save, please try again later'),
    })
    return this.edit()
  }
}
