/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import React, {createRef} from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigurationFormUrl from '../configuration_forms/ConfigurationFormUrl'

describe('ConfigurationFormUrl', () => {
  const props = (overrides?: any) => ({
    name: '',
    consumerKey: '',
    sharedSecret: '',
    configUrl: '',
    allowMembershipServiceAccess: false,
    verifyUniqueness: true,
    ...overrides,
  })

  const renderComponent = (overrides?: any) => {
    render(<ConfigurationFormUrl {...props(overrides)} />)
  }

  describe('isValid', () => {
    it('returns true when only required fields are input', async () => {
      const ref = createRef<ConfigurationFormUrl>()
      renderComponent({ref})
      await userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      await userEvent.type(screen.getByLabelText('Config URL *'), 'https://example.com')
      expect(ref.current!.isValid()).toEqual(true)
    })

    it('returns false when Name is missing', () => {
      const ref = createRef<ConfigurationFormUrl>()
      renderComponent({ref})
      userEvent.type(screen.getByLabelText('Config URL *'), 'https://example.com')
      expect(ref.current!.isValid()).toEqual(false)
    })

    it('returns false when Config URL is missing', () => {
      const ref = createRef<ConfigurationFormUrl>()
      renderComponent({ref})
      userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      expect(ref.current!.isValid()).toEqual(false)
    })

    it('returns false when Config URL is not a valid url', () => {
      const ref = createRef<ConfigurationFormUrl>()
      renderComponent({ref})
      userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      userEvent.type(screen.getByLabelText('Config URL *'), 'example.com')
      expect(ref.current!.isValid()).toEqual(false)
    })
  })
})
