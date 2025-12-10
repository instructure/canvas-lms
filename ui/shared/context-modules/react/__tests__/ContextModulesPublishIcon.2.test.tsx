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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {updateModuleItem} from '../../jquery/utils'
import ContextModulesPublishIcon from '../ContextModulesPublishIcon'
import {initBody, makeModuleWithItems} from '../../__tests__/testHelpers'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const server = setupServer()

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

const mockShowFlashAlert = showFlashAlert as jest.Mock

const defaultProps = {
  courseId: '1',
  moduleId: '1',
  moduleName: 'Lesson 2',
  published: true,
  isPublishing: false,
}

const PUBLISH_URL = '/api/v1/courses/1/modules/1'

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  server.use(
    http.put(PUBLISH_URL, () => {
      return HttpResponse.json({published: true})
    }),
  )
  mockShowFlashAlert.mockReset()
  initBody()
  makeModuleWithItems(1, [117, 119])
})

afterEach(() => {
  server.resetHandlers()
  jest.clearAllMocks()
  document.body.innerHTML = ''
})

describe('ContextModulesPublishIcon', () => {
  it('calls unpublishModuleOnly when unpublish module only is clicked', async () => {
    const user = userEvent.setup({delay: null})
    let requestCaptured = false
    server.use(
      http.put(PUBLISH_URL, async ({request}) => {
        const body = await request.json()
        expect(body).toEqual({module: {published: false, skip_content_tags: true}})
        requestCaptured = true
        return HttpResponse.json({published: false})
      }),
    )

    const {getByRole} = render(<ContextModulesPublishIcon {...defaultProps} />)

    // Open menu and click unpublish module only
    const menuButton = getByRole('button', {
      name: 'Lesson 2 module publish options, published',
      hidden: true,
    })
    await user.click(menuButton)
    const unpublishButton = getByRole('menuitem', {name: 'Unpublish module only'})
    await user.click(unpublishButton)

    // Verify API call was made
    await waitFor(() => {
      expect(requestCaptured).toBe(true)
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
    const user = userEvent.setup({delay: null})
    const {getByRole} = render(
      <ContextModulesPublishIcon {...defaultProps} published={false} />,
    )
    const menuButton = getByRole('button', {hidden: true})
    await user.click(menuButton)
    const publishButton = getByRole('menuitem', {name: 'Publish module and all items'})
    await user.click(publishButton)

    // Verify updateModuleItem was called for each module item during publishing
    await waitFor(() => {
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_117: expect.any(Object)}),
        expect.any(Object),
        expect.any(Object),
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_119: expect.any(Object)}),
        expect.any(Object),
        expect.any(Object),
      )
    })
  })

  it('calls updateModuleItem when unpublishing', async () => {
    const user = userEvent.setup({delay: null})
    server.use(
      http.put(PUBLISH_URL, () => {
        return HttpResponse.json({published: false})
      }),
    )

    const {getByRole} = render(
      <ContextModulesPublishIcon {...defaultProps} published={true} />,
    )
    const menuButton = getByRole('button', {hidden: true})
    await user.click(menuButton)
    const unpublishButton = getByRole('menuitem', {name: 'Unpublish module and all items'})
    await user.click(unpublishButton)

    // Verify updateModuleItem was called for each module item during unpublishing
    await waitFor(() => {
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_117: expect.any(Object)}),
        expect.any(Object),
        expect.any(Object),
      )
      expect(updateModuleItem).toHaveBeenCalledWith(
        expect.objectContaining({assignment_119: expect.any(Object)}),
        expect.any(Object),
        expect.any(Object),
      )
    })
  })

  it('disables the Publish All menu button when publishing or unpublishing', async () => {
    // ts is inferring what window.modules should look like. I don't care about anything else.
    // @ts-expect-error - window.modules is a Canvas global not in TS types
    window.modules = {
      updatePublishMenuDisabledState: jest.fn(),
    }

    server.use(
      http.put(PUBLISH_URL, () => {
        return HttpResponse.json({published: false})
      }),
    )

    const {getByRole, getByText} = render(
      <ContextModulesPublishIcon {...defaultProps} published={true} />,
    )
    const menuButton = getByRole('button', {hidden: true})
    menuButton.click()
    const publishButton = getByText('Unpublish module and all items')
    userEvent.click(publishButton)

    await waitFor(() => {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore - window.modules is a Canvas global not in TS types
      expect(window.modules.updatePublishMenuDisabledState).toHaveBeenCalledWith(true)
    })

    await waitFor(() => {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore - window.modules is a Canvas global not in TS types
      expect(window.modules.updatePublishMenuDisabledState).toHaveBeenCalledWith(false)
    })
  })
})
