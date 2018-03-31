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

import UniqueDropdownCollection from 'compiled/util/UniqueDropdownCollection'
import Backbone from 'Backbone'
import _ from 'underscore'

QUnit.module('UniqueDropdownCollection', {
  setup() {
    let i
    this.records = (() => {
      const result = []
      for (i = 1; i <= 3; i++) {
        result.push(new Backbone.Model({id: i, state: i.toString()}))
      }
      return result
    })()
    this.coll = new UniqueDropdownCollection(this.records, {
      propertyName: 'state',
      possibleValues: _.map([1, 2, 3, 4], i => i.toString())
    })
  }
})

test('#intialize', function() {
  ok(this.coll.length === this.records.length, 'stores all the records')
  equal(this.coll.takenValues.length, 3)
  equal(this.coll.availableValues.length, 1)
  ok(this.coll.availableValues instanceof Backbone.Collection)
})

test('updates available/taken when models change', function() {
  this.coll.availableValues.on('remove', model => strictEqual(model.get('value'), '4'))
  this.coll.availableValues.on('add', model => strictEqual(model.get('value'), '1'))

  this.coll.takenValues.on('remove', model => strictEqual(model.get('value'), '1'))
  this.coll.takenValues.on('add', model => strictEqual(model.get('value'), '4'))

  // not taken by other models until now
  return this.records[0].set('state', '4')
})

test('removing a model updates the available/taken values', function() {
  this.coll.availableValues.on('add', model => strictEqual(model.get('value'), '1'))
  this.coll.takenValues.on('remove', model => strictEqual(model.get('value'), '1'))

  return this.coll.remove(this.coll.get(1))
})

test('overrides add to munge params with an available value', function() {
  this.coll.model = Backbone.Model

  this.coll.add({})

  equal(this.coll.availableValues.length, 0)
  equal(this.coll.takenValues.length, 4)
  ok(this.coll.takenValues.get('4') instanceof Backbone.Model)
  equal(this.coll.at(this.coll.length - 1).get('state'), 4)
})

test('add should take the value from the front of the available values collection', function() {
  // remove one so there's only two taken
  this.coll.remove(this.coll.at(0))

  const first_avail = this.coll.availableValues.at(0).get('state')
  this.coll.availableValues.on('remove', model => strictEqual(model.get('state'), first_avail))

  this.coll.model = Backbone.Model

  return this.coll.add({})
})

QUnit.module('UniqueDropdownCollection, lazy setup', {
  setup() {
    let i
    this.records = (() => {
      const result = []
      for (i = 1; i <= 3; i++) {
        result.push(new Backbone.Model({id: i, state: i.toString()}))
      }
      return result
    })()
    this.coll = new UniqueDropdownCollection([], {
      propertyName: 'state',
      possibleValues: _.map([1, 2, 3, 4], i => i.toString())
    })
  }
})

test('reset of collection recalculates availableValues', function() {
  equal(this.coll.availableValues.length, 4, 'has the 4 default items on init')
  this.coll.reset(this.records)
  equal(this.coll.availableValues.length, 1, '`availableValues` is recalculated on reset')
})
