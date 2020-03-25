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

import I18n from 'i18n!assignmentsIndexView'
import KeyboardNavDialog from '../KeyboardNavDialog'
import keyboardNavTemplate from 'jst/KeyboardNavDialog'
import $ from 'jquery'
import _ from 'underscore'
import Backbone from 'Backbone'
import React from 'react'
import ReactDOM from 'react-dom'
import template from 'jst/assignments/IndexView'
import NoAssignments from 'jst/assignments/NoAssignmentsSearch'
import AssignmentKeyBindingsMixin from './AssignmentKeyBindingsMixin'
import userSettings from '../../userSettings'
import GradingPeriodsAPI from '../../api/gradingPeriodsApi'
import IndexMenu from 'jsx/assignments/IndexMenu'
import configureIndexMenuStore from 'jsx/assignments/store/indexMenuStore'
import BulkEditIndex from 'jsx/assignments/bulk_edit/BulkEditIndex'
import '../../jquery.rails_flash_notifications'

export default class IndexView extends Backbone.View
  @mixin AssignmentKeyBindingsMixin

  template: template
  el: '#content'

  @child 'assignmentGroupsView', '[data-view=assignmentGroups]'
  @child 'createGroupView', '[data-view=createGroup]'
  @child 'assignmentSettingsView', '[data-view=assignmentSettings]'
  @child 'assignmentSyncSettingsView', '[data-view=assignmentSyncSettings]'
  @child 'showByView', '[data-view=showBy]'

  events:
    'keyup #search_term': 'search'
    'change #grading_period_selector': 'filterResults'
    'focus .drag_and_drop_warning': 'show_dnd_warning'
    'blur .drag_and_drop_warning': 'hide_dnd_warning'

  els:
    '#addGroup': '$addGroupButton'
    '#assignmentSettingsCog': '$assignmentSettingsButton'
    '#settingsMountPoint': '$settingsMountPoint'
    '#bulkEditRoot': '$bulkEditRoot'

  initialize: ->
    super
    @collection.once 'reset', @enableSearch, @
    @collection.on 'cancelSearch', @clearSearch, @
    @bulkEditMode = false

  toJSON: ->
    json = super
    json.course_home = ENV.COURSE_HOME
    json.weight_final_grades = ENV.WEIGHT_FINAL_GRADES
    json.bulkEditMode = @bulkEditMode
    json

  afterRender: ->
    # need to hide child views and set trigger manually

    if @createGroupView
      @createGroupView.hide()
      @createGroupView.setTrigger @$addGroupButton

    if @assignmentSettingsView
      @assignmentSettingsView.hide()
      @assignmentSyncSettingsView.hide()

      @indexMenuStore = configureIndexMenuStore({
        weighted: ENV.WEIGHT_FINAL_GRADES,
        externalTools: [],
        modalIsOpen: false,
        selectedTool: null
      });

      contextInfo = ENV.context_asset_string.split('_')
      contextType = contextInfo[0]
      contextId = parseInt(contextInfo[1], 10)

      requestBulkEditFn =
        (!ENV.COURSE_HOME && ENV.FEATURES.assignment_bulk_edit && @requestBulkEdit) ||
        undefined

      if @$settingsMountPoint.length
        ReactDOM.render(
          React.createElement(IndexMenu, {
            store: @indexMenuStore,
            contextType: contextType,
            contextId: contextId,
            requestBulkEdit: requestBulkEditFn,
            setTrigger: @assignmentSettingsView.setTrigger.bind(@assignmentSettingsView)
            setDisableTrigger: @assignmentSyncSettingsView.setTrigger.bind(@assignmentSyncSettingsView)
            registerWeightToggle: @assignmentSettingsView.on.bind(@assignmentSettingsView)
            disableSyncToSis: @assignmentSyncSettingsView.openDisableSync.bind(@assignmentSyncSettingsView)
            sisName: ENV.SIS_NAME
            postToSisDefault: ENV.POST_TO_SIS_DEFAULT
            hasAssignments: ENV.HAS_ASSIGNMENTS,
            assignmentGroupsCollection: @collection
          }),
          @$settingsMountPoint[0]
        )

    if @bulkEditMode && @$bulkEditRoot.length
      ReactDOM.render(
        React.createElement(BulkEditIndex, {}),
        @$bulkEditRoot[0]
      )

    @filterKeyBindings() if !@canManage()

    @ensureContentStyle()

    @kbDialog = new KeyboardNavDialog().render(keyboardNavTemplate({keyBindings:@keyBindings}))
    window.onkeydown = @focusOnAssignments

    @selectGradingPeriod()

  requestBulkEdit: =>
    @bulkEditMode = true
    @render()

  enableSearch: ->
    @$('#search_term').prop 'disabled', false

  clearSearch: ->
    @$('#search_term').val('')
    @filterResults()

  search: _.debounce ->
    @filterResults()
  , 200

  gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods)

  show_dnd_warning: (event) =>
    @$(event.currentTarget).removeClass('screenreader-only')

  hide_dnd_warning: (event) =>
    @$(event.currentTarget).addClass('screenreader-only')

  filterResults: =>
    term = $('#search_term').val()
    gradingPeriod = null
    if ENV.HAS_GRADING_PERIODS
      gradingPeriodIndex = $("#grading_period_selector").val()
      gradingPeriod = @gradingPeriods[parseInt(gradingPeriodIndex)] if gradingPeriodIndex != "all"
      @saveSelectedGradingPeriod(gradingPeriod)
    if term == "" && (gradingPeriod == null)
      #show all
      @collection.each (group) =>
        group.groupView.endSearch()

      #remove noAssignments placeholder
      if @noAssignments?
        @noAssignments.remove()
        @noAssignments = null
    else
      regex = new RegExp(@cleanSearchTerm(term), 'ig')
      #search
      matchingAssignmentCount = @collection.reduce( (runningTotal, group) ->
        additionalCount = group.groupView.search(regex, gradingPeriod)
        runningTotal + additionalCount
      , 0)

      atleastoneGroup = matchingAssignmentCount > 0
      @alertForMatchingGroups(matchingAssignmentCount)

      #add noAssignments placeholder
      if !atleastoneGroup
        unless @noAssignments
          @noAssignments = new Backbone.View
            template: NoAssignments
            tagName: "li"
            className: "item-group-condensed"
          ul = @assignmentGroupsView.$el.children(".collectionViewItems")
          ul.append(@noAssignments.render().el)
      else
        #remove noAssignments placeholder
        if @noAssignments?
          @noAssignments.remove()
          @noAssignments = null

  alertForMatchingGroups: (numAssignments) ->
    msg = I18n.t({
        one: "1 assignment found."
        other: "%{count} assignments found."
        zero: "No matching assignments found."
      }, count: numAssignments
    )
    $.screenReaderFlashMessageExclusive(msg)

  cleanSearchTerm: (text) ->
    text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")

  focusOnAssignments: (e) =>
    if 74 == e.keyCode
      unless($(e.target).is(":input"))
        $(".assignment_group").filter(":visible").first().attr("tabindex",-1).focus()

  canManage: ->
    ENV.PERMISSIONS.manage

  ensureContentStyle: ->
    # when loaded from homepage, need to change content style
    if !@canManage() && window.location.href.indexOf('assignments') == -1
      $("#content").css("padding", "0em")

  filterKeyBindings: =>
    @keyBindings = @keyBindings.filter (binding) ->
      ! [69,68,65].includes(binding.keyCode)

  selectGradingPeriod: ->
    gradingPeriodId = userSettings.contextGet('assignments_current_grading_period')
    unless gradingPeriodId == null
      for i of @gradingPeriods
        if @gradingPeriods[i].id == gradingPeriodId
          $("#grading_period_selector").val(i)
          break

  saveSelectedGradingPeriod: (gradingPeriod) ->
    userSettings.contextSet('assignments_current_grading_period', gradingPeriod && gradingPeriod.id)
