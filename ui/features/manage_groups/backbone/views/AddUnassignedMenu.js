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

import PopoverMenuView from './PopoverMenuView'
import AddUnassignedUsersView from './AddUnassignedUsersView'
import InputFilterView from '@canvas/backbone-input-filter-view'
import template from '../../jst/addUnassignedMenu.handlebars'
import $ from 'jquery'
import '../../jquery/outerclick'

export default class AddUnassignedMenu extends PopoverMenuView {
  static initClass() {
    this.child('usersView', '[data-view=users]')
    this.child('inputFilterView', '[data-view=inputFilter]')

    this.prototype.className = 'add-unassigned-menu ui-tooltip popover right content-top horizontal'

    this.prototype.template = template

    this.prototype.events = {
      ...PopoverMenuView.prototype.events,
      'click .assign-user-to-group': 'setGroup',
    }
  }

  initialize(options) {
    this.collection.setParam('per_page', 10)
    if (options.usersView == null)
      options.usersView = new AddUnassignedUsersView({collection: this.collection})
    if (options.inputFilterView == null)
      options.inputFilterView = new InputFilterView({
        collection: this.collection,
        setParamOnInvalid: true,
      })
    this.my = 'right-8 top-47'
    this.at = 'left center'
    return super.initialize(...arguments)
  }

  setGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    const user = this.collection.getUser($target.data('user-id'))
    user.save({group: this.group})
    return this.hide()
  }

  showBy(_$target, _focus = false) {
    this.collection.reset()
    this.collection.deleteParam('search_term')
    return super.showBy(...arguments)
  }

  attach() {
    return this.render()
  }

  toJSON() {
    return {
      users: this.collection.toJSON(),
      ENV,
    }
  }

  focus() {
    return this.inputFilterView.el.focus()
  }

  setWidth() {
    return this.$el.width('auto')
  }
}
AddUnassignedMenu.initClass()
