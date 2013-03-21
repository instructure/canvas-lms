define [
  'i18n!quizzes'
  'compiled/views/ValidatedFormView'
  'jst/messageStudentsDialog'
  'compiled/models/Conversation'
  'jst/_messageStudentsWhoRecipientList'
  'underscore'
  'compiled/jquery/serializeForm'
], (I18n,ValidatedFormView, messageStudentsDialog,Conversation,recipientList,_) ->

  class MessageStudentsDialog extends ValidatedFormView

    # A list of "recipientGroups" that have two properties:
    # name: String # Describes the group of users
    # recipients: Array of Objects
    #   These objects must have two keys:
    #     id: String or Number # user's id
    #     short_name: String # represents a short version of the user's name
    @optionProperty 'recipientGroups'

    # The title of whatever the message is "for", renders the text as
    # for <title> when the dialog is rendered.
    @optionProperty 'title'

    els:
      '[name=recipientGroupName]': '$recipientGroupName'
      '#message-recipients': '$messageRecipients'
      '[name=body]': '$messageBody'

    template: messageStudentsDialog

    initialize: (opts) ->
      super
      @recipients = @recipientGroups[0].recipients
      @model or= new Conversation

    events: _.extend({}, ValidatedFormView::events,
      'change [name=recipientGroupName]': 'updateListOfRecipients')

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

