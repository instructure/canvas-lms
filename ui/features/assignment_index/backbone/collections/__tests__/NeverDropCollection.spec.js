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

import Backbone from '@canvas/backbone'
import NeverDropCollection from '../NeverDropCollection'

class AssignmentStub extends Backbone.Model {
  name() {
    return this.get('name')
  }

  toView = () => ({
    name: this.get('name'),
    id: this.id,
  })
}

class Assignments extends Backbone.Collection {
  model = AssignmentStub
}

describe('NeverDropCollection', () => {
  let assignments
  let neverDrops

  beforeEach(() => {
    const list = [1, 2, 3, 4, 5]
    assignments = new Assignments([])
    assignments.comparator = 'position'
    assignments.reset(
      list.map((val, i) => ({
        id: val,
        position: list.length - i,
        name: `Assignment ${val}`,
      }))
    )
    neverDrops = new NeverDropCollection([], {
      assignments,
      ag_id: 1,
    })
  })

  test('#initialize', () => {
    expect(neverDrops.assignments).toEqual(assignments)
    expect(neverDrops.ag_id).toBe(1)
  })

  test('#toAssignments', () => {
    neverDrops.add({})
    neverDrops.add({})
    neverDrops.add({})
    neverDrops.add({})
    const output = neverDrops.toAssignments(neverDrops.at(3).get('chosen_id'))
    const expected = assignments.slice(3).map(m => m.toView())
    expect(output).toEqual(expected)
  })

  test('#findNextAvailable', () => {
    neverDrops.add({})
    expect(neverDrops.findNextAvailable()).toEqual(
      neverDrops.availableValues.get(assignments.at(1).id),
      'finds the available item that has the id of the second assignment'
    )
  })
})
