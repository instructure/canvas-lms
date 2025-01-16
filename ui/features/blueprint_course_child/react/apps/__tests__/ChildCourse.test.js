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

import ChildCourse from '../ChildCourse'
import select from '@canvas/obj-select'
import getSampleData from '@canvas/blueprint-courses/getSampleData'

const ok = x => expect(x).toBeTruthy()
const notOk = x => expect(x).toBeFalsy()
const equal = (x, y) => expect(x).toBe(y)
const deepEqual = (x, y) => expect(x).toEqual(y)

let child = null

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const defaultData = () =>
  select(getSampleData(), ['terms', 'masterCourse', ['childCourse', 'course']])

describe('ChildCourse class', () => {
  afterEach(() => {
    if (child) {
      child.unmount()
      child = null
    }
    container.innerHTML = ''
  })

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
    child.app.showChangeLog = jest.fn()
    child.routes[0].onEnter(
      {params: {blueprintType: 'template', templateId: '2', changeId: '3'}},
      () => {},
    )
    expect(child.app.showChangeLog).toHaveBeenCalledTimes(1)
    expect(child.app.showChangeLog).toHaveBeenCalledWith({
      blueprintType: 'template',
      templateId: '2',
      changeId: '3',
    })

    child.app.hideChangeLog = jest.fn()
    child.routes[0].onExit({}, () => {})
    expect(child.app.hideChangeLog).toHaveBeenCalledTimes(1)
  })

  test.skip('start calls render() and setupRouter()', () => {
    child = new ChildCourse(container, defaultData())
    const renderSpy = jest.spyOn(child, 'render')
    const setupRouterSpy = jest.spyOn(child, 'setupRouter')

    child.start()

    expect(renderSpy).toHaveBeenCalledTimes(1)
    expect(setupRouterSpy).toHaveBeenCalledTimes(1)
  })
})
