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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import type doFetchApi from '@canvas/do-fetch-api-effect'
import type {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {updateModuleItem} from '../../jquery/utils'
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
  it('calls unpublishModuleOnly when unpublish module only is clicked', async () => {
    const user = userEvent.setup({delay: null})
    const {getByRole} = render(<ContextModulesPublishIcon {...defaultProps} />)

    // Open menu and click unpublish module only
    const menuButton = getByRole('button', {
      name: 'Lesson 2 module publish options, published',
      hidden: true,
    })
    await user.click(menuButton)
    const unpublishButton = getByRole('menuitem', {name: 'Unpublish module only'})
    await user.click(unpublishButton)

    // Verify API call
    await waitFor(() => {
      expect(mockDoFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          method: 'PUT',
          path: PUBLISH_URL,
          body: {module: {published: false, skip_content_tags: true}},
        }),
      )
    })

    // Verify flash message
    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Module unpublished',
          type: 'success',
          srOnly: true,
        }),
      )
    })
  })

  it('calls updateModuleItem when publishing', async () => {
    const fetchPromise = new Promise<DoFetchApiResults<unknown>>(resolve => {
      const {getByRole, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={false} />,
      )
      const menuButton = getByRole('button', {hidden: true})
      menuButton.click()
      const publishButton = getByText('Publish module and all items')
      publishButton.click()
      waitFor(() => {
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_17: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object),
        )
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_19: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object),
        )
      })
      resolve({response: new Response('', {status: 200}), json: {published: true}, text: ''})
    })
    mockDoFetchApi.mockReturnValue(fetchPromise)
    await fetchPromise
    waitFor(() => {
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_17: expect.any(Object)}),
        {bulkPublishInFlight: false, published: true},
        expect.any(Object),
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_19: expect.any(Object)}),
        {bulkPublishInFlight: false, published: true},
        expect.any(Object),
      )
    })
  })

  it('calls updateModuleItem when unpublishing', async () => {
    const fetchPromise = new Promise<DoFetchApiResults<unknown>>(resolve => {
      const {getByRole, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={true} />,
      )
      const menuButton = getByRole('button', {hidden: true})
      menuButton.click()
      const publishButton = getByText('Unpublish module and all items')
      userEvent.click(publishButton)
      waitFor(() => {
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_17: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object),
        )
        expect(updateModuleItem).toHaveBeenCalledWith(
          expect.objectContaining({assignment_19: expect.any(Object)}),
          {bulkPublishInFlight: true},
          expect.any(Object),
        )
      })
      resolve({response: new Response('', {status: 200}), json: {published: false}, text: ''})
    })
    mockDoFetchApi.mockReturnValue(fetchPromise)
    await fetchPromise
    waitFor(() => {
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_17: expect.any(Object)}),
        {bulkPublishInFlight: false, published: false},
        expect.any(Object),
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_19: expect.any(Object)}),
        {bulkPublishInFlight: false, published: false},
        expect.any(Object),
      )
    })
  })

  it('disables the Publish All menu button when publishing or unpublishing', async () => {
    // ts is inferring what window.modules should look like. I don't care about anything else.
    // @ts-expect-error
    window.modules = {
      updatePublishMenuDisabledState: jest.fn(),
    }

    const fetchPromise = new Promise<DoFetchApiResults<unknown>>(resolve => {
      const {getByRole, getByText} = render(
        <ContextModulesPublishIcon {...defaultProps} published={true} />,
      )
      const menuButton = getByRole('button', {hidden: true})
      menuButton.click()
      const publishButton = getByText('Unpublish module and all items')
      userEvent.click(publishButton)
      waitFor(() => {
        expect(window.modules.updatePublishMenuDisabledState).toHaveBeenCalledWith(true)
      })
      resolve({response: new Response('', {status: 200}), json: {published: false}, text: ''})
    })
    mockDoFetchApi.mockReturnValue(fetchPromise)
    await fetchPromise
    waitFor(() => {
      expect(window.modules.updatePublishMenuDisabledState).toHaveBeenCalledWith(false)
    })
  })
})
