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
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import AssignmentGroupSelector from '@canvas/assignments/backbone/views/AssignmentGroupSelector'
import GradingTypeSelector from '@canvas/assignments/backbone/views/GradingTypeSelector'
import GroupCategorySelector from '@canvas/groups/backbone/views/GroupCategorySelector'
import PeerReviewsSelector from '@canvas/assignments/backbone/views/PeerReviewsSelector'
import PostToSisSelector from './PostToSisSelector'
import {uniqueId, defer, includes, isEqual, extend as lodashExtend} from 'lodash'
import React from 'react'
import ReactDOM from 'react-dom'
import template from '../../jst/EditView.handlebars'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import DiscussionTopic from '@canvas/discussions/backbone/models/DiscussionTopic'
import Announcement from '@canvas/discussions/backbone/models/Announcement'
import $ from 'jquery'
import MissingDateDialog from '@canvas/due-dates/backbone/views/MissingDateDialogView'
import ConditionalRelease from '@canvas/conditional-release-editor'
import deparam from 'deparam'
import numberHelper from '@canvas/i18n/numberHelper'
import DueDateCalendarPicker from '@canvas/due-dates/react/DueDateCalendarPicker'
import SisValidationHelper from '@canvas/sis/SisValidationHelper'
import AssignmentExternalTools from '@canvas/assignments/react/AssignmentExternalTools'
import FilesystemObject from '@canvas/files/backbone/models/FilesystemObject'
import UsageRightsIndicator from '@canvas/files/react/components/UsageRightsIndicator'
import setUsageRights from '@canvas/files/util/setUsageRights'
import * as returnToHelper from '@canvas/util/validateReturnToURL'
import 'jqueryui/tabs'

const I18n = useI18nScope('discussion_topics')

RichContentEditor.preloadRemoteModule()

extend(EditView, ValidatedFormView)

function EditView() {
  this.enableGradedCheckBox = this.enableGradedCheckBox.bind(this)
  this.disableGradedCheckBox = this.disableGradedCheckBox.bind(this)
  this._validatePointsPossible = this._validatePointsPossible.bind(this)
  this._validateTitle = this._validateTitle.bind(this)
  this.validateBeforeSave = this.validateBeforeSave.bind(this)
  this.onSaveFail = this.onSaveFail.bind(this)
  this.submit = this.submit.bind(this)
  this.saveFormData = this.saveFormData.bind(this)
  this.updateAssignment = this.updateAssignment.bind(this)
  this.handleStudentTodoUpdate = this.handleStudentTodoUpdate.bind(this)
  this.renderStudentTodoAtDate = this.renderStudentTodoAtDate.bind(this)
  this.loadConditionalRelease = this.loadConditionalRelease.bind(this)
  this.renderTabs = this.renderTabs.bind(this)
  this.renderPostToSisOptions = this.renderPostToSisOptions.bind(this)
  this.renderPeerReviewOptions = this.renderPeerReviewOptions.bind(this)
  this.renderGroupCategoryOptions = this.renderGroupCategoryOptions.bind(this)
  this.renderGradingTypeOptions = this.renderGradingTypeOptions.bind(this)
  this.renderAssignmentGroupOptions = this.renderAssignmentGroupOptions.bind(this)
  this.renderUsageRights = this.renderUsageRights.bind(this)
  this.initialUsageRights = this.initialUsageRights.bind(this)
  this.afterRender = this.afterRender.bind(this)
  this.shouldRenderUsageRights = this.shouldRenderUsageRights.bind(this)
  this.render = this.render.bind(this)
  this.handlePointsChange = this.handlePointsChange.bind(this)
  this.handleCancel = this.handleCancel.bind(this)
  this.canPublish = this.canPublish.bind(this)
  this.isAnnouncement = this.isAnnouncement.bind(this)
  this.isTopic = this.isTopic.bind(this)
  this.locationAfterCancel = this.locationAfterCancel.bind(this)
  this.locationAfterSave = this.locationAfterSave.bind(this)
  this.setRenderSectionsAutocomplete = this.setRenderSectionsAutocomplete.bind(this)
  this.handleMessageEvent = this.handleMessageEvent.bind(this)
  window.addEventListener('message', this.handleMessageEvent.bind(this))
  return EditView.__super__.constructor.apply(this, arguments)
}

EditView.prototype.template = template

EditView.prototype.tagName = 'form'

