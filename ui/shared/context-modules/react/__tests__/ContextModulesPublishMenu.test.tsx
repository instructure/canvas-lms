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
import {act, render, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import ContextModulesPublishMenu from '../ContextModulesPublishMenu'

jest.mock('@canvas/do-fetch-api-effect')

const defaultProps = {
  courseId: '1',
  disabled: false,
  runningProgressId: null,
}

describe('ContextModulesPublishMenu', () => {
  afterEach(() => {
    jest.clearAllMocks()
    doFetchApi.mockReset()
    document.body.innerHTML = ''
  })

  it('renders the menu when clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    expect(getByText('Publish all modules and items')).toBeInTheDocument()
    expect(getByText('Publish modules only')).toBeInTheDocument()
    expect(getByText('Unpublish all modules and items')).toBeInTheDocument()
  })

  it('calls publishAll when clicked publish all menu item is clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    const publishButton = getByText('Publish all modules and items')
    act(() => publishButton.click())
    const modalTitle = getByRole('heading', {name: 'Publish all modules and items'})
    expect(modalTitle).toBeInTheDocument()
  })

  it('calls publishModuleOnly when clicked publish module menu item is clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    const publishButton = getByText('Publish modules only')
    act(() => publishButton.click())
    const modalTitle = getByRole('heading', {name: 'Publish modules only'})
    expect(modalTitle).toBeInTheDocument()
  })

  it('calls unpublishAll when clicked unpublish all items is clicked', () => {
    const {getByRole, getByText} = render(<ContextModulesPublishMenu {...defaultProps} />)
    const menuButton = getByRole('button')
    act(() => menuButton.click())
    const publishButton = getByText('Unpublish all modules and items')
    act(() => publishButton.click())
    const modalTitle = getByRole('heading', {name: 'Unpublish all modules and items'})
    expect(modalTitle).toBeInTheDocument()
  })

  it('is disabled when disabled prop is true', () => {
    const {getByRole} = render(<ContextModulesPublishMenu {...defaultProps} disabled={true} />)
    const menuButton = getByRole('button')
    expect(menuButton).toBeDisabled()
  })

  describe('error handling', () => {
    it('shows alert on successful publish', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: {
          progress: {
            progress: {
              id: 1234,
            },
          },
        },
      })
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'completed',
          url: '/api/v1/progress/3533',
        },
      })
      doFetchApi.mockResolvedValue({response: {ok: true}, json: [], link: null})

      const {getByRole, getByText, getAllByText} = render(
        <ContextModulesPublishMenu {...defaultProps} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Publish all modules and items')
      act(() => publishButton.click())
      const continueButton = getByText('Continue')
      act(() => continueButton.click())
      await waitFor(() => expect(getAllByText('Modules updated')).toHaveLength(2))
    })

    it('shows alert on failed publish', async () => {
      const whoops = new Error('whoops')
      doFetchApi.mockRejectedValueOnce(whoops)

      const {getByRole, getByText, getAllByText} = render(
        <ContextModulesPublishMenu {...defaultProps} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Publish all modules and items')
      act(() => publishButton.click())
      const continueButton = getByText('Continue')
      act(() => continueButton.click())
      await waitFor(() =>
        expect(getAllByText('There was an error while saving your changes')).toHaveLength(2)
      )
    })

    it('shows alert on failed poll for progress', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: {
          progress: {
            progress: {
              id: 1234,
            },
          },
        },
      })
      doFetchApi.mockRejectedValueOnce(new Error('whoops'))

      const {getByRole, getByText, getAllByText} = render(
        <ContextModulesPublishMenu {...defaultProps} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Publish all modules and items')
      act(() => publishButton.click())
      const continueButton = getByText('Continue')
      act(() => continueButton.click())
      await waitFor(() =>
        expect(
          getAllByText(
            "Something went wrong monitoring the work's progress. Try refreshing the page."
          )
        ).toHaveLength(2)
      )
    })

    it('shows alert when failing to update results', async () => {
      doFetchApi.mockResolvedValueOnce({
        json: {
          progress: {
            progress: {
              id: 1234,
            },
          },
        },
      })
      doFetchApi.mockResolvedValueOnce({
        json: {
          id: '3533',
          workflow_state: 'completed',
          url: '/api/v1/progress/3533',
        },
      })
      doFetchApi.mockRejectedValue(new Error('whoops'))

      const {getByRole, getByText, getAllByText} = render(
        <ContextModulesPublishMenu {...defaultProps} />
      )
      const menuButton = getByRole('button')
      act(() => menuButton.click())
      const publishButton = getByText('Publish all modules and items')
      act(() => publishButton.click())
      const continueButton = getByText('Continue')
      act(() => continueButton.click())
      await waitFor(() =>
        expect(
          getAllByText(
            'There was an error updating module and items publish status. Try refreshing the page.'
          )
        ).toHaveLength(2)
      )
    })
  })
})
