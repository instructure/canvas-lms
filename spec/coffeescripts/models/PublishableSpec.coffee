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

define ['compiled/models/Publishable'], (Publishable) ->

  buildModule = (published)->
    new Publishable {published: published}, {url: '/api/1/2/3'}

  QUnit.module 'Publishable:',
    setup: ->
    teardown: ->

  test 'publish updates the state of the model', ->
    cModule = buildModule false
    cModule.save = ()->
    cModule.publish()
    equal cModule.get('published'), true

  test 'publish saves to the server', ->
    cModule = buildModule true
    saveStub = @stub cModule, 'save'
    cModule.publish()
    ok saveStub.calledOnce

  test 'unpublish updates the state of the model', ->
    cModule = buildModule true
    cModule.save = ()->
    cModule.unpublish()
    equal cModule.get('published'), false

  test 'unpublish saves to the server', ->
    cModule = buildModule true
    saveStub = @stub cModule, 'save'
    cModule.unpublish()
    ok saveStub.calledOnce

  test 'toJSON wraps attributes', ->
    publishable = new Publishable {published: true}, {root: 'module'}
    equal publishable.toJSON()['module']['published'], true
