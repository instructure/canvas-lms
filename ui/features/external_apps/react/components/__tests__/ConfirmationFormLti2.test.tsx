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
import React, {createRef} from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ConfigurationFormLti2 from '../configuration_forms/ConfigurationFormLti2'

// Mock jQuery and its flashError function
jest.mock('jquery', () => {
  const mockJQuery = () => ({
    // Add any jQuery methods used in the component
  })
  mockJQuery.flashError = jest.fn()
  return mockJQuery
})

describe('ConfigurationFormLti2', () => {
  const props = (overrides?: any) => ({
    registrationUrl: '',
    ...overrides,
  })

  const renderComponent = (overrides?: any) => {
    render(<ConfigurationFormLti2 {...props(overrides)} />)
  }

  describe('isValid', () => {
    it('returns true when only required fields are input', async () => {
      const ref = createRef<ConfigurationFormLti2>()
      renderComponent({ref})
      await userEvent.type(screen.getByLabelText('Registration URL *'), 'https://example.com')
      expect(ref.current!.isValid()).toEqual(true)
    })

    it('returns false when Registration URL is missing', async () => {
      const ref = createRef<ConfigurationFormLti2>()
      renderComponent({ref})
      expect(ref.current!.isValid()).toEqual(false)
    })
  })
})
