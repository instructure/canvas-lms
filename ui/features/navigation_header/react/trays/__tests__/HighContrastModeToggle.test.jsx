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
import {getByText} from '@testing-library/dom'
import {render, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import Subject from '../HighContrastModeToggle'

const USER_ID = 100
const route = `api/v1/users/${USER_ID}/features/flags/high_contrast`

describe('HighContrastModeToggle', () => {
  beforeEach(() => {
    ENV.current_user_id = USER_ID
  })

  describe('when HCM is off', () => {
    const goodResponseOn = {
      feature: 'high_contrast',
      state: 'on',
    }

    beforeEach(() => {
      ENV.use_high_contrast = false
      fetchMock.put(route, goodResponseOn, {overwriteRoutes: true})
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('shows a toggle in the "off" position', () => {
      const {container} = render(<Subject />)
      const toggle = container.querySelector('input')
      expect(toggle.checked).toBe(false)
    })

    it('makes an API call to turn on HCM if the toggle is clicked and shows a spinner', async () => {
      const {container, findByTestId} = render(<Subject />)
      const toggle = container.querySelector('input')
      fireEvent.click(toggle)
      await findByTestId('hcm-change-spinner')
      expect(fetchMock.calls(route)).toHaveLength(1)
      const response = JSON.parse(fetchMock.calls(route)[0][1].body)
      expect(response).toMatchObject({
        feature: 'high_contrast',
        state: 'on',
      })
    })

    it('shows the explainer after a successful return, and flips the toggle on', async () => {
      const {container, findByText} = render(<Subject />)
      const toggle = container.querySelector('input')
      fireEvent.click(toggle)
      await findByText(/reload the page or navigate/i)
      expect(toggle.checked).toBe(true)
      expect(ENV.use_high_contrast).toBe(true)
    })
  })

  describe('when HCM is on', () => {
    const goodResponseOff = {
      feature: 'high_contrast',
      state: 'off',
    }

    beforeEach(() => {
      ENV.use_high_contrast = true
      fetchMock.put(route, goodResponseOff, {overwriteRoutes: true})
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('shows a toggle in the "on" position', () => {
      const {container} = render(<Subject />)
      const toggle = container.querySelector('input')
      expect(toggle.checked).toBe(true)
    })

    it('makes an API call to turn off HCM if the toggle is clicked and shows a spinner', async () => {
      const {container, findByTestId} = render(<Subject />)
      const toggle = container.querySelector('input')
      fireEvent.click(toggle)
      await findByTestId('hcm-change-spinner')
      expect(fetchMock.calls(route)).toHaveLength(1)
      const response = JSON.parse(fetchMock.calls(route)[0][1].body)
      expect(response).toMatchObject({
        feature: 'high_contrast',
        state: 'off',
      })
    })

    it('shows the explainer after a successful return, and flips the toggle off', async () => {
      const {container, findByText} = render(<Subject />)
      const toggle = container.querySelector('input')
      fireEvent.click(toggle)
      await findByText(/reload the page or navigate/i)
      expect(toggle.checked).toBe(false)
      expect(ENV.use_high_contrast).toBe(false)
    })
  })

  describe('sad path', () => {
    let liveRegion
    const badResponse = {
      feature: 'something_else',
      state: 'who knows?',
    }

    beforeEach(() => {
      ENV.use_high_contrast = false
      fetchMock.put(route, badResponse, {overwriteRoutes: true})
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    })

    afterEach(() => {
      fetchMock.restore()
      liveRegion.remove()
      liveRegion = undefined
    })

    it('puts up a flash when bad data comes back from the API call', async () => {
      const {container, findByTestId} = render(<Subject />)
      const toggle = container.querySelector('input')
      fireEvent.click(toggle)
      await findByTestId('hcm-change-spinner')
      expect(getByText(liveRegion, /error occurred while trying to change/i)).toBeInTheDocument()
      expect(getByText(liveRegion, /unexpected response from api call/i)).toBeInTheDocument()
    })
  })
})
