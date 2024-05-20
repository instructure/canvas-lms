/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {each, filter, intersection, includes, without} from 'lodash'
import * as tz from '@canvas/datetime'
import DialogBaseView from '@canvas/dialog-base-view'
import deparam from 'deparam'
import template from '../../jst/editConferenceForm.handlebars'
import userSettingOptionsTemplate from '../../jst/userSettingOptions.handlebars'
import authenticity_token from '@canvas/authenticity-token'
import numberHelper from '@canvas/i18n/numberHelper'
import '@canvas/jquery/jquery.instructure_forms'
import {encodeQueryString} from '@canvas/query-string-encoding'

const I18n = useI18nScope('conferences')

extend(EditConferenceView, DialogBaseView)

function EditConferenceView() {
  this.onClose = this.onClose.bind(this)
  this.update = this.update.bind(this)
  return EditConferenceView.__super__.constructor.apply(this, arguments)
}

EditConferenceView.prototype.template = template

EditConferenceView.prototype.dialogOptions = function () {
  return {
    width: 'auto',
    close: this.onClose,
  }
}

EditConferenceView.prototype.events = {
  'change .all_users_checkbox': 'toggleAllUsers',
  'change #web_conference_long_running': 'changeLongRunning',
  'change #web_conference_conference_type': 'renderConferenceFormUserSettings',
}

EditConferenceView.prototype.render = function () {
  EditConferenceView.__super__.render.apply(this, arguments)
  this.delegateEvents()
  this.toggleAllUsers()
  this.markInvitedUsers()
  this.markInvitedSectionsAndGroups()
  this.renderConferenceFormUserSettings()
  this.setupGroupAndSectionEventListeners()
  return this.$('form').formSubmit({
    object_name: 'web_conference',
    beforeSubmit: (function (_this) {
      return function (data) {
        data = deparam(encodeQueryString(data)).web_conference
        _this.model.set(data)
        return _this.model.trigger('startSync')
      }
    })(this),
    success: (function (_this) {
      return function (data) {
        _this.model.set(data)
        _this.model.trigger('sync')
        return $.flashMessage(I18n.t('Conference Saved!'))
      }
    })(this),
    error: (function (_this) {
      return function () {
        _this.show(_this.model)
        return $.flashError(I18n.t('Save failed.'))
      }
    })(this),
    processData: (function (_this) {
      return function (formData) {
        const dkey = 'web_conference[duration]'
        if (numberHelper.validate(formData[dkey])) {
          formData.duration = formData[dkey] = numberHelper.parse(formData[dkey])
        }
        return formData
      }
    })(this),
  })
}

EditConferenceView.prototype.show = function (model, opts) {
  let newTitle
  if (opts == null) {
    opts = {}
  }
  this.model = model
  this.render()
  if (opts.isEditing) {
    newTitle = I18n.t('Edit %{conference_title}', {
      conference_title: model.get('title'),
    })
    this.$el.dialog('option', 'title', newTitle)
  } else {
    this.$el.dialog('option', 'title', I18n.t('New Conference'))
  }
  return EditConferenceView.__super__.show.apply(this, arguments)
}

EditConferenceView.prototype.update = function () {
  this.$('form').submit()
  return this.close()
}

EditConferenceView.prototype.onClose = function () {
  return window.router.navigate('')
}

EditConferenceView.prototype.toJSON = function () {
  const conferenceData = EditConferenceView.__super__.toJSON.apply(this, arguments)
  const is_editing = !this.model.isNew()
  const is_adding = !is_editing
  const invite_all = is_adding
  this.updateConferenceUserSettingDetailsForConference(conferenceData)
  conferenceData.http_method = is_adding ? 'POST' : 'PUT'
  if (conferenceData.duration === null) {
    conferenceData.restore_duration = ENV.default_conference.duration
  } else {
    conferenceData.restore_duration = conferenceData.duration
  }
  // convert to a string here rather than using the I18n.n helper in
  // editConferenceform.handlebars because we don't want to try and parse
  // the value when the form is redisplayed in the event of an error (like
  // the user enters an invalid value for duration). This way the value is
  // redisplayed in the form as the user entered it, and not as "NaN.undefined".
  if (numberHelper.validate(conferenceData.duration)) {
    conferenceData.duration = I18n.n(conferenceData.duration)
  }
  const hide_groups = !ENV.groups || ENV.groups.length === 0
  const hide_sections = !ENV.sections || ENV.sections.length <= 1
  const hide_user_header = hide_groups && hide_sections
  return {
    settings: {
      is_editing,
      is_adding,
      disable_duration_changes:
        (conferenceData.long_running || is_editing) && conferenceData.started_at,
      auth_token: authenticity_token(),
      hide_sections,
      hide_groups,
      hide_user_header,
    },
    conferenceData,
    users: ENV.users,
    sections: ENV.sections,
    groups: ENV.groups,
    context_is_group: ENV.context_asset_string.split('_')[0] === 'group',
    conferenceTypes: ENV.conference_type_details.map(function (type) {
      return {
        name: type.name,
        type: type.type,
        selected: conferenceData.conference_type === type.type,
      }
    }),
    inviteAll: invite_all,
    removeObservers: false,
  }
}

