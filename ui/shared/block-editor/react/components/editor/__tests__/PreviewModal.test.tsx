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
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Editor} from '@craftjs/core'
import {PreviewModal} from '../PreviewModal'

const user = userEvent.setup()

describe('PreviewModal', () => {
  it('renders', () => {
    const {getAllByText, getByText, getByLabelText} = render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />)
      </Editor>
    )

    expect(getByText('Preview')).toBeInTheDocument()
    expect(getAllByText('View Size')).toHaveLength(2)
    expect(getByLabelText('Desktop')).toBeInTheDocument()
    expect(getByLabelText('Tablet')).toBeInTheDocument()
    expect(getByLabelText('Mobile')).toBeInTheDocument()
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('defaults to Desktop size', () => {
    render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />
      </Editor>
    )

    expect(screen.getByLabelText('Desktop')).toBeChecked()
    const view = document.querySelector('.block-editor-view.desktop')
    expect(view).toBeInTheDocument()
    expect(view).toHaveStyle({width: '1026px'})
  })

  it('renders Tablet size', async () => {
    render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />)
      </Editor>
    )

    user.click(screen.getByLabelText('Tablet'))
    const tablet = screen.getByLabelText('Tablet')
    expect(tablet).toBeInTheDocument()

    await user.click(tablet)

    const view = document.querySelector('.block-editor-view.tablet')
    expect(view).toBeInTheDocument()
    expect(view).toHaveStyle({width: '768px'})
  })

  it('renders Mobile size', async () => {
    render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />)
      </Editor>
    )

    user.click(screen.getByLabelText('Mobile'))
    const mobile = screen.getByLabelText('Mobile')
    expect(mobile).toBeInTheDocument()

    await user.click(mobile)

    const view = document.querySelector('.block-editor-view.mobile')
    expect(view).toBeInTheDocument()
    expect(view).toHaveStyle({width: '320px'})
  })

  it('calls onDismiss on Escape key', async () => {
    const onDismiss = jest.fn()
    render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={onDismiss} />)
      </Editor>
    )

    fireEvent.keyDown(document.activeElement as HTMLElement, {key: 'Escape'})

    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls OnDismiss on Close button click', async () => {
    const onDismiss = jest.fn()
    render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={onDismiss} />)
      </Editor>
    )

    const closeButton = screen.getByText('Close').closest('button ') as HTMLButtonElement
    expect(closeButton).toBeInTheDocument()

    await user.click(closeButton)

    expect(onDismiss).toHaveBeenCalled()
  })
})