EditView.prototype.className = 'form-horizontal no-margin'

EditView.prototype.dontRenableAfterSaveSuccess = true

EditView.prototype.els = {
  '#availability_options': '$availabilityOptions',
  '#use_for_grading': '$useForGrading',
  '#discussion_topic_assignment_points_possible': '$assignmentPointsPossible',
  '#discussion_point_change_warning': '$discussionPointPossibleWarning',
  '#discussion-edit-view': '$discussionEditView',
  '#discussion-details-tab': '$discussionDetailsTab',
  '#conditional-release-target': '$conditionalReleaseTarget',
  '#todo_options': '$todoOptions',
  '#todo_date_input': '$todoDateInput',
  '#allow_todo_date': '$allowTodoDate',
  '#allow_user_comments': '$allowUserComments',
  '#require_initial_post': '$requireInitialPost',
  '#assignment_external_tools': '$AssignmentExternalTools',
}

EditView.prototype.events = lodashExtend(EditView.prototype.events, {
  'click .removeAttachment': 'removeAttachment',
  'click .save_and_publish': 'saveAndPublish',
  'click .cancel_button': 'handleCancel',
  'change #use_for_grading': 'toggleGradingDependentOptions',
  'change .delay_post_at_date': 'hanldeDelayedPostAtChange',
  'change #discussion_topic_assignment_points_possible': 'handlePointsChange',
  change: 'onChange',
  'tabsbeforeactivate #discussion-edit-view': 'onTabChange',
  'change #allow_todo_date': 'toggleTodoDateInput',
  'change #allow_user_comments': 'updateAllowComments',
})

EditView.prototype.messages = {
  group_category_section_label: I18n.t('group_discussion_title', 'Group Discussion'),
  group_category_field_label: I18n.t('this_is_a_group_discussion', 'This is a Group Discussion'),
  group_locked_message: I18n.t(
    'group_discussion_locked',
    'Students have already submitted to this discussion, so group settings cannot be changed.'
  ),
}

EditView.optionProperty('permissions')

EditView.prototype.initialize = function (options) {
  this.assignment = this.model.get('assignment')
  this.initialPointsPossible = this.assignment.pointsPossible()
  this.dueDateOverrideView = options.views['js-assignment-overrides']
  this.on(
    'success',
    (function (_this) {
      return function (xhr) {
        let contextId, contextType, ref, ref1, usageRights
        if (((ref = xhr.attachments) != null ? ref.length : void 0) === 1) {
          usageRights = _this.attachment_model.get('usage_rights')
          if (usageRights && !isEqual(_this.initialUsageRights(), usageRights)) {
            ref1 = ENV.context_asset_string.split('_')
            contextType = ref1[0]
            contextId = ref1[1]
            _this.attachment_model.set('id', xhr.attachments[0].id)
            return setUsageRights(
              [_this.attachment_model],
              usageRights,
              function (_success, _data) {
                return {}
              },
              contextId,
              contextType + 's'
            ).always(function () {
              _this.unwatchUnload()
              return _this.redirectAfterSave()
            })
          } else {
            _this.unwatchUnload()
            return _this.redirectAfterSave()
          }
        } else {
          _this.unwatchUnload()
          return _this.redirectAfterSave()
        }
      }
    })(this)
  )
  this.attachment_model = new FilesystemObject()
  EditView.__super__.initialize.apply(this, arguments)
  this.lockedItems = options.lockedItems || {}
  this.announcementsLocked = options.announcementsLocked
  const todoDate = this.model.get('todo_date')
  return (this.studentTodoAtDateValue = todoDate ? new Date(todoDate) : '')
}

EditView.prototype.setRenderSectionsAutocomplete = function (func) {
  return (this.renderSectionsAutocomplete = func)
}

EditView.prototype.redirectAfterSave = function () {
  return (window.location = this.locationAfterSave(deparam()))
}

EditView.prototype.locationAfterSave = function (params) {
  if (returnToHelper.isValid(params.return_to)) {
    return params.return_to
  } else {
    const url = new URL(window.location.href)
    const searchParams = new URLSearchParams(url.search)
    if (searchParams.get('embed') === 'true') {
      return this.model.get('html_url') + '?embed=true'
    } else {
      return this.model.get('html_url')
    }
  }
}

EditView.prototype.redirectAfterCancel = function () {
  const location = this.locationAfterCancel(deparam())
  if (location) {
    return (window.location = location)
  }
}

