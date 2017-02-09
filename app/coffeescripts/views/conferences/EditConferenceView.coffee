define [
  'i18n!conferences'
  'jquery'
  'underscore'
  'timezone'
  'compiled/views/DialogBaseView'
  'compiled/util/deparam'
  'jst/conferences/editConferenceForm'
  'jst/conferences/userSettingOptions'
  'compiled/behaviors/authenticity_token',
  'jsx/shared/helpers/numberHelper'
], (I18n, $, _, tz, DialogBaseView, deparam, template, userSettingOptionsTemplate, authenticity_token, numberHelper) ->

  class EditConferenceView extends DialogBaseView

    template: template

    dialogOptions: ->
      width: 'auto'
      close: @onClose

    events:
      'click .all_users_checkbox': 'toggleAllUsers'
      'change #web_conference_long_running': 'changeLongRunning'
      'change #web_conference_conference_type': 'renderConferenceFormUserSettings'

    render: ->
      super
      @delegateEvents()
      @toggleAllUsers()
      @markInvitedUsers()
      @renderConferenceFormUserSettings()
      @$('form').formSubmit(
        object_name: 'web_conference'
        beforeSubmit: (data) =>
          # unpack e.g. 'web_conference[title]'
          data = deparam($.param(data)).web_conference
          @model.set(data)
          @model.trigger('startSync')
        success: (data) =>
          @model.set(data)
          @model.trigger('sync')
        error: =>
          @show(@model)
          alert('Save failed.')
        processData: (formData) =>
          dkey = 'web_conference[duration]';
          if(numberHelper.validate(formData[dkey]))
            # formData.duration doesn't appear to be used by the api,
            # but since it's in the formData, I feel obliged to process it
            formData.duration  = formData[dkey] = numberHelper.parse(formData[dkey])
          formData
      )

    show: (model, opts = {}) ->
      @model = model
      @render()
      if (opts.isEditing)
        newTitle = I18n.t('Edit "%{conference_title}"', conference_title: model.get('title'))
        @$el.dialog('option', 'title', newTitle)
      else
        @$el.dialog('option', 'title', I18n.t('New Conference'))
      super

    update: =>
      @$('form').submit()
      @close()

    onClose: =>
      window.router.navigate('')

    toJSON: ->
      conferenceData = super
      is_editing = !@model.isNew()
      is_adding = !is_editing
      invite_all = is_adding
      @updateConferenceUserSettingDetailsForConference(conferenceData)
      conferenceData['http_method'] = if is_adding then 'POST' else 'PUT'
      if (conferenceData.duration == null)
        conferenceData.restore_duration = ENV.default_conference.duration
      else
        conferenceData.restore_duration = conferenceData.duration

      # convert to a string here rather than using the I18n.n helper in
      # editConferenceform.handlebars because we don't want to try and parse
      # the value when the form is redisplayed in the event of an error (like
      # the user enters an invalid value for duration). This way the value is
      # redisplayed in the form as the user entered it, and not as "NaN.undefined".
      if numberHelper.validate(conferenceData.duration)
        conferenceData.duration = I18n.n(conferenceData.duration)

      json =
        settings:
          is_editing: is_editing
          is_adding: is_adding
          disable_duration_changes: ((conferenceData['long_running'] || is_editing) && conferenceData['started_at'])
          auth_token: authenticity_token()
        conferenceData: conferenceData
        users: ENV.users
        context_is_group: ENV.context_asset_string.split("_")[0] == "group"
        conferenceTypes: ENV.conference_type_details.map((type) ->
          {name: type.name, type: type.type, selected: (conferenceData.conference_type == type.type)}
        )
        inviteAll: invite_all

    updateConferenceUserSettingDetailsForConference: (conferenceData) ->
      # make handlebars comparisons easy
      _.each(ENV.conference_type_details, (conferenceInfo) ->
        _.each(conferenceInfo.settings, (optionObj) ->
          currentVal = conferenceData.user_settings[optionObj.field]
          # if no value currently set, use the default.
          if (currentVal == undefined)
            currentVal = optionObj['default']

          switch optionObj['type']
            when 'boolean'
              optionObj['isBoolean'] = true
              optionObj['checked'] = currentVal
              break
            when 'text'
              optionObj['isText'] = true
              optionObj['value'] = currentVal
              break
            when 'date_picker'
              optionObj['isDatePicker'] = true
              if(currentVal)
                optionObj['value'] = tz.format(currentVal, 'date.formats.full_with_weekday')
              else
                optionObj['value'] = currentVal
              break
            when 'select'
              optionObj['isSelect'] = true
              break
        )
      )

    renderConferenceFormUserSettings: ->
      conferenceData = @toJSON()
      selectedConferenceType = $('#web_conference_conference_type').val()
      # Grab the selected entry to pass in for rendering the appropriate user setting options.
      selected = _.select(ENV.conference_type_details, (conference_settings) -> conference_settings.type == selectedConferenceType)
      if (selected.length > 0)
        selected = selected[0]

      members = []
      userSettings = []
      if(selected.settings != undefined )
        $.each( selected.settings, ( i, val ) ->
          if (val['location'] == 'members')
            members.push(val)
          else
            userSettings.push(val)

        )

      @$('.web_conference_user_settings').html(userSettingOptionsTemplate(
        settings: userSettings,
        conference: conferenceData,
        conference_started: !!conferenceData['started_at']
      ))
      @$('.web_conference_member_user_settings').html(userSettingOptionsTemplate(
        settings: members,
        conference: conferenceData,
        conference_started: !!conferenceData['started_at']
      ))
      @$('.date_entry').each(() ->
        if(!this.disabled)
            $(this).datetime_field(alwaysShowTime: true)
      )

    toggleAllUsers: ->
      if(@$('.all_users_checkbox').is(':checked'))
        $("#members_list").hide()
      else
        $("#members_list").slideDown()

    markInvitedUsers: ->
      _.each(@model.get('user_ids'), (id) ->
        el = @$("#members_list .member.user_" + id).find(":checkbox")
        el.attr('checked', true)
        el.attr('disabled', true)
      )

    changeLongRunning: (e) ->
      if ($(e.currentTarget).is(':checked'))
        $('#web_conference_duration').prop('disabled', true).val('')
      else
        # use restore time from data attribute
        $('#web_conference_duration').prop('disabled', false).val($('#web_conference_duration').data('restore-value'))
