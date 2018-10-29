//
// Copyright (C) 2012 - present Instructure, Inc.
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
//

import $ from 'jquery'
import Backbone from 'Backbone'
import Outcome from '../../models/Outcome'
import OutcomeGroup from '../../models/OutcomeGroup'

// Manage the toolbar buttons.
export default class ToolbarView extends Backbone.View {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this.goBack = this.goBack.bind(this)
    this.addOutcome = this.addOutcome.bind(this)
    this.addGroup = this.addGroup.bind(this)
    this.findDialog = this.findDialog.bind(this)
    this.importOutcomes = this.importOutcomes.bind(this)
    this.disable = this.disable.bind(this)
    this.enable = this.enable.bind(this)
    this.resetBackButton = this.resetBackButton.bind(this)
    super(...args)
  }

  static initClass() {
    this.prototype.events = {
      'click .go_back': 'goBack',
      'click .add_outcome_link': 'addOutcome',
      'click .add_outcome_group': 'addGroup',
      'click .import_outcomes': 'importOutcomes',
      'click .find_outcome': 'findDialog'
    }
  }

  goBack(e) {
    e.preventDefault()
    this.trigger('goBack')
    $('.add_outcome_link').focus()
  }

  addOutcome(e) {
    e.preventDefault()
    const model = new Outcome({title: ''})
    return this.trigger('add', model)
  }

  addGroup(e) {
    e.preventDefault()
    const model = new OutcomeGroup({title: ''})
    return this.trigger('add', model)
  }

  findDialog(e) {
    e.preventDefault()
    return this.trigger('find')
  }

  importOutcomes(e) {
    e.preventDefault()
    return this.trigger('import')
  }

  disable() {
    return this.$el.find('button').each((i, button) => {
      $(button).attr('disabled', 'disabled')
      $(button).attr('aria-disabled', 'true')
    })
  }

  enable() {
    return this.$el.find('button').each((i, button) => {
      $(button).removeAttr('disabled')
      $(button).removeAttr('aria-disabled')
    })
  }

  resetBackButton(model, directories) {
    if (!ENV.PERMISSIONS.manage_outcomes) return
    if (model || directories.length > 1) {
      return this.$('.go_back').show(200)
    } else {
      return this.$('.go_back').hide(200)
    }
  }
}
ToolbarView.initClass()
