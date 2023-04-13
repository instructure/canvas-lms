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

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import Backbone from '@canvas/backbone'

import {useScope as useI18nScope} from '@canvas/i18n'

import template from '../../jst/ProgressingContentMigration.handlebars'

import progressingIssuesTemplate from '../../jst/ProgressingIssues.handlebars'

import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'

import ContentMigrationIssueView from './ContentMigrationIssueView'

import ProgressBarView from './ProgressBarView'

import ProgressStatusView from './ProgressStatusView'

import SelectContentView from './SelectContentView'

import SourceLinkView from './SourceLinkView'

const I18n = useI18nScope('content_migrations')

extend(ProgressingContentMigrationView, Backbone.View)

function ProgressingContentMigrationView() {
  this.showSelectContentDialog = this.showSelectContentDialog.bind(this)
  this.render = this.render.bind(this)
  return ProgressingContentMigrationView.__super__.constructor.apply(this, arguments)
}

ProgressingContentMigrationView.prototype.template = template

ProgressingContentMigrationView.prototype.tagName = 'li'

ProgressingContentMigrationView.prototype.className = 'clearfix migrationProgressItem'

ProgressingContentMigrationView.prototype.events = {
  'click .showIssues': 'toggleIssues',
  'click .selectContentBtn': 'showSelectContentDialog',
}

ProgressingContentMigrationView.prototype.els = {
  '.showIssues': '$showIssues',
  '.migrationIssues': '$migrationIssues',
  '.changable': '$changable',
  '.progressStatus': '$progressStatus',
  '.selectContentDialog': '$selectContentDialog',
  '[data-bind=migration_issues_count]': '$issuesCount',
  '.sourceLink': '$sourceLink',
}

ProgressingContentMigrationView.prototype.initialize = function () {
  ProgressingContentMigrationView.__super__.initialize.apply(this, arguments)
  this.issuesLoaded = false
  this.progress = this.model.progressModel
  this.issues = this.model.issuesCollection
  // Continue looking for progress after content is selected
  this.model.on(
    'continue',
    (function (_this) {
      return function () {
        let ref
        if ((ref = _this.progress) != null) {
          ref.poll()
        }
        return _this.render()
      }
    })(this)
  )
  // Render the progress bar if workflow_state changes to running
  this.progress.on(
    'change:workflow_state',
    (function (_this) {
      return function (_event) {
        if (_this.progress.get('workflow_state') === 'running') {
          return _this.renderProgressBar()
        }
      }
    })(this)
  )
  // When progress is complete, update
  return this.progress.on(
    'complete',
    (function (_this) {
      return function (_event) {
        return _this.updateMigrationModel()
      }
    })(this)
  )
}

ProgressingContentMigrationView.prototype.toJSON = function () {
  const json = ProgressingContentMigrationView.__super__.toJSON.apply(this, arguments)
  json.display_name = this.displayName()
  json.created_at = this.createdAt()
  json.issuesCount = this.model.get('migration_issues_count')
  switch (this.model.get('workflow_state')) {
    case 'waiting_for_select':
      json.waiting_for_select = true
      break
    case 'completed':
    case 'failed':
      if (this.model.get('migration_issues_count') > 0) {
        json.migration_issues = true
      }
      break
    //  ¯\_(ツ)_/¯
    // was repeated in CoffeeScript
    // eslint-disable-next-line no-duplicate-case
    case 'failed':
      json.message = this.model.get('message') || this.progress.get('message')
      break
    case 'running':
      json.loading = true
  }
  return json
}

ProgressingContentMigrationView.prototype.displayName = function () {
  return this.model.get('migration_type_title') || I18n.t('content_migration', 'Content Migration')
}

ProgressingContentMigrationView.prototype.createdAt = function () {
  return this.model.get('created_at') || new Date().toISOString()
}

// Render a collection view that represents issues for this migration
// @backbone override
ProgressingContentMigrationView.prototype.render = function () {
  ProgressingContentMigrationView.__super__.render.apply(this, arguments)
  const issuesCollectionView = new PaginatedCollectionView({
    collection: this.issues,
    itemView: ContentMigrationIssueView,
    template: progressingIssuesTemplate,
    autoFetch: true,
  })
  this.$migrationIssues.html(issuesCollectionView.render().el)
  const progressStatus = new ProgressStatusView({
    model: this.model,
    el: this.$progressStatus,
  })
  progressStatus.render()
  const sourceLink = new SourceLinkView({
    model: this.model,
    el: this.$sourceLink,
  })
  sourceLink.render()
  return this
}

