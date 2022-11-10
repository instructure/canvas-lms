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

import Backbone from '@canvas/backbone'
import template from '../../jst/user.handlebars'

class UserView extends Backbone.View {
  constructor(...args) {
    super(...args)
    this.click = this.click.bind(this)
    this.changeSelection = this.changeSelection.bind(this)
  }

  attach() {
    return this.model.collection.on('selectedModelChange', this.changeSelection)
  }

  click(e) {
    e.preventDefault()
    return this.model.collection.trigger('selectedModelChange', this.model)
  }

  changeSelection(u) {
    if (u === this.model) return setTimeout(() => this.$el.addClass('selected'), 0)
  }
}

UserView.prototype.tagName = 'tr'
UserView.prototype.className = 'rosterUser al-hover-container'
UserView.prototype.template = template
UserView.prototype.events = {click: 'click'}

export default UserView
