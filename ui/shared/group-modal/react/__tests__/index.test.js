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
import GroupModal from '../index'

describe('GroupModal', () => {
  const onSave = jest.fn()
  const onDismiss = jest.fn()
  const open = true
  const groupCategory = {id: '1'}
  const group = {
    name: '',
    id: '2',
    group_category_id: '1',
    role: '',
    join_level: '',
    group_limit: 2,
    members_count: 2
  }

  beforeEach(() => {
    group.role = null
  })

  afterEach(() => {
    fetchMock.restore()
  })

  describe('Add', () => {
    it('renders join level in add group dialog for student organized group categories', () => {
      const {getByText, queryByText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={{...group, role: 'student_organized'}}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      expect(getByText(/Joining/i)).toBeVisible()
      expect(queryByText(/Group Membership Limit/i)).toBeNull()
    })

    it('does not render join level in add group dialog for non student organized group categories', () => {
      const {getByText, queryByText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      expect(getByText(/Group Membership Limit/i)).toBeVisible()
      expect(queryByText(/Joining/i)).toBeNull()
    })

    it('renders modular footer', () => {
      const {getByText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      expect(getByText(/Save/i)).toBeVisible()
      expect(getByText(/Cancel/i)).toBeVisible()
    })

    it('clears prior state if modal is closed', () => {
      const {getByText, getByPlaceholderText, rerender} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), 'foo')
      expect(getByPlaceholderText('Name')).toHaveValue('foo')
      userEvent.click(getByText('Cancel'))
      rerender(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={false}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      expect(getByPlaceholderText('Name')).toHaveValue('')
    })

    it('disables the save button if group name is empty', () => {
      const {getByText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      expect(
        getByText('Save')
          .closest('button')
          .hasAttribute('disabled')
      ).toBeTruthy()
    })

    it('enables the save button if group name is provided', () => {
      const {getByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
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
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), 'Teacher Organized')
      userEvent.click(getByText('Save'))
      const [, fetchOptions] = fetchMock.lastCall()
      expect(fetchOptions.method).toBe('POST')
      expect(JSON.parse(fetchOptions.body)).toMatchObject({
        group_category_id: '1',
        isFull: '',
        max_membership: '2',
        name: 'Teacher Organized'
      })
      expect(getAllByText(/saving/i)).toBeTruthy()
      await act(() => fetchMock.flush(true))
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it('creates a student organized group and reports status', async () => {
      fetchMock.postOnce(`path:/api/v1/group_categories/${groupCategory.id}/groups`, 200)
      const {getByText, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={{...group, role: 'student_organized'}}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
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
      expect(getAllByText(/saving/i)).toBeTruthy()
      await act(() => fetchMock.flush(true))
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })
  })

  describe('Edit', () => {
    it('preserves prior model state on render', () => {
      const {getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'foo', group_limit: 3}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      expect(getByPlaceholderText('Name')).toHaveValue('foo')
      expect(getByPlaceholderText('Number')).toHaveValue('3')
    })

    it('allows updating a non student organized group', async () => {
      fetchMock.putOnce(`path:/api/v1/groups/${group.id}`, 200)
      const {getByText, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'Teacher Organized'}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), '{selectall}{backspace}')
      userEvent.type(getByPlaceholderText('Name'), 'Beetle Juice')
      userEvent.type(getByPlaceholderText('Number'), '{selectall}{backspace}')
      userEvent.type(getByPlaceholderText('Number'), '3')
      userEvent.click(getByText('Save'))
      const [, fetchOptions] = fetchMock.lastCall()
      expect(fetchOptions.method).toBe('PUT')
      expect(JSON.parse(fetchOptions.body)).toMatchObject({
        group_category_id: '1',
        isFull: '',
        max_membership: '3',
        name: 'Beetle Juice'
      })
      expect(getAllByText(/saving/i)).toBeTruthy()
      await act(() => fetchMock.flush(true))
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it('allows updating a student organized group', async () => {
      fetchMock.putOnce(`path:/api/v1/groups/${group.id}`, 200)
      const {getByText, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'Student Organized', role: 'student_organized'}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), '{selectall}{backspace}')
      userEvent.type(getByPlaceholderText('Name'), 'Sleepy Hollow')
      userEvent.click(getByText('Save'))
      const [, fetchOptions] = fetchMock.lastCall()
      expect(fetchOptions.method).toBe('PUT')
      expect(JSON.parse(fetchOptions.body)).toMatchObject({
        group_category_id: '1',
        join_level: 'invitation_only',
        name: 'Sleepy Hollow'
      })
      expect(getAllByText(/saving/i)).toBeTruthy()
      await act(() => fetchMock.flush(true))
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it("allows updating a 'name only' group", async () => {
      fetchMock.putOnce(`path:/api/v1/groups/${group.id}`, 200)
      const {getByText, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'nameOnly'}}
          label="Edit Group"
          open={open}
          nameOnly
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), '{selectall}{backspace}')
      userEvent.type(getByPlaceholderText('Name'), 'Name Only')
      userEvent.click(getByText('Save'))
      const [, fetchOptions] = fetchMock.lastCall()
      expect(fetchOptions.method).toBe('PUT')
      expect(JSON.parse(fetchOptions.body)).toMatchObject({
        group_category_id: '1',
        name: 'Name Only'
      })
      expect(getAllByText(/saving/i)).toBeTruthy()
      await act(() => fetchMock.flush(true))
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it('resets group membership limit', async () => {
      fetchMock.putOnce(`path:/api/v1/groups/${group.id}`, 200)
      const {getByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'Empty Group Limit', group_limit: 2}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Number'), '{selectall}{backspace}')
      expect(getByPlaceholderText('Number')).toHaveAttribute('value', '')
      userEvent.click(getByText('Save'))
      const [, fetchOptions] = fetchMock.lastCall()
      expect(fetchOptions.method).toBe('PUT')
      expect(JSON.parse(fetchOptions.body)).toMatchObject({
        group_category_id: '1',
        isFull: '',
        max_membership: '',
        name: 'Empty Group Limit'
      })
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
      fetchMock.postOnce(`path:/api/v1/group_categories/${groupCategory.id}/groups`, 400)
      const {getByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), 'foo')
      userEvent.click(getByText('Save'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/error/i)).toBeInTheDocument()
    })

    it('errors on attempting to save membership limit that is less than its current members', async () => {
      const {getByText, findAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, members_count: 4}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />
      )
      userEvent.type(getByPlaceholderText('Name'), 'foo')
      userEvent.type(getByPlaceholderText('Number'), '{selectall}{backspace}')
      userEvent.type(getByPlaceholderText('Number'), '3')
      userEvent.click(getByText('Save'))
      const errors = await findAllByText(
        'Group membership limit must be equal to or greater than current members count.'
      )
      expect(errors[0]).toBeInTheDocument()
    })
  })
})
