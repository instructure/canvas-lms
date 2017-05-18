#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'underscore'
  'i18n!discussions.reply'
  'jquery'
  'compiled/models/Entry'
  'str/htmlEscape'
  'jst/discussions/_reply_attachment'
  'compiled/fn/preventDefault'
  'compiled/views/editor/KeyboardShortcuts'
  'str/stripTags'
  'jsx/shared/rce/RichContentEditor'
  'jquery.instructure_forms'
], (Backbone, _, I18n, $, Entry, htmlEscape, replyAttachmentTemplate,
      preventDefault, KeyboardShortcuts, stripTags, RichContentEditor) ->

  RichContentEditor.preloadRemoteModule()

  class Reply

    ##
    # Creates a new reply to an Entry
    #
    # @param {view} an EntryView instance
    constructor: (@view, @options={}) ->
      @el = @view.$ '.discussion-reply-action:first'
      # works for threaded discussion topic and entries
      @discussionEntry = @el.closest '.discussion_entry'
      # required for non-threaded reply area at bottom of an entry block
      @discussionEntry = @el.closest '.entry' if @discussionEntry.length == 0
      @form = @discussionEntry.find('form.discussion-reply-form:first').submit preventDefault @submit
      @textArea = @getEditingElement()
      @form.find('.cancel_button').click @hide
      @form.on 'click', '.toggle-wrapper a', (e) =>
        e.preventDefault()
        RichContentEditor.callOnRCE(@textArea, 'toggle')
        # hide the clicked link, and show the other toggle link.
        # todo: replace .andSelf with .addBack when JQuery is upgraded.
        $(e.currentTarget).siblings('a').andSelf().toggle()
      @form.delegate '.alert .close', 'click', preventDefault @hideNotification
      @editing = false

      _.defer(@attachKeyboardShortcuts)


    attachKeyboardShortcuts: =>
      @view.$('.toggle-wrapper').first().before((new KeyboardShortcuts()).render().$el)

    ##
    # Shows or hides the TinyMCE editor for a reply
    #
    # @api public
    toggle: ->
      if not @editing
        @edit()
      else
        @hide()

    ##
    # Shows the TinyMCE editor for a reply
    #
    # @api public
    edit: ->
      @form.addClass 'replying'
      @discussionEntry.addClass 'replying'
      RichContentEditor.initSidebar()
      RichContentEditor.loadNewEditor(@textArea, {
        focus: true,
        manageParent: true,
        tinyOptions: {
          width: '100%'
        }
      })
      @editing = true
      @trigger 'edit', this

    ##
    # Hides the TinyMCE editor
    #
    # @api public
    hide: =>
      @content = RichContentEditor.callOnRCE(@textArea, 'get_code')
      RichContentEditor.destroyRCE(@textArea)
      @form.removeClass 'replying'
      @discussionEntry.removeClass 'replying'
      @textArea.val @content
      @editing = false
      @trigger 'hide', this
      @discussionEntry.find('.discussion-reply-action').focus()

    hideNotification: =>
      @view.model.set 'notification', ''

    ##
    # Submit handler for the reply form. Creates a new Entry and saves it
    # to the server.
    #
    # @api private
    submit: =>
      @hide()
      RichContentEditor.callOnRCE(@textArea, 'set_code', '')
      @view.model.set 'notification', "<div class='alert alert-info'>#{htmlEscape I18n.t 'saving_reply', 'Saving reply...'}</div>"
      entry = new Entry @getModelAttributes()
      entry.save null,
        success: @onPostReplySuccess
        error: @onPostReplyError
        multipart: entry.get('attachment')
        proxyAttachment: true
      @removeAttachments()

    ##
    # Get the jQueryEl element on the discussion entry to edit.
    #
    # @api private
    getEditingElement: ->
      @view.$('.reply-textarea:first')

    ##
    # Computes the model's attributes before saving it to the server
    #
    # @api private
    getModelAttributes: ->
      now = new Date().getTime()
      # TODO: remove this summary, server should send it in create response and no further
      # work is required
      summary: stripTags(@content)
      message: @content
      parent_id: if @options.topLevel then null else @view.model.get 'id'
      user_id: ENV.current_user_id
      created_at: now
      updated_at: now
      attachment: @form.find('input[type=file]')[0]
      new: true

    ##
    # Callback when the model is succesfully saved
    #
    # @api private
    onPostReplySuccess: (entry, response) =>
      if response.errors
        @hideNotification()
        @textArea.val entry.get('message')
        @edit()
        @form.formErrors(response)
      else
        @view.model.set 'notification', ''
        @trigger 'save', entry
        @textArea.val ''

    ##
    # Callback when the model fails to save
    #
    # @api private
    onPostReplyError: (entry) =>
      @view.model.set 'notification', "<div class='alert alert-info'>#{I18n.t "*An error occurred*, please post your reply again later", wrapper: '<strong>$1</strong>'}</div>"
      @textArea.val entry.get('message')
      @edit()

    ##
    # Adds an attachment
    addAttachment: ($el) ->
      @form.find('ul.discussion-reply-attachments').append(replyAttachmentTemplate())
      @form.find('ul.discussion-reply-attachments input').focus()
      @form.find('a.discussion-reply-add-attachment').hide() # TODO: when the data model allows it, tweak this to support multiple in the UI

    ##
    # Removes an attachment
    removeAttachment: ($el) ->
      $el.closest('ul.discussion-reply-attachments li').remove()
      @form.find('a.discussion-reply-add-attachment').show().focus()

    ##
    # Removes all attachments
    removeAttachments: ->
      @form.find('ul.discussion-reply-attachments').empty()
      @form.find('a.discussion-reply-add-attachment').show().focus()

  _.extend Reply.prototype, Backbone.Events

  Reply
