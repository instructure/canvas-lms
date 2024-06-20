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

import createAnnIndex from '../index'

const ok = value => expect(value).toBeTruthy()
const notOk = value => expect(value).toBeFalsy()

let app = null

const node = document.createElement('div')
node.setAttribute('id', 'fixtures')
document.body.appendChild(node)
const container = document.getElementById('fixtures')

const defaultData = () => ({})

describe('Announcements app', () => {
  afterEach(() => {
    if (app) {
      app.unmount()
      app = null
    }
    container.innerHTML = ''
  })

  test('mounts Announcements to container component', () => {
    app = createAnnIndex(container, defaultData())
    app.render()
    ok(container.querySelector('.announcements-v2__wrapper'))
  })

  test('unmounts Announcements from container component', () => {
    app = createAnnIndex(container, defaultData())
    app.render()
    app.unmount()
    notOk(document.querySelector('.announcements-v2__wrapper'))
  })
})
