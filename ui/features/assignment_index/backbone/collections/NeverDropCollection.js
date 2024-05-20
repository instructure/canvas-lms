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

import {extend} from '@canvas/backbone/utils'
import {compact} from 'lodash'
import Backbone from '@canvas/backbone'
import UniqueDropdownCollection from './UniqueDropdownCollection'

extend(NeverDropCollection, UniqueDropdownCollection)

function NeverDropCollection() {
  return NeverDropCollection.__super__.constructor.apply(this, arguments)
}

NeverDropCollection.prototype.initialize = function (records, options) {
  // need to pass in the assignments list
  // and the assignment group id
  let ref1
  if (options == null) {
    options = {}
  }
  const ref = options || {}
  this.assignments = ref.assignments
  this.ag_id = ref.ag_id
  options.possibleValues =
    ((ref1 = this.assignments) != null
      ? ref1.map(function (a) {
          return a.id
        })
      : void 0) || []
  options.propertyName = 'chosen_id'
  options.model = Backbone.Model
  return NeverDropCollection.__super__.initialize.apply(this, arguments)
}

NeverDropCollection.prototype.updateAssignments = function (assignments) {
  return (this.assignments = assignments)
}

NeverDropCollection.prototype.updateAssignmentGroupId = function (id) {
  return (this.ag_id = id)
}

// pass the chosen_id to include in the output
// used to return a list of models to build the select
// this will retain the assignment order when rendering
// the <options>
NeverDropCollection.prototype.toAssignments = function (include_id) {
  const models = this.assignments.map(
    (function (_this) {
      return function (m) {
        const available = _this.availableValues.find(function (am) {
          return m.id === am.id
        })
        if (available || m.id === include_id) {
          return m.toView()
        }
        return undefined
      }
    })(this)
  )
  // compact results because we're mapping assignments :(
  return compact(models)
}

NeverDropCollection.prototype.parse = function (resp, _opts) {
  const coll = []
  let assignment, i
  for (let idx = (i = 0), len = resp.length; i < len; idx = ++i) {
    const drop = resp[idx]
    if ((assignment = this.findAssignment(drop))) {
      const model_obj = {
        id: resp.id || idx,
        chosen: assignment.name(),
        chosen_id: assignment.get('id'),
        label_id: this.ag_id || 'new',
      }
      coll.push(model_obj)
    }
  }
  return coll
}

NeverDropCollection.prototype.findAssignment = function (id) {
  return this.assignments.find(function (a) {
    return a.id === id
  })
}

// override default UniqueCollection logic for finding the next item
// returns a model from @availableValues
NeverDropCollection.prototype.findNextAvailable = function () {
  const next = this.assignments.find(
    (function (_this) {
      return function (a) {
        return _this.availableValues.find(function (av) {
          return a.id === av.id
        })
      }
    })(this)
  )
  return this.availableValues.get(next.id)
}

export default NeverDropCollection