// Render the initial progress bar after it renders, if its in a running state
// @expects void
// @api backbone override
ProgressingContentMigrationView.prototype.afterRender = function () {
  if (this.model.get('workflow_state') === 'running') {
    if (this.progress.get('workflow_state') === 'running') {
      return this.renderProgressBar()
    }
  }
}

// Create a new progress bar with the @progress model. Replace the changable html
// with this progress information.
//
// @expects void
// @api private
ProgressingContentMigrationView.prototype.renderProgressBar = function () {
  const progressBarView = new ProgressBarView({
    model: this.progress,
    el: this.$changable,
  })
  return progressBarView.render()
}

// Does a fetch on the migration model. If successful it will re-render the progress
// view.
//
// @api private
ProgressingContentMigrationView.prototype.updateMigrationModel = function () {
  return this.model.fetch({
    error: (function (_this) {
      return function (_model, _response, _option) {
        return _this.model.set('status', 'failed')
      }
    })(this),
    success: (function (_this) {
      return function (_model, _response, _options) {
        return _this.render()
      }
    })(this),
  })
}

// When clicking on the issues button for the first time it needs to fetch all of the issues.
// This progress view keeps track of if it's fetched issues for this migration with the
// @issueLoaded class variable. If this is false more issues need to be fetched from the
// server. Also, when toggled the text should change on the button.
//
// @expects event
// @api private
ProgressingContentMigrationView.prototype.toggleIssues = function (event) {
  let dfd
  event.preventDefault()
  if (this.issuesLoaded) {
    this.$migrationIssues.toggle()
    this.$migrationIssues.attr(
      'aria-expanded',
      this.$migrationIssues.attr('aria-expanded') !== 'true'
    )
    return this.setIssuesButtonText()
  } else {
    dfd = this.fetchIssues()
    return dfd.done(
      (function (_this) {
        return function () {
          _this.issuesLoaded = true
          return _this.toggleIssues(event)
        }
      })(this)
    )
  }
}

// Fetches issues and adds a loading icon and text to the button.
// @api private
ProgressingContentMigrationView.prototype.fetchIssues = function () {
  this.model.set('issuesButtonText', I18n.t('loading', 'Loading...'))
  const dfd = this.issues.fetch()
  this.$el.disableWhileLoading(dfd)
  return dfd
}

// Determines which text to add to the issues button. This is so when you click
// the issues button it changes from Show Issues to Hide Issues as well as
// handles a case where loading text is still there an needs to be removed.
//
// @api private
ProgressingContentMigrationView.prototype.setIssuesButtonText = function () {
  if (!this.hiddenIssues) {
    this.$issuesCount.hide()
    this.model.set('issuesButtonText', I18n.t('hide_issues', 'Hide Issues'))
    this.$showIssues.attr('aria-label', I18n.t('hide_issues', 'Hide Issues'))
    this.$showIssues.attr('title', I18n.t('hide_issues', 'Hide Issues'))
    if ($(document.activeElement).is(this.$showIssues)) {
      this.$showIssues.blur().focus()
    }
    return (this.hiddenIssues = true)
  } else {
    this.$issuesCount.show()
    this.$showIssues.attr('aria-label', I18n.t('show_issues', 'Show Issues'))
    this.$showIssues.attr('title', I18n.t('show_issues', 'Show Issues'))
    if ($(document.activeElement).is(this.$showIssues)) {
      this.$showIssues.blur().focus()
    }
    this.model.set('issuesButtonText', I18n.t('issues', 'issues'))
    return (this.hiddenIssues = false)
  }
}

// Render's a new SelectContentDialog which allows someone to select the migration
// content to be migrated.
// @api private
ProgressingContentMigrationView.prototype.showSelectContentDialog = function (event) {
  event.preventDefault()
  this.selectContentView ||
    (this.selectContentView = new SelectContentView({
      model: this.model,
      el: this.$selectContentDialog,
      title: I18n.t('Select Content'),
      width: 900,
      height: 700,
    }))
  return this.selectContentView.open()
}

export default ProgressingContentMigrationView
