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

import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import _ from 'underscore'
import template from '../../jst/GroupCategorySelector.handlebars'
import '@canvas/assignments/jquery/toggleAccessibly'
import awaitElement from '@canvas/await-element'
import {renderCreateDialog} from '@canvas/groups/react/CreateOrEditSetModal'
import StudentGroupStore from '@canvas/due-dates/react/StudentGroupStore'
import GroupCategory from '@canvas/groups/backbone/models/GroupCategory.coffee'

I18n = useI18nScope('assignment_group_category')

export default class GroupCategorySelector extends Backbone.View

  template: template

  GROUP_CATEGORY = '#assignment_group_category'
  GROUP_CATEGORY_ID = '#assignment_group_category_id'
  CREATE_GROUP_CATEGORY_ID = '#create_group_category_id'
  HAS_GROUP_CATEGORY = '#has_group_category'
  GROUP_CATEGORY_OPTIONS = '#group_category_options'

  els: do ->
    els = {}
    els["#{GROUP_CATEGORY}"] = '$groupCategory'
    els["#{GROUP_CATEGORY_ID}"] = '$groupCategoryID'
    els["#{HAS_GROUP_CATEGORY}"] = '$hasGroupCategory'
    els["#{GROUP_CATEGORY_OPTIONS}"] = '$groupCategoryOptions'
    els

  events: do ->
    events = {}
    events[ "change #{GROUP_CATEGORY_ID}" ] = 'groupCategorySelected'
    events[ "click #{CREATE_GROUP_CATEGORY_ID}" ] = 'showGroupCategoryCreateDialog'
    events[ "change #{HAS_GROUP_CATEGORY}" ] = 'toggleGroupCategoryOptions'
    events

  initialize: (options) ->
    super
    @renderSectionsAutocomplete = options.renderSectionsAutocomplete

  @optionProperty 'parentModel'
  @optionProperty 'groupCategories'
  @optionProperty 'nested'
  @optionProperty 'hideGradeIndividually'
  @optionProperty 'sectionLabel'
  @optionProperty 'fieldLabel'
  @optionProperty 'lockedMessage'
  @optionProperty 'inClosedGradingPeriod'

  render: =>
    selectedID = @parentModel.groupCategoryId()
    if _.isEmpty(@groupCategories)
      StudentGroupStore.setSelectedGroupSet(null)
    else if !selectedID? or !_.findWhere(@groupCategories, {id: selectedID.toString()})?
      StudentGroupStore.setSelectedGroupSet(null)
    else
      StudentGroupStore.setSelectedGroupSet(selectedID)
    super
    @$groupCategory.toggleAccessibly !_.isEmpty(@groupCategories)

  groupCategorySelected: =>
    newSelectedId = @$groupCategoryID.val()
    StudentGroupStore.setSelectedGroupSet(newSelectedId)

  showGroupCategoryCreateDialog: =>
    awaitElement 'create-group-set-modal-mountpoint'
    .then renderCreateDialog
    .then (result) =>
      if result
        $newCategory = document.createElement('option')
        $newCategory.value = result.id
        $newCategory.text = result.name
        $newCategory.setAttribute('selected', true)
        @$groupCategoryID.append $newCategory
        @$groupCategoryID.val(result.id)
        @groupCategories.push(result)
        @$groupCategory.toggleAccessibly = true

  groupDiscussionChecked: =>
    @$hasGroupCategory.prop('checked')

  disableGroupDiscussionCheckbox: =>
    @$hasGroupCategory.prop('disabled', true)

  enableGroupDiscussionCheckbox: =>
    @$hasGroupCategory.prop('disabled', false)

  canManageGroups: =>
    if ENV.PERMISSIONS?.hasOwnProperty('can_manage_groups')
      ENV.PERMISSIONS.can_manage_groups
    else
      true

  toggleGroupCategoryOptions: =>
    isGrouped = @groupDiscussionChecked()
    @$groupCategoryOptions.toggleAccessibly isGrouped

    selectedGroupSetId = if isGrouped then @$groupCategoryID.val() else null
    StudentGroupStore.setSelectedGroupSet(selectedGroupSetId)
    if isGrouped and _.isEmpty(@groupCategories) and @canManageGroups()
      @showGroupCategoryCreateDialog()

    @renderSectionsAutocomplete() if @renderSectionsAutocomplete?

  toJSON: =>
    frozenAttributes = @parentModel.frozenAttributes?() || []
    groupCategoryFrozen = _.includes frozenAttributes, 'group_category_id'
    groupCategoryLocked = !@parentModel.canGroup()

    isGroupAssignment: @parentModel.groupCategoryId() && @parentModel.groupCategoryId() != 'blank'
    groupCategoryId: @parentModel.groupCategoryId()
    groupCategories: @groupCategories
    groupCategoryUnselected: !@parentModel.groupCategoryId() ||
                              @parentModel.groupCategoryId() == 'blank' ||
                            !_.chain(@groupCategories)
                            .pluck('id')
                            .contains(@parentModel.groupCategoryId())
                            .value() && !_.isEmpty(@groupCategories)

    hideGradeIndividually: @hideGradeIndividually
    gradeGroupStudentsIndividually: !@hideGradeIndividually && @parentModel.gradeGroupStudentsIndividually()
    groupCategoryLocked: groupCategoryLocked

    hasGroupCategoryDisabled:  groupCategoryFrozen || groupCategoryLocked
    gradeIndividuallyDisabled: groupCategoryFrozen
    groupCategoryIdDisabled:   groupCategoryFrozen || groupCategoryLocked

    sectionLabel: @sectionLabel
    fieldLabel: @fieldLabel
    lockedMessage: @lockedMessage
    ariaChecked: if @parentModel.groupCategoryId() then 'true' else 'false'

    nested: @nested
    prefix: 'assignment' if @nested
    inClosedGradingPeriod: @inClosedGradingPeriod
    cannotManageGroups: !@canManageGroups()

  filterFormData: (data) =>
    hasGroupCategory = data.has_group_category
    delete data.has_group_category
    if hasGroupCategory == '0'
      data.group_category_id = null
      data.grade_group_students_individually = false
    data

  fieldSelectors: do ->
    s = {}
    s['groupCategorySelector'] = '#assignment_group_category_id'
    s['newGroupCategory'] = '#create_group_category_id'
    s

  validateBeforeSave: (data, errors) =>
    errors = @_validateGroupCategoryID data, errors
    errors

  _validateGroupCategoryID: (data, errors) =>
    gcid = if @nested
      data.assignment.groupCategoryId()
    else
      data.group_category_id

    if gcid == "blank"
      if _.isEmpty(@groupCategories)
        if @canManageGroups()
          errors["newGroupCategory"] = [
            message: I18n.t 'Please create a group set'
          ]
        else
          errors["newGroupCategory"] = [
            message: I18n.t 'Group Add permission is needed to create a New Group Category'
          ]
      else
        errors["groupCategorySelector"] = [
          message: I18n.t 'Please select a group set for this assignment'
        ]
    errors
