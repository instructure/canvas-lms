/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import $ from 'jquery'
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import TermsOfServiceModal from '../TermsOfServiceModal'
import fakeENV from '@canvas/test-utils/fakeENV'
import {openWindow} from '@canvas/util/globalUtils'

jest.mock('@canvas/util/globalUtils', () => {
  const actual = jest.requireActual('@canvas/util/globalUtils')
  return {...actual, openWindow: jest.fn()}
})

const server = setupServer()

interface TermsOfServiceModalProps {
  preview?: boolean
}

const renderTermsOfServiceModal = (props: TermsOfServiceModalProps = {}) =>
  render(<TermsOfServiceModal {...props} />)

describe('TermsOfServiceModal', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    jest.clearAllMocks()
    fakeENV.setup({
      TERMS_OF_SERVICE_CUSTOM_CONTENT: 'Hello World',
    })
    $('#fixtures').html('<div id="main">')
  })

  afterEach(() => {
    server.resetHandlers()
    cleanup()
    $('#fixtures').empty()
    fakeENV.teardown()
  })

  it('renders correct link when preview is provided', () => {
    renderTermsOfServiceModal({preview: true})
    expect(screen.getByText('Preview')).toBeInTheDocument()
  })

  it('renders correct link when preview is not provided', () => {
    renderTermsOfServiceModal()
    expect(screen.getByText('Acceptable Use Policy')).toBeInTheDocument()
  })

  it('opens external url instead of modal when aup returns redirectUrl', async () => {
    server.use(
      http.get('/api/v1/acceptable_use_policy', () =>
        HttpResponse.json({redirectUrl: 'https://example.com/aup'}),
      ),
    )
    const mockOpenWindow = openWindow as unknown as jest.Mock
    renderTermsOfServiceModal()
    screen.getByTestId('tos-link').click()
    // assert window open and no modal
    await waitFor(() =>
      expect(mockOpenWindow).toHaveBeenCalledWith(
        'https://example.com/aup',
        '_blank',
        'noopener,noreferrer',
      ),
    )
    expect(screen.queryByTestId('tos-modal')).toBeNull()
  })

  it('opens modal when aup returns inline content', async () => {
    server.use(
      http.get('/api/v1/acceptable_use_policy', () =>
        HttpResponse.json({content: '<p>Inline AUP</p>'}),
      ),
    )
    const mockOpenWindow = openWindow as unknown as jest.Mock
    renderTermsOfServiceModal()
    screen.getByTestId('tos-link').click()
    // modal should appear
    await waitFor(() => expect(screen.queryByTestId('tos-modal')).not.toBeNull())
    expect(screen.getByText('Inline AUP')).toBeInTheDocument()
    expect(mockOpenWindow).not.toHaveBeenCalled()
  })

  it('reuses cached redirectUrl on subsequent clicks without refetch', async () => {
    let fetchCount = 0
    server.use(
      http.get('/api/v1/acceptable_use_policy', () => {
        fetchCount++
        return HttpResponse.json({redirectUrl: 'https://ex.com/aup'})
      }),
    )
    const mockOpenWindow = openWindow as unknown as jest.Mock
    renderTermsOfServiceModal()
    const link = screen.getByTestId('tos-link')
    // first click fetches + opens
    link.click()
    await waitFor(() => expect(mockOpenWindow).toHaveBeenCalledTimes(1))
    // second click should not refetch
    link.click()
    await waitFor(() => expect(mockOpenWindow).toHaveBeenCalledTimes(2))
    expect(fetchCount).toBe(1)
  })

  it('reuses cached inline content on subsequent clicks without refetch', async () => {
    let fetchCount = 0
    server.use(
      http.get('/api/v1/acceptable_use_policy', () => {
        fetchCount++
        return HttpResponse.json({content: '<p>Inline AUP</p>'})
      }),
    )
    renderTermsOfServiceModal()
    const link = screen.getByTestId('tos-link')
    // first open
    link.click()
    await waitFor(() => expect(screen.getByText('Inline AUP')).toBeInTheDocument())
    expect(fetchCount).toBe(1)
    // close modal
    const closeWrapper = screen.getByTestId('instui-modal-close')
    closeWrapper.querySelector('button')!.click()
    await waitFor(() => expect(screen.queryByTestId('tos-modal')).toBeNull())
    // second open uses cached content
    link.click()
    await waitFor(() => expect(screen.getByText('Inline AUP')).toBeInTheDocument())
    expect(fetchCount).toBe(1)
  })

  it('silently fails and does not open modal when api returns invalid response', async () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
    server.use(
      http.get('/api/v1/acceptable_use_policy', () => HttpResponse.json({invalid: 'data'})),
    )
    const mockOpenWindow = openWindow as unknown as jest.Mock
    renderTermsOfServiceModal()
    screen.getByTestId('tos-link').click()
    // wait a bit to ensure nothing happens
    await new Promise(resolve => setTimeout(resolve, 100))
    // modal should not open
    expect(screen.queryByTestId('tos-modal')).toBeNull()
    // no window should open
    expect(mockOpenWindow).not.toHaveBeenCalled()
    // error should be logged
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Failed to load acceptable use policy:',
      expect.any(Error),
    )
    consoleErrorSpy.mockRestore()
  })

  it('silently fails and does not open modal when api returns undefined', async () => {
    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})
    server.use(http.get('/api/v1/acceptable_use_policy', () => HttpResponse.json(null)))
    const mockOpenWindow = openWindow as unknown as jest.Mock
    renderTermsOfServiceModal()
    screen.getByTestId('tos-link').click()
    // wait a bit to ensure nothing happens
    await new Promise(resolve => setTimeout(resolve, 100))
    // modal should not open
    expect(screen.queryByTestId('tos-modal')).toBeNull()
    // no window should open
    expect(mockOpenWindow).not.toHaveBeenCalled()
    // error should be logged
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      'Failed to load acceptable use policy:',
      expect.any(Error),
    )
    consoleErrorSpy.mockRestore()
  })
})
