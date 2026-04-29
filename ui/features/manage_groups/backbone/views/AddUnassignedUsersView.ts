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

// @ts-expect-error TS7 migration
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
    // @ts-expect-error TS7 migration
    this.collection.on('add remove change reset', this.render, this)
    // @ts-expect-error TS7 migration
    this.collection.on('setParam deleteParam', this.checkParam, this)
  }

  // @ts-expect-error - Legacy Backbone typing
  checkParam(param, value) {
    // @ts-expect-error - Backbone View property
    if (this.lastRequest != null) {
      // @ts-expect-error - Backbone View property
      this.lastRequest.abort()
    }
    // @ts-expect-error TS7 migration
    this.collection.termError = value === false
    if (value) {
      // @ts-expect-error - Backbone View property
      return (this.lastRequest = this.collection.fetch())
    } else {
      return this.render()
    }
  }

  render() {
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
      // @ts-expect-error TS7 migration
      users: this.collection.toJSON(),
      term:
        // @ts-expect-error TS7 migration
        this.collection.options.params != null
          ? // @ts-expect-error TS7 migration
            this.collection.options.params.search_term
          : undefined,
      // @ts-expect-error TS7 migration
      termError: this.collection.termError,
    }
  }
}
// @ts-expect-error TS7 migration
AddUnassignedUsersView.prototype.template = template
