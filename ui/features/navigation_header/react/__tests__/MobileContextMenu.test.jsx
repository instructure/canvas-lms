// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import MobileContextMenu from '../MobileContextMenu'
import fetchMock from 'fetch-mock'

const tabsFromApi = [
  {
    id: 'home',
    html_url: '/courses/1',
    label: 'Home',
    type: 'internal',
  },
  {
    id: 'context_external_tool',
    html_url: '/courses/1/external_tools/1',
    hidden: true,
    label: 'Course Navigation',
    type: 'external',
  },
  {
    id: 'discussions',
    html_url: '/courses/1/discussion_topics',
    hidden: true,
    label: 'Discussions',
    type: 'internal',
  },
  {
    id: 'grades',
    html_url: '/courses/1/grades',
    unused: true,
    label: 'Grades',
    type: 'internal',
  },
  {
    id: 'dig',
    html_url: '/courses/1/external_tools/2',
    unused: true,
    label: 'DIG',
    type: 'external',
  },
]
const spinner = 'Spinner'
const contextType = 'Course'
const contextId = '1'

const props = {
  spinner,
  contextType,
  contextId,
}

describe('MobileContextMenu', () => {
  beforeEach(() => {
    window.ENV = {context_asset_string: 'courses_1'}
    fetchMock.mock('*', JSON.stringify(tabsFromApi))
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders spinner while loading', () => {
    const {getByText} = render(<MobileContextMenu {...props} />)
    expect(getByText(/Spinner/i)).toBeVisible()
  })

  it('displays tabs that are not marked hidden or unused', async () => {
    const {getAllByRole, getByText} = render(<MobileContextMenu {...props} />)
    await waitFor(() => getAllByRole('link'))
    expect(getByText('Home')).toBeVisible()
  })

  it('does not display external tabs that are set to hidden', async () => {
    const {getAllByRole, queryByText} = render(<MobileContextMenu {...props} />)
    await waitFor(() => getAllByRole('link'))
    expect(queryByText('Course Navigation')).not.toBeInTheDocument()
  })

  it('displays internal hidden tabs with offline icon', async () => {
    const {container, getAllByRole, getByText} = render(<MobileContextMenu {...props} />)
    await waitFor(() => getAllByRole('link'))
    const iconOff = container.querySelectorAll("svg[name='IconOff']")
    expect(getByText('Discussions')).toBeVisible()
    expect(getByText('- Disabled. Not visible to students.')).toBeVisible()
    expect(iconOff.length).toEqual(3)
    expect(iconOff[0]).toBeVisible()
  })

  it('displays internal unused tabs with offline icon', async () => {
    const {container, getAllByRole, getByText} = render(<MobileContextMenu {...props} />)
    await waitFor(() => getAllByRole('link'))
    const iconOff = container.querySelectorAll("svg[name='IconOff']")
    expect(getByText('Grades')).toBeVisible()
    expect(iconOff.length).toEqual(3)
    expect(iconOff[1]).toBeVisible()
  })

  it('displays external unused tabs with offline icon', async () => {
    const {container, getAllByRole, getByText} = render(<MobileContextMenu {...props} />)
    await waitFor(() => getAllByRole('link'))
    const iconOff = container.querySelectorAll("svg[name='IconOff']")
    expect(getByText('DIG')).toBeVisible()
    expect(iconOff.length).toEqual(3)
    expect(iconOff[2]).toBeVisible()
  })
})
