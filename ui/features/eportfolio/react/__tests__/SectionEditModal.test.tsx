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
import SectionEditModal from '../SectionEditModal'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer()

// Track API calls
const apiCalls: {method: string; url: string}[] = []

describe('SectionEditModal', () => {
  const portfolio = {id: 0, name: 'Test Portfolio', public: true, profile_url: '/path/to/profile'}
  const section = {id: 2, name: 'Second Section', position: 2, category_url: '/path/to/section'}
  const sectionList = [
    {id: 1, name: 'First Section', position: 1, category_url: '/path/to/section'},
    section,
  ]
  const mockConfirm = vi.fn()
  const mockCancel = vi.fn()
  const props = {
    portfolio,
    onConfirm: mockConfirm,
    onCancel: mockCancel,
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    server.resetHandlers()
    apiCalls.length = 0
    vi.clearAllMocks()

    // Set up handlers for all endpoints
    server.use(
      http.delete('/eportfolios/:portfolioId/categories/:categoryId', ({request}) => {
        apiCalls.push({method: 'DELETE', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
      http.post('/eportfolios/:portfolioId/categories', ({request}) => {
        apiCalls.push({method: 'POST', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
      http.put('/eportfolios/:portfolioId/categories/:categoryId', ({request}) => {
        apiCalls.push({method: 'PUT', url: request.url})
        return HttpResponse.json({}, {status: 200})
      }),
      http.post('/eportfolios/:portfolioId/reorder_categories', ({request}) => {
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

  it.skip('sets focus on blank text input', () => {
    const {getByTestId, getByText} = render(
      <SectionEditModal {...props} modalType="add" section={null} sectionList={sectionList} />,
    )
    const textInput = getByTestId('add-field')
    const saveButton = getByText('Save')
    saveButton.click()
    waitFor(() => {
      expect(getByText('Name is required.')).toBeInTheDocument()
      expect(textInput).toHaveFocus()
    })
  })

  // fickle; these pass individually
  describe.skip('delete', () => {
    it('does not delete on cancel', async () => {
      const {getByText} = render(
        <SectionEditModal
          {...props}
          modalType="delete"
          section={section}
          sectionList={sectionList}
        />,
      )
      const cancelButton = getByText('Cancel')
      cancelButton.click()
      await waitFor(() => expect(wasApiCalled('DELETE')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('deletes when clicking delete button', async () => {
      const {getByText} = render(
        <SectionEditModal
          {...props}
          modalType="delete"
          section={section}
          sectionList={sectionList}
        />,
      )
      const deleteButton = getByText('Delete')
      deleteButton.click()
      await waitFor(() => expect(wasApiCalled('DELETE', '/categories/2')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })

  describe('add', () => {
    it('does not add section on cancel', async () => {
      const {getByText, getByTestId} = render(
        <SectionEditModal {...props} modalType="add" section={null} sectionList={sectionList} />,
      )
      const textInput = getByTestId('add-field')
      fireEvent.change(textInput, {target: {value: 'Third Section'}})
      const cancelButton = getByText('Cancel')
      cancelButton.click()
      await waitFor(() => expect(wasApiCalled('POST', '/categories')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('adds section when clicking save button', async () => {
      const {getByText, getByTestId} = render(
        <SectionEditModal {...props} modalType="add" section={null} sectionList={sectionList} />,
      )
      const textInput = getByTestId('add-field')
      fireEvent.change(textInput, {target: {value: 'Third Section'}})
      const saveButton = getByText('Save')
      saveButton.click()
      await waitFor(() => expect(wasApiCalled('POST', '/categories')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })

  describe('rename', () => {
    it('does not rename section on cancel', async () => {
      const {getByText} = render(
        <SectionEditModal
          {...props}
          modalType="rename"
          section={section}
          sectionList={sectionList}
        />,
      )
      const cancelButton = getByText('Cancel')
      cancelButton.click()
      await waitFor(() => expect(wasApiCalled('PUT')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('renames section when clicking save button', async () => {
      const {getByText} = render(
        <SectionEditModal
          {...props}
          modalType="rename"
          section={section}
          sectionList={sectionList}
        />,
      )
      const saveButton = getByText('Save')
      saveButton.click()
      await waitFor(() => expect(wasApiCalled('PUT', '/categories/2')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
  describe('move to', () => {
    it('does not move section on cancel', async () => {
      const {getByText, getByTestId} = render(
        <SectionEditModal
          {...props}
          modalType="move"
          section={section}
          sectionList={sectionList}
        />,
      )
      const select = getByTestId('move-select')
      select.click()
      getByText('First Section').click()
      const cancelButton = getByText('Cancel')
      cancelButton.click()
      await waitFor(() => expect(wasApiCalled('POST', '/reorder_categories')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })
    it('move section when clicking save button', async () => {
      const {getByText, getByTestId} = render(
        <SectionEditModal
          {...props}
          modalType="move"
          section={section}
          sectionList={sectionList}
        />,
      )
      const select = getByTestId('move-select')
      select.click()
      getByText('First Section').click()
      const saveButton = getByText('Save')
      saveButton.click()
      await waitFor(() => expect(wasApiCalled('POST', '/reorder_categories')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
})
