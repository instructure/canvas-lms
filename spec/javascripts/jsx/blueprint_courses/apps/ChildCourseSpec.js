/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ChildCourse from 'jsx/blueprint_courses/apps/ChildCourse'
import select from 'jsx/shared/select'
import getSampleData from '../getSampleData'

let child = null
const container = document.getElementById('fixtures')

QUnit.module('ChildCourse class', {
  teardown: () => {
    if (child) {
      child.unmount()
      child = null
    }
    container.innerHTML = ''
  }
})

const defaultData = () => select(getSampleData(), [
  'terms',
  'masterCourse',
  ['childCourse', 'course'],
])

test('mounts ChildContent to container component', () => {
  child = new ChildCourse(container, defaultData())
  child.render()
  ok(container.querySelector('.bcc__wrapper'))
})

test('unmounts ChildContent from container component', () => {
  child = new ChildCourse(container, defaultData())
  child.render()
  child.unmount()
  notOk(document.querySelector('.bcc__wrapper'))
})

test('change log route onEnter calls app showChangeLog with params from URL', () => {
  child = new ChildCourse(container, defaultData())
  child.render()
  child.app.showChangeLog = sinon.spy()
  child.routes[0].onEnter({ params: { blueprintType: 'template', templateId: '2', changeId: '3' } }, () => {})
  equal(child.app.showChangeLog.callCount, 1)
  deepEqual(child.app.showChangeLog.getCall(0).args[0], { blueprintType: 'template', templateId: '2', changeId: '3' })

  child.app.hideChangeLog = sinon.spy()
  child.routes[0].onExit({}, () => {})
  equal(child.app.hideChangeLog.callCount, 1)
})

test('start calls render() and setupRouter()', () => {
  child = new ChildCourse(container, defaultData())
  const renderStub = sinon.stub(child, 'render')
  const setupRouterStub = sinon.stub(child, 'setupRouter')

  child.start()

  equal(renderStub.callCount, 1)
  equal(setupRouterStub.callCount, 1)
})
