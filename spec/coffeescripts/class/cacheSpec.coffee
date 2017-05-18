#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'underscore'
  'compiled/class/cache'
], (_, cache) ->

  QUnit.module 'class/cache',
    setup: ->
      # need to get the cache from its wrapper object
      # because cache is meant to be used as a class
      # mixin
      @cache = cache.cache

  test 'should store strings', ->
    @cache.set 'key', 'value'
    equal @cache.get('key'), 'value'

  test 'should store arrays and objects', ->
    @cache.set 'array', [1, 2, 3]
    @cache.set 'object', a: 1, b: 2

    ok _.isEqual @cache.get('array'), [1, 2, 3]
    ok _.isEqual @cache.get('object'), a: 1, b: 2

  test 'should delete keys', ->
    @cache.set 'key', 'value'
    @cache.remove 'key'
    equal @cache.get('key'), null

  test 'should accept complex keys', ->
    @cache.set [1, 2, 3], 'value1'
    @cache.set {a: 1, b: 1}, 'value2'
    @cache.set [1, 2], {a: 1}, 'test', 'value3'

    equal @cache.get([1, 2, 3]), 'value1'
    equal @cache.get({a: 1, b: 1}), 'value2'
    equal @cache.get([1, 2], {a: 1}, 'test'), 'value3'

  test 'should accept a prefix', ->
    @cache.prefix = 'prefix-'
    @cache.set 'key', 'value'
    equal typeof @cache.store['prefix-"key"'], 'string'

  test 'should accept local and sessionStorage as stores', ->
    @cache.use 'localStorage'
    equal @cache.store, localStorage

    @cache.use 'sessionStorage'
    equal @cache.store, sessionStorage

    # teardown for this test only
    @cache.use 'memory'
