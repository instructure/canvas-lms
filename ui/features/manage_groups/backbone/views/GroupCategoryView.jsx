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

import {useScope as useI18nScope} from '@canvas/i18n'

import {View} from '@canvas/backbone'
import {debounce} from 'lodash'
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

const I18n = useI18nScope('groups')

let _previousSearchTerm = ''
export default class GroupCategoryView extends View {
  static initClass() {
    this.prototype.template = template

    this.child('groupCategoryDetailView', '[data-view=groupCategoryDetail]')
    this.child('unassignedUsersView', '[data-view=unassignedUsers]')
    this.child('groupsView', '[data-view=groups]')

    this.prototype.els = {
      '.filterable': '$filter',
      '.filterable-unassigned-users': '$filterUnassignedUsers',
      '.unassigned-users-heading': '$unassignedUsersHeading',
      '.groups-with-count': '$groupsHeading',
    }
  }

  initialize(options) {
    let progress
    this.groups = this.model.groups()
    // TODO: move all of these to GroupCategoriesView#createItemView
    if (options.groupCategoryDetailView == null) {
      options.groupCategoryDetailView = new GroupCategoryDetailView({
        parentView: this,
        model: this.model,
        collection: this.groups,
      })
    }
    if (options.groupsView == null) options.groupsView = this.groupsView(options)
    if (options.unassignedUsersView == null)
      options.unassignedUsersView = this.unassignedUsersView(options)
    if ((progress = this.model.get('progress'))) {
      this.model.progressModel.set(progress)
    }
    return super.initialize(...arguments)
  }

  groupsView(_options) {
    let addUnassignedMenu = null
    if (ENV.IS_LARGE_ROSTER) {
      const users = this.model.unassignedUsers()
      addUnassignedMenu = new AddUnassignedMenu({collection: users})
    }
    return new GroupsView({
      collection: this.groups,
      addUnassignedMenu,
    })
  }

  unassignedUsersView(_options) {
    if (ENV.IS_LARGE_ROSTER) return false
    return new UnassignedUsersView({
      category: this.model,
      collection: this.model.unassignedUsers(),
      groupsCollection: this.groups,
    })
  }

  filterChange(event) {
    const search_term = event.target.value
    if (search_term === _previousSearchTerm) return // Don't rerender if nothing has changed

    this.options.unassignedUsersView.setFilter(search_term)

    if (!(search_term.length >= 3)) {
      this._setUnassignedHeading(this.originalCount)
    }
    return (_previousSearchTerm = search_term)
  }

  attach() {
    this.model.on('destroy', this.remove, this)
    this.model.on('change', () => this.groupsView.updateDetails())

    this.model.on('change:unassigned_users_count', this.setUnassignedHeading, this)
    this.groups.on('add remove reset', this.setGroupsHeading, this)

    this.model.progressModel.on('change:url', () => {
      return this.model.progressModel.set({completion: 0})
    })
    this.model.progressModel.on('change', this.render, this)
    return this.model.on('progressResolved', () => {
      return this.model.fetch({
        success: () => {
          this.model.groups().fetch()
          this.model.unassignedUsers().fetch()
          return this.render()
        },
      })
    })
  }

  cacheEls() {
    super.cacheEls(...arguments)

    if (!this.attachedFilter) {
      this.$filterUnassignedUsers.on('keyup', debounce(this.filterChange.bind(this), 300))
      this.attachedFilter = true
    }

    // need to be set before their afterRender's run (i.e. before this
    // view's afterRender)
    this.groupsView.$externalFilter = this.$filter
    if (this.unassignedUsersView) {
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
        <GroupCategoryProgress progressPercent={this.model.progressModel.attributes.completion} />,
        container
      )
    }
  }

  setUnassignedHeading() {
    let left
    const count = (left = this.model.unassignedUsersCount()) != null ? left : 0
    this.originalCount = this.originalCount || count
    return this._setUnassignedHeading(count)
  }

  _setUnassignedHeading(count) {
    if (this.unassignedUsersView) {
      this.unassignedUsersView.render()
    }
    return this.$unassignedUsersHeading.text(
      this.model.get('allows_multiple_memberships')
        ? I18n.t('everyone', 'Everyone (%{count})', {count})
        : ENV.group_user_type === 'student'
        ? I18n.t('unassigned_students', 'Unassigned Students (%{count})', {count})
        : I18n.t('unassigned_users', 'Unassigned Users (%{count})', {count})
    )
  }

  setGroupsHeading() {
    const count = this.model.groupsCount()
    return this.$groupsHeading.text(I18n.t('groups_count', 'Groups (%{count})', {count}))
  }

  toJSON() {
    const json = this.model.present()
    json.ENV = ENV
    json.groupsAreSearchable = ENV.IS_LARGE_ROSTER && !json.randomlyAssignStudentsInProgress
    return json
  }
}
GroupCategoryView.initClass()