EditView.prototype.locationAfterCancel = function (params) {
  if (returnToHelper.isValid(params.return_to)) {
    return params.return_to
  }
  if (ENV.CANCEL_TO != null) {
    return ENV.CANCEL_TO
  }
  return null
}

EditView.prototype.isTopic = function () {
  return this.model.constructor === DiscussionTopic
}

EditView.prototype.isAnnouncement = function () {
  return this.model.constructor === Announcement
}

EditView.prototype.willPublish = function ({delayed_post_at} = {}) {
  const delayedString = delayed_post_at || this.getFormData().delayed_post_at // date string
  // When the page is first loaded, the delay_post checkbox info is not available. In that case we want to default to true and
  // Rely on the existence of the delayedString to determine if the announcement will publish immediately or not
  const delayPostingCheckbox = this.getFormData().delay_posting
    ? this.getFormData().delay_posting
    : '1' // status of the checkbox
  const isDelayedPostedAtChecked = delayPostingCheckbox === '1'

  if (delayedString && isDelayedPostedAtChecked) {
    const delayedDate = new Date(delayedString)
    const now = new Date()
    return delayedDate <= now
  }

  return true
}

EditView.prototype.canPublish = function () {
  return !this.isAnnouncement() && !this.model.get('published') && this.permissions.CAN_MODERATE
}

EditView.prototype.toJSON = function () {
  const data = EditView.__super__.toJSON.apply(this, arguments)
  const json = lodashExtend(data, this.options, {
    showAssignment: !!this.assignmentGroupCollection,
    useForGrading: this.model.get('assignment') != null,
    isTopic: this.isTopic(),
    isAnnouncement: this.isAnnouncement(),
    willPublish: this.willPublish(data),
    canPublish: this.canPublish(),
    contextIsCourse: this.options.contextType === 'courses',
    canAttach: this.permissions.CAN_ATTACH,
    canModerate: this.permissions.CAN_MODERATE,
    cannotEditGrades: !this.permissions.CAN_EDIT_GRADES && this.assignment.gradedSubmissionsExist(),
    isLargeRoster:
      (typeof ENV !== 'undefined' && ENV !== null ? ENV.IS_LARGE_ROSTER : void 0) || false,
    threaded: data.discussion_type === 'threaded',
    inClosedGradingPeriod: this.assignment.inClosedGradingPeriod(),
    lockedItems: this.lockedItems,
    allow_todo_date: data.todo_date != null,
    unlocked: data.locked === void 0 ? !this.isAnnouncement() : !data.locked,
    announcementsLocked: this.announcementsLocked,
  })
  json.assignment = json.assignment.toView()
  return json
}

EditView.prototype.handleCancel = function (ev) {
  ev.preventDefault()
  if (!this.lockedItems.content) {
    RichContentEditor.closeRCE(this.$textarea)
  }
  this.unwatchUnload()
  return this.redirectAfterCancel()
}

EditView.prototype.handlePointsChange = function (ev) {
  ev.preventDefault()
  this.assignment.pointsPossible(this.$assignmentPointsPossible.val())
  if (this.assignment.hasSubmittedSubmissions()) {
    return this.$discussionPointPossibleWarning.toggleAccessibly(
      this.assignment.pointsPossible() !== this.initialPointsPossible
    )
  }
}

EditView.prototype.validateGuidData = function (event) {
  const data = event.data.data

  // If data is a string, convert it to an array for consistent processing
  const dataArray = Array.isArray(data) ? data : [data]
  const regexPattern =
    /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/

  for (const str of dataArray) {
    if (!regexPattern.test(str)) {
      return false
    }
  }
  return dataArray
}

EditView.prototype.handleMessageEvent = function (event) {
  if (event?.data?.subject !== 'assignment.set_ab_guid') {
    return
  }
  const abGuid = this.validateGuidData(event)
  if (abGuid) {
    this.assignment.set('ab_guid', abGuid)
  }
}

EditView.prototype.loadNewEditor = function ($textarea) {
  if (this.lockedItems.content) {
    return
  }
  return RichContentEditor.loadNewEditor($textarea, {
    focus: true,
    manageParent: true,
  })
}

