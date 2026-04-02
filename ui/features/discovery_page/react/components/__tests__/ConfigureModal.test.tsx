/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {ConfigureModal} from '../ConfigureModal'
import {fetchDiscoveryConfig} from '../../api'

vi.mock('../../api', async importOriginal => {
  const original = await importOriginal<typeof import('../../api')>()
  return {
    ...original,
    fetchDiscoveryConfig: vi.fn(),
    saveDiscoveryConfig: vi.fn().mockResolvedValue({discovery_page: {primary: [], secondary: []}}),
    fetchPreviewToken: vi.fn().mockResolvedValue('test-token'),
  }
})

const mockedFetch = vi.mocked(fetchDiscoveryConfig)

describe('ConfigureModal', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('item limit counter', () => {
    const fiveSignInOptions = [
      {authentication_provider_id: 1, label: 'Provider'},
      {authentication_provider_id: 2, label: 'Provider'},
      {authentication_provider_id: 3, label: 'Provider'},
      {authentication_provider_id: 4, label: 'Provider'},
      {authentication_provider_id: 5, label: 'Provider'},
    ]

    const tenSignInOptions = [
      {authentication_provider_id: 1, label: 'Provider'},
      {authentication_provider_id: 2, label: 'Provider'},
      {authentication_provider_id: 3, label: 'Provider'},
      {authentication_provider_id: 4, label: 'Provider'},
      {authentication_provider_id: 5, label: 'Provider'},
      {authentication_provider_id: 6, label: 'Provider'},
      {authentication_provider_id: 7, label: 'Provider'},
      {authentication_provider_id: 8, label: 'Provider'},
      {authentication_provider_id: 9, label: 'Provider'},
      {authentication_provider_id: 10, label: 'Provider'},
    ]

    const elevenSignInOptions = [
      {authentication_provider_id: 1, label: 'Provider'},
      {authentication_provider_id: 2, label: 'Provider'},
      {authentication_provider_id: 3, label: 'Provider'},
      {authentication_provider_id: 4, label: 'Provider'},
      {authentication_provider_id: 5, label: 'Provider'},
      {authentication_provider_id: 6, label: 'Provider'},
      {authentication_provider_id: 7, label: 'Provider'},
      {authentication_provider_id: 8, label: 'Provider'},
      {authentication_provider_id: 9, label: 'Provider'},
      {authentication_provider_id: 10, label: 'Provider'},
      {authentication_provider_id: 11, label: 'Provider'},
    ]

    beforeEach(() => {
      window.ENV = {...window.ENV, auth_providers: [], discovery_page_url: undefined}
    })

    it('shows 0/10 count when there are no committed items', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: [], secondary: []}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('0/10 sign-in options added.')
    })

    it('shows count below the limit', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: fiveSignInOptions, secondary: []}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('5/10 sign-in options added.')
    })

    it('shows limit-reached message at exactly 10 items', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: tenSignInOptions, secondary: []}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('Sign-in options limit reached (10/10).')
    })

    it('disables Add buttons when at the item limit', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: tenSignInOptions, secondary: []}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('Sign-in options limit reached (10/10).')
      // findAllByTestId retries until the loading overlay's focus-trap clears
      // and the modal body content becomes accessible
      const addButtons = await screen.findAllByTestId('add-sign-in-option-button')
      expect(addButtons.length).toBeGreaterThan(0)
      addButtons.forEach(btn => expect(btn).toBeDisabled())
    })

    it('shows limit-exceeded message above 10 items', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: elevenSignInOptions, secondary: []}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText(
        'Sign-in options limit exceeded (11/10). Please remove options to save.',
      )
    })

    it('disables the Save button when over the item limit', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: elevenSignInOptions, secondary: []}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText(
        'Sign-in options limit exceeded (11/10). Please remove options to save.',
      )
      expect(screen.getByTestId('save-button')).toBeDisabled()
    })
  })
})
