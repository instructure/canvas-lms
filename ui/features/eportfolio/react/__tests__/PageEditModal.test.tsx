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
import fetchMock from 'fetch-mock'

describe('PageEditModal', () => {
  const portfolio = {id: 0, name: 'Test Portfolio', public: true, profile_url: '/path/to/profile'}
  const page = {id: 2, name: 'Second Page', position: 2, entry_url: '/path/to/page'}
  const pageList = [{id: 1, name: 'First Page', position: 1, entry_url: '/path/to/page'}, page]
  const mockConfirm = jest.fn()
  const mockCancel = jest.fn()

  const props = {
    portfolio,
    onConfirm: mockConfirm,
    onCancel: mockCancel,
    sectionId: 100,
  }

  beforeEach(() => {
    fetchMock.restore()
  })

  it('sets focus on blank text input', () => {
    const {getByTestId, getByText} = render(
      <PageEditModal {...props} modalType="add" page={null} pageList={pageList} />,
    )
    const textInput = getByTestId('add-field')
    const saveButton = getByText('Save')
    saveButton.click()
    waitFor(() => {
      expect(textInput).toHaveFocus()
      expect(getByText('Name is required.')).toBeInTheDocument()
    })
  })

  describe('delete', () => {
    it('does not delete on cancel', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="delete" page={page} pageList={pageList} />,
      )
      const path = encodeURI('/eportfolios/0/entries/2')
      fetchMock.delete(path, {status: 200})

      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'DELETE')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('deletes when clicking delete button', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="delete" page={page} pageList={pageList} />,
      )
      const path = encodeURI('/eportfolios/0/entries/2')
      fetchMock.delete(path, {status: 200})

      const deleteButton = getByText('Delete')
      deleteButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'DELETE')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })

  describe('add', () => {
    it('does not add page on cancel', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="add" page={null} pageList={pageList} />,
      )
      const path = encodeURI(
        '/eportfolios/0/entries?eportfolio_entry[name]=Third Page&eportfolio_entry[eportfolio_category_id]=100',
      )
      fetchMock.post(path, {status: 200})

      const textInput = getByTestId('add-field')
      fireEvent.change(textInput, {target: {value: 'Third Page'}})
      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'POST')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('adds page when clicking save button', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="add" page={null} pageList={pageList} />,
      )
      const path = encodeURI(
        '/eportfolios/0/entries?eportfolio_entry[name]=Third Page&eportfolio_entry[eportfolio_category_id]=100',
      )
      fetchMock.post(path, {status: 200})

      const textInput = getByTestId('add-field')
      fireEvent.change(textInput, {target: {value: 'Third Page'}})
      const saveButton = getByText('Save')
      saveButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'POST')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
  describe('rename', () => {
    it('does not rename page on cancel', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="rename" page={page} pageList={pageList} />,
      )
      const path = encodeURI(
        '/eportfolios/0/entries/2?eportfolio_entry[name]=Second Page&eportfolio_entry[eportfolio_category_id]=100',
      )
      fetchMock.put(path, {status: 200})

      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'PUT')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('renames page when clicking save button', async () => {
      const {getByText} = render(
        <PageEditModal {...props} modalType="rename" page={page} pageList={pageList} />,
      )
      const path = encodeURI(
        '/eportfolios/0/entries/2?eportfolio_entry[name]=Second Page&eportfolio_entry[eportfolio_category_id]=100',
      )
      fetchMock.put(path, {status: 200})

      const saveButton = getByText('Save')
      saveButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'PUT')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
  describe('move to', () => {
    it('does not move page on cancel', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="move" page={page} pageList={pageList} />,
      )
      // encodeURIComponent encodes the slashes
      // encodeURI enocdes the commas
      // so we have to hard code the uri
      const path = encodeURI('/eportfolios/0/100/reorder_entries?order=2%2C1')
      fetchMock.post(path, {status: 200})

      const select = getByTestId('move-select')
      select.click()
      getByText('First Page').click()
      const cancelButton = getByText('Cancel')
      cancelButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'POST')).toBe(false))
      await waitFor(() => expect(mockCancel).toHaveBeenCalled())
    })

    it('move page when clicking save button', async () => {
      const {getByText, getByTestId} = render(
        <PageEditModal {...props} modalType="move" page={page} pageList={pageList} />,
      )
      const path = '/eportfolios/0/100/reorder_entries?order=2%2C1'
      fetchMock.post(path, {status: 200})

      const select = getByTestId('move-select')
      select.click()
      getByText('First Page').click()
      const saveButton = getByText('Save')
      saveButton.click()

      await waitFor(() => expect(fetchMock.called(path, 'POST')).toBe(true))
      await waitFor(() => expect(mockConfirm).toHaveBeenCalled())
    })
  })
})
