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
  'compiled/util/UniqueDropdownCollection'
  'Backbone'
  'underscore'
], (UniqueDropdownCollection, Backbone, _) ->

  QUnit.module "UniqueDropdownCollection",
    setup: ->
      @records = (new Backbone.Model(id: i, state: i.toString()) for i in [1..3])
      @coll = new UniqueDropdownCollection @records,
        propertyName: 'state'
        possibleValues: _.map [1..4], (i) -> i.toString()

  test "#intialize", ->

    ok @coll.length == @records.length, 'stores all the records'
    equal @coll.takenValues.length, 3
    equal @coll.availableValues.length, 1
    ok @coll.availableValues instanceof Backbone.Collection

  test "updates available/taken when models change", ->

    @coll.availableValues.on 'remove', (model) ->
      strictEqual model.get('value'), '4'
    @coll.availableValues.on 'add', (model) ->
      strictEqual model.get('value'), '1'

    @coll.takenValues.on 'remove', (model) ->
      strictEqual model.get('value'), '1'
    @coll.takenValues.on 'add', (model) ->
      strictEqual model.get('value'), '4'

    # not taken by other models until now
    @records[0].set 'state', '4'

  test "removing a model updates the available/taken values", ->

    @coll.availableValues.on 'add', (model) ->
      strictEqual model.get('value'), '1'
    @coll.takenValues.on 'remove', (model) ->
      strictEqual model.get('value'), '1'

    @coll.remove(@coll.get(1))

  test "overrides add to munge params with an available value", ->

    @coll.model = Backbone.Model

    @coll.add {}

    equal @coll.availableValues.length, 0
    equal @coll.takenValues.length, 4
    ok @coll.takenValues.get('4') instanceof Backbone.Model
    equal @coll.at(@coll.length - 1).get('state'), 4

  test "add should take the value from the front of the available values collection", ->

    #remove one so there's only two taken
    @coll.remove(@coll.at(0))

    first_avail = @coll.availableValues.at(0).get('state')
    @coll.availableValues.on 'remove', (model) ->
      strictEqual model.get('state'), first_avail

    @coll.model = Backbone.Model

    @coll.add {}


  QUnit.module "UniqueDropdownCollection, lazy setup",
    setup: ->
      @records = (new Backbone.Model(id: i, state: i.toString()) for i in [1..3])
      @coll = new UniqueDropdownCollection [],
        propertyName: 'state'
        possibleValues: _.map [1..4], (i) -> i.toString()

  test "reset of collection recalculates availableValues", ->
    equal @coll.availableValues.length, 4, 'has the 4 default items on init'
    @coll.reset @records
    equal @coll.availableValues.length, 1, '`availableValues` is recalculated on reset'


