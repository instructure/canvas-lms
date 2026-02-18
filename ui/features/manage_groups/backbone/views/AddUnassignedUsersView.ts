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
import CollectionView from '@canvas/backbone-collection-view'
import template from '../../jst/addUnassignedUsers.handlebars'
import itemTemplate from '../../jst/addUnassignedUser.handlebars'

export default class AddUnassignedUsersView extends CollectionView {
  // @ts-expect-error - Legacy Backbone typing
  initialize(options) {
    return super.initialize({
      ...options,
      itemView: View.extend({tagName: 'li'}),
      itemViewOptions: {
        template: itemTemplate,
      },
    })
  }

  attach() {
    this.collection.on('add remove change reset', this.render, this)
    this.collection.on('setParam deleteParam', this.checkParam, this)
  }

  // @ts-expect-error - Legacy Backbone typing
  checkParam(param, value) {
    // @ts-expect-error - Backbone View property
    if (this.lastRequest != null) {
      // @ts-expect-error - Backbone View property
      this.lastRequest.abort()
    }
    this.collection.termError = value === false
    if (value) {
      // @ts-expect-error - Backbone View property
      return (this.lastRequest = this.collection.fetch())
    } else {
      return this.render()
    }
  }

  // @ts-expect-error - Legacy Backbone typing
  render() {
    // @ts-expect-error - Legacy Backbone typing
    super.render()

    // If a parent view is provided then retain focus on it
    // @ts-expect-error - Backbone View property
    if (this.options.parentView && typeof this.options.parentView.refocusSearch === 'function') {
      setTimeout(() => {
        // @ts-expect-error - Backbone View property
        this.options.parentView.refocusSearch()
      }, 10)
    }

    return this
  }

  toJSON() {
    return {
      users: this.collection.toJSON(),
      term:
        this.collection.options.params != null
          ? this.collection.options.params.search_term
          : undefined,
      termError: this.collection.termError,
    }
  }
}
AddUnassignedUsersView.prototype.template = template
