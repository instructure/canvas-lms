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

define ['Backbone'], ({Model}) ->

  QUnit.module 'Backbone.Model',
    setup: -> @model = new Model

  test '@mixin', ->
    initSpy = @spy()
    mixable =
      defaults:
        cash: 'money'
      initialize: initSpy
    class Mixed extends Model
      @mixin mixable
      initialize: ->
        initSpy.apply this, arguments
        super

    model = new Mixed
    equal model.get('cash'), 'money',
      'mixes in defaults'
    ok initSpy.calledTwice, 'inherits initialize'

  test 'increment', ->
    model = new Model count: 1
    model.increment 'count', 2
    equal model.get('count'), 3

  test 'decrement', ->
    model = new Model count: 10
    model.decrement 'count', 7
    equal model.get('count'), 3

  test '#deepGet returns nested attributes', ->
    @model.attributes = {foo: {bar: {zing: 'cats'}}}

    value = @model.deepGet 'foo.bar.zing'
    equal value, 'cats', 'gets a nested attribute'
