#
# Copyright (C) 2014 - present Instructure, Inc.
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

define ['jsx/shared/helpers/createStore'], (createStore) ->

  test 'sets initial state', ->
    store = createStore({foo: 'bar'})
    deepEqual store.getState(), {foo: 'bar'}

  test 'merges data on setState', ->
    store = createStore({foo: 'bar', baz: null})
    deepEqual store.getState(), {foo: 'bar', baz: null}
    store.setState({baz: 'qux'})
    deepEqual store.getState(), {foo: 'bar', baz: 'qux'}

  test 'emits change on setState', ->
    expect 1
    store = createStore({foo: null})
    store.addChangeListener ->
      ok true
    store.setState foo: 'bar'

  test 'removes change listeners', ->
    callCount = 0
    fn = -> callCount++
    store = createStore({foo: null})
    store.addChangeListener fn
    store.setState foo: 'bar'
    equal callCount, 1
    store.removeChangeListener fn
    store.setState foo: 'baz'
    equal callCount, 1