EditView.prototype.render = function () {
  EditView.__super__.render.apply(this, arguments)
  this.$textarea = this.$('textarea[name=message]')
    .attr('id', uniqueId('discussion-topic-message'))
    .css('display', 'none')
  if (!this.lockedItems.content) {
    defer(
      (function (_this) {
        return function () {
          return _this.loadNewEditor(_this.$textarea)
        }
      })(this)
    )
  }
  if (this.assignmentGroupCollection) {
    ;(
      this.assignmentGroupFetchDfd ||
      (this.assignmentGroupFetchDfd = this.assignmentGroupCollection.fetch())
    ).done(this.renderAssignmentGroupOptions)
  }
  defer(this.renderGradingTypeOptions)
  if (this.permissions.CAN_SET_GROUP) {
    defer(this.renderGroupCategoryOptions)
  }
  defer(this.renderPeerReviewOptions)
  if (ENV.POST_TO_SIS) {
    defer(this.renderPostToSisOptions)
  }
  defer(this.watchUnload)
  if (this.showConditionalRelease()) {
    defer(this.renderTabs)
  }
  if (this.showConditionalRelease()) {
    defer(this.loadConditionalRelease)
  }
  this.$('.datetime_field').datetime_field()
  if (!this.model.get('locked')) {
    this.updateAllowComments()
  }
  return this
}

EditView.prototype.shouldRenderUsageRights = function () {
  return (
    ENV.FEATURES.usage_rights_discussion_topics &&
    ENV.USAGE_RIGHTS_REQUIRED &&
    ENV.PERMISSIONS.manage_files &&
    this.permissions.CAN_ATTACH
  )
}

EditView.prototype.afterRender = function () {
  if (this.$todoDateInput.length) {
    this.renderStudentTodoAtDate()
  }
  const ref = ENV.context_asset_string.split('_')
  const context = ref[0]
  const context_id = ref[1]
  if (context === 'course') {
    this.AssignmentExternalTools = AssignmentExternalTools.attach(
      this.$AssignmentExternalTools.get(0),
      'assignment_edit',
      parseInt(context_id, 10),
      parseInt(this.assignment.id, 10)
    )
  }
  if (this.shouldRenderUsageRights()) {
    return this.renderUsageRights()
  }
}

EditView.prototype.initialUsageRights = function () {
  let ref
  if (this.model.get('attachments')) {
    return (ref = this.model.get('attachments')[0]) != null ? ref.usage_rights : void 0
  }
}

EditView.prototype.renderUsageRights = function () {
  const ref = ENV.context_asset_string.split('_')
  const contextType = ref[0]
  const contextId = ref[1]
  const usage_rights = this.initialUsageRights()
  if (usage_rights && !this.attachment_model.get('usage_rights')) {
    this.attachment_model.set('usage_rights', usage_rights)
  }
  const props = {
    suppressWarning: true,
    hidePreview: true,
    contextType: contextType + 's',
    contextId,
    model: this.attachment_model,
    deferSave: (function (_this) {
      return function (usageRights) {
        _this.attachment_model.set('usage_rights', usageRights)
        return _this.renderUsageRights()
      }
    })(this),
    userCanEditFilesForContext: true,
    userCanRestrictFilesForContext: false,
    usageRightsRequiredForContext: true,
    modalOptions: {
      isOpen: false,
      openModal: (function (_this) {
        return function (contents, _afterClose) {
          // eslint-disable-next-line react/no-render-return-value
          return ReactDOM.render(contents, _this.$('#usage_rights_modal')[0])
        }
      })(this),
      closeModal: (function (_this) {
        return function () {
          return ReactDOM.unmountComponentAtNode(_this.$('#usage_rights_modal')[0])
        }
      })(this),
    },
  }
  const component = React.createElement(UsageRightsIndicator, props, null)
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(component, this.$('#usage_rights_control')[0])
}

EditView.prototype.renderAssignmentGroupOptions = function () {
  this.assignmentGroupSelector = new AssignmentGroupSelector({
    el: '#assignment_group_options',
    assignmentGroups: this.assignmentGroupCollection.toJSON(),
    parentModel: this.assignment,
    nested: true,
  })
  return this.assignmentGroupSelector.render()
}

EditView.prototype.renderGradingTypeOptions = function () {
  this.gradingTypeSelector = new GradingTypeSelector({
    el: '#grading_type_options',
    parentModel: this.assignment,
    nested: true,
    preventNotGraded: true,
    canEditGrades: this.permissions.CAN_EDIT_GRADES,
  })
  return this.gradingTypeSelector.render()
}

