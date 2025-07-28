// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {act, fireEvent, render, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import React from 'react'
import GroupCategoryCloneModal, {CATEGORY_NAME_MAX_LENGTH} from '../GroupCategoryCloneModal'

// mock reloadWindow
jest.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: jest.fn(),
}))

describe('GroupCategoryCloneModal', () => {
  const onDismiss = jest.fn()
  const open = true
  const groupCategory = {
    id: '1',
    name: '',
  }

  afterEach(() => {
    fetchMock.restore()
  })

  describe('clone group set', () => {
    it('prepends (Clone) to name from given group set', () => {
      const {getByPlaceholderText} = render(
        <GroupCategoryCloneModal
          groupCategory={{...groupCategory, name: 'Course Admin View Group Set'}}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )
      expect(getByPlaceholderText('Name')).toHaveValue('(Clone) Course Admin View Group Set')
    })

    it('renders modular footer', () => {
      const {getByText} = render(
        <GroupCategoryCloneModal
          groupCategory={groupCategory}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )
      expect(getByText(/Submit/i)).toBeVisible()
      expect(getByText(/Cancel/i)).toBeVisible()
    })

    it('enables the submit button if group name is provided', async () => {
      const {getByText, getByPlaceholderText} = render(
        <GroupCategoryCloneModal
          groupCategory={groupCategory}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )
      fireEvent.input(getByPlaceholderText('Name'), {target: {value: 'enabled'}})

      await waitFor(() => {
        expect(getByText('Submit').closest('button')).toBeEnabled()
      })
    })

    it('creates a clone from current group set and reports status', async () => {
      fetchMock.postOnce(`path:/group_categories/${groupCategory.id}/clone_with_name`, {
        status: 200,
        group_category: {id: '1'},
      })
      const {getByText, getAllByText} = render(
        <GroupCategoryCloneModal
          groupCategory={{...groupCategory, name: 'Course Admin View Group Set'}}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )
      await userEvent
        .setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
        .click(getByText('Submit'))
      const [, fetchOptions] = fetchMock.lastCall()
      expect(fetchOptions.method).toBe('POST')
      expect(JSON.parse(fetchOptions.body)).toMatchObject({
        name: '(Clone) Course Admin View Group Set',
      })
      expect(getAllByText(/cloning/i)).toBeTruthy()
      await act(() => fetchMock.flush(true))
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
    })
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore()
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce(`path:/group_categories/${groupCategory.id}/clone_with_name`, 400)
      const {getByText} = render(
        <GroupCategoryCloneModal
          groupCategory={{...groupCategory, name: 'Course Admin View Group Set'}}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )
      await userEvent
        .setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
        .click(getByText('Submit'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/error/i)).toBeInTheDocument()
    })

    it('Shows error if name is empty and clears it when user enters a name', async () => {
      const {getByPlaceholderText, queryByText} = render(
        <GroupCategoryCloneModal
          groupCategory={{...groupCategory, name: 'Course Admin View Group Set'}}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )

      const inputName = getByPlaceholderText('Name')
      await userEvent.clear(inputName)

      expect(inputName).toHaveValue('')

      await userEvent
        .setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
        .click(queryByText('Submit'))

      expect(queryByText('Group set name is required')).toBeInTheDocument()

      fireEvent.input(inputName, {target: {value: 'something'}})

      await waitFor(() => {
        expect(queryByText('Group set name is required')).not.toBeInTheDocument()
      })
    })

    it(`Shows error if name is greater than ${CATEGORY_NAME_MAX_LENGTH}`, async () => {
      const {getByPlaceholderText, queryByText} = render(
        <GroupCategoryCloneModal
          groupCategory={{...groupCategory, name: 'Course Admin View Group Set'}}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />,
      )

      const inputName = getByPlaceholderText('Name')

      fireEvent.input(inputName, {target: {value: 'a'.repeat(CATEGORY_NAME_MAX_LENGTH + 1)}})
      await userEvent
        .setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
        .click(queryByText('Submit'))

      const errorMessage = `Must be fewer than ${CATEGORY_NAME_MAX_LENGTH} characters`
      expect(queryByText(errorMessage)).toBeInTheDocument()
    })
  })
})
