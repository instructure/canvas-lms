//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {View} from '@canvas/backbone'
import {debounce} from 'es-toolkit/compat'
import GroupCategoryDetailView from './GroupCategoryDetailView'
import GroupsView from './GroupsView'
import UnassignedUsersView from './UnassignedUsersView'
import AddUnassignedMenu from './AddUnassignedMenu'
import template from '../../jst/groupCategory.handlebars'
import '@canvas/rails-flash-notifications'
import '@canvas/jquery/jquery.disableWhileLoading'
import React from 'react'
import ReactDOM from 'react-dom'
import GroupCategoryProgress from '../../react/GroupCategoryProgress'

const I18n = createI18nScope('groups')

let _previousSearchTerm = ''
export default class GroupCategoryView extends View {
  static initClass() {
    // @ts-expect-error - Backbone View property
    this.prototype.template = template

    // @ts-expect-error - Backbone View property
    this.child('groupCategoryDetailView', '[data-view=groupCategoryDetail]')
    // @ts-expect-error - Backbone View property
    this.child('unassignedUsersView', '[data-view=unassignedUsers]')
    // @ts-expect-error - Backbone View property
    this.child('groupsView', '[data-view=groups]')

    // @ts-expect-error - Backbone View property
    this.prototype.els = {
      '.filterable': '$filter',
      '.filterable-unassigned-users': '$filterUnassignedUsers',
      '.unassigned-users-heading': '$unassignedUsersHeading',
      '.groups-with-count': '$groupsHeading',
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  initialize(options) {
    let progress
    // @ts-expect-error - Backbone View property
    this.groups = this.model.groups()
    // TODO: move all of these to GroupCategoriesView#createItemView
    if (options.groupCategoryDetailView == null) {
      // @ts-expect-error - Legacy Backbone typing
      options.groupCategoryDetailView = new GroupCategoryDetailView({
        parentView: this,
        // @ts-expect-error - Backbone View property
        model: this.model,
        // @ts-expect-error - Backbone View property
        collection: this.groups,
      })
    }
    if (options.groupsView == null) options.groupsView = this.groupsView(options)
    if (options.unassignedUsersView == null)
      options.unassignedUsersView = this.unassignedUsersView(options)
    // @ts-expect-error - Backbone View property
    if ((progress = this.model.get('progress'))) {
      // @ts-expect-error - Backbone View property
      this.model.progressModel.set(progress)
    }
    return super.initialize(...arguments)
  }

  // @ts-expect-error - Legacy Backbone typing
  groupsView(_options) {
    let addUnassignedMenu = null
    if (ENV.IS_LARGE_ROSTER) {
      // @ts-expect-error - Backbone View property
      const users = this.model.unassignedUsers()
      // @ts-expect-error - Legacy Backbone typing
      addUnassignedMenu = new AddUnassignedMenu({collection: users})
    }
    return new GroupsView({
      // @ts-expect-error - Backbone View property
      collection: this.groups,
      addUnassignedMenu,
    })
  }

  // @ts-expect-error - Legacy Backbone typing
  unassignedUsersView(_options) {
    if (ENV.IS_LARGE_ROSTER) return false
    return new UnassignedUsersView({
      // @ts-expect-error - Backbone View property
      category: this.model,
      // @ts-expect-error - Backbone View property
      collection: this.model.unassignedUsers(),
      // @ts-expect-error - Backbone View property
      groupsCollection: this.groups,
    })
  }

  // @ts-expect-error - Legacy Backbone typing
  filterChange(event) {
    const search_term = event.target.value
    if (search_term === _previousSearchTerm) return // Don't rerender if nothing has changed

    // @ts-expect-error - Backbone View property
    this.options.unassignedUsersView.setFilter(search_term)

    if (!(search_term.length >= 3)) {
      // @ts-expect-error - Backbone View property
      this._setUnassignedHeading(this.originalCount)
    }
    return (_previousSearchTerm = search_term)
  }

  attach() {
    // @ts-expect-error - Backbone View property
    this.model.on('destroy', this.remove, this)
    // @ts-expect-error - Backbone View property
    this.model.on('change', () => this.groupsView.updateDetails())

    // @ts-expect-error - Backbone View property
    this.model.on('change:unassigned_users_count', this.setUnassignedHeading, this)
    // @ts-expect-error - Backbone View property
    this.groups.on('add remove reset', this.setGroupsHeading, this)

    // @ts-expect-error - Backbone View property
    this.model.progressModel.on('change:url', () => {
      // @ts-expect-error - Backbone View property
      return this.model.progressModel.set({completion: 0})
    })
    // @ts-expect-error - Backbone View property
    this.model.progressModel.on('change', this.render, this)
    // @ts-expect-error - Backbone View property
    return this.model.on('progressResolved', () => {
      // @ts-expect-error - Backbone View property
      const status = this.model.progressModel.get('workflow_state')
      // @ts-expect-error - Backbone View property
      const progressMessage = this.model.progressModel.get('message')
      let message
      try {
        message = progressMessage ? JSON.parse(progressMessage) : null
      } catch (_err) {
        message = null
      }

      if (message && message.type === 'import_groups') {
        if (status === 'completed') {
          if (message.groups > 0) {
            $.flashMessage(
              I18n.t('Your %{groups} groups and %{users} students were successfully uploaded', {
                groups: message.groups,
                users: message.users,
              }),
            )
          } else {
            $.flashError(I18n.t('No groups were found in the uploaded file.'))
          }
        }
        if (status === 'failed') {
          $.flashError(I18n.t('Your groups could not be uploaded. Check formatting and try again.'))
        }
      }

      // @ts-expect-error - Backbone View property
      return this.model.fetch({
        success: () => {
          // @ts-expect-error - Backbone View property
          this.model.groups().fetch()
          // @ts-expect-error - Backbone View property
          this.model.unassignedUsers().fetch()
          // @ts-expect-error - Backbone View property
          return this.render()
        },
      })
    })
  }

  cacheEls() {
    super.cacheEls(...arguments)

    // @ts-expect-error - Backbone View property
    if (!this.attachedFilter) {
      // @ts-expect-error - Backbone View property
      this.$filterUnassignedUsers.on('keyup', debounce(this.filterChange.bind(this), 300))
      // @ts-expect-error - Backbone View property
      this.attachedFilter = true
    }

    // need to be set before their afterRender's run (i.e. before this
    // view's afterRender)
    // @ts-expect-error - Backbone View property
    this.groupsView.$externalFilter = this.$filter
    if (this.unassignedUsersView) {
      // @ts-expect-error - Backbone View property
      this.unassignedUsersView.$externalFilter = this.$filterUnassignedUsers
    }
  }

  afterRender() {
    this.renderProgress()
    this.setUnassignedHeading()
    return this.setGroupsHeading()
  }

  renderProgress() {
    const container = document.getElementById('group-category-progress')
    if (container != null) {
      ReactDOM.render(
        // @ts-expect-error - Backbone View property
        <GroupCategoryProgress progressPercent={this.model.progressModel.attributes.completion} />,
        container,
      )
    }
  }

  setUnassignedHeading() {
    let left
    // @ts-expect-error - Backbone View property
    const count = (left = this.model.unassignedUsersCount()) != null ? left : 0
    // @ts-expect-error - Backbone View property
    this.originalCount = this.originalCount || count
    return this._setUnassignedHeading(count)
  }

  // @ts-expect-error - Legacy Backbone typing
  _setUnassignedHeading(count) {
    if (this.unassignedUsersView) {
      // @ts-expect-error - Backbone View property
      this.unassignedUsersView.render()
    }
    // @ts-expect-error - Legacy Backbone typing
    return this.$unassignedUsersHeading.text(
      // @ts-expect-error - Backbone View property
      this.model.get('allows_multiple_memberships')
        ? I18n.t('everyone', 'Everyone (%{count})', {count})
        : // @ts-expect-error - Backbone View property
          ENV.group_user_type === 'student'
          ? I18n.t('unassigned_students', 'Unassigned Students (%{count})', {count})
          : I18n.t('unassigned_users', 'Unassigned Users (%{count})', {count}),
    )
  }

  setGroupsHeading() {
    // @ts-expect-error - Backbone View property
    const count = this.model.groupsCount()
    // @ts-expect-error - Legacy Backbone typing
    return this.$groupsHeading.text(I18n.t('groups_count', 'Groups (%{count})', {count}))
  }

  toJSON() {
    // @ts-expect-error - Backbone View property
    const json = this.model.present()
    json.ENV = ENV
    json.groupsAreSearchable = ENV.IS_LARGE_ROSTER && !json.randomlyAssignStudentsInProgress
    return json
  }
}
GroupCategoryView.initClass()