EditView.prototype.renderGroupCategoryOptions = function () {
  this.groupCategorySelector = new GroupCategorySelector({
    el: '#group_category_options',
    parentModel: this.model,
    groupCategories: ENV.GROUP_CATEGORIES,
    hideGradeIndividually: true,
    sectionLabel: this.messages.group_category_section_label,
    fieldLabel: this.messages.group_category_field_label,
    lockedMessage: this.messages.group_locked_message,
    inClosedGradingPeriod: this.assignment.inClosedGradingPeriod(),
    renderSectionsAutocomplete: this.renderSectionsAutocomplete,
  })
  return this.groupCategorySelector.render()
}

EditView.prototype.renderPeerReviewOptions = function () {
  this.peerReviewSelector = new PeerReviewsSelector({
    el: '#peer_review_options',
    parentModel: this.assignment,
    nested: true,
    hideAnonymousPeerReview: true,
  })
  return this.peerReviewSelector.render()
}

EditView.prototype.renderPostToSisOptions = function () {
  this.postToSisSelector = new PostToSisSelector({
    el: '#post_to_sis_options',
    parentModel: this.assignment,
    nested: true,
  })
  return this.postToSisSelector.render()
}

EditView.prototype.renderTabs = function () {
  this.$discussionEditView.tabs()
  return this.toggleConditionalReleaseTab()
}

EditView.prototype.loadConditionalRelease = function () {
  if (!ENV.CONDITIONAL_RELEASE_ENV) {
    return
  }
  return (this.conditionalReleaseEditor = ConditionalRelease.attach(
    this.$conditionalReleaseTarget.get(0),
    I18n.t('discussion topic'),
    ENV.CONDITIONAL_RELEASE_ENV
  ))
}

EditView.prototype.renderStudentTodoAtDate = function () {
  this.toggleTodoDateInput()
  // eslint-disable-next-line react/no-render-return-value
  return ReactDOM.render(
    React.createElement(DueDateCalendarPicker, {
      dateType: 'todo_date',
      name: 'todo_date',
      handleUpdate: this.handleStudentTodoUpdate,
      rowKey: 'student_todo_at_date',
      labelledBy: 'student_todo_at_date_label',
      inputClasses: '',
      disabled: false,
      isFancyMidnight: true,
      dateValue: this.studentTodoAtDateValue,
      labelText: I18n.t('Discussion Topic will show on student to-do list for date'),
      labelClasses: 'screenreader-only',
    }),
    this.$todoDateInput[0]
  )
}

EditView.prototype.handleStudentTodoUpdate = function (newDate) {
  this.studentTodoAtDateValue = newDate
  return this.renderStudentTodoAtDate()
}

EditView.prototype.getFormData = function () {
  let data, dateField, i, len, ref
  data = EditView.__super__.getFormData.apply(this, arguments)
  const dateFields = ['last_reply_at', 'posted_at', 'delayed_post_at', 'lock_at']
  for (i = 0, len = dateFields.length; i < len; i++) {
    dateField = dateFields[i]
    data[dateField] = $.unfudgeDateForProfileTimezone(data[dateField])
  }
  data.title || (data.title = I18n.t('default_discussion_title', 'No Title'))
  data.discussion_type = data.threaded === '1' ? 'threaded' : 'side_comment'
  if (data.podcast_enabled !== '1') {
    data.podcast_has_student_posts = false
  }
  if (data.allow_rating !== '1') {
    data.only_graders_can_rate = false
  }
  if (((ref = data.assignment) != null ? ref.set_assignment : void 0) === '1') {
    data.allow_todo_date = '0'
  }
  data.todo_date = this.studentTodoAtDateValue
  if (data.allow_todo_date !== '1') {
    data.todo_date = null
  }
  if (
    this.groupCategorySelector &&
    !(typeof ENV !== 'undefined' && ENV !== null ? ENV.IS_LARGE_ROSTER : void 0)
  ) {
    data = this.groupCategorySelector.filterFormData(data)
  }
  const assign_data = data.assignment
  delete data.assignment
  if (assign_data != null ? assign_data.points_possible : void 0) {
    assign_data.ab_guid = this.assignment.get('ab_guid')
  }
  if (assign_data != null ? assign_data.points_possible : void 0) {
    if (numberHelper.validate(assign_data.points_possible)) {
      assign_data.points_possible = numberHelper.parse(assign_data.points_possible)
    }
  }
  if (assign_data != null ? assign_data.peer_review_count : void 0) {
    if (numberHelper.validate(assign_data.peer_review_count)) {
      assign_data.peer_review_count = numberHelper.parse(assign_data.peer_review_count)
    }
  }
  if ((assign_data != null ? assign_data.set_assignment : void 0) === '1') {
    data.set_assignment = '1'
    data.assignment = this.updateAssignment(assign_data)
  } else {
    // Announcements don't have assignments.
    // DiscussionTopics get a model created for them in their
    // constructor. Delete it so the API doesn't automatically
    // create assignments unless the user checked "Use for Grading".
    // The controller checks for set_assignment on the assignment model,
    // so we can't make it undefined here for the case of discussion topics.
    data.assignment = this.model.createAssignment({
      // there are no assignment params here, so sending a '0' will cause the
      // @discussion_topic.assignment to be removed in the back end if it already
      // exists. By sending a '1', you can preserve the assignment as-is.
      set_assignment: this.permissions.CAN_CREATE_ASSIGNMENT
        ? '0'
        : this.permissions.CAN_UPDATE_ASSIGNMENT
        ? '1'
        : '0',
    })
  }
  // these options get passed to Backbone.sync in ValidatedFormView
  this.saveOpts = {
    multipart: !!data.attachment,
    proxyAttachment: true,
  }
  if (this.shouldPublish) {
    data.published = true
  }
  return data
}

