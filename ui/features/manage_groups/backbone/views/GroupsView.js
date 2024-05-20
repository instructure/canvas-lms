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

import {throttle} from 'lodash'
import PaginatedCollectionView from '@canvas/pagination/backbone/views/PaginatedCollectionView'
import GroupView from './GroupView'
import GroupUsersView from './GroupUsersView'
import GroupDetailView from './GroupDetailView'
import Filterable from '../mixins/Filterable'
import template from '../../jst/groups.handlebars'

export default class GroupsView extends PaginatedCollectionView {
  static initClass() {
    this.mixin(Filterable)

    this.prototype.template = template

    this.prototype.els = {
      // override Filterable's els, since our filter is in another view
      ...PaginatedCollectionView.prototype.els,
      '.no-results': '$noResults',
    }

    this.prototype.events = {
      ...PaginatedCollectionView.prototype.events,
      scroll: 'closeMenus',
      dragstart: 'closeMenus',
    }

    this.prototype.closeMenus = throttle(function () {
      return this.collection.models.map(model => model.itemView.closeMenus())
    }, 50)
  }

  attach() {
    return this.collection.on('change', this.reorder)
  }

  afterRender() {
    this.$filter = this.$externalFilter
    return super.afterRender(...arguments)
  }

  initialize() {
    super.initialize(...arguments)
    if (this.collection.loadAll) return this.detachScroll()
  }

  createItemView(group) {
    const groupUsersView = new GroupUsersView({
      model: group,
      collection: group.users(),
      itemViewOptions: {
        canEditGroupAssignment: !group.isLocked(),
        markInactiveStudents: __guard__(group.users(), x => x.markInactiveStudents),
      },
    })
    const groupDetailView = new GroupDetailView({model: group, users: group.users()})
    const groupView = new GroupView({
      model: group,
      groupUsersView,
      groupDetailView,
      addUnassignedMenu: this.options.addUnassignedMenu,
    })
    return (group.itemView = groupView)
  }

  updateDetails() {
    return this.collection.models.map(model => model.itemView.updateFullState())
  }
}
GroupsView.initClass()

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined
}
