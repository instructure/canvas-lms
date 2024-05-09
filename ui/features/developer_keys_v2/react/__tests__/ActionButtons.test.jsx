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
import {render, fireEvent} from '@testing-library/react'
import ActionButtons from '../ActionButtons'

const defaultProps = ({
  showVisibilityToggle = true,
  developerKey = {
    id: '1',
    api_key: 'test',
    created_at: 'test',
  },
} = {}) => {
  return {
    dispatch: jest.fn(),
    makeVisibleDeveloperKey: jest.fn(),
    makeInvisibleDeveloperKey: jest.fn(),
    deleteDeveloperKey: jest.fn(),
    editDeveloperKey: jest.fn(),
    developerKeysModalOpen: jest.fn(),
    ltiKeysSetLtiKey: jest.fn(),
    contextId: '2',
    developerKey,
    visible: true,
    developerName: 'Unnamed Tool',
    onDelete: jest.fn(),
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

    expect(container.querySelector('#edit-developer-key-button')).toBeInTheDocument()
  })

  it('warns the user when deleting a LTI key', () => {
    const oldConfirm = window.confirm
    window.confirm = jest.fn()

    const {getByText} = renderActionButtons({
      developerKey: {
        id: '1',
        api_key: 'test',
        created_at: 'test',
        is_lti_key: true,
      },
    })

    fireEvent.click(getByText('Delete key Unnamed Tool'))

    expect(window.confirm).toHaveBeenCalledWith(
      'Are you sure you want to delete this developer key? This action will also delete all tools associated with the developer key in this context.'
    )

    window.confirm = oldConfirm
  })
})
