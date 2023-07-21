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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import PreviewModal from '../PreviewModal'
import {mockShare} from './test-utils'

describe('content_shares/PreviewModal', () => {
  it('renders an iframe with the appropriate src', () => {
    window.ENV = {COMMON_CARTRIDGE_VIEWER_URL: 'http://example.com'}
    const share = mockShare()
    render(<PreviewModal open={true} share={share} />)
    const iframe = document.querySelector('iframe')
    expect(iframe).toBeInTheDocument()
    expect(iframe.getAttribute('src')).toBe(
      `http://example.com?cartridge=${encodeURIComponent(share.content_export.attachment.url)}`
    )
  })

  it('dismisses the modal', () => {
    const handleDismiss = jest.fn()
    const {getAllByText} = render(<PreviewModal open={true} onDismiss={handleDismiss} />)
    const closeButtons = getAllByText(/close/i)
    closeButtons.forEach(button => fireEvent.click(button))
    expect(handleDismiss).toHaveBeenCalledTimes(closeButtons.length)
  })
})
