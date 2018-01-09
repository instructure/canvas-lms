#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'underscore'
  'i18n!groups'
  '../../DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/groups/manage/groupCategoryEdit'
  'str/htmlEscape'
], (_, I18n, DialogFormView, wrapperTemplate, template, h) ->

  class GroupCategoryEditView extends DialogFormView

    template: template
    wrapperTemplate: wrapperTemplate
    className: "form-dialog group-category-edit"

    defaults:
      width: 500
      height: if ENV.allow_self_signup then 520 else 210
      title: I18n.t('edit_group_set', 'Edit Group Set')
      fixDialogButtons: false

    els:
      '.self-signup-help': '$selfSignupHelp'
      '.self-signup-description': '$selfSignup'
      '.self-signup-toggle': '$selfSignupToggle'
      '.self-signup-controls': '$selfSignupControls'
      '.auto-group-leader-toggle': '$autoGroupLeaderToggle'
      '.auto-group-leader-controls': '$autoGroupLeaderControls'

    events: _.extend {},
      DialogFormView::events
      'click .dialog_closer': 'close'
      'click .self-signup-toggle': 'toggleSelfSignup'
      'click .auto-group-leader-toggle': 'toggleAutoGroupLeader'

    afterRender: ->
      @toggleSelfSignup()
      @toggleAutoGroupLeader()
      @setAutoLeadershipFormState()

    openAgain: ->
      super
      # reset the form contents
      @render()

    setAutoLeadershipFormState: ->
      if @model.get('auto_leader')?
        @$autoGroupLeaderToggle.prop('checked', true)
        @$autoGroupLeaderControls.find("input[value='#{@model.get('auto_leader').toUpperCase()}']").prop('checked', true)
      else
        @$autoGroupLeaderToggle.prop('checked', false)
      @toggleAutoGroupLeader()


    toggleAutoGroupLeader: ->
      enabled = @$autoGroupLeaderToggle.prop 'checked'
      @$autoGroupLeaderControls.find('label.radio').css opacity: if enabled then 1 else 0.5
      @$autoGroupLeaderControls.find('input[name=auto_leader_type]').prop('disabled', !enabled)

    toggleSelfSignup: ->
      disabled = !@$selfSignupToggle.prop('checked')
      @$selfSignupControls.css opacity: if disabled then 0.5 else 1
      @$selfSignupControls.find(':input').prop 'disabled', disabled

    validateFormData: (data, errors) ->
      groupLimit = @$("[name=group_limit]")
      if groupLimit.length and !groupLimit[0].validity.valid
        {"group_limit": [{message: I18n.t('group_limit_number', 'Group limit must be a number') }]}

    toJSON: ->
      json = @model.present()
      _.extend {},
        ENV: ENV,
        json,
        enable_self_signup: json.self_signup
        restrict_self_signup: json.self_signup is 'restricted'
        group_limit: """
          <input name="group_limit"
                 type="number"
                 min="2"
                 class="input-micro"
                 value="#{h(json.group_limit ? '')}">
          """
