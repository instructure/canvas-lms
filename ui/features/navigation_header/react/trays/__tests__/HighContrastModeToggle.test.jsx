/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import HighContrastModeToggle from '../HighContrastModeToggle'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

describe('HighContrastModeToggle', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup({
      current_user_id: '1',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('when HCM is off', () => {
    let capturedRequests

    beforeEach(() => {
      capturedRequests = []
      fakeENV.setup({
        current_user_id: '1',
        use_high_contrast: false,
      })
      server.use(
        http.put('/api/v1/users/:userId/features/flags/high_contrast', async ({request}) => {
          const body = await request.json()
          capturedRequests.push(body)
          return HttpResponse.json({
            feature: 'high_contrast',
            state: 'on',
          })
        }),
      )
    })

    it('shows a toggle in the "off" position', () => {
      const {getByRole} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      expect(toggle).not.toBeChecked()
    })

    it('makes an API call to turn on HCM if the toggle is clicked and shows a spinner', async () => {
      const {getByRole} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      expect(capturedRequests).toHaveLength(1)
      expect(capturedRequests[0]).toMatchObject({
        feature: 'high_contrast',
        state: 'on',
      })
    })

    it('shows the explainer after a successful return, and flips the toggle on', async () => {
      const {getByRole, findByText} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      await findByText(/reload the page or navigate/i)
      expect(toggle).toBeChecked()
      expect(window.ENV.use_high_contrast).toBe(true)
    })
  })

  describe('when HCM is on', () => {
    let capturedRequests

    beforeEach(() => {
      capturedRequests = []
      fakeENV.setup({
        current_user_id: '1',
        use_high_contrast: true,
      })
      server.use(
        http.put('/api/v1/users/:userId/features/flags/high_contrast', async ({request}) => {
          const body = await request.json()
          capturedRequests.push(body)
          return HttpResponse.json({
            feature: 'high_contrast',
            state: 'off',
          })
        }),
      )
    })

    it('shows a toggle in the "on" position', () => {
      const {getByRole} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      expect(toggle).toBeChecked()
    })

    it('makes an API call to turn off HCM if the toggle is clicked and shows a spinner', async () => {
      const {getByRole} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      expect(capturedRequests).toHaveLength(1)
      expect(capturedRequests[0]).toMatchObject({
        feature: 'high_contrast',
        state: 'off',
      })
    })

    it('shows the explainer after a successful return, and flips the toggle off', async () => {
      const {getByRole, findByText} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      await findByText(/reload the page or navigate/i)
      expect(toggle).not.toBeChecked()
      expect(window.ENV.use_high_contrast).toBe(false)
    })
  })

  describe('sad path', () => {
    beforeEach(() => {
      fakeENV.setup({
        current_user_id: '1',
        use_high_contrast: false,
      })
      server.use(
        http.put('/api/v1/users/:userId/features/flags/high_contrast', () => {
          return HttpResponse.json({error: 'something terrible happened'}, {status: 400})
        }),
      )
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    })

    afterEach(() => {
      const liveRegion = document.getElementById('flash_screenreader_holder')
      if (liveRegion) {
        liveRegion.remove()
      }
    })

    it('puts up a flash when bad data comes back from the API call', async () => {
      const {getByRole, findByRole} = render(<HighContrastModeToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      await findByRole('alert')
      expect(toggle).not.toBeChecked()
      expect(window.ENV.use_high_contrast).toBe(false)
    })
  })
})