EditView.prototype.updateAssignment = function (data) {
  let assignment
  const defaultDate = this.dueDateOverrideView.getDefaultDueDate()
  data.lock_at = (defaultDate != null ? defaultDate.get('lock_at') : void 0) || null
  data.unlock_at = (defaultDate != null ? defaultDate.get('unlock_at') : void 0) || null
  data.due_at = (defaultDate != null ? defaultDate.get('due_at') : void 0) || null
  data.assignment_overrides = this.dueDateOverrideView.getOverrides()
  data.only_visible_to_overrides = !this.dueDateOverrideView.overridesContainDefault()
  assignment = this.model.get('assignment')
  assignment || (assignment = this.model.createAssignment())
  return assignment.set(data)
}

EditView.prototype.removeAttachment = function () {
  this.model.set('attachments', [])
  this.$el.append('<input type="hidden" name="remove_attachment" >')
  this.$('.attachmentRow').remove()
  return this.$('[name="attachment"]').show().focus()
}

EditView.prototype.saveFormData = function () {
  if (this.showConditionalRelease()) {
    return EditView.__super__.saveFormData.apply(this, arguments).pipe(
      (function (_this) {
        return function (data, status, xhr) {
          let assignment
          if (data.set_assignment) {
            assignment = data.assignment
          }
          _this.conditionalReleaseEditor.updateAssignment(assignment)
          return _this.conditionalReleaseEditor.save().pipe(
            function () {
              return new $.Deferred().resolve(data, status, xhr).promise()
            },
            function (err) {
              return new $.Deferred().reject(xhr, err).promise()
            }
          )
        }
      })(this)
    )
  } else {
    return EditView.__super__.saveFormData.apply(this, arguments)
  }
}

EditView.prototype.submit = function (event) {
  let missingDateDialog, sections
  event.preventDefault()
  event.stopPropagation()
  if (this.gradedChecked() && this.dueDateOverrideView.containsSectionsWithoutOverrides()) {
    sections = this.dueDateOverrideView.sectionsWithoutOverrides()
    missingDateDialog = new MissingDateDialog({
      validationFn() {
        return sections
      },
      labelFn(section) {
        return section.get('name')
      },
      success: (function (_this) {
        return function () {
          let ref
          missingDateDialog.$dialog.dialog('close').remove()
          if ((ref = _this.model.get('assignment')) != null) {
            ref.setNullDates()
          }
          return ValidatedFormView.prototype.submit.call(_this)
        }
      })(this),
    })
    missingDateDialog.cancel = function (_e) {
      return missingDateDialog.$dialog.dialog('close').remove()
    }
    return missingDateDialog.render()
  } else {
    return EditView.__super__.submit.apply(this, arguments)
  }
}

EditView.prototype.fieldSelectors = lodashExtend(
  {
    usage_rights_control: '#usage_rights_control button',
  },
  AssignmentGroupSelector.prototype.fieldSelectors,
  GroupCategorySelector.prototype.fieldSelectors
)

