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

import Publishable from '../Publishable'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

const buildModule = published => new Publishable({published}, {url: '/api/1/2/3'})

describe('Publishable:', () => {
  test('publish updates the state of the model', () => {
    const cModule = buildModule(false)
    cModule.save = function () {}
    cModule.publish()
    expect(cModule.get('published')).toBeTruthy()
  })

  test('publish saves to the server', () => {
    const cModule = buildModule(true)
    const saveStub = sandbox.stub(cModule, 'save')
    cModule.publish()
    expect(saveStub.calledOnce).toBeTruthy()
  })

  test('unpublish updates the state of the model', () => {
    const cModule = buildModule(true)
    cModule.save = function () {}
    cModule.unpublish()
    expect(cModule.get('published')).toBeFalsy()
  })

  test('unpublish saves to the server', () => {
    const cModule = buildModule(true)
    const saveStub = sandbox.stub(cModule, 'save')
    cModule.unpublish()
    expect(saveStub.calledOnce).toBeTruthy()
  })

  test('toJSON wraps attributes', () => {
    const publishable = new Publishable({published: true}, {root: 'module'})
    expect(publishable.toJSON().module.published).toBeTruthy()
  })
})
