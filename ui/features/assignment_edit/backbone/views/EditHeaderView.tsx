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

import React from 'react'
import {render} from '@canvas/react'
import {Pill} from '@instructure/ui-pill'
import {IconPublishSolid, IconUnpublishedLine} from '@instructure/ui-icons'
import {extend} from '@canvas/backbone/utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation} from '@canvas/util/globalUtils'
import Backbone from '@canvas/backbone'
import $ from 'jquery'
import template from '../../jst/EditHeaderView.handlebars'
import '@canvas/jquery/jquery.disableWhileLoading'
import ConditionalReleaseTabs from '../../react/ConditionalReleaseTabs'
import type {ConditionalReleaseTabsHandle} from '../../react/ConditionalReleaseTabs'
import {shimGetterShorthand} from '@canvas/util/legacyCoffeesScriptHelpers'

const I18n = createI18nScope('assignmentsEditHeaderView')

// @ts-expect-error
extend(EditHeaderView, Backbone.View)

function EditHeaderView() {
  // @ts-expect-error
  this.onShowErrors = this.onShowErrors.bind(this)
  // @ts-expect-error
  this.onGradingTypeUpdate = this.onGradingTypeUpdate.bind(this)
  // @ts-expect-error
  this.onDelete = this.onDelete.bind(this)
  // @ts-expect-error
  return EditHeaderView.__super__.constructor.apply(this, arguments)
}

// @ts-expect-error
EditHeaderView.optionProperty('userIsAdmin')

EditHeaderView.prototype.template = template

EditHeaderView.prototype.events = {
  'click .delete_assignment_link': 'onDelete',
  'change #grading_type_selector': 'onGradingTypeUpdate',
}

// same getter pattern as used in AssignmentListItemView
EditHeaderView.prototype.messages = shimGetterShorthand(
  {},
  {
    confirm() {
      return I18n.t('Are you sure you want to delete this assignment?')
    },
  },
)

EditHeaderView.prototype.initialize = function (options: any) {
  // @ts-expect-error
  EditHeaderView.__super__.initialize.apply(this, arguments)
  this.editView = options.views.edit_assignment_form
  return this.editView.on('show-errors', this.onShowErrors)
}

EditHeaderView.prototype.afterRender = function () {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    this._crTabsRef = React.createRef<ConditionalReleaseTabsHandle>()
    const mountPoint = this.$el.find('#conditional-release-tabs-mount')[0]
    if (mountPoint) {
      render(
        <ConditionalReleaseTabs
          ref={this._crTabsRef}
          onTabChange={() => this.editView.updateConditionalRelease()}
        />,
        mountPoint,
        {sync: true},
      )
    }
    this.toggleConditionalReleaseTab(this.model.gradingType())
  }
  // EVAL-3711 Remove ICE feature flag
  if (ENV.FEATURES?.instui_nav) {
    render(
      <Pill
        renderIcon={this.model.published() ? <IconPublishSolid /> : <IconUnpublishedLine />}
        color={this.model.published() ? 'success' : 'primary'}
      >
        {this.model.published() ? 'Published' : 'Not Published'}
      </Pill>,
      this.$el.find('.published-assignment-container')[0],
      {sync: true},
    )
  }
}

EditHeaderView.prototype.canDelete = function () {
  let ref
  return (
    (this.userIsAdmin || this.model.canDelete()) &&
    !(
      ((ref = ENV.MASTER_COURSE_DATA) != null ? ref.is_master_course_child_content : void 0) &&
      // @ts-expect-error
      ENV.MASTER_COURSE_DATA.restricted_by_master_course
    )
  )
}

// @ts-expect-error
EditHeaderView.prototype.onDelete = function (e) {
  e.preventDefault()
  if (this.canDelete()) {
    if (window.confirm(this.messages.confirm)) {
      return this.delete()
    } else {
      // @ts-expect-error
      return window.$('a:first[role="button"].al-trigger.btn').focus()
    }
  }
}

EditHeaderView.prototype.delete = function () {
  let destroyDfd
  // @ts-expect-error
  const disablingDfd = new $.Deferred()
  if ((destroyDfd = this.model.destroy())) {
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
  // @ts-expect-error
  return assignLocation(ENV.ASSIGNMENT_INDEX_URL)
}

// @ts-expect-error
EditHeaderView.prototype.onGradingTypeUpdate = function (e) {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
    return this.toggleConditionalReleaseTab(e.target.value)
  }
}

// @ts-expect-error
EditHeaderView.prototype.toggleConditionalReleaseTab = function (gradingType) {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && this._crTabsRef?.current) {
    if (gradingType === 'not_graded') {
      this._crTabsRef.current.setDisabledIndices([1])
      this._crTabsRef.current.setActiveIndex(0)
    } else {
      this._crTabsRef.current.setDisabledIndices([])
    }
  }
}

// @ts-expect-error
EditHeaderView.prototype.onShowErrors = function (errors) {
  if (ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED && this._crTabsRef?.current) {
    if (errors.conditional_release) {
      this._crTabsRef.current.setActiveIndex(1)
    } else {
      this._crTabsRef.current.setActiveIndex(0)
    }
  }
}

EditHeaderView.prototype.renderHeaderTitle = function () {
  return this.model.name()
    ? this.model.isQuizLTIAssignment()
      ? I18n.t('Edit Quiz')
      : I18n.t('Edit Assignment')
    : this.model.isQuizLTIAssignment()
      ? I18n.t('Create Quiz')
      : I18n.t('Create New Assignment')
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
  // @ts-expect-error
  json.showSpeedGraderLink = ENV.SHOW_SPEED_GRADER_LINK
  json.is_locked =
    ((ref = ENV.MASTER_COURSE_DATA) != null ? ref.is_master_course_child_content : void 0) &&
    // @ts-expect-error
    ENV.MASTER_COURSE_DATA.restricted_by_master_course
  return json
}

export default EditHeaderView
