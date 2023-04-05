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
import {act, render} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import ContextModulesPublishIcon from '../ContextModulesPublishIcon'

jest.mock('@canvas/do-fetch-api-effect')

const defaultProps = {
  courseId: '1',
  moduleId: '1',
  published: true,
}

beforeAll(() => {
  doFetchApi
    .mockResolvedValue({response: {ok: true}, json: {published: true}})
    .mockResolvedValueOnce({response: {ok: true}, json: {published: true}})
    .mockResolvedValueOnce({response: {ok: true}, json: []})
    .mockResolvedValueOnce({response: {ok: true}, json: {published: true}})
    .mockResolvedValueOnce({response: {ok: true}, json: []})
})

beforeEach(() => {
  doFetchApi.mockClear()
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('ContextModulesPublishIcon', () => {
  it('renders the menu when clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    expect(getByText('Publish module and all items')).toBeInTheDocument()
    expect(getByText('Publish module only')).toBeInTheDocument()
    expect(getByText('Unpublish module and all items')).toBeInTheDocument()
  })

  it('calls publishAll when clicked publish all menu item is clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    const publishButton = getByText('Publish module and all items')
    act(() => publishButton.click())
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/1/modules/1',
      method: 'PUT',
      body: {module: {published: true, skip_content_tags: false}},
    })
  })

  it('calls publishModuleOnly when clicked publish module menu item is clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    const publishButton = getByText('Publish module only')
    act(() => publishButton.click())
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/1/modules/1',
      method: 'PUT',
      body: {module: {published: true, skip_content_tags: true}},
    })
  })

  it('calls unpublishAll when clicked unpublish all items is clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    const publishButton = getByText('Unpublish module and all items')
    act(() => publishButton.click())
    expect(doFetchApi).toHaveBeenCalledWith({
      path: '/api/v1/courses/1/modules/1',
      method: 'PUT',
      body: {module: {published: false, skip_content_tags: false}},
    })
  })
})
