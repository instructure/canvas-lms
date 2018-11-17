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

import {View} from 'Backbone'
import _ from 'underscore'
import 'jqueryui/button'

// #
// requires a MaterializedDiscussionTopic model
export default class DiscussionToolbarView extends View {
  constructor(...args) {
    super(...args)
    this.clearInputs = this.clearInputs.bind(this)
  }

  static initClass() {
    this.prototype.els = {
      '#discussion-search': '$searchInput',
      '#onlyUnread': '$unread',
      '#showDeleted': '$deleted',
      '.disableWhileFiltering': '$disableWhileFiltering'
    }

    this.prototype.events = {
      'keyup #discussion-search': 'filterBySearch',
      'change #onlyUnread': 'toggleUnread',
      'change #showDeleted': 'toggleDeleted',
      'click #collapseAll': 'collapseAll',
      'click #expandAll': 'expandAll'
    }

    this.prototype.filter = this.prototype.afterRender

    this.prototype.filterBySearch = _.debounce(function() {
      let value = this.$searchInput.val()
      if (value === '') {
        value = null
      }
      this.model.set('query', value)
      return this.maybeDisableFields()
    }, 250)
  }

  initialize() {
    super.initialize(...arguments)
    return this.model.on('change', () => this.clearInputs())
  }

  afterRender() {
    this.$unread.button()
    return this.$deleted.button()
  }

  clearInputs() {
    if (this.model.hasFilter()) return
    this.$searchInput.val('')
    this.$unread.prop('checked', false)
    this.$unread.button('refresh')
    return this.maybeDisableFields()
  }

  toggleUnread() {
    // setTimeout so the ui can update the button before the rest
    // do expensive stuff

    return setTimeout(() => {
      this.model.set('unread', this.$unread.prop('checked'))
      return this.maybeDisableFields()
    }, 50)
  }

  toggleDeleted() {
    return this.trigger('showDeleted', this.$deleted.prop('checked'))
  }

  collapseAll() {
    this.model.set('collapsed', true)
    return this.trigger('collapseAll')
  }

  expandAll() {
    this.model.set('collapsed', false)
    return this.trigger('expandAll')
  }

  maybeDisableFields() {
    return this.$disableWhileFiltering.attr('disabled', this.model.hasFilter())
  }
}
DiscussionToolbarView.initClass()
