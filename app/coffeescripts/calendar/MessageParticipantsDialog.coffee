define 'compiled/calendar/MessageParticipantsDialog', [
  'i18n!calendar'
  'jst/calendar/messageParticipants'
  'jst/calendar/recipientList'
], (I18n, messageParticipantsTemplate, recipientListTemplate) ->

  class
    constructor: (@group, @dataSource) ->
      @$form = $(messageParticipantsTemplate(@group))
      @$form.submit @sendMessage

      @$select = @$form.find('select.message_groups')
      @$select.change(@loadParticipants)
      @$select.val('unregistered')
      
      @$participantList = @$form.find('ul')
        
    show: ->
      @$form.appendTo('body').dialog
        width: 400
        resizable: false
        title: if @group.participant_type is "Group" then I18n.t('message_groups', 'Message Groups') else I18n.t('message_students', 'Message Students')
        buttons: [
          {
            text: I18n.t('buttons.send_message', 'Send')
            click: -> $(this).submit()
          }
          {
            text: I18n.t('buttons.cancel', 'Cancel')
            click: -> $(this).dialog('close')
          }
        ]
        close: $(this).remove()
      @loadParticipants()

    participantStatus: (text=null)->
      @$participantList.html('')
      $status = $('<li class="status" />').appendTo(@$participantList)
      if text
        $status.text text
      else
        $status.spin()

    loadParticipants: =>
      registrationStatus = @$select.val()
      @loading = true
      @participantStatus()

      @dataSource.getParticipants @group, registrationStatus, (data) =>
        delete @loading
        if data.length
          @$participantList.html(recipientListTemplate(
            recipientType: @group.participant_type,
            recipients: data
          ))
        else
          @participantStatus(if @group.participant_type is "Group" then I18n.t('no_groups', 'No groups found') else I18n.t('no_users', 'No users found'))

    sendMessage: (jsEvent) =>
      jsEvent.preventDefault()

      return if @loading
      data = @$form.getFormData()
      return unless data['recipients[]'] and data['body']

      deferred = $.ajaxJSON '/conversations', 'POST', data, @messageSent, @messageFailed
      @$form.disableWhileLoading(deferred)

    messageSent: (data) =>
      @$form.dialog('close')
      $.flashMessage(I18n.t('messages_sent', 'Messages Sent'))

    messageFailed: (data) =>
      @$form.find('.error').text(I18n.t('errors.send_message_failed', 'There was an error sending your message, please try again'))
