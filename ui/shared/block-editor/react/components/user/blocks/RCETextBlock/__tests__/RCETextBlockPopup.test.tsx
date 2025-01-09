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
import {render, screen, waitFor} from '@testing-library/react'
import {RCETextBlockPopup} from '../RCETextBlockPopup'

describe('RCETextBlockPopup', () => {
  beforeEach(() => {
    const div = document.createElement('div')
    div.id = 'flash_screenreader_holder'
    div.setAttribute('role', 'alert')
    document.body.appendChild(div)
  })

  it('renders', async () => {
    render(
      <RCETextBlockPopup
        nodeId="1"
        content="<p>content</p>"
        onClose={() => {}}
        onSave={() => {}}
      />,
    )
    expect(screen.getByText('Edit Text')).toBeInTheDocument()
    expect(screen.getByText('Cancel')).toBeInTheDocument()
    expect(screen.getByText('Save')).toBeInTheDocument()
    const mountNode = document.getElementById('rce-text-block-popup') as HTMLElement
    expect(mountNode).toBeInTheDocument()
    await waitFor(() => {
      expect(mountNode.querySelector('.rce-wrapper')).toBeInTheDocument()
    })
  })

  it('calls onSave with the content', async () => {
    const onSave = jest.fn()
    render(
      <RCETextBlockPopup nodeId="1" content="<p>content</p>" onClose={() => {}} onSave={onSave} />,
    )
    await waitFor(() => {
      expect(document.querySelector('.rce-wrapper')).toBeInTheDocument()
    })
    const saveButton = screen.getByText('Save')
    saveButton.click()
    await waitFor(() => {
      expect(onSave).toHaveBeenCalledWith('<p>content</p>')
    })
  })

  it('calls onClose when cancel is clicked', async () => {
    const onClose = jest.fn()
    render(
      <RCETextBlockPopup nodeId="1" content="<p>content</p>" onClose={onClose} onSave={() => {}} />,
    )
    const cancelButton = screen.getByText('Cancel')
    cancelButton.click()
    expect(onClose).toHaveBeenCalled()
  })

  it('fires the close event when the modal is closed', async () => {
    const handleClose = jest.fn()
    render(
      <RCETextBlockPopup
        nodeId="1"
        content="<p>content</p>"
        onClose={() => {}}
        onSave={() => {}}
      />,
    )
    document.addEventListener('rce-text-block-popup-close', handleClose)
    const cancelButton = screen.getByText('Cancel')
    cancelButton.click()
    expect(handleClose).toHaveBeenCalled()
  })

  it('toggles the fullscreen button', async () => {
    // we can't test fullscreen since tinymce is never actually rendered
    render(
      <RCETextBlockPopup
        nodeId="1"
        content="<p>content</p>"
        onClose={() => {}}
        onSave={() => {}}
      />,
    )
    await waitFor(() => {
      expect(document.querySelector('.rce-wrapper')).toBeInTheDocument()
    })

    const fullscreenButton = screen
      .getByTestId('rce-fullscreen-btn')
      .closest('button') as HTMLButtonElement
    expect(fullscreenButton.textContent).toEqual('Fullscreen')
    fullscreenButton.click()
    expect(fullscreenButton.textContent).toEqual('Exit Fullscreen')
  })
})
