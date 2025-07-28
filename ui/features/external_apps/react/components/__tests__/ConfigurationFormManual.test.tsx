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
import ConfigurationFormManual from '../configuration_forms/ConfigurationFormManual'

describe('ConfigurationFormManual', () => {
  const props = (overrides?: any) => ({
    name: '',
    url: '',
    domain: '',
    membershipServiceFeatureFlagEnabled: true,
    ...overrides,
  })

  const renderComponent = (overrides?: any) => {
    render(<ConfigurationFormManual {...props(overrides)} />)
  }

  describe('isValid', () => {
    it('returns true when valid', async () => {
      const ref = createRef<ConfigurationFormManual>()
      renderComponent({ref})
      await userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      await userEvent.type(screen.getByLabelText('Launch URL *'), 'https://example.com')
      expect(ref.current!.isValid()).toEqual(true)
    })

    it('returns true with only name and domain', async () => {
      const ref = createRef<ConfigurationFormManual>()
      renderComponent({ref})
      await userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      await userEvent.type(screen.getByLabelText('Domain'), 'example.com')
      expect(ref.current!.isValid()).toEqual(true)
    })

    it('returns true with only name and url', async () => {
      const ref = createRef<ConfigurationFormManual>()
      renderComponent({ref})
      await userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      await userEvent.type(screen.getByLabelText('Launch URL *'), 'https://example.com')
      expect(ref.current!.isValid()).toEqual(true)
    })

    it('returns false with missing required fields', () => {
      const ref = createRef<ConfigurationFormManual>()
      renderComponent({ref})
      expect(ref.current!.isValid()).toEqual(false)
    })

    it('returns false with invalid launch url', async () => {
      const ref = createRef<ConfigurationFormManual>()
      renderComponent({ref})
      await userEvent.type(screen.getByLabelText('Name *'), 'Test App')
      await userEvent.type(screen.getByLabelText('Launch URL *'), 'example.com')
      expect(ref.current!.isValid()).toEqual(false)
    })
  })

  describe('customFieldsToMultiline', () => {
    it('splits the fields appropriately', () => {
      const fields = {
        foo: 'bar',
        baz: 'fizzbuzz',
        user_id: '$Canvas.user.id',
        resource_link_id: '$ResourceLink.id',
      }

      const expected = `\
foo=bar
baz=fizzbuzz
user_id=$Canvas.user.id
resource_link_id=$ResourceLink.id`

      expect(ConfigurationFormManual.customFieldsToMultiLine(fields)).toEqual(expected)
    })
  })
})
