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

import BlueprintCourse from 'jsx/blueprint_courses/apps/BlueprintCourse'
import select from 'jsx/shared/select'
import getSampleData from '../getSampleData'

let blueprint = null
const container = document.getElementById('fixtures')

QUnit.module('BlueprintCourse app', {
  teardown: () => {
    if (blueprint) {
      blueprint.unmount()
      blueprint = null
    }
    container.innerHTML = ''
  }
})

const defaultData = () => Object.assign(select(getSampleData(), [
  'terms',
  'masterCourse',
  ['childCourse', 'course'],
]), { canManageCourse: true })

test('mounts BlueprintSidebar to container component', () => {
  blueprint = new BlueprintCourse(container, defaultData())
  blueprint.render()
  ok(container.querySelector('.bcs__wrapper'))
})

test('unmounts BlueprintSidebar from container component', () => {
  blueprint = new BlueprintCourse(container, defaultData())
  blueprint.render()
  blueprint.unmount()
  notOk(document.querySelector('.bcs__wrapper'))
})

test('change log route onEnter calls app showChangeLog with params from URL', () => {
  blueprint = new BlueprintCourse(container, defaultData())
  blueprint.render()
  blueprint.app.showChangeLog = sinon.spy()
  blueprint.routes[0].onEnter({ params: { blueprintType: 'template', templateId: '2', changeId: '3' } }, () => {})
  equal(blueprint.app.showChangeLog.callCount, 1)
  deepEqual(blueprint.app.showChangeLog.getCall(0).args[0], { blueprintType: 'template', templateId: '2', changeId: '3' })

  blueprint.app.hideChangeLog = sinon.spy()
  blueprint.routes[0].onExit({}, () => {})
  equal(blueprint.app.hideChangeLog.callCount, 1)
})

test('start does not call setupRouter() when shabang is missing in the URL', function () {
  blueprint = new BlueprintCourse(container, defaultData())
  const renderStub = sinon.stub(blueprint, 'render')
  const setupRouterStub = sinon.stub(blueprint, 'setupRouter')

  blueprint.start()

  equal(renderStub.callCount, 1)
  equal(setupRouterStub.callCount, 0)
})

test('start calls render() and setupRouter() when shabang is in the URL', function () {
  window.location.hash = '#!/blueprint'
  blueprint = new BlueprintCourse(container, defaultData())
  const renderStub = sinon.stub(blueprint, 'render')
  const setupRouterStub = sinon.stub(blueprint, 'setupRouter')

  blueprint.start()

  equal(renderStub.callCount, 1)
  equal(setupRouterStub.callCount, 1)
})
