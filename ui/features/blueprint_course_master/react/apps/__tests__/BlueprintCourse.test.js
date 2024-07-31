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

import BlueprintCourse from '../BlueprintCourse'
import select from '@canvas/obj-select'
import getSampleData from '@canvas/blueprint-courses/getSampleData'

let blueprint = null
let container = null

const defaultData = () =>
  Object.assign(select(getSampleData(), ['terms', 'masterCourse', ['childCourse', 'course']]), {
    canManageCourse: true,
    canAutoPublishCourses: true, // Adding the required prop
  })

describe('BlueprintCourse app', () => {
  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
  })

  afterEach(() => {
    if (blueprint) {
      blueprint.unmount()
      blueprint = null
    }
    document.body.removeChild(container)
    container = null
  })

  test('mounts BlueprintSidebar to container component', () => {
    blueprint = new BlueprintCourse(container, defaultData())
    blueprint.render()
    expect(container.querySelector('.bcs__wrapper')).not.toBeNull()
  })

  test('unmounts BlueprintSidebar from container component', () => {
    blueprint = new BlueprintCourse(container, defaultData())
    blueprint.render()
    blueprint.unmount()
    expect(document.querySelector('.bcs__wrapper')).toBeNull()
  })

  test('change log route onEnter calls app showChangeLog with params from URL', () => {
    blueprint = new BlueprintCourse(container, defaultData())
    blueprint.render()
    blueprint.app.showChangeLog = jest.fn()
    blueprint.routes[0].onEnter(
      {params: {blueprintType: 'template', templateId: '2', changeId: '3'}},
      () => {}
    )
    expect(blueprint.app.showChangeLog).toHaveBeenCalledTimes(1)
    expect(blueprint.app.showChangeLog).toHaveBeenCalledWith({
      blueprintType: 'template',
      templateId: '2',
      changeId: '3',
    })

    blueprint.app.hideChangeLog = jest.fn()
    blueprint.routes[0].onExit({}, () => {})
    expect(blueprint.app.hideChangeLog).toHaveBeenCalledTimes(1)
  })

  test('start does not call setupRouter() when shabang is missing in the URL', () => {
    blueprint = new BlueprintCourse(container, defaultData())
    const renderSpy = jest.spyOn(blueprint, 'render')
    const setupRouterSpy = jest.spyOn(blueprint, 'setupRouter')

    blueprint.start()

    expect(renderSpy).toHaveBeenCalledTimes(1)
    expect(setupRouterSpy).not.toHaveBeenCalled()
  })

  test('start calls render() and setupRouter() when shabang is in the URL', () => {
    window.location.hash = '#!/blueprint'
    blueprint = new BlueprintCourse(container, defaultData())
    const renderSpy = jest.spyOn(blueprint, 'render')
    const setupRouterSpy = jest.spyOn(blueprint, 'setupRouter')

    blueprint.start()

    expect(renderSpy).toHaveBeenCalledTimes(1)
    expect(setupRouterSpy).toHaveBeenCalledTimes(1)
  })
})
