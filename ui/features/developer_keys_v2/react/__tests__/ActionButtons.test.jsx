/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import ActionButtons from '../ActionButtons'
import {confirmDanger} from '@canvas/instui-bindings/react/Confirm'

vi.mock('@canvas/instui-bindings/react/Confirm')

const defaultProps = ({
  showVisibilityToggle = true,
  visible = true,
  developerKey = {
    id: '1',
    api_key: 'test',
    created_at: 'test',
  },
} = {}) => {
  return {
    dispatch: vi.fn(),
    makeVisibleDeveloperKey: vi.fn(),
    makeInvisibleDeveloperKey: vi.fn(),
    deleteDeveloperKey: vi.fn(),
    editDeveloperKey: vi.fn(),
    developerKeysModalOpen: vi.fn(),
    ltiKeysSetLtiKey: vi.fn(),
    contextId: '2',
    developerKey,
    visible,
    developerName: 'Unnamed Tool',
    onDelete: vi.fn(),
    showVisibilityToggle,
  }
}

const renderActionButtons = props => render(<ActionButtons {...defaultProps(props)} />)

describe('ActionButtons', () => {
  it('renders visibility icon for Site Admin', () => {
    const {getByText} = renderActionButtons()

    expect(getByText('Make key Unnamed Tool invisible')).toBeInTheDocument()
  })

  it('does not render visibility icon for root account', () => {
    const {container} = renderActionButtons({showVisibilityToggle: false})

    expect(container).not.toHaveTextContent('Make key Unnamed Tool invisible')
  })

  it('renders edit button for non lti keys', () => {
    const {container} = renderActionButtons()

    expect(container).toHaveTextContent('Edit key Unnamed Tool')
  })

  it('renders edit button for lti registration keys', () => {
    const {getByText} = renderActionButtons({
      developerKey: {
        id: '1',
        api_key: 'test',
        created_at: 'test',
        is_lti_key: true,
        is_lti_registration: true,
        ltiRegistration: {},
      },
    })
    const editButton = getByText('Edit key Unnamed Tool')

    expect(editButton).toBeInTheDocument()
    expect(editButton.closest('a').href).toContain('/accounts/2/developer_keys/1')
  })

  it('renders edit button for lti keys', () => {
    const {container} = renderActionButtons({
      developerKey: {
        id: '1',
        api_key: 'test',
        created_at: 'test',
        is_lti_key: true,
      },
    })

    expect(container.querySelector('#edit-developer-key-button-1')).toBeInTheDocument()
  })

  it('warns the user when deleting a LTI key', () => {
    confirmDanger.mockImplementation(() => Promise.resolve())

    const {getByText} = renderActionButtons({
      developerKey: {
        id: '1',
        api_key: 'test',
        created_at: 'test',
        is_lti_key: true,
      },
    })

    fireEvent.click(getByText('Delete key Unnamed Tool'))

    expect(confirmDanger).toHaveBeenCalledWith({
      confirmButtonLabel: 'Delete',
      heading: undefined,
      title: 'Delete LTI Developer Key',
      message:
        'Are you sure you want to delete this developer key? This action will also delete all tools associated with the developer key in this context.',
    })
  })

  describe('when devKeysReadOnly is true', () => {
    let originalEnv

    beforeEach(() => {
      originalEnv = window.ENV
      window.ENV = {...originalEnv, devKeysReadOnly: true}
    })

    afterEach(() => {
      window.ENV = originalEnv
    })

    it('disables visibility toggle button', () => {
      const {getByText} = renderActionButtons()
      const visibilityButton = getByText('Make key Unnamed Tool invisible').closest('button')
      expect(visibilityButton).toBeDisabled()
    })

    it('disables delete button', () => {
      const {getByText} = renderActionButtons()
      const deleteButton = getByText(
        'Key Unnamed Tool &mdash; you do not have permission to modify keys in this account',
      ).closest('button')
      expect(deleteButton).toBeDisabled()
    })

    it('shows read-only tooltip for visibility button when key is visible', async () => {
      const user = userEvent.setup()
      const {getByText, findByText} = renderActionButtons({visible: true})
      const visibilityButton = getByText('Make key Unnamed Tool invisible').closest('button')

      await user.hover(visibilityButton)

      await findByText(
        'Key is visible. You do not have permission to modify key visibility in this account',
      )
    })

    it('shows read-only tooltip for visibility button when key is invisible', async () => {
      const user = userEvent.setup()
      const {getByText, findByText} = renderActionButtons({visible: false})
      const visibilityButton = getByText('Make key Unnamed Tool visible').closest('button')

      await user.hover(visibilityButton)

      await findByText(
        'Key is invisible. You do not have permission to modify key visibility in this account',
      )
    })

    it('shows read-only tooltip for delete button', async () => {
      const user = userEvent.setup()
      const {getByText, findByText} = renderActionButtons()
      const deleteButton = getByText(
        'Key Unnamed Tool &mdash; you do not have permission to modify keys in this account',
      ).closest('button')

      await user.hover(deleteButton)

      await findByText('You do not have permission to modify keys in this account')
    })

    it('changes edit button tooltip to view details for non-LTI keys', async () => {
      const user = userEvent.setup()
      const {container, findByText} = renderActionButtons()
      const editButton = container.querySelector('#edit-developer-key-button-1')

      await user.hover(editButton)

      await findByText('View key details')
    })

    it('changes edit button tooltip to view details for LTI registration keys', async () => {
      const user = userEvent.setup()
      const {container, findByText} = renderActionButtons({
        developerKey: {
          id: '1',
          api_key: 'test',
          created_at: 'test',
          is_lti_key: true,
          is_lti_registration: true,
          ltiRegistration: {},
        },
      })
      const editButton = container.querySelector('#edit-developer-key-button-1')

      await user.hover(editButton)

      await findByText('View key details')
    })
  })
})
