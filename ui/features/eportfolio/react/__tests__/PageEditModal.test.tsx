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
import {fireEvent, render, waitFor} from '@testing-library/react'
import PageEditModal from '../PageEditModal'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

// Track API calls
const apiCalls: {method: string; url: string}[] = []

describe('PageEditModal', () => {
  const portfolio = {id: 0, name: 'Test Portfolio', public: true, profile_url: '/path/to/profile'}
  const page = {id: 2, name: 'Second Page', position: 2, entry_url: '/path/to/page'}
  const pageList = [{id: 1, name: 'First Page', position: 1, entry_url: '/path/to/page'}, page]
  const mockConfirm = vi.fn()
  const mockCancel = vi.fn()

  const props = {
    portfolio,
    onConfirm: mockConfirm,
    onCancel: mockCancel,
    sectionId: 100,
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.resetHandlers()
    apiCalls.length = 0
    vi.clearAllMocks()

    // Set up handlers for all endpoints
    server.use(
      http.delete('/eportfolios/:portfolioId/entries/:entryId', ({request}) => {
        apiCalls.push({method: 'DELETE', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
      http.post('/eportfolios/:portfolioId/entries', ({request}) => {
        apiCalls.push({method: 'POST', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
      http.put('/eportfolios/:portfolioId/entries/:entryId', ({request}) => {
        apiCalls.push({method: 'PUT', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
      http.post('/eportfolios/:portfolioId/:sectionId/reorder_entries', ({request}) => {
        apiCalls.push({method: 'POST', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
    )
  })

  const wasApiCalled = (method: string, pathFragment?: string) => {
    return apiCalls.some(
      call => call.method === method && (!pathFragment || call.url.includes(pathFragment)),
    )
  }

  it('sets focus on blank text input', async () => {
    const {getByTestId, getByText} = render(
      <PageEditModal {...props} modalType="add" page={null} pageList={pageList} />,
    )
    const textInput = getByTestId('add-field')
    const saveButton = getByText('Save')
    saveButton.click()
    await waitFor(() => {
      expect(textInput).toHaveFocus()
      expect(getByText('Name is required.')).toBeInTheDocument()
    })
  })

  describe('delete', () => {
    it('does not delete on cancel', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="delete" page={page} pageList={pageList} />,
      )

      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(wasApiCalled('DELETE')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('deletes when clicking delete button', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="delete" page={page} pageList={pageList} />,
      )

      const deleteButton = getByText('Delete')
      deleteButton.click()

      await waitFor(() => expect(wasApiCalled('DELETE', '/entries/2')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })

  describe('add', () => {
    it('does not add page on cancel', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="add" page={null} pageList={pageList} />,
      )

      const textInput = getByTestId('add-field')
      fireEvent.change(textInput, {target: {value: 'Third Page'}})
      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(wasApiCalled('POST', '/entries')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('adds page when clicking save button', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="add" page={null} pageList={pageList} />,
      )

      const textInput = getByTestId('add-field')
      fireEvent.change(textInput, {target: {value: 'Third Page'}})
      const saveButton = getByText('Save')
      saveButton.click()

      await waitFor(() => expect(wasApiCalled('POST', '/entries')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
  describe('rename', () => {
    it('does not rename page on cancel', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="rename" page={page} pageList={pageList} />,
      )

      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(wasApiCalled('PUT')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('renames page when clicking save button', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="rename" page={page} pageList={pageList} />,
      )

      const saveButton = getByText('Save')
      saveButton.click()

      await waitFor(() => expect(wasApiCalled('PUT', '/entries/2')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
  describe('move to', () => {
    it('does not move page on cancel', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="move" page={page} pageList={pageList} />,
      )

      const select = getByTestId('move-select')
      select.click()
      getByText('First Page').click()
      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(wasApiCalled('POST', '/reorder_entries')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('move page when clicking save button', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="move" page={page} pageList={pageList} />,
      )

      const select = getByTestId('move-select')
      select.click()
      getByText('First Page').click()
      const saveButton = getByText('Save')
      saveButton.click()

      await waitFor(() => expect(wasApiCalled('POST', '/reorder_entries')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
})
