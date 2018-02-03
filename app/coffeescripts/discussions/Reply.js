//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'
import _ from 'underscore'
import I18n from 'i18n!discussions.reply'
import $ from 'jquery'
import Entry from '../models/Entry'
import htmlEscape from 'str/htmlEscape'
import replyAttachmentTemplate from 'jst/discussions/_reply_attachment'
import preventDefault from '../fn/preventDefault'
import KeyboardShortcuts from '../views/editor/KeyboardShortcuts'
import stripTags from 'str/stripTags'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import 'jquery.instructure_forms'

RichContentEditor.preloadRemoteModule()

class Reply {
  // #
  // Creates a new reply to an Entry
  //
  // @param {view} an EntryView instance
  constructor (view, options = {}) {
    ['attachKeyboardShortcuts', 'hide', 'hideNotification', 'submit', 'onPostReplySuccess', 'onPostReplyError'].forEach(m => this[m] = this[m].bind(this))
    this.view = view
    this.options = options
    this.el = this.view.$('.discussion-reply-action:first')
    // works for threaded discussion topic and entries
    this.discussionEntry = this.el.closest('.discussion_entry')
    // required for non-threaded reply area at bottom of an entry block
    if (this.discussionEntry.length === 0) {
      this.discussionEntry = this.el.closest('.entry')
    }
    this.form = this.discussionEntry.find('form.discussion-reply-form:first').submit(preventDefault(this.submit))
    this.textArea = this.getEditingElement()
    this.form.find('.cancel_button').click(this.hide)
    this.form.on('click', '.toggle-wrapper a', (e) => {
      e.preventDefault()
      RichContentEditor.callOnRCE(this.textArea, 'toggle')
      // hide the clicked link, and show the other toggle link.
      // todo: replace .andSelf with .addBack when JQuery is upgraded.
      return $(e.currentTarget).siblings('a').andSelf().toggle()
    })
    this.form.delegate('.alert .close', 'click', preventDefault(this.hideNotification))
    this.editing = false

    _.defer(this.attachKeyboardShortcuts)
  }

  attachKeyboardShortcuts () {
    return this.view.$('.toggle-wrapper').first().before(new KeyboardShortcuts().render().$el)
  }

  // #
  // Shows or hides the TinyMCE editor for a reply
  //
  // @api public
  toggle () {
    if (!this.editing) {
      return this.edit()
    } else {
      return this.hide()
    }
  }

  // #
  // Shows the TinyMCE editor for a reply
  //
  // @api public
  edit () {
    this.form.addClass('replying')
    this.discussionEntry.addClass('replying')
    RichContentEditor.initSidebar()
    RichContentEditor.loadNewEditor(this.textArea, {
      focus: true,
      manageParent: true,
      tinyOptions: {
        width: '100%'
      }
    })
    this.editing = true
    return this.trigger('edit', this)
  }

  createTextArea(id) {
    return (
      $('<textarea/>')
        .addClass('reply-textarea')
        .attr('id', id)
        .attr('aria-hidden', 'true')
    )
  }

  replaceTextArea(textAreaId) {
    RichContentEditor.destroyRCE(this.textArea)
    this.textArea = this.createTextArea(textAreaId)
    this.textArea.val(this.content)
    $(`#tinymce-parent-of-${textAreaId}`).replaceWith(this.textArea)
  }

  // #
  // Hides the TinyMCE editor
  //
  // @api public
  hide () {
    const textAreaId = this.textArea.attr('id')
    this.content = RichContentEditor.callOnRCE(this.textArea, 'get_code')
    this.form.removeClass('replying')
    this.discussionEntry.removeClass('replying')
    this.editing = false
    this.replaceTextArea(textAreaId)
    this.trigger('hide', this)
    return this.discussionEntry.find('.discussion-reply-action').focus()
  }

  hideNotification () {
    return this.view.model.set('notification', '')
  }

  // #
  // Submit handler for the reply form. Creates a new Entry and saves it
  // to the server.
  //
  // @api private
  submit () {
    this.hide()
    this.view.model.set('notification', `<div class='alert alert-info'>${htmlEscape(I18n.t('saving_reply', 'Saving reply...'))}</div>`)
    const entry = new Entry(this.getModelAttributes())
    entry.save(null, {
      success: this.onPostReplySuccess,
      error: this.onPostReplyError,
      multipart: entry.get('attachment'),
      proxyAttachment: true,
    })
    return this.removeAttachments()
  }

  // #
  // Get the jQueryEl element on the discussion entry to edit.
  //
  // @api private
  getEditingElement () {
    return this.view.$('.reply-textarea:first')
  }

  // #
  // Computes the model's attributes before saving it to the server
  //
  // @api private
  getModelAttributes () {
    const now = new Date().getTime()
    // TODO: remove this summary, server should send it in create response and no further
    // work is required
    return {
      summary: stripTags(this.content),
      message: this.content,
      parent_id: this.options.topLevel ? null : this.view.model.get('id'),
      user_id: ENV.current_user_id,
      created_at: now,
      updated_at: now,
      attachment: this.form.find('input[type=file]')[0],
      new: true,
    }
  }

  // #
  // Callback when the model is succesfully saved
  //
  // @api private
  onPostReplySuccess (entry, response) {
    if (response.errors) {
      this.hideNotification()
      this.textArea.val(entry.get('message'))
      this.edit()
      return this.form.formErrors(response)
    } else {
      this.view.model.set('notification', '')
      this.trigger('save', entry)
      return this.textArea.val('')
    }
  }

  // #
  // Callback when the model fails to save
  //
  // @api private
  onPostReplyError (entry) {
    this.view.model.set(
      'notification',
      `<div class='alert alert-info'>${I18n.t('*An error occurred*, please post your reply again later', {
        wrapper: '<strong>$1</strong>',
      })}</div>`
    )
    this.textArea.val(entry.get('message'))
    return this.edit()
  }

  // #
  // Adds an attachment
  addAttachment ($el) {
    this.form.find('ul.discussion-reply-attachments').append(replyAttachmentTemplate())
    this.form.find('ul.discussion-reply-attachments input').focus()
    return this.form.find('a.discussion-reply-add-attachment').hide() // TODO: when the data model allows it, tweak this to support multiple in the UI
  }

  // #
  // Removes an attachment
  removeAttachment ($el) {
    $el.closest('ul.discussion-reply-attachments li').remove()
    return this.form.find('a.discussion-reply-add-attachment').show().focus()
  }

  // #
  // Removes all attachments
  removeAttachments () {
    this.form.find('ul.discussion-reply-attachments').empty()
    return this.form.find('a.discussion-reply-add-attachment').show().focus()
  }
}

_.extend(Reply.prototype, Backbone.Events)

export default Reply
