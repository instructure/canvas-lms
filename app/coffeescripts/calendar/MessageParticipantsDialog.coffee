define [
  'jquery'
  'underscore'
  'i18n!calendar'
  'jst/calendar/messageParticipants'
  'jst/calendar/recipientList'
], ($, _, I18n, messageParticipantsTemplate, recipientListTemplate) ->

  class MessageParticipantsDialog
    constructor: (@opts) ->
      if @opts.timeslot
        @recipients = _(@opts.timeslot.child_events).map (e) -> e.user or e.group
        participantType = if @recipients[0].short_name == undefined then 'Group' else 'User'

        @$form = $(messageParticipantsTemplate participant_type: participantType)
        @$form.find('select.message_groups').remove()
      else
        @group = @opts.group
        @$form = $(messageParticipantsTemplate participant_type: @group.participant_type)
        @dataSource = @opts.dataSource

        @$select = @$form.find('select.message_groups')
          .change(@loadParticipants)
          .val('unregistered')


      @$form.submit @sendMessage

      @$participantList = @$form.find('ul')

      if @recipients
        @$participantList.html recipientListTemplate(recipientType: participantType, recipients: @recipients)

    show: ->
      @$form.dialog
        width: 400
        resizable: false
        buttons: [
          text: I18n.t('buttons.cancel', 'Cancel')
          click: -> $(this).dialog('close')
        ,
          text: I18n.t('buttons.send_message', 'Send')
          'data-text-while-loading': I18n.t('buttons.sending_message', 'Sending...')
          class: 'btn-primary'
          click: -> $(this).submit()
        ]
        close: -> $(this).remove()
      @loadParticipants()

    participantStatus: (text=null)->
      $status = $('<li class="status" />')
      @$participantList.html($status)
      if text
        $status.text text
      else
        $status.spin()

    loadParticipants: =>
      return if @recipients

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
          text = if @group.participant_type is "Group"
            I18n.t('no_groups', 'No groups found')
          else
            I18n.t('no_users', 'No users found')
          @participantStatus(text)

    sendMessage: (jsEvent) =>
      jsEvent.preventDefault()

      return if @loading
      data = @$form.getFormData()
      return unless data['recipients[]'] and data['body']

      deferred = $.ajaxJSON '/conversations', 'POST', data, @messageSent, @messageFailed
      @$form.disableWhileLoading(deferred, buttons: ['[data-text-while-loading] .ui-button-text'])

    messageSent: (data) =>
      @$form.dialog('close')
      $.flashMessage(I18n.t('messages_sent', 'Messages Sent'))

    messageFailed: (data) =>
      @$form.find('.error').text(I18n.t('errors.send_message_failed', 'There was an error sending your message, please try again'))
