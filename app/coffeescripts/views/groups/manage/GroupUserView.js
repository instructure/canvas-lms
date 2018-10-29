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

import {View} from 'Backbone'
import template from 'jst/groups/manage/groupUser'

export default class GroupUserView extends View {
  static initClass() {
    this.optionProperty('canAssignToGroup')
    this.optionProperty('canEditGroupAssignment')

    this.prototype.tagName = 'li'

    this.prototype.className = 'group-user'

    this.prototype.template = template

    this.prototype.els = {'.al-trigger': '$userActions'}
  }

  closeMenu() {
    const menu = this.$userActions.data('kyleMenu')
    if (menu) menu.$menu.popup('close')
  }

  attach() {
    return this.model.on('change', this.render, this)
  }

  afterRender() {
    return this.$el.data('model', this.model)
  }

  highlight() {
    this.$el.addClass('group-user-highlight')
    return setTimeout(() => this.$el.removeClass('group-user-highlight'), 1000)
  }

  toJSON() {
    const group = this.model.get('group')
    const result = Object.assign(
      {groupId: group && group.id},
      this,
      super.toJSON(...arguments)
    )
    result.shouldMarkInactive =
      this.options.markInactiveStudents && this.model.attributes.is_inactive
    result.isLeader = this.isLeader()
    return result
  }

  isLeader() {
    // transpiled from: @model.get('group')?.get?('leader')?.id == @model.get('id')
    let ref, ref1;
    return ((ref = this.model.get('group')) != null ? typeof ref.get === "function" ? (ref1 = ref.get('leader')) != null ? ref1.id : void 0 : void 0 : void 0) === this.model.get('id');
  }
}
GroupUserView.initClass()
