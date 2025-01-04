/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render, act} from '@testing-library/react'
import App from '../App'
import CourseEpubExportStore from '../CourseStore'

describe('EpubExportApp', () => {
  let props

  beforeEach(() => {
    props = {
      1: {
        name: 'Maths 101',
        id: 1,
      },
      2: {
        name: 'Physics 101',
        id: 2,
      },
    }
    jest.spyOn(CourseEpubExportStore, 'getAll').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('initializes with empty state', () => {
    const {container} = render(<App />)
    expect(container.querySelectorAll('li')).toHaveLength(0)
  })

  it('updates state when CourseEpubExportStore changes', () => {
    const {container} = render(<App />)
    act(() => {
      CourseEpubExportStore.setState(props)
    })
    expect(container.querySelectorAll('li')).toHaveLength(2)
  })

  it('fetches courses on mount', () => {
    render(<App />)
    expect(CourseEpubExportStore.getAll).toHaveBeenCalled()
  })
})