EditView.prototype.saveAndPublish = function (event) {
  this.shouldPublish = true
  this.disableWhileLoadingOpts = {
    buttons: ['.save_and_publish'],
  }
  return this.submit(event)
}

EditView.prototype.onSaveFail = function (xhr) {
  this.shouldPublish = false
  this.disableWhileLoadingOpts = {}
  return EditView.__super__.onSaveFail.call(this, xhr)
}

EditView.prototype.sectionsAreRequired = function () {
  if (!ENV.context_asset_string.startsWith('course')) {
    return false
  }
  const isAnnouncement = ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement
  const announcementsFlag = ENV.SECTION_SPECIFIC_ANNOUNCEMENTS_ENABLED
  const discussionsFlag = ENV.SECTION_SPECIFIC_DISCUSSIONS_ENABLED
  if (isAnnouncement) {
    return announcementsFlag
  } else {
    return discussionsFlag
  }
}

EditView.prototype.validateBeforeSave = function (data, errors) {
  // The anonymous_state is missing if the fields are disabled. We need the value for edit mode too.
  let crErrors, ref, validateBeforeSaveData
  data.anonymous_state = $('input[name=anonymous_state]:checked').val()
  if (data.delay_posting === '0') {
    data.delayed_post_at = null
  }
  if (data.lock_at !== null && data.delayed_post_at > data.lock_at) {
    errors.lock_at = [
      {
        message: I18n.t('Date must be after date available'),
      },
    ]
  }
  if (data.anonymous_state !== 'full_anonymity' && data.anonymous_state !== 'partial_anonymity') {
    data.anonymous_state = null
  }
  if (this.isTopic() && data.set_assignment === '1') {
    if (this.assignmentGroupSelector != null) {
      errors = this.assignmentGroupSelector.validateBeforeSave(data, errors)
    }
    validateBeforeSaveData = {
      assignment_overrides: this.dueDateOverrideView.getAllDates(),
      postToSIS: data.assignment.attributes.post_to_sis === '1',
    }
    errors = this.dueDateOverrideView.validateBeforeSave(validateBeforeSaveData, errors)
    errors = this._validatePointsPossible(data, errors)
    errors = this._validateTitle(data, errors)
    if (data.anonymous_state !== null) {
      errors.anonymous_state = [
        {
          message: I18n.t('You are not allowed to create an anonymous graded discussion'),
        },
      ]
    }
  } else {
    this.model.set(
      'assignment',
      this.model.createAssignment({
        set_assignment: false,
      })
    )
  }
  if (
    !(typeof ENV !== 'undefined' && ENV !== null ? ENV.IS_LARGE_ROSTER : void 0) &&
    this.isTopic() &&
    this.groupCategorySelector
  ) {
    errors = this.groupCategorySelector.validateBeforeSave(data, errors)
  }
  if (data.allow_todo_date === '1' && data.todo_date === null) {
    errors.todo_date = [
      {
        type: 'date_required_error',
        message: I18n.t('You must enter a date'),
      },
    ]
  }
  if (this.sectionsAreRequired() && !data.specific_sections) {
    errors.specific_sections = [
      {
        type: 'specific_sections_required_error',
        message: I18n.t('You must input a section'),
      },
    ]
  }
  if (this.isAnnouncement()) {
    if (!(((ref = data.message) != null ? ref.length : void 0) > 0)) {
      if (!this.lockedItems.content) {
        errors.message = [
          {
            type: 'message_required_error',
            message: I18n.t('A message is required'),
          },
        ]
      }
    }
  }
  if (this.showConditionalRelease()) {
    crErrors = this.conditionalReleaseEditor.validateBeforeSave()
    if (crErrors) {
      errors.conditional_release = crErrors
    }
  }
  if (
    this.shouldRenderUsageRights() &&
    this.$('#discussion_attachment_uploaded_data').val() !== '' &&
    !this.attachment_model.get('usage_rights')
  ) {
    errors.usage_rights_control = [
      {
        message: I18n.t('You must set usage rights'),
      },
    ]
  }
  return errors
}

