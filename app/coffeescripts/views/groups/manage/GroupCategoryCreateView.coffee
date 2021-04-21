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

import _ from 'underscore'
import I18n from 'i18n!groups'
import GroupCategoryEditView from './GroupCategoryEditView'
import template from 'jst/groups/manage/groupCategoryCreate'

export default class GroupCategoryCreateView extends GroupCategoryEditView

  template: template
  className: "form-dialog group-category-create"

  messages:
    positive_group_count: I18n.t('positive_group_count', 'Must enter a positive group count')
    groups_too_low: I18n.t('Must have at least 1 group per section')

  defaults:
    width: 600
    height: if ENV.allow_self_signup then 600 else 310
    title: I18n.t('create_group_set', 'Create Group Set')

  els: _.extend {}, GroupCategoryEditView::els,
    '.admin-signup-controls': '$adminSignupControls'
    '.group-by-section-controls': '$groupBySectionControls'
    '#split_groups': '$splitGroups'
    '.admin-signup-controls input[name=split_groups][value=1]': '$autoGroupSplitControl'
    '.admin-signup-controls input[name=split_groups][value=2]': '$autoGroupSplitByMemberControl'

  events: _.extend {}, GroupCategoryEditView::events,
    'click .admin-signup-controls [name=create_group_count]': 'clickSplitGroups'
    'click .auto-group-leader-toggle': 'toggleAutoGroupLeader'
    'click .admin-signup-controls input[name=split_groups]' : 'setVisibilityOfGroupLeaderControls'

  afterRender: ->
    super()
    @setVisibilityOfGroupLeaderControls()

  setVisibilityOfGroupLeaderControls: ->
    splitGroupsChecked = @$autoGroupSplitControl.prop("checked") || @$autoGroupSplitByMemberControl.prop("checked")
    show = (@selfSignupIsEnabled() or splitGroupsChecked)
    @$autoGroupLeaderControls.toggle(show)
    @$adminSignupControls.toggleClass('dotted-separator', show)
    @$groupBySectionControls.toggle(ENV.group_user_type == 'student' && splitGroupsChecked)

  toggleSelfSignup: ->
    enabled = @selfSignupIsEnabled()
    @$el.toggleClass('group-category-self-signup', enabled)
    @$el.toggleClass('group-category-admin-signup', !enabled)
    @$selfSignupControls.find(':input').prop 'disabled', !enabled
    @$adminSignupControls.find(':input').prop 'disabled', enabled
    @setVisibilityOfGroupLeaderControls()

  selfSignupIsEnabled: ->
    @$selfSignupToggle.prop('checked')

  clickSplitGroups: (e) ->
    # firefox doesn't like multiple inputs in the same label, so a little js to the rescue
    e.preventDefault()
    @$splitGroups.click()

  toJSON: ->
    _.extend {},
      super,
      num_groups: '<input name="create_group_count" type="number" min="0" class="input-micro" value="0">'
      num_members: '<input name="create_group_member_count" type="number" min="0" class="input-micro" value="0">'
      ENV: ENV

  ##
  # client side validation
  validateFormData: (data) ->
    errors = {}
    if data.split_groups is '1'
      create_group_count = parseInt(data.create_group_count)
      if create_group_count > 0
        if data.group_by_section == '1' && ENV.student_section_count && ENV.student_section_count > create_group_count
          errors["create_group_count"] = [{type: 'groups_too_low', message: @messages.groups_too_low}]
      else
        errors["create_group_count"] = [{type: 'positive_group_count', message: @messages.positive_group_count}]

    errors

  setFocusAfterError: ->
    @$('#newGroupSubmitButton').focus()
