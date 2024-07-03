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

import UniqueDropdownCollection from '../UniqueDropdownCollection'
import Backbone from '@canvas/backbone'
import _ from 'lodash'

describe('UniqueDropdownCollection', () => {
  let records, coll

  beforeEach(() => {
    records = (() => {
      const result = []
      for (let i = 1; i <= 3; i++) {
        result.push(new Backbone.Model({id: i, state: i.toString()}))
      }
      return result
    })()
    coll = new UniqueDropdownCollection(records, {
      propertyName: 'state',
      possibleValues: _.map([1, 2, 3, 4], i => i.toString()),
    })
  })

  test('#initialize', () => {
    expect(coll.length).toBe(records.length)
    expect(coll.takenValues.length).toBe(3)
    expect(coll.availableValues.length).toBe(1)
    expect(coll.availableValues instanceof Backbone.Collection).toBe(true)
  })

  test('updates available/taken when models change', done => {
    coll.availableValues.on('remove', model => {
      expect(model.get('value')).toBe('4')
    })
    coll.availableValues.on('add', model => {
      expect(model.get('value')).toBe('1')
    })

    coll.takenValues.on('remove', model => {
      expect(model.get('value')).toBe('1')
    })
    coll.takenValues.on('add', model => {
      expect(model.get('value')).toBe('4')
      done()
    })

    records[0].set('state', '4')
  })

  test('removing a model updates the available/taken values', done => {
    coll.availableValues.on('add', model => {
      expect(model.get('value')).toBe('1')
    })
    coll.takenValues.on('remove', model => {
      expect(model.get('value')).toBe('1')
      done()
    })

    coll.remove(coll.get(1))
  })

  test('overrides add to munge params with an available value', () => {
    coll.model = Backbone.Model

    coll.add({})

    expect(coll.availableValues.length).toBe(0)
    expect(coll.takenValues.length).toBe(4)
    expect(coll.takenValues.get('4') instanceof Backbone.Model).toBe(true)
    expect(coll.at(coll.length - 1).get('state')).toBe('4')
  })

  test('add should take the value from the front of the available values collection', done => {
    coll.remove(coll.at(0))

    const first_avail = coll.availableValues.at(0).get('state')
    coll.availableValues.on('remove', model => {
      expect(model.get('state')).toBe(first_avail)
      done()
    })

    coll.model = Backbone.Model

    coll.add({})
  })
})

describe('UniqueDropdownCollection, lazy setup', () => {
  let records, coll

  beforeEach(() => {
    records = (() => {
      const result = []
      for (let i = 1; i <= 3; i++) {
        result.push(new Backbone.Model({id: i, state: i.toString()}))
      }
      return result
    })()
    coll = new UniqueDropdownCollection([], {
      propertyName: 'state',
      possibleValues: _.map([1, 2, 3, 4], i => i.toString()),
    })
  })

  test('reset of collection recalculates availableValues', () => {
    expect(coll.availableValues.length).toBe(4)
    coll.reset(records)
    expect(coll.availableValues.length).toBe(1)
  })
})
