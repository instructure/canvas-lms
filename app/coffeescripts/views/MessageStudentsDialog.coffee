define [
  'i18n!quizzes'
  'compiled/views/ValidatedFormView'
  'jst/messageStudentsDialog'
  'compiled/models/Conversation'
  'jst/_messageStudentsWhoRecipientList'
  'underscore'
  'compiled/jquery/serializeForm'
], (I18n, ValidatedFormView, messageStudentsDialog, Conversation, recipientList, _) ->

  class MessageStudentsDialog extends ValidatedFormView

    # A list of "recipientGroups" that have two properties:
    # name: String # Describes the group of users
    # recipients: Array of Objects
    #   These objects must have two keys:
    #     id: String or Number # user's id
    #     short_name: String # represents a short version of the user's name
    @optionProperty 'recipientGroups'

    # The context of whatever the message is "for", renders the text as
    # Message Students for <context> when the dialog is rendered.
    @optionProperty 'context'

    els:
      '[name=recipientGroupName]': '$recipientGroupName'
      '#message-recipients': '$messageRecipients'
      '[name=body]': '$messageBody'

    template: messageStudentsDialog

    className: 'validated-form-view form-dialog'

    initialize: (opts) ->
      super
      @title = if @context
        I18n.t('message_students_for_context', 'Message students for %{context}', {@context})
      else
        I18n.t('message_students', 'Message students')

      @recipients = @recipientGroups[0].recipients
      @model or= new Conversation

    events: _.extend({}, ValidatedFormView::events,
      'change [name=recipientGroupName]': 'updateListOfRecipients'
      'click .dialog_closer': 'close')

    toJSON: =>
      json = {}
      json[key] = @[key] for key in [ 'title','recipients','recipientGroups' ]
      json

    validateBeforeSave: (data, errors) =>
      errs = @model.validate data
      if errs
        errors.body = errs.body if errs.body
        errors.recipientGroupName = errs.recipients if errs.recipients
      errors

    _findRecipientGroupByName: (name) =>
      _.detect @recipientGroups, (grp) -> grp.name is name

    getFormData: =>
      {recipientGroupName, body} = @$el.toJSON()
      {recipients} = @_findRecipientGroupByName recipientGroupName
      body: body, recipients: _.pluck(recipients,'id')

    updateListOfRecipients: =>
      groupName = @$recipientGroupName.val()
      {recipients} = @_findRecipientGroupByName groupName
      @$messageRecipients.html recipientList recipients: recipients

    onSaveSuccess: ->
      @close()
      $.flashMessage(I18n.t('notices.message_sent', "Message Sent!"))

    open: ->
      @render()
      @$el.dialog(autoOpen: false, height: 500, width: 500, title: @title).dialog('open')

    close: ->
      @$el.dialog('close')
      @remove()
