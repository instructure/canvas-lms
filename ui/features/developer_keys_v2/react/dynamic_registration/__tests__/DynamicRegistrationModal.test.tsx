/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import React from 'react'

import {DynamicRegistrationModal} from '../DynamicRegistrationModal'
import {useDynamicRegistrationState} from '../DynamicRegistrationState'

describe('DynamicRegistrationModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal
    error = console.error
    warn = console.warn

    console.error = jest.fn()
    console.warn = jest.fn()

    // const node = document.createElement('div')
    // document.body.appendChild(node)
  })

  afterAll(() => {
    console.error = error
    console.warn = warn
  })

  describe('default export', () => {
    const store = {
      dispatch: jest.fn(),
    }
    it('opens the modal', async () => {
      useDynamicRegistrationState.getState().open()
      const component = render(<DynamicRegistrationModal contextId="1" store={store as any} />)
      const urlInput = await component.findByTestId('dynamic-reg-modal-url-input')
      expect(urlInput).toBeInTheDocument()
    })

    it('forwards users to the tool', async () => {
      useDynamicRegistrationState.getState().register('http://localhost', () => {})
      const component = render(<DynamicRegistrationModal contextId="1" store={store as any} />)
      const iframe = await component.findByTestId('dynamic-reg-modal-iframe')
      expect(iframe).toBeInTheDocument()
      expect(iframe).toHaveAttribute('src', '/api/lti/register?registration_url=http://localhost')
    })
  })
})
