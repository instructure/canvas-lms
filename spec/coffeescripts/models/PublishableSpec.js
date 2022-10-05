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

import Publishable from '@canvas/context-modules/backbone/models/Publishable'

const buildModule = published => new Publishable({published}, {url: '/api/1/2/3'})

QUnit.module('Publishable:', {
  setup() {},
  teardown() {},
})

test('publish updates the state of the model', () => {
  const cModule = buildModule(false)
  cModule.save = function () {}
  cModule.publish()
  equal(cModule.get('published'), true)
})

test('publish saves to the server', () => {
  const cModule = buildModule(true)
  const saveStub = sandbox.stub(cModule, 'save')
  cModule.publish()
  ok(saveStub.calledOnce)
})

test('unpublish updates the state of the model', () => {
  const cModule = buildModule(true)
  cModule.save = function () {}
  cModule.unpublish()
  equal(cModule.get('published'), false)
})

test('unpublish saves to the server', () => {
  const cModule = buildModule(true)
  const saveStub = sandbox.stub(cModule, 'save')
  cModule.unpublish()
  ok(saveStub.calledOnce)
})

test('toJSON wraps attributes', () => {
  const publishable = new Publishable({published: true}, {root: 'module'})
  equal(publishable.toJSON().module.published, true)
})