EditView.prototype._validateTitle = function (data, errors) {
  let max_name_length
  const post_to_sis = data.assignment.attributes.post_to_sis === '1'
  max_name_length = 256
  if (post_to_sis && ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT === true) {
    max_name_length = ENV.MAX_NAME_LENGTH
  }
  const validationHelper = new SisValidationHelper({
    postToSIS: post_to_sis,
    maxNameLength: max_name_length,
    name: data.title,
    maxNameLengthRequired: ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT,
  })
  if (validationHelper.nameTooLong()) {
    errors.title = [
      {
        message: I18n.t('Title is too long, must be under %{length} characters', {
          length: max_name_length + 1,
        }),
      },
    ]
  }
  return errors
}

EditView.prototype._validatePointsPossible = function (data, errors) {
  const assign = data.assignment
  const frozenPoints = includes(assign.frozenAttributes(), 'points_possible')
  if (!frozenPoints && assign.pointsPossible() && !numberHelper.validate(assign.pointsPossible())) {
    errors['assignment[points_possible]'] = [
      {
        message: I18n.t('points_possible_number', 'Points possible must be a number'),
      },
    ]
  }
  return errors
}

EditView.prototype.showErrors = function (errors) {
  // override view handles displaying override errors, remove them
  // before calling super
  delete errors.assignmentOverrides
  if (this.showConditionalRelease()) {
    // switch to a tab with errors
    if (errors.conditional_release) {
      this.$discussionEditView.tabs('option', 'active', 1)
      this.conditionalReleaseEditor.focusOnError()
    } else {
      this.$discussionEditView.tabs('option', 'active', 0)
    }
  }
  return EditView.__super__.showErrors.call(this, errors)
}

EditView.prototype.toggleGradingDependentOptions = function () {
  this.toggleAvailabilityOptions()
  this.toggleConditionalReleaseTab()
  this.toggleTodoDateBox()
  if (this.renderSectionsAutocomplete != null) {
    return this.renderSectionsAutocomplete()
  }
}

EditView.prototype.hanldeDelayedPostAtChange = function () {
  const submitButton = $('.submit_button')
  if (!this.willPublish()) {
    submitButton.text(I18n.t('Save'))
  } else {
    submitButton.text(I18n.t('Publish'))
  }
}

EditView.prototype.gradedChecked = function () {
  return this.$useForGrading.is(':checked')
}

// Graded discussions and section specific discussions are mutually exclusive
EditView.prototype.disableGradedCheckBox = function () {
  return this.$useForGrading.prop('disabled', true)
}

// Graded discussions and section specific discussions are mutually exclusive
EditView.prototype.enableGradedCheckBox = function () {
  return this.$useForGrading.prop('disabled', false)
}

EditView.prototype.toggleAvailabilityOptions = function () {
  if (this.gradedChecked()) {
    return this.$availabilityOptions.hide()
  } else {
    return this.$availabilityOptions.show()
  }
}

EditView.prototype.showConditionalRelease = function () {
  return ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && !this.isAnnouncement()
}

EditView.prototype.toggleConditionalReleaseTab = function () {
  if (this.showConditionalRelease()) {
    if (this.gradedChecked()) {
      return this.$discussionEditView.tabs('option', 'disabled', false)
    } else {
      this.$discussionEditView.tabs('option', 'disabled', [1])
      return this.$discussionEditView.tabs('option', 'active', 0)
    }
  }
}

EditView.prototype.toggleTodoDateBox = function () {
  if (this.gradedChecked()) {
    return this.$todoOptions.hide()
  } else {
    return this.$todoOptions.show()
  }
}

EditView.prototype.toggleTodoDateInput = function () {
  if (this.$allowTodoDate.is(':checked')) {
    return this.$todoDateInput.show()
  } else {
    return this.$todoDateInput.hide()
  }
}

EditView.prototype.updateAllowComments = function () {
  const allowsComments =
    this.$allowUserComments.is(':checked') || !this.model.get('is_announcement')
  this.$requireInitialPost.prop('disabled', !allowsComments)
  return this.model.set('locked', !allowsComments)
}

EditView.prototype.onChange = function () {
  if (this.showConditionalRelease() && this.assignmentUpToDate) {
    return (this.assignmentUpToDate = false)
  }
}

EditView.prototype.onTabChange = function () {
  if (this.showConditionalRelease() && !this.assignmentUpToDate && this.conditionalReleaseEditor) {
    let ref
    const assignmentData = (ref = this.getFormData().assignment) != null ? ref.attributes : void 0
    this.conditionalReleaseEditor.updateAssignment(assignmentData)
    this.assignmentUpToDate = true
  }
  return true
}

export default EditView
