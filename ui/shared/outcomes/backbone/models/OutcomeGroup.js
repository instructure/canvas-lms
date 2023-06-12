/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* eslint-disable no-void */

import $ from 'jquery'
import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'

import OutcomeCollection from '../collections/OutcomeCollection'

import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'

extend(OutcomeGroup, Backbone.Model)

function OutcomeGroup() {
  return OutcomeGroup.__super__.constructor.apply(this, arguments)
}

OutcomeGroup.prototype.initialize = function (_options) {
  this.setUpOutcomesAndGroupsIfNeeded()
  return OutcomeGroup.__super__.initialize.apply(this, arguments)
}

OutcomeGroup.prototype.name = function () {
  return this.get('title')
}

OutcomeGroup.prototype.isAbbreviated = function () {
  return !this.has('description')
}

OutcomeGroup.prototype.setUrlTo = function (action) {
  return (this.url = function () {
    switch (action) {
      case 'add':
      case 'move':
        return this.get('parent_outcome_group').subgroups_url
      case 'edit':
      case 'delete':
        return this.get('url')
    }
  }.call(this))
}

OutcomeGroup.prototype.setUpOutcomesAndGroupsIfNeeded = function () {
  if (!this.outcomeGroups) {
    this.outcomeGroups = new OutcomeGroupCollection([], {
      parentGroup: this,
    })
  }
  if (!this.outcomes) {
    return (this.outcomes = new OutcomeCollection([]))
  }
}

OutcomeGroup.prototype.getSubtrees = function () {
  return this.outcomeGroups
}

OutcomeGroup.prototype.getItems = function () {
  return this.outcomes
}

OutcomeGroup.prototype.expand = function (force, options) {
  if (force == null) {
    force = false
  }
  if (options == null) {
    options = {}
  }
  this.isExpanded = true
  this.trigger('expanded')
  if (this.expandDfd || force) {
    return $.when()
  }
  this.isExpanding = true
  this.trigger('beginexpanding')
  this.expandDfd = $.Deferred().done(
    (function (_this) {
      return function () {
        _this.isExpanding = false
        return _this.trigger('endexpanding')
      }
    })(this)
  )
  let ref, ref1
  let outcomesDfd
  let outcomeGroupDfd
  if (this.get('outcomeGroups_count') !== 0) {
    outcomeGroupDfd = (ref = this.outcomeGroups) != null ? ref.fetch() : void 0
  }
  if (this.get('outcomes_count') !== 0 && !options.onlyShowSubtrees) {
    outcomesDfd = (ref1 = this.outcomes) != null ? ref1.fetch() : void 0
  }
  return $.when(outcomeGroupDfd, outcomesDfd).done(this.expandDfd.resolve)
}

OutcomeGroup.prototype.collapse = function () {
  this.isExpanded = false
  return this.trigger('collapsed')
}

OutcomeGroup.prototype.toggle = function (options) {
  if (this.isExpanded) {
    return this.collapse()
  } else {
    return this.expand(false, options)
  }
}

extend(OutcomeGroupCollection, PaginatedCollection)

function OutcomeGroupCollection() {
  return OutcomeGroupCollection.__super__.constructor.apply(this, arguments)
}

OutcomeGroupCollection.optionProperty('parentGroup')

OutcomeGroupCollection.prototype.model = OutcomeGroup

OutcomeGroupCollection.prototype.url = function () {
  return this.parentGroup.attributes.subgroups_url
}

export default OutcomeGroup
