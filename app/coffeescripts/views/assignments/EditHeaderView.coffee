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
  'i18n!assignments'
  'Backbone'
  'jquery'
  'jsx/shared/conditional_release/ConditionalRelease'
  'jst/assignments/EditHeaderView'
  'jquery.disableWhileLoading'
], (I18n, Backbone, $, ConditionalRelease, template) ->

  class EditHeaderView extends Backbone.View
    @optionProperty 'userIsAdmin'

    template: template

    events:
      'click .delete_assignment_link': 'onDelete'
      'change #grading_type_selector': 'onGradingTypeUpdate'
      'tabsbeforeactivate': 'onTabChange'

    messages:
      confirm: I18n.t('Are you sure you want to delete this assignment?')

    els:
      '#edit-assignment-header-tabs': '$headerTabs'
      '#edit-assignment-header-cr-tabs': '$headerTabsCr'

    initialize: (options) ->
      super
      @editView = options.views['edit_assignment_form']
      @editView.on 'show-errors', @onShowErrors

    afterRender: ->
      # doubled for conditional release
      @$headerTabs.tabs()
      @$headerTabsCr.tabs()
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @toggleConditionalReleaseTab(@model.gradingType())

      if ENV.ANONYMOUS_MODERATED_MARKING_ENABLED
        @model.renderModeratedGradingFormFieldGroup()

    canDelete: ->
      (@userIsAdmin or @model.canDelete()) && !(ENV.MASTER_COURSE_DATA?.is_master_course_child_content && ENV.MASTER_COURSE_DATA.restricted_by_master_course)

    onDelete: (e) =>
      e.preventDefault()
      if @canDelete()
        if confirm(@messages.confirm)
          @delete()
        else
          window.$('a:first[role="button"].al-trigger.btn').focus()

    delete: ->
      disablingDfd = new $.Deferred()
      if destroyDfd = @model.destroy()
        destroyDfd.then(@onSaveSuccess)
        destroyDfd.fail -> disablingDfd.reject()
        $('#content').disableWhileLoading disablingDfd
      else
        # .destroy() returns false if model isNew
        @onDeleteSuccess()

    onDeleteSuccess: ->
      location.href = ENV.ASSIGNMENT_INDEX_URL

    onGradingTypeUpdate: (e) =>
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @toggleConditionalReleaseTab(e.target.value)

    toggleConditionalReleaseTab: (gradingType) ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        if gradingType == 'not_graded'
          @$headerTabsCr.tabs("option", "disabled", [1])
          @$headerTabsCr.tabs("option", "active", 0)
        else
          @$headerTabsCr.tabs("option", "disabled", false)

    onTabChange: ->
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        @editView.updateConditionalRelease()
      true

    onShowErrors: (errors) =>
      if ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
        if errors['conditional_release']
          @$headerTabsCr.tabs("option", "active", 1)
        else
          @$headerTabsCr.tabs("option", "active", 0)

    toJSON: ->
      json = @model.toView()
      json.canDelete = @canDelete()
      json['CONDITIONAL_RELEASE_SERVICE_ENABLED'] = ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
      json['is_locked'] = (ENV.MASTER_COURSE_DATA?.is_master_course_child_content && ENV.MASTER_COURSE_DATA.restricted_by_master_course)
      json
