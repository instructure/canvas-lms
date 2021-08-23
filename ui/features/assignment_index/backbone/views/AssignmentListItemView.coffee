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

import I18n from 'i18n!AssignmentListItemView'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import React from 'react'
import ReactDOM from 'react-dom'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import DirectShareUserModal from '@canvas/direct-sharing/react/components/DirectShareUserModal'
import DirectShareCourseTray from '@canvas/direct-sharing/react/components/DirectShareCourseTray'
import * as MoveItem from '@canvas/move-item-tray'
import Assignment from '@canvas/assignments/backbone/models/Assignment.coffee'
import PublishIconView from '@canvas/publish-icon-view'
import LockIconView from '@canvas/lock-icon'
import DateDueColumnView from '@canvas/assignments/backbone/views/DateDueColumnView.coffee'
import DateAvailableColumnView from '@canvas/assignments/backbone/views/DateAvailableColumnView.coffee'
import CreateAssignmentView from './CreateAssignmentView.coffee'
import SisButtonView from '@canvas/sis/backbone/views/SisButtonView.coffee'
import preventDefault from 'prevent-default'
import template from '../../jst/AssignmentListItem.handlebars'
import scoreTemplate from '../../jst/_assignmentListItemScore.handlebars'
import round from 'round'
import AssignmentKeyBindingsMixin from '../mixins/AssignmentKeyBindingsMixin'
import 'jqueryui/tooltip'
import '../../../../boot/initializers/activateTooltips.js'
import '@canvas/rails-flash-notifications'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'

