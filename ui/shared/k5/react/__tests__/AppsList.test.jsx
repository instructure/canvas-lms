/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import AppsList from '../AppsList'

describe('AppsList', () => {
  const getProps = (overrides = {}) => ({
    isLoading: false,
    apps: [
      {
        id: '1',
        courses: [
          {
            id: '1',
            name: 'Physics',
          },
          {
            id: '2',
            name: 'English',
          },
        ],
        title: 'YouTube',
        icon: '/youtubeicon.png',
      },
      {
        id: '3',
        courses: [
          {
            id: '2',
            name: 'English',
          },
        ],
        title: 'Drive',
        icon: '/driveicon.png',
      },
    ],
    ...overrides,
  })

  afterEach(() => {
    localStorage.clear()
  })

  it('renders all provided apps', () => {
    const {getByText} = render(<AppsList {...getProps()} />)
    expect(getByText('YouTube')).toBeInTheDocument()
    expect(getByText('Drive')).toBeInTheDocument()
  })

  it('renders a title for the section', () => {
    const {getByText} = render(<AppsList {...getProps()} />)
    expect(getByText('Student Applications')).toBeInTheDocument()
  })

  it('renders nothing if no apps provided in list', () => {
    const {queryByText} = render(<AppsList {...getProps({apps: []})} />)
    expect(queryByText('Student Applications')).not.toBeInTheDocument()
  })

  it('renders 2 loading skeletons if isLoading set', () => {
    const {getAllByText} = render(<AppsList {...getProps({isLoading: true})} />)
    const skeletons = getAllByText('Loading apps...')
    expect(skeletons.length).toBe(3)
  })

  it('renders no loading indicator if isLoading not set', () => {
    const {queryByText} = render(<AppsList {...getProps()} />)
    expect(queryByText('Loading apps...')).not.toBeInTheDocument()
  })
})
