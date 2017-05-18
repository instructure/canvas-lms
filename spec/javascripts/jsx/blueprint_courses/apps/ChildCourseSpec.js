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
import sampleData from '../sampleData'

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

const defaultData = () => select(sampleData, [
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

test('change log route onEnter calls app showChangeLog with changeId from URL', () => {
  child = new ChildCourse(container, defaultData())
  child.render()
  child.app.showChangeLog = sinon.spy()
  child.routes[0].onEnter({ params: { id: '3' } }, () => {})
  equal(child.app.showChangeLog.callCount, 1)
  equal(child.app.showChangeLog.getCall(0).args[0], '3')

  child.app.hideChangeLog = sinon.spy()
  child.routes[0].onExit({}, () => {})
  equal(child.app.hideChangeLog.callCount, 1)
})
