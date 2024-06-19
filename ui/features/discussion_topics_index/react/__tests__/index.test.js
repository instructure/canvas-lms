/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import createAnnIndex from '../index'

let app = null

const ok = value => expect(value).toBeTruthy()
const notOk = value => expect(value).toBeFalsy()

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

const defaultData = () => ({
  contextCodes: ['course_1'],
  roles: ['student', 'user'],
})

describe('Discussions app', () => {
  afterEach(() => {
    if (app) {
      app.unmount()
      app = null
    }
    container.innerHTML = ''
  })

  test('mounts Discussions to container component', () => {
    app = createAnnIndex(container, defaultData())
    app.render()
    ok(container.querySelector('.discussions-v2__wrapper'))
  })

  test('unmounts Discussions from container component', () => {
    app = createAnnIndex(container, defaultData())
    app.render()
    app.unmount()
    notOk(document.querySelector('.discussions-v2__wrapper'))
  })
})
