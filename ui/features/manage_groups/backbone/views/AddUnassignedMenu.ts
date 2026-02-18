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
    // @ts-expect-error - Backbone View property
    this.child('usersView', '[data-view=users]')
    // @ts-expect-error - Backbone View property
    this.child('inputFilterView', '[data-view=inputFilter]')

    // @ts-expect-error - Backbone View property
    this.prototype.className = 'add-unassigned-menu ui-tooltip popover right content-top horizontal'

    // @ts-expect-error - Backbone View property
    this.prototype.template = template

    // @ts-expect-error - Backbone View property
    this.prototype.events = {
      // @ts-expect-error - Backbone View property
      ...PopoverMenuView.prototype.events,
      'click .assign-user-to-group': 'setGroup',
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  initialize(options) {
    // @ts-expect-error - Backbone View property
    this.collection.setParam('per_page', 10)

    if (options.usersView == null) {
      options.usersView = new AddUnassignedUsersView({
        // @ts-expect-error - Backbone View property
        collection: this.collection,
        parentView: this,
      })
    }

    if (options.inputFilterView == null) {
      options.inputFilterView = new InputFilterView({
        // @ts-expect-error - Backbone View property
        collection: this.collection,
        setParamOnInvalid: true,
      })
    }

    // @ts-expect-error - Backbone View property
    this.my = 'right-8 top-47'
    // @ts-expect-error - Backbone View property
    this.at = 'left center'

    // @ts-expect-error - Backbone View property
    return super.initialize(...arguments)
  }

  refocusSearch() {
    // Prevent hide triggered by focusout for a short period.
    // @ts-expect-error - Backbone View property
    this.hideDisabled = true
    // @ts-expect-error - Backbone View property
    this.inputFilterView.el.focus()
    setTimeout(() => {
      // @ts-expect-error - Backbone View property
      this.hideDisabled = false
    }, 200)
  }

  // @ts-expect-error - Legacy Backbone typing
  setGroup(e) {
    e.preventDefault()
    e.stopPropagation()
    const $target = $(e.currentTarget)
    // @ts-expect-error - Backbone View property
    const user = this.collection.getUser($target.data('user-id'))
    // @ts-expect-error - Backbone View property
    user.save({group: this.group})
    return this.hide()
  }

  // @ts-expect-error - Legacy Backbone typing
  showBy(_$target, _focus = false) {
    // @ts-expect-error - Backbone View property
    this.collection.reset()
    // @ts-expect-error - Backbone View property
    this.collection.deleteParam('search_term')
    // @ts-expect-error - Legacy Backbone typing
    return super.showBy(...arguments)
  }

  attach() {
    // @ts-expect-error - Backbone View property
    return this.render()
  }

  toJSON() {
    return {
      // @ts-expect-error - Backbone View property
      users: this.collection.toJSON(),
      ENV,
    }
  }

  focus() {
    // @ts-expect-error - Backbone View property
    return this.inputFilterView.el.focus()
  }

  setWidth() {
    // @ts-expect-error - Backbone View property
    return this.$el.width('auto')
  }
}
AddUnassignedMenu.initClass()
