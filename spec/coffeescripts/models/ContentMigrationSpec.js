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
import ContentMigration from '@canvas/content-migrations/backbone/models/ContentMigration'
import DaySubstitutionCollection from '@canvas/day-substitution/backbone/collections/DaySubstitutionCollection'

QUnit.module('ContentMigration', {
  setup() {
    this.model = new ContentMigration({foo: 'bar'})
  },
})

test('dynamicDefaults are set when initializing the model', () => {
  const model = new ContentMigration({
    foo: 'bar',
    cat: 'hat',
  })
  equal(model.dynamicDefaults.foo, 'bar', 'bar was set')
  equal(model.dynamicDefaults.cat, 'hat', 'hat was set')
})

test('dynamicDefaults is stored on the instance, not all classes', () => {
  const model1 = new ContentMigration({foo: 'bar'})
  const model2 = new ContentMigration({cat: 'hat'})
  equal(model2.dynamicDefaults.foo, undefined)
  equal(model1.dynamicDefaults.cat, undefined)
})

test('resetModel adds restores dynamic defaults', function () {
  this.model.clear()
  equal(this.model.get('foo'), undefined, 'Model is clear')
  this.model.resetModel()
  equal(this.model.get('foo'), 'bar', 'Model defaults are now reset')
})

test('resetModel removes non initialized attributes', function () {
  this.model.set('cat', 'hat')
  this.model.resetModel()
  equal(this.model.get('cat'), undefined, 'Non initialized attributes removed')
})

test('resetModel resets all collections that were defined in the dynamicDefaults', () => {
  const collection = new Backbone.Collection([
    new Backbone.Model(),
    new Backbone.Model(),
    new Backbone.Model(),
  ])
  const model = new ContentMigration({someCollection: collection})
  equal(model.get('someCollection').length, 3, 'There are 3 collections in the model')
  model.resetModel()
  equal(model.get('someCollection').length, 0, 'All models in the collection were cleared')
})

test('toJSON adds a date_shift_options namespace if non exists', function () {
  const json = this.model.toJSON()
  equal(typeof json.date_shift_options, 'object', 'adds date_shift_options')
})

test('adds daySubsitution JSON to day_subsitutions namespace if daySubCollection exists', function () {
  const collection = new DaySubstitutionCollection({bar: 'baz'})
  this.model.daySubCollection = collection
  const collectionJSON = collection.toJSON()
  const json = this.model.toJSON()
  deepEqual(
    json.date_shift_options.day_substitutions,
    collectionJSON,
    'day subsitution json added from collection'
  )
})

test('toJSON keeps all date_shift_options when adding new day_substitutions', function () {
  const dsOptions = {bar: 'baz'}
  const collection = new DaySubstitutionCollection()
  this.model.daySubCollection = collection
  this.model.set('date_shift_options', {bar: 'baz'})
  const json = this.model.toJSON()
  equal(json.date_shift_options.bar, 'baz', 'Keeps date_shift_options')
})
