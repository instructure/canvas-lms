#
# Copyright (C) 2014 - present Instructure, Inc.
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

import I18n from 'i18n!conferences'
import $ from 'jquery'
import _ from 'underscore'
import tz from '@canvas/timezone'
import DialogBaseView from '@canvas/dialog-base-view'
import deparam from 'deparam'
import template from '../../jst/editConferenceForm.handlebars'
import userSettingOptionsTemplate from '../../jst/userSettingOptions.handlebars'
import authenticity_token from '@canvas/authenticity-token'
import numberHelper from '@canvas/i18n/numberHelper'
import '@canvas/forms/jquery/jquery.instructure_forms' # formSubmit

export default class EditConferenceView extends DialogBaseView

  template: template

  dialogOptions: ->
    width: 'auto'
    close: @onClose

  events:
    'change .all_users_checkbox': 'toggleAllUsers'
    'change #web_conference_long_running': 'changeLongRunning'
    'change #web_conference_conference_type': 'renderConferenceFormUserSettings'

  render: ->
    super
    @delegateEvents()
    @toggleAllUsers()
    @markInvitedUsers()
    @markInvitedSectionsAndGroups()
    @renderConferenceFormUserSettings()
    @setupGroupAndSectionEventListeners()
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

    hide_groups = !ENV.groups || ENV.groups.length == 0
    hide_sections = !ENV.sections || ENV.sections.length <= 1
    hide_user_header = hide_groups && hide_sections

    json =
      settings:
        is_editing: is_editing
        is_adding: is_adding
        disable_duration_changes: ((conferenceData['long_running'] || is_editing) && conferenceData['started_at'])
        auth_token: authenticity_token()
        hide_sections: hide_sections
        hide_groups: hide_groups
        hide_user_header: hide_user_header
      conferenceData: conferenceData
      users: ENV.users
      sections: ENV.sections
      groups: ENV.groups
      context_is_group: ENV.context_asset_string.split("_")[0] == "group"
      conferenceTypes: ENV.conference_type_details.map((type) ->
        {name: type.name, type: type.type, selected: (conferenceData.conference_type == type.type)}
      )
      inviteAll: invite_all
      removeObservers: false

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
        return
      )
      return
    )
    return

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
      @$('.remove_observers_checkbox').prop('disabled', false)
    else
      $("#members_list").slideDown()
      @$('.remove_observers_checkbox').prop('disabled', true)

  markInvitedUsers: ->
    _.each(@model.get('user_ids'), (id) ->
      el = $("#members_list .member.user_" + id).find(":checkbox")
      el.attr('checked', true)
      el.attr('disabled', true)
    )

  markInvitedSectionsAndGroups: ->
    _.each(ENV.sections, (section) =>
      section_user_ids = ENV.section_user_ids_map[section.id]
      intersection = _.intersection(section_user_ids, @model.get("user_ids"))
      if (intersection.length == section_user_ids.length)
        el = $("#members_list .member.section_" + section.id).find(":checkbox")
        el.attr('checked', true)
        el.attr('disabled', true)
    )

    _.each(ENV.groups, (group) =>
      group_user_ids = ENV.group_user_ids_map[group.id]
      intersection = _.intersection(group_user_ids, @model.get("user_ids"))
      if (intersection.length == group_user_ids.length)
        el = $("#members_list .member.group_" + group.id).find(":checkbox")
        el.attr('checked', true)
        el.attr('disabled', true)
    )


  changeLongRunning: (e) ->
    if ($(e.currentTarget).is(':checked'))
      $('#web_conference_duration').prop('disabled', true).val('')
    else
      # use restore time from data attribute
      $('#web_conference_duration').prop('disabled', false).val($('#web_conference_duration').data('restore-value'))

  setupGroupAndSectionEventListeners: () ->
    selectedBySection = []
    selectedByGroup = []
    toggleMember = (id, checked) ->
      memberEl = $("#members_list .member.user_" + id).find(":checkbox")
      memberEl.attr('checked', checked)
      memberEl.attr('disabled', checked)

    _.each(ENV.groups, (group) =>
      el = $("#members_list .member.group_" + group.id)
      el.on("change", (e) =>
        _.each(
          ENV.group_user_ids_map[group.id],
          (id) =>
            if (e.target.checked)
              selectedByGroup.push(id)
              toggleMember(id, e.target.checked)
            else
              selectedByGroup = _.without(selectedByGroup, id)
              if (!_.contains(selectedBySection, id) && !_.contains(@model.get("user_ids"), id))
                toggleMember(id, e.target.checked)
        )
      )
    )

    _.each(ENV.sections, (section) =>
      el = $("#members_list .member.section_" + section.id)
      el.on("change", (e) =>
        _.each(
          ENV.section_user_ids_map[section.id],
          (id) =>
            if (e.target.checked)
              selectedBySection.push(id)
              toggleMember(id, e.target.checked)
            else
              selectedBySection = _.without(selectedBySection, id)
              if (!_.contains(selectedByGroup, id) && !_.contains(@model.get("user_ids"), id))
                toggleMember(id, e.target.checked)
        )
      )
    )