EditConferenceView.prototype.updateConferenceUserSettingDetailsForConference = function (
  conferenceData
) {
  // make handlebars comparisons easy
  each(ENV.conference_type_details, function (conferenceInfo) {
    each(conferenceInfo.settings, function (optionObj) {
      let currentVal
      currentVal = conferenceData.user_settings[optionObj.field]
      if (currentVal === void 0) {
        currentVal = optionObj.default
      }
      switch (optionObj.type) {
        case 'boolean':
          optionObj.isBoolean = true
          optionObj.checked = currentVal
          break
        case 'text':
          optionObj.isText = true
          optionObj.value = currentVal
          break
        case 'date_picker':
          optionObj.isDatePicker = true
          if (currentVal) {
            optionObj.value = tz.format(currentVal, 'date.formats.full_with_weekday')
          } else {
            optionObj.value = currentVal
          }
          break
        case 'select':
          optionObj.isSelect = true
          break
      }
    })
  })
}

EditConferenceView.prototype.renderConferenceFormUserSettings = function () {
  const conferenceData = this.toJSON()
  const selectedConferenceType = $('#web_conference_conference_type').val()
  // Grab the selected entry to pass in for rendering the appropriate user setting options
  let selected = filter(ENV.conference_type_details, function (conference_settings) {
    return conference_settings.type === selectedConferenceType
  })
  if (selected.length > 0) {
    selected = selected[0]
  }
  const members = []
  const userSettings = []
  if (selected.settings !== void 0) {
    $.each(selected.settings, function (i, val) {
      if (val.location === 'members') {
        return members.push(val)
      } else {
        return userSettings.push(val)
      }
    })
  }
  this.$('.web_conference_user_settings').html(
    userSettingOptionsTemplate({
      settings: userSettings,
      conference: conferenceData,
      conference_started: !!conferenceData.started_at,
    })
  )
  this.$('.web_conference_member_user_settings').html(
    userSettingOptionsTemplate({
      settings: members,
      conference: conferenceData,
      conference_started: !!conferenceData.started_at,
    })
  )
  return this.$('.date_entry').each(function () {
    if (!this.disabled) {
      return $(this).datetime_field({
        alwaysShowTime: true,
      })
    }
  })
}

EditConferenceView.prototype.toggleAllUsers = function () {
  if (this.$('.all_users_checkbox').is(':checked')) {
    $('#members_list').hide()
    return this.$('.remove_observers_checkbox').prop('disabled', false)
  } else {
    $('#members_list').slideDown()
    return this.$('.remove_observers_checkbox').prop('disabled', true)
  }
}

EditConferenceView.prototype.markInvitedUsers = function () {
  each(this.model.get('user_ids'), function (id) {
    const el = $('#members_list .member.user_' + id).find(':checkbox')
    el.prop('checked', true)
    return el.prop('disabled', true)
  })
}

EditConferenceView.prototype.markInvitedSectionsAndGroups = function () {
  each(
    ENV.sections,
    (function (_this) {
      return function (section) {
        const section_user_ids = ENV.section_user_ids_map[section.id]
        const intersection_ = intersection(section_user_ids, _this.model.get('user_ids'))
        if (intersection_.length === section_user_ids.length) {
          const el = $('#members_list .member.section_' + section.id).find(':checkbox')
          el.prop('checked', true)
          return el.prop('disabled', true)
        }
      }
    })(this)
  )
  each(
    ENV.groups,
    (function (_this) {
      return function (group) {
        let el
        const group_user_ids = ENV.group_user_ids_map[group.id]
        const intersection_ = intersection(group_user_ids, _this.model.get('user_ids'))
        if (intersection_.length === group_user_ids.length) {
          el = $('#members_list .member.group_' + group.id).find(':checkbox')
          el.prop('checked', true)
          return el.prop('disabled', true)
        }
      }
    })(this)
  )
}

EditConferenceView.prototype.changeLongRunning = function (e) {
  if ($(e.currentTarget).is(':checked')) {
    return $('#web_conference_duration').prop('disabled', true).val('')
  } else {
    return $('#web_conference_duration')
      .prop('disabled', false)
      .val($('#web_conference_duration').data('restore-value'))
  }
}

EditConferenceView.prototype.setupGroupAndSectionEventListeners = function () {
  let selectedBySection = []
  let selectedByGroup = []
  const toggleMember = function (id, checked) {
    const memberEl = $('#members_list .member.user_' + id).find(':checkbox')
    memberEl.prop('checked', checked)
    return memberEl.prop('disabled', checked)
  }
  each(
    ENV.groups,
    (function (_this) {
      return function (group) {
        const el = $('#members_list .member.group_' + group.id)
        return el.on('change', function (e) {
          each(ENV.group_user_ids_map[group.id], function (id) {
            if (e.target.checked) {
              selectedByGroup.push(id)
              return toggleMember(id, e.target.checked)
            } else {
              selectedByGroup = without(selectedByGroup, id)
              if (!includes(selectedBySection, id) && !includes(_this.model.get('user_ids'), id)) {
                return toggleMember(id, e.target.checked)
              }
            }
          })
        })
      }
    })(this)
  )
  each(
    ENV.sections,
    (function (_this) {
      return function (section) {
        const el = $('#members_list .member.section_' + section.id)
        return el.on('change', function (e) {
          each(ENV.section_user_ids_map[section.id], function (id) {
            if (e.target.checked) {
              selectedBySection.push(id)
              return toggleMember(id, e.target.checked)
            } else {
              selectedBySection = without(selectedBySection, id)
              if (!includes(selectedByGroup, id) && !includes(_this.model.get('user_ids'), id)) {
                return toggleMember(id, e.target.checked)
              }
            }
          })
        })
      }
    })(this)
  )
}

export default EditConferenceView
