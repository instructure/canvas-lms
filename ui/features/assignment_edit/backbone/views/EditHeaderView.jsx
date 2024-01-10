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

import React from 'react'
import ReactDOM from 'react-dom'
import {Pill} from '@instructure/ui-pill'
import {IconPublishSolid, IconUnpublishedLine} from '@instructure/ui-icons'
import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/EditHeaderView.handlebars'
import '@canvas/jquery/jquery.disableWhileLoading'
import 'jqueryui/tabs'

const I18n = useI18nScope('assignmentsEditHeaderView')

extend(EditHeaderView, Backbone.View)

function EditHeaderView() {
  this.onShowErrors = this.onShowErrors.bind(this)
  this.onGradingTypeUpdate = this.onGradingTypeUpdate.bind(this)
  this.onDelete = this.onDelete.bind(this)
  return EditHeaderView.__super__.constructor.apply(this, arguments)
}

EditHeaderView.optionProperty('userIsAdmin')

EditHeaderView.prototype.template = template

EditHeaderView.prototype.events = {
  'click .delete_assignment_link': 'onDelete',
  'change #grading_type_selector': 'onGradingTypeUpdate',
  tabsbeforeactivate: 'onTabChange',
}

EditHeaderView.prototype.messages = {
  confirm: I18n.t('Are you sure you want to delete this assignment?'),
}

EditHeaderView.prototype.els = {
  '#edit-assignment-header-tabs': '$headerTabs',
  '#edit-assignment-header-cr-tabs': '$headerTabsCr',
}

EditHeaderView.prototype.initialize = function (options) {
  EditHeaderView.__super__.initialize.apply(this, arguments)
  this.editView = options.views.edit_assignment_form
  return this.editView.on('show-errors', this.onShowErrors)
}

EditHeaderView.prototype.afterRender = function () {
  // doubled for conditional release
  this.$headerTabs.tabs()
  this.$headerTabsCr.tabs()
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    return this.toggleConditionalReleaseTab(this.model.gradingType())
  }
  // EVAL-3711 Remove ICE feature flag
  if (ENV.FEATURES.instui_nav) {
    ReactDOM.render(
      <Pill
        renderIcon={this.model.published() ? <IconPublishSolid /> : <IconUnpublishedLine />}
        color={this.model.published() ? 'success' : 'primary'}
      >
        {this.model.published() ? 'Published' : 'Not Published'}
      </Pill>,
      this.$el.find('.published-assignment-container')[0]
    )
  }
}

EditHeaderView.prototype.canDelete = function () {
  let ref
  return (
    (this.userIsAdmin || this.model.canDelete()) &&
    !(
      ((ref = ENV.MASTER_COURSE_DATA) != null ? ref.is_master_course_child_content : void 0) &&
      ENV.MASTER_COURSE_DATA.restricted_by_master_course
    )
  )
}

EditHeaderView.prototype.onDelete = function (e) {
  e.preventDefault()
  if (this.canDelete()) {
    // eslint-disable-next-line no-alert
    if (window.confirm(this.messages.confirm)) {
      return this.delete()
    } else {
      return window.$('a:first[role="button"].al-trigger.btn').focus()
    }
  }
}

EditHeaderView.prototype.delete = function () {
  let destroyDfd
  const disablingDfd = new $.Deferred()
  if ((destroyDfd = this.model.destroy())) {
    // eslint-disable-next-line promise/catch-or-return
    destroyDfd.then(this.onDeleteSuccess.bind(this))
    destroyDfd.fail(function () {
      return disablingDfd.reject()
    })
    return $('#content').disableWhileLoading(disablingDfd)
  } else {
    return this.onDeleteSuccess()
  }
}

EditHeaderView.prototype.onDeleteSuccess = function () {
  return (window.location.href = ENV.ASSIGNMENT_INDEX_URL)
}

EditHeaderView.prototype.onGradingTypeUpdate = function (e) {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    return this.toggleConditionalReleaseTab(e.target.value)
  }
}

EditHeaderView.prototype.toggleConditionalReleaseTab = function (gradingType) {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    if (gradingType === 'not_graded') {
      this.$headerTabsCr.tabs('option', 'disabled', [1])
      return this.$headerTabsCr.tabs('option', 'active', 0)
    } else {
      return this.$headerTabsCr.tabs('option', 'disabled', false)
    }
  }
}

EditHeaderView.prototype.onTabChange = function () {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    this.editView.updateConditionalRelease()
  }
  return true
}

EditHeaderView.prototype.onShowErrors = function (errors) {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    if (errors.conditional_release) {
      return this.$headerTabsCr.tabs('option', 'active', 1)
    } else {
      return this.$headerTabsCr.tabs('option', 'active', 0)
    }
  }
}

EditHeaderView.prototype.renderHeaderTitle = function () {
  return this.model.name()
    ? this.model.isQuizLTIAssignment()
      ? 'Edit Quiz'
      : 'Edit Assignment'
    : this.model.isQuizLTIAssignment()
    ? 'Create Quiz'
    : 'Create New Assignment'
}

EditHeaderView.prototype.toJSON = function () {
  let ref
  const json = this.model.toView()
  json.canDelete = this.canDelete()
  json.renderHeaderTitle = this.renderHeaderTitle()
  json.CONDITIONAL_RELEASE_SERVICE_ENABLED = ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED
  json.courseId = ENV.COURSE_ID
  // EVAL-3711 Remove ICE feature flag
  json.instui_nav = ENV.FEATURES.instui_nav
  json.showSpeedGraderLink = ENV.SHOW_SPEED_GRADER_LINK
  json.is_locked =
    ((ref = ENV.MASTER_COURSE_DATA) != null ? ref.is_master_course_child_content : void 0) &&
    ENV.MASTER_COURSE_DATA.restricted_by_master_course
  return json
}

export default EditHeaderView
