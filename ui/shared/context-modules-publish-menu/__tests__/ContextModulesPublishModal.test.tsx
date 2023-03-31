/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import ContextModulesPublishModal from '../ContextModulesPublishModal'

jest.mock('@canvas/do-fetch-api-effect')

const defaultProps = {
  isOpen: true,
  onClose: () => {},
  onPublish: () => {},
  onPublishComplete: () => {},
  progressId: null,
  publishItems: false,
  title: 'Test Title',
}

beforeAll(() => {
  doFetchApi.mockResolvedValue({response: {ok: true}, json: {completed: []}})
})

beforeEach(() => {
  doFetchApi.mockClear()
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('ContextModulesPublishModal', () => {
  it('renders the title', () => {
    const {getByRole} = render(<ContextModulesPublishModal {...defaultProps} />)
    const modalTitle = getByRole('heading', {name: 'Test Title'})
    expect(modalTitle).toBeInTheDocument()
  })

  it('calls onPublish when the publish button is clicked', () => {
    const onPublish = jest.fn()
    const {getByText} = render(
      <ContextModulesPublishModal {...defaultProps} onPublish={onPublish} />
    )
    const publishButton = getByText('Continue')
    act(() => publishButton.click())
    expect(onPublish).toHaveBeenCalled()
  })

  it('has a close button', () => {
    const onClose = jest.fn()
    const {getByTestId} = render(<ContextModulesPublishModal {...defaultProps} onClose={onClose} />)
    const closeButton = getByTestId('close-button')
    act(() => closeButton.click())
    expect(onClose).toHaveBeenCalled()
  })

  it('changes the publish button to stop button if there is a progressId', () => {
    const onPublish = jest.fn()
    const {getByTestId} = render(
      <ContextModulesPublishModal {...defaultProps} onPublish={onPublish} />
    )
    const publishButton = getByTestId('publish-button')
    expect(publishButton.textContent).toBe('Continue')
    act(() => publishButton.click())
    expect(onPublish).toHaveBeenCalled()
    expect(publishButton.textContent).toBe('Stop')
  })

  it('disables the stop button if canceling', () => {
    const {getByTestId} = render(<ContextModulesPublishModal {...defaultProps} />)
    const publishButton = getByTestId('publish-button')
    act(() => publishButton.click())
    expect(publishButton.textContent).toBe('Stop')
    expect(publishButton).not.toBeDisabled()
    act(() => publishButton.click())
    expect(publishButton.textContent).toBe('Stop')
    expect(publishButton).toBeDisabled()
  })
})
