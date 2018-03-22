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

import createAnnIndex from 'jsx/discussions/index'

let app = null
const container = document.getElementById('fixtures')

QUnit.module('Discussions app', {
  teardown: () => {
    if (app) {
      app.unmount()
      app = null
    }
    container.innerHTML = ''
  }
})

const defaultData = () => ({
  contextCodes: ['course_1'],
  roles: ['student', 'user'],
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