export default class AssignmentListItemView extends Backbone.View
  @mixin AssignmentKeyBindingsMixin
  @optionProperty 'userIsAdmin'

  tagName: "li"
  className: ->
    "assignment#{if @canMove() then '' else ' sort-disabled'}"
  template: template

  @child 'publishIconView',         '[data-view=publish-icon]'
  @child 'lockIconView',            '[data-view=lock-icon]'
  @child 'dateDueColumnView',       '[data-view=date-due]'
  @child 'dateAvailableColumnView', '[data-view=date-available]'
  @child 'editAssignmentView',      '[data-view=edit-assignment]'
  @child 'sisButtonView',           '[data-view=sis-button]'

  els:
    '.al-trigger': '$settingsButton'
    '.edit_assignment': '$editAssignmentButton'
    '.move_assignment': '$moveAssignmentButton'

  events:
    'click .delete_assignment': 'onDelete'
    'click .duplicate_assignment': 'onDuplicate'
    'click .send_assignment_to': 'onSendAssignmentTo'
    'click .copy_assignment_to': 'onCopyAssignmentTo'
    'click .tooltip_link': preventDefault ->
    'keydown': 'handleKeys'
    'mousedown': 'stopMoveIfProtected'
    'click .icon-lock': 'onUnlockAssignment'
    'click .icon-unlock': 'onLockAssignment'
    'click .move_assignment': 'onMove'
    'click .duplicate-failed-retry': 'onDuplicateFailedRetry'
    'click .migrate-failed-retry': 'onMigrateFailedRetry'
    'click .duplicate-failed-cancel': 'onDuplicateOrImportFailedCancel'
    'click .import-failed-cancel': 'onDuplicateOrImportFailedCancel'

  messages: shimGetterShorthand {},
    confirm: -> I18n.t('Are you sure you want to delete this assignment?')
    ag_move_label: -> I18n.beforeLabel I18n.t('Assignment Group')

  initialize: ->
    super
    @initializeChildViews()
    # we need the following line in order to access this view later
    @model.assignmentView = @

    @model.on('change:hidden', @toggleHidden)
    @model.set('disabledForModeration', !@canEdit())

    if @canManage()
      @model.on('change:published', @updatePublishState)

      # re-render for attributes we are showing
      attrs = ["name", "points_possible", "due_at", "lock_at", "unlock_at", "modules", "published", "workflow_state"]
      observe = attrs.map((attr) -> "change:#{attr}").join(" ")
      @model.on(observe, @render)
    @model.on 'change:submission', @updateScore

    @model.pollUntilFinishedLoading()

  initializeChildViews: ->
    @publishIconView = false
    @lockIconView = false
    @sisButtonView = false
    @editAssignmentView = false
    @dateAvailableColumnView = false

    if @canManage()
      @publishIconView = new PublishIconView({
        model: @model,
        title: @model.get('name')
      })
      @lockIconView = new LockIconView({
        model: @model,
        unlockedText: I18n.t("%{name} is unlocked. Click to lock.", name: @model.get('name')),
        lockedText: I18n.t("%{name} is locked. Click to unlock", name: @model.get('name')),
        course_id: @model.get('course_id'),
        content_id: @model.get('id'),
        content_type: 'assignment'
      })
      @editAssignmentView = new CreateAssignmentView(model: @model)

      if @isGraded() && @model.postToSISEnabled() && @model.published()
        @sisButtonView = new SisButtonView
          model: @model
          sisName: @model.postToSISName()
          dueDateRequired: @model.dueDateRequiredForAccount()
          maxNameLengthRequired: @model.maxNameLengthRequiredForAccount()

    @dateDueColumnView       = new DateDueColumnView(model: @model)
    @dateAvailableColumnView = new DateAvailableColumnView(model: @model)

  # Public: Called when move menu item is selected
  #
  # Returns nothing.
  onMove: () =>
    @moveTrayProps =
      title: I18n.t('Move Assignment')
      items: [
        id: @model.get('id')
        title: @model.get('name')
      ]
      moveOptions:
        groupsLabel:  @messages.ag_move_label
        groups: MoveItem.backbone.collectionToGroups(@model.collection.view?.parentCollection, (col) => col.get('assignments'))
      onMoveSuccess: (res) =>
        keys =
          model: 'assignments'
          parent: 'assignment_group_id'
        MoveItem.backbone.reorderAcrossCollections(res.data.order, res.groupId, @model, keys)
      focusOnExit: =>
        document.querySelector("#assignment_#{@model.id} a[id*=manage_link]")
      formatSaveUrl: ({ groupId }) ->
        "#{ENV.URLS.assignment_sort_base_url}/#{groupId}/reorder"

    MoveItem.renderTray(@moveTrayProps, document.getElementById('not_right_side'))

  updatePublishState: =>
    @$('.ig-row').toggleClass('ig-published', @model.get('published'))

  # call remove on children so that they can clean up old dialogs.
  render: ->
    @toggleHidden(@model, @model.get('hidden'))
    @publishIconView.remove()         if @publishIconView
    @lockIconView.remove()            if @lockIconView
    @sisButtonView.remove()           if @sisButtonView
    @editAssignmentView.remove()      if @editAssignmentView
    @dateDueColumnView.remove()       if @dateDueColumnView
    @dateAvailableColumnView.remove() if @dateAvailableColumnView

    super
    # reset the model's view property; it got overwritten by child views
    @model.view = this if @model

  afterRender: ->
    @createModuleToolTip()

    if @editAssignmentView
      @editAssignmentView.hide()
      @editAssignmentView.setTrigger @$editAssignmentButton if @canEdit()

    @updateScore() if @canReadGrades()

  toggleHidden: (model, hidden) =>
    @$el.toggleClass('hidden', hidden)
    @$el.toggleClass('search_show', !hidden)

  stopMoveIfProtected: (e) ->
    e.stopPropagation() unless @canMove()

  createModuleToolTip: =>
    link = @$el.find('.tooltip_link')
    if link.length > 0
      link.tooltip
        position:
          my: 'center bottom'
          at: 'center top-10'
          collision: 'fit fit'
        tooltipClass: 'center bottom vertical'
        content: ->
          $(link.data('tooltipSelector')).html()

  toJSON: ->
    data = @model.toView()
    data.canManage = @canManage()
    data = @_setJSONForGrade(data) unless data.canManage

    data.canEdit = @canEdit()
    data.canMove = @canMove()
    data.canDelete = @canDelete()
    data.canDuplicate = @canDuplicate()
    data.is_locked =  @model.isRestrictedByMasterCourse()
    data.showAvailability = @model.multipleDueDates() or not @model.defaultDates().available()
    data.showDueDate = @model.multipleDueDates() or @model.singleSectionDueDate()

    data.cyoe = CyoeHelper.getItemData(data.id, @isGraded() && (!@model.isQuiz() || data.is_quiz_assignment))
    data.return_to = encodeURIComponent window.location.pathname

    data.quizzesRespondusEnabled = @model.quizzesRespondusEnabled()

    data.DIRECT_SHARE_ENABLED = !!ENV.DIRECT_SHARE_ENABLED
    data.canOpenManageOptions = @canOpenManageOptions()

    if data.canManage
      data.spanWidth      = 'span3'
      data.alignTextClass = ''
    else
      data.spanWidth      = 'span4'
      data.alignTextClass = 'align-right'

    if @model.isQuiz()
      data.menu_tools = ENV.quiz_menu_tools || []
      data.menu_tools.forEach (tool) =>
        tool.url = tool.base_url + "&quizzes[]=#{@model.get("quiz_id")}"
    else if @model.isDiscussionTopic()
      data.menu_tools = ENV.discussion_topic_menu_tools || []
      data.menu_tools.forEach (tool) =>
        tool.url = tool.base_url + "&discussion_topics[]=#{@model.get("discussion_topic")?.id}"
    else
      data.menu_tools = ENV.assignment_menu_tools || []
      data.menu_tools.forEach (tool) =>
        tool.url = tool.base_url + "&assignments[]=#{@model.get("id")}"

    if modules = @model.get('modules')
      moduleName = modules[0]
      has_modules = modules.length > 0
      joinedNames = modules.join(",")
      Object.assign data, {
        modules: modules
        module_count: modules.length
        module_name: moduleName
        has_modules: has_modules
        joined_names: joinedNames
      }
    else
      data

  addAssignmentToList: (response) =>
    return unless response
    assignment = new Assignment(response)
    # Force the positions to match what is in the db.
    @model.collection.forEach((a) =>
      a.set('position', response.new_positions[a.get('id')])
    )
    if @hasIndividualPermissions()
      ENV.PERMISSIONS.by_assignment_id[assignment.id] = ENV.PERMISSIONS.by_assignment_id[assignment.originalAssignmentID()]
    @model.collection.add(assignment)
    @focusOnAssignment(response)

  addMigratedQuizToList: (response) =>
    return unless response
    quizzes = response.migrated_assignment
    if quizzes
      @addAssignmentToList(quizzes[0])

  onDuplicate: (e) =>
    return unless @canDuplicate()
    e.preventDefault()
    @model.duplicate(@addAssignmentToList)

  onDuplicateFailedRetry: (e, action) =>
    e.preventDefault()
    $button = $(e.target)
    $button.prop('disabled', true)
    @model.duplicate_failed((response) =>
      @addAssignmentToList(response)
      @delete(silent: true)
    ).always -> $button.prop('disabled', false)

  onMigrateFailedRetry: (e, action) =>
    e.preventDefault()
    $button = $(e.target)
    $button.prop('disabled', true)
    @model.retry_migration((response) =>
      @addMigratedQuizToList(response)
      @delete(silent: true)
    ).always -> $button.prop('disabled', false)

  onDuplicateOrImportFailedCancel: (e) =>
    e.preventDefault()
    @delete(silent: true)

  onDelete: (e) =>
    e.preventDefault()
    return unless @canDelete()
    return @$el.find('a[id*=manage_link]').focus() unless confirm(@messages.confirm)
    if @previousAssignmentInGroup()?
      @focusOnAssignment(@previousAssignmentInGroup())
      @delete()
    else
      id = @model.attributes.assignment_group_id
      @delete()
      @focusOnGroupByID(id)

  onSendAssignmentTo: (e) =>
    e.preventDefault()
    renderModal = (open) =>
      mountPoint = document.getElementById('send-to-mount-point')
      return unless mountPoint
      ReactDOM.render(React.createElement(DirectShareUserModal, {
        open: open
        courseId: ENV.COURSE_ID || ENV.COURSE.id
        contentShare: {content_type: 'assignment', content_id: @model.id}
        shouldReturnFocus: false
        onDismiss: dismissModal
      }), mountPoint)

    dismissModal = () =>
      renderModal(false)
      # delay necessary because something else is messing with our focus, even with shouldReturnFocus: false
      setTimeout(
        () => @$settingsButton.focus()
        100)

    renderModal(true)

  onCopyAssignmentTo: (e) =>
    e.preventDefault()
    renderTray = (open) =>
      mountPoint = document.getElementById('copy-to-mount-point')
      return unless mountPoint
      ReactDOM.render(React.createElement(DirectShareCourseTray, {
        open: open
        sourceCourseId: ENV.COURSE_ID || ENV.COURSE.id
        contentSelection: {assignments: [@model.id]}
        shouldReturnFocus: false
        onDismiss: dismissTray
      }), mountPoint)

    dismissTray = () =>
      renderTray(false)
      # delay necessary because something else is messing with our focus, even with shouldReturnFocus: false
      setTimeout(
        () => @$settingsButton.focus()
        100)

    renderTray(true)

  onUnlockAssignment: (e) =>
    e.preventDefault()

  onLockAssignment: (e) =>
    e.preventDefault()

  delete: (opts = { silent: false }) ->
    callbacks = {}
    unless opts.silent
      callbacks.success = -> $.screenReaderFlashMessage(I18n.t('Assignment was deleted'))
    @model.destroy(callbacks)
    @$el.remove()

  hasIndividualPermissions: ->
    ENV.PERMISSIONS.by_assignment_id?

  canDelete: ->
    modelResult = (@userIsAdmin or @model.canDelete()) && !@model.isRestrictedByMasterCourse()
    userResult = if @hasIndividualPermissions()
      !!(ENV.PERMISSIONS.by_assignment_id[@model.id]?.delete)
    else
      ENV.PERMISSIONS.manage_assignments_delete
    modelResult && userResult

  canDuplicate: ->
    (@userIsAdmin || @canAdd()) && @model.canDuplicate()

  canMove: ->
    @userIsAdmin or (@canManage() and @model.canMove())

  canEdit: ->
    if !@hasIndividualPermissions()
      return @userIsAdmin or @canManage()

    @userIsAdmin or (@canManage() && !!(ENV.PERMISSIONS.by_assignment_id[@model.id]?.update))

  canAdd: ->
    ENV.PERMISSIONS.manage_assignments_add

  canManage: ->
    ENV.PERMISSIONS.manage

  canOpenManageOptions: ->
    @canManage() || @canAdd() || @canDelete() || ENV.DIRECT_SHARE_ENABLED

  isGraded: ->
    submission_types = @model.get('submission_types')
    submission_types && !submission_types.includes('not_graded') && !submission_types.includes('wiki_page')

  gradeStrings: (grade) ->
    pass_fail_map =
      incomplete:
        I18n.t 'incomplete', 'Incomplete'
      complete:
        I18n.t 'complete', 'Complete'

    grade = pass_fail_map[grade] or grade

    'percent':
      nonscreenreader: I18n.t 'grade_percent', '%{grade}%', grade: grade
      screenreader: I18n.t 'grade_percent_screenreader', 'Grade: %{grade}%', grade: grade
    'pass_fail':
      nonscreenreader: "#{grade}"
      screenreader: I18n.t 'grade_pass_fail_screenreader', 'Grade: %{grade}', grade: grade
    'letter_grade':
      nonscreenreader: "#{grade}"
      screenreader: I18n.t 'grade_letter_grade_screenreader', 'Grade: %{grade}', grade: grade
    'gpa_scale':
      nonscreenreader: "#{grade}"
      screenreader: I18n.t 'grade_gpa_scale_screenreader', 'Grade: %{grade}', grade: grade


  _setJSONForGrade: (json) ->
    if submission = @model.get('submission')
      submissionJSON = if submission.present then submission.present() else submission.toJSON()
      score = submission.get('score')
      if typeof score is 'number' && !isNaN(score)
        submissionJSON.score = round score, round.DEFAULT
      json.submission = submissionJSON
      grade = submission.get('grade')
      gradeString = @gradeStrings(grade)[json.gradingType]
      json.submission.gradeDisplay = gradeString?.nonscreenreader
      json.submission.gradeDisplayForScreenreader = gradeString?.screenreader

    pointsPossible = json.pointsPossible

    if typeof pointsPossible is 'number' && !isNaN(pointsPossible)
      json.pointsPossible = round pointsPossible, round.DEFAULT
      json.submission.pointsPossible = json.pointsPossible if json.submission?

    json.submission.gradingType = json.gradingType if json.submission?

    if json.gradingType is 'not_graded'
      json.hideGrade = true
    json

  updateScore: =>
    json = @model.toView()
    json = @_setJSONForGrade(json) unless @canManage()
    @$('.js-score').html scoreTemplate(json)

  canReadGrades: ->
    ENV.PERMISSIONS.read_grades

  goToNextItem: =>
    if @nextAssignmentInGroup()?
      @focusOnAssignment(@nextAssignmentInGroup())
    else if @nextVisibleGroup()?
      @focusOnGroup(@nextVisibleGroup())
    else
      @focusOnFirstGroup()

  goToPrevItem: =>
    if @previousAssignmentInGroup()?
      @focusOnAssignment(@previousAssignmentInGroup())
    else
      @focusOnGroupByID(@model.attributes.assignment_group_id)

  editItem: =>
    @$("#assignment_#{@model.id}_settings_edit_item").click()

  deleteItem: =>
    @$("#assignment_#{@model.id}_settings_delete_item").click()

  addItem: =>
    group_id = @model.attributes.assignment_group_id
    $(".add_assignment", "#assignment_group_#{group_id}").click()

  showAssignment: =>
    $(".ig-title", "#assignment_#{@model.id}")[0].click()

  assignmentGroupView: =>
    @model.collection.view

  visibleAssignments: =>
    @assignmentGroupView().visibleAssignments()

  nextVisibleGroup: =>
    @assignmentGroupView().nextGroup()

  nextAssignmentInGroup: =>
    current_assignment_index = @visibleAssignments().indexOf(@model)
    @visibleAssignments()[current_assignment_index + 1]

  previousAssignmentInGroup: =>
    current_assignment_index = @visibleAssignments().indexOf(@model)
    @visibleAssignments()[current_assignment_index - 1]

  focusOnAssignment: (assignment) =>
    $("#assignment_#{assignment.id}").attr("tabindex",-1).focus()

  focusOnGroup: (group) =>
    $("#assignment_group_#{group.attributes.id}").attr("tabindex",-1).focus()

  focusOnGroupByID: (group_id) =>
    $("#assignment_group_#{group_id}").attr("tabindex",-1).focus()

  focusOnFirstGroup: =>
    $(".assignment_group").filter(":visible").first().attr("tabindex",-1).focus()
