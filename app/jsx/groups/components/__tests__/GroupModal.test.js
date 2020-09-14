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
import {act, render} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import GroupModal from '../GroupModal'

describe('GroupModal', () => {
  const onSave = jest.fn()
  const onDismiss = jest.fn()
  const groupCategory = {id: '1', role: '', group_limit: 2}
  const open = true

  beforeEach(() => {
    groupCategory.role = null
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders join level in add group dialog for student organized group categories', () => {
    groupCategory.role = 'student_organized'
    const {getByText, queryByText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    expect(getByText(/Joining/i)).toBeVisible()
    expect(queryByText(/Group Membership Limit/i)).toBeNull()
  })

  it('does not render join level in add group dialog for non student organized group categories', () => {
    groupCategory.role = null
    const {getByText, queryByText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    expect(getByText(/Group Membership Limit/i)).toBeVisible()
    expect(queryByText(/Joining/i)).toBeNull()
  })

  it('renders modular footer', () => {
    const {getByText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    expect(getByText(/Save/i)).toBeVisible()
    expect(getByText(/Cancel/i)).toBeVisible()
  })

  it('clears prior state if modal is closed', () => {
    const {getByText, getByPlaceholderText, rerender} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    userEvent.type(getByPlaceholderText('Name'), 'foo')
    expect(getByPlaceholderText('Name')).toHaveValue('foo')
    userEvent.click(getByText('Cancel'))
    rerender(
      <GroupModal
        groupCategory={groupCategory}
        onSave={onSave}
        onDismiss={onDismiss}
        open={false}
      />
    )
    expect(getByPlaceholderText('Name')).toHaveValue('')
  })

  it('disables the save button if group name is empty', () => {
    const {getByText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    expect(
      getByText('Save')
        .closest('button')
        .hasAttribute('disabled')
    ).toBeTruthy()
  })

  it('enables the save button if group name is provided', () => {
    const {getByText, getByPlaceholderText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    userEvent.type(getByPlaceholderText('Name'), 'foo')
    expect(
      getByText('Save')
        .closest('button')
        .hasAttribute('disabled')
    ).toBeFalsy()
  })

  it('creates a non student organized group and reports status', async () => {
    fetchMock.postOnce(`path:/api/v1/group_categories/${groupCategory.id}/groups`, 200)
    const {getByText, getAllByText, getByPlaceholderText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    userEvent.type(getByPlaceholderText('Name'), 'Teacher Organized')
    userEvent.click(getByText('Save'))
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      group_category_id: '1',
      isFull: '',
      max_membership: 2,
      name: 'Teacher Organized'
    })
    expect(getAllByText(/creating/i)).not.toHaveLength(0)
    await act(() => fetchMock.flush(true))
    expect(getAllByText(/success/i)).not.toHaveLength(0)
    expect(onDismiss).toHaveBeenCalled()
  })

  it('creates a student organized group and reports status', async () => {
    groupCategory.role = 'student_organized'
    fetchMock.postOnce(`path:/api/v1/group_categories/${groupCategory.id}/groups`, 200)
    const {getByText, getAllByText, getByPlaceholderText} = render(
      <GroupModal groupCategory={groupCategory} onSave={onSave} onDismiss={onDismiss} open={open} />
    )
    userEvent.type(getByPlaceholderText('Name'), 'Student Organized')
    userEvent.click(getByText('Save'))
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      group_category_id: '1',
      join_level: 'invitation_only',
      name: 'Student Organized'
    })
    expect(getAllByText(/creating/i)).not.toHaveLength(0)
    await act(() => fetchMock.flush(true))
    expect(getAllByText(/success/i)).not.toHaveLength(0)
    expect(onDismiss).toHaveBeenCalled()
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore() // eslint-disable-line no-console
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce(`path:/api/v1/group_categories/${groupCategory.id}/groups`, 400)
      const {getByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          onSave={onSave}
          onDismiss={onDismiss}
          open={open}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), 'foo')
      userEvent.click(getByText('Save'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/error/i)).toBeInTheDocument()
    })
  })
})
