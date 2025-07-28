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

import {waitFor} from '@testing-library/dom'
import createPermissionsIndex from '../index'

let app = null

const defaultData = () => ({
  contextId: 1,
  permissions: [],
  roles: [],
})

const indexContainer = document.createElement('div')

beforeEach(() => {
  document.body.appendChild(indexContainer)
})

afterEach(() => {
  if (app) {
    app.unmount()
    app = null
  }
  indexContainer.remove()
})

const waitForElement = async (selector, {timeout = 1000, interval = 50} = {}) => {
  const startTime = Date.now()
  while (Date.now() - startTime < timeout) {
    const element = document.querySelector(selector)
    if (element) return element
    await new Promise(resolve => setTimeout(resolve, interval))
  }
  throw new Error(`Element ${selector} not found after ${timeout}ms`)
}

it('mounts/unmounts permissions to container component', async () => {
  app = createPermissionsIndex(indexContainer, defaultData())
  app.render()

  await waitFor(() =>
    expect(document.querySelector('.permissions-v2__wrapper')).toBeInTheDocument(),
  )

  app.unmount()

  await waitFor(() =>
    expect(document.querySelector('.permissions-v2__wrapper')).not.toBeInTheDocument(),
  )
})
