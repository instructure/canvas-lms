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

import React from 'react'
import {waitFor} from '@testing-library/react'
import createAnnIndex from '../index'

describe('Announcements app', () => {
  let container
  let app

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
  })

  afterEach(() => {
    if (app) {
      app.unmount()
      app = null
    }
    container.remove()
  })

  it('renders the Announcements component', async () => {
    app = createAnnIndex(container, {})
    app.render()
    
    await waitFor(() => {
      expect(container.querySelector('.announcements-v2__wrapper')).toBeInTheDocument()
    })
  })

  it('unmounts the Announcements component', async () => {
    app = createAnnIndex(container, {})
    app.render()
    
    await waitFor(() => {
      expect(container.querySelector('.announcements-v2__wrapper')).toBeInTheDocument()
    })
    
    app.unmount()
    expect(container.querySelector('.announcements-v2__wrapper')).not.toBeInTheDocument()
  })
})
