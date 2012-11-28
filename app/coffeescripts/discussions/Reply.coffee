define [
  'Backbone'
  'underscore'
  'i18n!discussions.reply'
  'jquery'
  'compiled/models/Entry'
  'str/htmlEscape'
  'jst/discussions/_reply_attachment'
  'compiled/fn/preventDefault'
  'tinymce.editor_box'
], (Backbone, _, I18n, $, Entry, htmlEscape, replyAttachmentTemplate, preventDefault) ->

  class Reply

    ##
    # Creates a new reply to an Entry
    #
    # @param {view} an EntryView instance
    constructor: (@view, @options={}) ->
      @el = @view.$ '.discussion-reply-label:first'
      @showWhileEditing = @el.next()
      @textarea = @showWhileEditing.find('.reply-textarea')
      @form = @el.closest('form').submit preventDefault @submit
      @form.find('.cancel_button').click @hide
      @form.delegate '.alert .close', 'click', preventDefault @hideNotification
      @editing = false

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
      @textarea.editorBox tinyOptions: width: '100%'
      @el.hide()
      setTimeout (=> @textarea.editorBox 'focus'), 20 if @options.focus
      @editing = true
      @trigger 'edit', this

    ##
    # Hides the TinyMCE editor
    #
    # @api public
    hide: =>
      @content = @textarea._justGetCode()
      @textarea._removeEditor()
      @form.removeClass 'replying'
      @textarea.val @content
      @el.show()
      @editing = false
      @trigger 'hide', this

    hideNotification: =>
      @view.model.set 'notification', ''

    ##
    # Submit handler for the reply form. Creates a new Entry and saves it
    # to the server.
    #
    # @api private
    submit: =>
      @hide()
      @textarea._setContentCode ''
      @view.model.set 'notification', "<div class='alert alert-info'>#{I18n.t 'saving_reply', 'Saving reply...'}</div>"
      entry = new Entry @getModelAttributes()
      entry.save null,
        success: @onPostReplySuccess
        error: @onPostReplyError
        multipart: entry.get('attachment')
      @hide()
      @removeAttachments()
      @el.hide()

    ##
    # Computes the model's attributes before saving it to the server
    #
    # @api private
    getModelAttributes: ->
      now = new Date().getTime()
      # TODO: remove this summary, server should send it in create response and no further
      # work is required
      summary: $('<div/>').html(@content).text()
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
    onPostReplySuccess: (entry) =>
      @view.model.set 'notification', ''
      @el.show()
      @trigger 'save', entry

    ##
    # Callback when the model fails to save
    #
    # @api private
    onPostReplyError: (entry) =>
      @view.model.set 'notification', "<div class='alert alert-info'>#{I18n.t 'error_saving_reply', "*An error occured*, please post your reply again later", wrapper: '<strong>$1</strong>'}</div>"
      @textarea.val entry.get('message')
      @edit()

    ##
    # Adds an attachment
    addAttachment: ($el) ->
      @form.find('ul.discussion-reply-attachments').append(replyAttachmentTemplate())
      @form.find('a.discussion-reply-add-attachment').hide() # TODO: when the data model allows it, tweak this to support multiple in the UI

    ##
    # Removes an attachment
    removeAttachment: ($el) ->
      $el.closest('ul.discussion-reply-attachments li').remove()
      @form.find('a.discussion-reply-add-attachment').show()

    ##
    # Removes all attachments
    removeAttachments: ->
      @form.find('ul.discussion-reply-attachments').empty()
      @form.find('a.discussion-reply-add-attachment').show()

  _.extend Reply.prototype, Backbone.Events

  Reply

