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
import ContentMigration from '../ContentMigration'
import DaySubstitutionCollection from '@canvas/day-substitution/backbone/collections/DaySubstitutionCollection'

describe('ContentMigration', () => {
  let model

  beforeEach(() => {
    model = new ContentMigration({foo: 'bar'})
  })

  test('dynamicDefaults are set when initializing the model', () => {
    const model = new ContentMigration({
      foo: 'bar',
      cat: 'hat',
    })
    expect(model.dynamicDefaults.foo).toBe('bar')
    expect(model.dynamicDefaults.cat).toBe('hat')
  })

  test('dynamicDefaults is stored on the instance, not all classes', () => {
    const model1 = new ContentMigration({foo: 'bar'})
    const model2 = new ContentMigration({cat: 'hat'})
    expect(model2.dynamicDefaults.foo).toBeUndefined()
    expect(model1.dynamicDefaults.cat).toBeUndefined()
  })

  test('resetModel adds restores dynamic defaults', () => {
    model.clear()
    expect(model.get('foo')).toBeUndefined()
    model.resetModel()
    expect(model.get('foo')).toBe('bar')
  })

  test('resetModel removes non initialized attributes', () => {
    model.set('cat', 'hat')
    model.resetModel()
    expect(model.get('cat')).toBeUndefined()
  })

  test('resetModel resets all collections that were defined in the dynamicDefaults', () => {
    const collection = new Backbone.Collection([
      new Backbone.Model(),
      new Backbone.Model(),
      new Backbone.Model(),
    ])
    const model = new ContentMigration({someCollection: collection})
    expect(model.get('someCollection').length).toBe(3)
    model.resetModel()
    expect(model.get('someCollection').length).toBe(0)
  })

  test('toJSON adds a date_shift_options namespace if none exists', () => {
    const json = model.toJSON()
    expect(typeof json.date_shift_options).toBe('object')
  })

  test('adds daySubstitution JSON to day_substitutions namespace if daySubCollection exists', () => {
    const collection = new DaySubstitutionCollection({bar: 'baz'})
    model.daySubCollection = collection
    const collectionJSON = collection.toJSON()
    const json = model.toJSON()
    expect(json.date_shift_options.day_substitutions).toEqual(collectionJSON)
  })

  test('toJSON keeps all date_shift_options when adding new day_substitutions', () => {
    const dsOptions = {bar: 'baz'}
    const collection = new DaySubstitutionCollection()
    model.daySubCollection = collection
    model.set('date_shift_options', {bar: 'baz'})
    const json = model.toJSON()
    expect(json.date_shift_options.bar).toBe('baz')
  })
})
