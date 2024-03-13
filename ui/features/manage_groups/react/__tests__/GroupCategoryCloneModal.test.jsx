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

import React from 'react'
import {act, render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import GroupCategoryCloneModal from '../GroupCategoryCloneModal'

describe('GroupCategoryCloneModal', () => {
  const {reload} = window.location
  const onDismiss = jest.fn()
  const open = true
  const groupCategory = {
    id: '1',
    name: '',
  }

  beforeAll(() => {
    Object.defineProperty(window, 'location', {
      writable: true,
      value: {reload: jest.fn()},
    })
  })

  afterAll(() => {
    window.location.reload = reload
  })

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
        />
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
        />
      )
      expect(getByText(/Submit/i)).toBeVisible()
      expect(getByText(/Cancel/i)).toBeVisible()
    })

    it('disables the submit button if group name is empty', () => {
      const {getByText} = render(
        <GroupCategoryCloneModal
          groupCategory={groupCategory}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />
      )
      expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeTruthy()
    })

    it('enables the submit button if group name is provided', async () => {
      const {getByText, getByPlaceholderText} = render(
        <GroupCategoryCloneModal
          groupCategory={groupCategory}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />
      )
      await userEvent.setup({delay: null}).type(getByPlaceholderText('Name'), 'enabled')
      expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeFalsy()
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
        />
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
      expect(window.location.reload).toHaveBeenCalled()
    })
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore() // eslint-disable-line no-console
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce(`path:/group_categories/${groupCategory.id}/clone_with_name`, 400)
      const {getByText} = render(
        <GroupCategoryCloneModal
          groupCategory={{...groupCategory, name: 'Course Admin View Group Set'}}
          label="Clone Group Set"
          open={open}
          onDismiss={onDismiss}
        />
      )
      await userEvent
        .setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
        .click(getByText('Submit'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/error/i)).toBeInTheDocument()
    })
  })
})
