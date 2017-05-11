#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'compiled/models/ContentMigration'
  'compiled/collections/DaySubstitutionCollection'
], (Backbone, ContentMigration, DaySubstitutionCollection) -> 
  QUnit.module 'ContentMigration',
    setup: -> @model = new ContentMigration foo: 'bar'

  test 'dynamicDefaults are set when initializing the model', -> 
    model = new ContentMigration
              foo: 'bar'
              cat: 'hat'

    equal model.dynamicDefaults.foo, 'bar', 'bar was set'
    equal model.dynamicDefaults.cat, 'hat', 'hat was set'

  test 'dynamicDefaults is stored on the instance, not all classes', -> 
    model1 = new ContentMigration foo: 'bar'
    model2 = new ContentMigration cat: 'hat'

    equal model2.dynamicDefaults.foo, undefined
    equal model1.dynamicDefaults.cat, undefined
  
  test 'resetModel adds restores dynamic defaults', -> 
    @model.clear()
    equal @model.get('foo'), undefined, 'Model is clear'

    @model.resetModel()
    equal @model.get('foo'), 'bar', 'Model defaults are now reset'

  test 'resetModel removes non initialized attributes', -> 
    @model.set('cat', 'hat')
    @model.resetModel()
    equal @model.get('cat'), undefined, 'Non initialized attributes removed'

  test 'resetModel resets all collections that were defined in the dynamicDefaults', -> 
    collection = new Backbone.Collection [new Backbone.Model, new Backbone.Model, new Backbone.Model] # 3 models
    model = new ContentMigration someCollection: collection

    equal model.get('someCollection').length, 3, 'There are 3 collections in the model'
    model.resetModel()
    equal model.get('someCollection').length, 0, 'All models in the collection were cleared'

  test 'toJSON adds a date_shift_options namespace if non exists', -> 
    json = @model.toJSON()
    equal typeof(json.date_shift_options), 'object', 'adds date_shift_options'

  test 'adds daySubsitution JSON to day_subsitutions namespace if daySubCollection exists', -> 
    collection = new DaySubstitutionCollection({bar:'baz'})
    @model.daySubCollection = collection

    collectionJSON = collection.toJSON()
    json = @model.toJSON()

    deepEqual json.date_shift_options.day_substitutions, collectionJSON, 'day subsitution json added from collection'

  test 'toJSON keeps all date_shift_options when adding new day_substitutions', -> 
    dsOptions = {bar: 'baz'}
    collection = new DaySubstitutionCollection

    @model.daySubCollection = collection
    @model.set('date_shift_options', {bar: 'baz'})

    json = @model.toJSON()

    equal json.date_shift_options.bar, 'baz', 'Keeps date_shift_options'
