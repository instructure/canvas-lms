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

import React from 'react'
import {render, screen} from '@testing-library/react'
import PublishIconButton from '../PublishIconButton'

let defaultProps: any
describe('PublishIconButton', () => {
  beforeEach(() => {
    defaultProps = {
      item: {
        id: '1',
        folder_id: '1',
        display_name: 'file',
        filename: 'file',
        upload_status: 'success',
        'content-type': 'file',
        url: 'https://example.com/file',
        size: 1000,
        created_at: '2024-01-01T00:00:00Z',
        updated_at: '2024-01-01T00:00:00Z',
        unlock_at: null,
        locked: false,
        hidden: false,
        lock_at: null,
        hidden_for_user: false,
        thumbnail_url: null,
        modified_at: '2024-01-01T00:00:00Z',
        mime_class: 'file',
        media_entry_id: null,
        category: 'file',
        locked_for_user: false,
        visibility_level: 'file',
        preview_url: 'https://example.com/file',
      },
      userCanRestrictFilesForContext: true,
    }
  })

  it('renders published icon when item is published', () => {
    render(<PublishIconButton {...defaultProps} />)
    expect(screen.getByText('Published')).toBeInTheDocument()
  })

  it('renders unpublished icon when item is not published', () => {
    defaultProps.item.locked = true
    render(<PublishIconButton {...defaultProps} />)
    expect(screen.getByText('Unpublished')).toBeInTheDocument()
  })

  it('renders restricted icon when item is published and restricted', () => {
    defaultProps.item.lock_at = '2024-12-31T23:59:59Z'
    render(<PublishIconButton {...defaultProps} />)
    const tooltip = screen.getByRole('tooltip')
    expect(tooltip).toHaveTextContent(/Available until .* at \d{1,2}:\d{2}(am|pm)/i)
  })

  it('renders hidden icon when item is published and hidden', () => {
    defaultProps.item.hidden = true
    render(<PublishIconButton {...defaultProps} />)
    expect(screen.getByText('Only available to students with link')).toBeInTheDocument()
  })

  it('renders restricted icon when user cannot edit and item is restricted', () => {
    defaultProps.userCanRestrictFilesForContext = false
    defaultProps.item.lock_at = '2024-12-31T23:59:59Z'
    render(<PublishIconButton {...defaultProps} />)
    const tooltip = screen.getByRole('tooltip')
    expect(tooltip).toHaveTextContent(/Available until .* at \d{1,2}:\d{2}(am|pm)/i)
    expect(screen.queryByRole('button')).not.toBeInTheDocument()
  })

  it('renders nothing when user cannot edit and item is not restricted', () => {
    defaultProps.userCanRestrictFilesForContext = false
    const {container} = render(<PublishIconButton {...defaultProps} />)
    expect(container).toBeEmptyDOMElement()
  })
})
