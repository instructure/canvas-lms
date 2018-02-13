/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import Backbone from 'Backbone'
import NeverDropCollection from 'compiled/collections/NeverDropCollection'

class AssignmentStub extends Backbone.Model {
  name() {
    return this.get('name')
  }

  toView = () => ({
    name: this.get('name'),
    id: this.id
  })
}
class Assignments extends Backbone.Collection {
  model = AssignmentStub
}

QUnit.module('NeverDropCollection', {
  setup() {
    const list = [1, 2, 3, 4, 5]
    this.assignments = new Assignments([])
    this.assignments.comparator = 'position'
    this.assignments.reset(
      list.map((val, i) => ({
        id: val,
        position: list.length - i,
        name: `Assignment ${val}`
      }))
    )
    this.never_drops = new NeverDropCollection([], {
      assignments: this.assignments,
      ag_id: 1
    })
  }
})

test('#initialize', function() {
  deepEqual(this.never_drops.assignments, this.assignments)
  strictEqual(this.never_drops.ag_id, 1)
})

test('#toAssignments', function() {
  this.never_drops.add({})
  this.never_drops.add({})
  this.never_drops.add({})
  this.never_drops.add({})
  const output = this.never_drops.toAssignments(this.never_drops.at(3).get('chosen_id'))
  const expected = this.assignments.slice(3).map(m => m.toView())
  deepEqual(output, expected)
})

test('#findNextAvailable', function() {
  this.never_drops.add({})
  deepEqual(
    this.never_drops.findNextAvailable(),
    this.never_drops.availableValues.get(this.assignments.at(1).id),
    'finds the available item that has the id of the second assignment'
  )
})
