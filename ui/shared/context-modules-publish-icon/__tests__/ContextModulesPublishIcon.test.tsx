/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import ContextModulesPublishIcon from '../ContextModulesPublishIcon'

const defaultProps = {
  courseId: '1',
  moduleId: '1',
  published: true,
}

const PUBLISH_URL = '/api/v1/courses/1/modules/1'

describe('ContextModulesPublishIcon', () => {
  beforeEach(() => {
    fetchMock.get('/api/v1/courses/1/modules/1/items', 200)
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders the menu when clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    expect(getByText('Publish module and all items')).toBeInTheDocument()
    expect(getByText('Publish module only')).toBeInTheDocument()
    expect(getByText('Unpublish module and all items')).toBeInTheDocument()
  })

  it('calls publishAll when clicked publish all menu item is clicked', async () => {
    fetchMock.put(PUBLISH_URL, {
      module: {published: true, skip_content_tags: false},
    })
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Module publish menu'})
    act(() => menuButton.click())
    const publishButton = getByText('Publish module and all items')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Publishing module and items')).toBeInTheDocument())
    expect(getByText('Module and items published')).toBeInTheDocument()
  })

  it('calls publishModuleOnly when clicked publish module menu item is clicked', async () => {
    fetchMock.put(PUBLISH_URL, {
      module: {published: true, skip_content_tags: true},
    })
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Module publish menu'})
    act(() => menuButton.click())
    const publishButton = getByText('Publish module only')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Publishing module')).toBeInTheDocument())
    expect(getByText('Module published')).toBeInTheDocument()
  })

  it('calls unpublishAll when clicked unpublish all items is clicked', async () => {
    fetchMock.put(PUBLISH_URL, {
      module: {published: false, skip_content_tags: false},
    })
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {name: 'Module publish menu'})
    act(() => menuButton.click())
    const publishButton = getByText('Unpublish module and all items')
    act(() => publishButton.click())
    await waitFor(() => expect(getByText('Unpublishing module and items')).toBeInTheDocument())
    expect(getByText('Module and items unpublished')).toBeInTheDocument()
  })
})
