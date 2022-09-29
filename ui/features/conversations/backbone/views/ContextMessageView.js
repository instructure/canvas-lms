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

import {View} from '@canvas/backbone'
import template from '../../jst/contextMessage.handlebars'

export default class ContextMessageView extends View {
  static initClass() {
    this.prototype.tagName = 'li'

    this.prototype.template = template

    this.prototype.events = {
      'click a.context-more': 'toggle',
      'click .delete-btn': 'triggerRemoval',
    }
  }

  initialize() {
    super.initialize(...arguments)
    this.model.set({isCondensable: this.model.get('body').length > 180})
    return this.model.set({isCondensed: true})
  }

  toJSON() {
    const json = super.toJSON(...arguments)
    if (json.isCondensable && json.isCondensed) {
      json.body = json.body.substr(0, 180).replace(/\W\w*$/, '')
    }
    return json
  }

  toggle(e) {
    e.preventDefault()
    this.model.set({isCondensed: !this.model.get('isCondensed')})
    this.render()
    return this.$('a').focus()
  }

  triggerRemoval() {
    return this.model.trigger('removeView', {view: this})
  }
}
ContextMessageView.initClass()
