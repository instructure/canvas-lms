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
import {fireEvent, render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Editor} from '@craftjs/core'
import {PreviewModal, getViewWidth} from '../PreviewModal'

const user = userEvent.setup()

describe('PreviewModal', () => {
  it('renders', () => {
    const {getByText} = render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />)
      </Editor>,
    )
    expect(getByText('Preview')).toBeInTheDocument()
    expect(getByText('Desktop')).toBeInTheDocument()
    expect(getByText('Tablet')).toBeInTheDocument()
    expect(getByText('Mobile')).toBeInTheDocument()
    expect(getByText('Close')).toBeInTheDocument()
  })

  it('defaults to Desktop size', () => {
    const {getByText} = render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />
      </Editor>,
    )

    expect(getByText('Desktop').closest('button')).toHaveAttribute('aria-current', 'true')
    const view = document.querySelector('.block-editor-previewview.desktop')
    expect(view).toBeInTheDocument()
    expect(view).toHaveStyle({width: getViewWidth('desktop')})
  })

  it('renders Tablet size', () => {
    const {getByText} = render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />)
      </Editor>,
    )

    const tabletButton = getByText('Tablet').closest('button') as HTMLButtonElement
    expect(tabletButton).toBeInTheDocument()
    tabletButton.click()

    expect(tabletButton).toHaveAttribute('aria-current', 'true')
    const view = document.querySelector('.block-editor-previewview.tablet')
    expect(view).toBeInTheDocument()
    expect(view).toHaveStyle({width: getViewWidth('tablet')})
  })

  it('renders Mobile size', async () => {
    const {getByText} = render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={() => {}} />)
      </Editor>,
    )

    const mobileButton = getByText('Mobile').closest('button') as HTMLButtonElement
    expect(mobileButton).toBeInTheDocument()
    mobileButton.click()

    expect(mobileButton).toHaveAttribute('aria-current', 'true')
    const view = document.querySelector('.block-editor-previewview.mobile')
    expect(view).toBeInTheDocument()
    expect(view).toHaveStyle({width: getViewWidth('mobile')})
  })

  it('calls onDismiss on Escape key', async () => {
    const onDismiss = jest.fn()
    render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={onDismiss} />)
      </Editor>,
    )

    fireEvent.keyDown(document.activeElement as HTMLElement, {key: 'Escape'})

    expect(onDismiss).toHaveBeenCalled()
  })

  it('calls OnDismiss on Close button click', async () => {
    const onDismiss = jest.fn()
    const {getByText} = render(
      <Editor enabled={false}>
        <PreviewModal open={true} onDismiss={onDismiss} />)
      </Editor>,
    )

    const closeButton = getByText('Close').closest('button ') as HTMLButtonElement
    expect(closeButton).toBeInTheDocument()

    await user.click(closeButton)

    expect(onDismiss).toHaveBeenCalled()
  })
})
