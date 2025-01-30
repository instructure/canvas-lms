/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import type doFetchApi from '@canvas/do-fetch-api-effect'
import type {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import ContextModulesPublishIcon from '../ContextModulesPublishIcon'
import {initBody, makeModuleWithItems} from '../../__tests__/testHelpers'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(() =>
    Promise.resolve({
      response: new Response('', {status: 200}),
      json: {published: true},
      text: '',
      link: undefined,
    } as DoFetchApiResults<{published: boolean}>),
  ),
}))

jest.mock('@canvas/context-modules/jquery/utils', () => {
  const originalModule = jest.requireActual('@canvas/context-modules/jquery/utils')
  return {
    __esModule: true,
    ...originalModule,
    updateModuleItem: jest.fn(),
  }
})

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

const mockDoFetchApi = jest.requireMock('@canvas/do-fetch-api-effect')
  .default as jest.MockedFunction<typeof doFetchApi>

const mockShowFlashAlert = showFlashAlert as jest.Mock

const defaultProps = {
  courseId: '1',
  moduleId: '1',
  moduleName: 'Lesson 2',
  published: true,
  isPublishing: false,
}

const PUBLISH_URL = '/api/v1/courses/1/modules/1'

const mockResponse = new Response('', {status: 200})
mockResponse.json = () => Promise.resolve({published: true})

beforeEach(() => {
  mockDoFetchApi.mockImplementation(() =>
    Promise.resolve({
      response: mockResponse,
      json: {published: true},
      text: '',
      link: undefined,
    } as DoFetchApiResults<{published: boolean}>),
  )
  mockShowFlashAlert.mockReset()
  initBody()
  makeModuleWithItems(1, [117, 119])
})

afterEach(() => {
  jest.clearAllMocks()
  mockDoFetchApi.mockReset()
  document.body.innerHTML = ''
})

describe('ContextModulesPublishIcon', () => {
  describe('basic rendering', () => {
    it('displays a spinner with default message while publishing is in-flight', () => {
      const {getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} isPublishing={true} />,
      )
      expect(getByText('working')).toBeInTheDocument()
    })

    it('displays a spinner with given message while publishing is in-flight', () => {
      const {getByText} = render(
        <ContextModulesPublishIcon
          {...defaultProps}
          isPublishing={true}
          loadingMessage="the loading message"
        />,
      )
      expect(getByText('the loading message')).toBeInTheDocument()
    })

    it('renders as unpublished when unpublished', () => {
      const {container, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={false} />,
      )
      expect(getByText('Lesson 2 module publish options, unpublished')).toBeInTheDocument()
      expect(container.querySelector('[name="IconUnpublished"]')).toBeInTheDocument()
    })

    it('renders as published when published', () => {
      const {container, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={true} />,
      )
      expect(getByText('Lesson 2 module publish options, published')).toBeInTheDocument()
      expect(container.querySelector('[name="IconPublish"]')).toBeInTheDocument()
    })
  })

  it('renders the menu when clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishIcon {...defaultProps} />)
    const menuButton = getByRole('button', {hidden: true})
    act(() => menuButton.click())
    expect(getByText('Publish module and all items')).toBeInTheDocument()
    expect(getByText('Publish module only')).toBeInTheDocument()
    expect(getByText('Unpublish module and all items')).toBeInTheDocument()
    expect(getByText('Unpublish module only')).toBeInTheDocument()
  })

  it('calls publishAll when clicked publish all menu item is clicked', async () => {
    const user = userEvent.setup({delay: null})
    const {getByRole} = render(<ContextModulesPublishIcon {...defaultProps} />)

    // Open menu and click publish all
    const menuButton = getByRole('button', {
      name: 'Lesson 2 module publish options, published',
      hidden: true,
    })
    await user.click(menuButton)
    const publishButton = getByRole('menuitem', {name: 'Publish module and all items'})
    await user.click(publishButton)

    // Verify API call
    await waitFor(() => {
      expect(mockDoFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PUT',
          path: PUBLISH_URL,
          body: {module: {published: true, skip_content_tags: false}},
        }),
      )
    })

    // Verify flash message
    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Module and items published',
          type: 'success',
          srOnly: true,
        }),
      )
    })
  })

  it('calls publishModuleOnly when clicked publish module menu item is clicked', async () => {
    const user = userEvent.setup({delay: null})
    const {getByRole} = render(<ContextModulesPublishIcon {...defaultProps} />)

    // Open menu and click publish module only
    const menuButton = getByRole('button', {
      name: 'Lesson 2 module publish options, published',
      hidden: true,
    })
    await user.click(menuButton)
    const publishButton = getByRole('menuitem', {name: 'Publish module only'})
    await user.click(publishButton)

    // Verify API call
    await waitFor(() => {
      expect(mockDoFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PUT',
          path: PUBLISH_URL,
          body: {module: {published: true, skip_content_tags: true}},
        }),
      )
    })

    // Verify flash message
    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Module published',
          type: 'success',
          srOnly: true,
        }),
      )
    })
  })

  it('calls unpublishAll when clicked unpublish all items is clicked', async () => {
    const user = userEvent.setup({delay: null})
    const {getByRole} = render(<ContextModulesPublishIcon {...defaultProps} />)

    // Open menu and click unpublish all
    const menuButton = getByRole('button', {
      name: 'Lesson 2 module publish options, published',
      hidden: true,
    })
    await user.click(menuButton)
    const unpublishButton = getByRole('menuitem', {name: 'Unpublish module and all items'})
    await user.click(unpublishButton)

    // Verify API call
    await waitFor(() => {
      expect(mockDoFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PUT',
          path: PUBLISH_URL,
          body: {module: {published: false, skip_content_tags: false}},
        }),
      )
    })

    // Verify flash message
    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Module and items unpublished',
          type: 'success',
          srOnly: true,
        }),
      )
    })
  })
})
