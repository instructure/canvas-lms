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
import userEvent from '@testing-library/user-event'
import {ConfigureModal} from '../ConfigureModal'
import {fetchDiscoveryConfig, saveDiscoveryConfig} from '../../api'
import {confirm} from '@canvas/instui-bindings/react/Confirm'

vi.mock('../../api', async importOriginal => {
  const original = await importOriginal<typeof import('../../api')>()
  return {
    ...original,
    fetchDiscoveryConfig: vi.fn(),
    saveDiscoveryConfig: vi.fn().mockResolvedValue({discovery_page: {primary: [], secondary: []}}),
    fetchPreviewToken: vi.fn().mockResolvedValue('test-token'),
  }
})

vi.mock('@canvas/instui-bindings/react/Confirm', () => ({
  confirm: vi.fn(),
}))

const mockedFetch = vi.mocked(fetchDiscoveryConfig)
const mockedSave = vi.mocked(saveDiscoveryConfig)
const mockedConfirm = vi.mocked(confirm)

describe('ConfigureModal', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('discovery page status', () => {
    beforeEach(() => {
      window.ENV = {...window.ENV, auth_providers: [], discovery_page_url: undefined}
    })

    it('shows no status pill while loading', () => {
      mockedFetch.mockReturnValue(new Promise(() => {})) // never resolves
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      expect(screen.queryByText('Enabled')).not.toBeInTheDocument()
      expect(screen.queryByText('Disabled')).not.toBeInTheDocument()
    })

    it('shows “Enabled” pill when config returns active: true', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: [], secondary: [], active: true}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('Enabled')
      expect(screen.queryByText('Disabled')).not.toBeInTheDocument()
    })

    it('shows “Disabled” pill when config returns active: false', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: [], secondary: [], active: false}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('Disabled')
      expect(screen.queryByText('Enabled')).not.toBeInTheDocument()
    })

    it('shows “View Discovery Page” link when discovery_page_url is set', async () => {
      window.ENV = {
        ...window.ENV,
        auth_providers: [],
        discovery_page_url: 'https://example.com/discovery',
      }
      mockedFetch.mockResolvedValue({discovery_page: {primary: [], secondary: [], active: true}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('View Discovery Page')
    })

    it('does not show “View Discovery Page” link when discovery_page_url is not set', async () => {
      mockedFetch.mockResolvedValue({discovery_page: {primary: [], secondary: [], active: true}})
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await screen.findByText('Enabled')
      expect(screen.queryByText('View Discovery Page')).not.toBeInTheDocument()
    })
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

  describe('save confirmation', () => {
    const oneProvider = [{authentication_provider_id: 1, label: 'SSO'}]

    beforeEach(() => {
      window.ENV = {
        ...window.ENV,
        auth_providers: [{id: '1', url: '', auth_type: 'saml'}],
        discovery_page_url: undefined,
      }
    })

    async function makeDirtyAndSave(user: ReturnType<typeof userEvent.setup>) {
      // wait for loading to finish and card to render
      const deleteLabel = await screen.findByText('Delete item')
      await user.click(deleteLabel.closest('button')!)
      // save should now be enabled
      await user.click(screen.getByTestId('save-button'))
    }

    it('shows confirmation when saving with active: true and user confirms', async () => {
      const user = userEvent.setup()
      mockedConfirm.mockResolvedValue(true)
      mockedFetch.mockResolvedValue({
        discovery_page: {primary: oneProvider, secondary: [], active: true},
      })
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await makeDirtyAndSave(user)
      expect(mockedConfirm).toHaveBeenCalledWith(
        expect.objectContaining({title: 'Save Discovery Page'}),
      )
      expect(mockedSave).toHaveBeenCalled()
    })

    it('does not save when user cancels the confirmation', async () => {
      const user = userEvent.setup()
      mockedConfirm.mockResolvedValue(false)
      mockedFetch.mockResolvedValue({
        discovery_page: {primary: oneProvider, secondary: [], active: true},
      })
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await makeDirtyAndSave(user)
      expect(mockedConfirm).toHaveBeenCalled()
      expect(mockedSave).not.toHaveBeenCalled()
    })

    it('saves without confirmation when active is false', async () => {
      const user = userEvent.setup()
      mockedFetch.mockResolvedValue({
        discovery_page: {primary: oneProvider, secondary: [], active: false},
      })
      render(<ConfigureModal open={true} onClose={vi.fn()} />)
      await makeDirtyAndSave(user)
      expect(mockedConfirm).not.toHaveBeenCalled()
      expect(mockedSave).toHaveBeenCalled()
    })
  })

  describe('exit confirmation', () => {
    const oneProvider = [{authentication_provider_id: 1, label: 'SSO'}]

    beforeEach(() => {
      window.ENV = {
        ...window.ENV,
        auth_providers: [{id: '1', url: '', auth_type: 'saml'}],
        discovery_page_url: undefined,
      }
    })

    it('closes without confirmation when there are no unsaved changes', async () => {
      const user = userEvent.setup()
      mockedFetch.mockResolvedValue({discovery_page: {primary: [], secondary: []}})
      const onClose = vi.fn()
      render(<ConfigureModal open={true} onClose={onClose} />)
      await screen.findByText('0/10 sign-in options added.')
      await user.click(screen.getByTestId('close-button'))
      expect(mockedConfirm).not.toHaveBeenCalled()
      expect(onClose).toHaveBeenCalled()
    })

    it('shows confirmation when closing with unsaved changes and user confirms', async () => {
      const user = userEvent.setup()
      mockedConfirm.mockResolvedValue(true)
      mockedFetch.mockResolvedValue({discovery_page: {primary: oneProvider, secondary: []}})
      const onClose = vi.fn()
      render(<ConfigureModal open={true} onClose={onClose} />)
      const deleteLabel = await screen.findByText('Delete item')
      await user.click(deleteLabel.closest('button')!)
      await user.click(screen.getByTestId('close-button'))
      expect(mockedConfirm).toHaveBeenCalledWith(
        expect.objectContaining({title: 'Unsaved Changes'}),
      )
      expect(onClose).toHaveBeenCalled()
    })

    it('does not close when user cancels the exit confirmation', async () => {
      const user = userEvent.setup()
      mockedConfirm.mockResolvedValue(false)
      mockedFetch.mockResolvedValue({discovery_page: {primary: oneProvider, secondary: []}})
      const onClose = vi.fn()
      render(<ConfigureModal open={true} onClose={onClose} />)
      const deleteLabel = await screen.findByText('Delete item')
      await user.click(deleteLabel.closest('button')!)
      await user.click(screen.getByTestId('close-button'))
      expect(mockedConfirm).toHaveBeenCalled()
      expect(onClose).not.toHaveBeenCalled()
    })
  })
})
