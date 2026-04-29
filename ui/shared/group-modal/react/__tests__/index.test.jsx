// @vitest-environment jsdom
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
import {act, fireEvent, render, waitForElementToBeRemoved, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import GroupModal from '../index'

const USER_EVENT_OPTIONS = {pointerEventsCheck: PointerEventsCheckLevel.Never, delay: null}

const server = setupServer()

describe('GroupModal', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  const onSave = vi.fn()
  const onDismiss = vi.fn()
  const open = true
  const groupCategory = {id: '1'}
  const group = {
    name: '',
    id: '2',
    group_category_id: '1',
    role: '',
    join_level: '',
    group_limit: 2,
    members_count: 2,
  }

  beforeEach(() => {
    group.role = null
  })

  describe('Add', () => {
    it('renders join level in add group dialog for student organized group categories', () => {
      const {getByText, queryByLabelText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={{...group, role: 'student_organized'}}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      expect(getByText(/Joining/i)).toBeVisible()
      expect(queryByLabelText(/Group Membership Limit/i)).toBeNull()
    })

    it('does not render join level in add group dialog for non student organized group categories', () => {
      const {getByLabelText, queryByText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      expect(getByLabelText(/Group Membership Limit/i)).toBeVisible()
      expect(queryByText(/Joining/i)).toBeNull()
    })

    it('renders modular footer', () => {
      const {getByTestId} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      expect(getByTestId('group-modal-save-button')).toBeVisible()
      expect(getByTestId('group-modal-cancel-button')).toBeVisible()
    })

    it('clears prior state if modal is closed', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, getByPlaceholderText, rerender} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'foo')
      expect(getByPlaceholderText('Name')).toHaveValue('foo')
      await user.click(getByText('Cancel'))
      rerender(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={false}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      expect(getByPlaceholderText('Name')).toHaveValue('')
    })

    it('disables the save button if group name is empty', () => {
      const {getByTestId} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      expect(getByTestId('group-modal-save-button')).toHaveAttribute('disabled')
    })

    it('enables the save button if group name is provided', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByTestId, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'foo')
      expect(getByTestId('group-modal-save-button')).not.toHaveAttribute('disabled')
    })

    it('creates a non student organized group and reports status', async () => {
      server.use(
        http.post(`/api/v1/group_categories/${groupCategory.id}/groups`, () =>
          HttpResponse.json({}),
        ),
      )
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByTestId, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'Teacher Organized')
      let capturedBody = null
      server.use(
        http.post(`/api/v1/group_categories/${groupCategory.id}/groups`, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      await user.click(getByTestId('group-modal-save-button'))
      expect(getAllByText(/saving/i)).toBeTruthy()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(capturedBody).toMatchObject({
        group_category_id: '1',
        isFull: '',
        max_membership: '2',
        name: 'Teacher Organized',
      })
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it('creates a student organized group and reports status', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      let capturedBody = null
      server.use(
        http.post(`/api/v1/group_categories/${groupCategory.id}/groups`, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      const {getByTestId, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={{...group, role: 'student_organized'}}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'Student Organized')
      await user.click(getByTestId('group-modal-save-button'))
      expect(getAllByText(/saving/i)).toBeTruthy()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(capturedBody).toMatchObject({
        group_category_id: '1',
        join_level: 'invitation_only',
        name: 'Student Organized',
      })
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
        />,
      )
      expect(getByPlaceholderText('Name')).toHaveValue('foo')
      expect(getByPlaceholderText('Number')).toHaveValue('3')
    })

    it('correctly displays input even after reopening the modal', async () => {
      function TestComponent() {
        const [isOpen, toggleOpen] = React.useReducer(o => !o, true)
        return (
          <>
            <button type="button" onClick={() => toggleOpen()}>
              Toggle
            </button>
            <GroupModal
              group={{...group, name: 'foo', group_limit: 3}}
              label="Edit Group"
              open={isOpen}
              requestMethod="PUT"
              onSave={onSave}
              onDismiss={onDismiss}
            />
          </>
        )
      }
      const wrapper = render(<TestComponent />)
      expect(wrapper.getByPlaceholderText('Name')).toHaveValue('foo')
      expect(wrapper.getByPlaceholderText('Number')).toHaveValue('3')
      await userEvent.click(wrapper.getByText('Toggle')) // close
      await waitForElementToBeRemoved(() => wrapper.getByPlaceholderText('Number'))
      await userEvent.click(wrapper.getByText('Toggle')) // reopen
      await waitFor(() => wrapper.getByPlaceholderText('Number'))
      expect(wrapper.getByPlaceholderText('Name')).toHaveValue('foo')
      expect(wrapper.getByPlaceholderText('Number')).toHaveValue('3')
    })

    it('allows updating a non student organized group', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      let capturedBody = null
      server.use(
        http.put(`/api/v1/groups/${group.id}`, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      const {getByTestId, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'Teacher Organized'}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.clear(getByPlaceholderText('Name'))
      await user.type(getByPlaceholderText('Name'), 'Beetle Juice')
      await user.type(getByPlaceholderText('Number'), '{selectall}{backspace}3')
      await user.click(getByTestId('group-modal-save-button'))
      expect(getAllByText(/saving/i)).toBeTruthy()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(capturedBody).toMatchObject({
        group_category_id: '1',
        isFull: '',
        max_membership: '3',
        name: 'Beetle Juice',
      })
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it('allows updating a student organized group', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      let capturedBody = null
      server.use(
        http.put(`/api/v1/groups/${group.id}`, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      const {getByTestId, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'Student Organized', role: 'student_organized'}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.clear(getByPlaceholderText('Name'))
      await user.type(getByPlaceholderText('Name'), 'Sleepy Hollow')
      await user.click(getByTestId('group-modal-save-button'))
      expect(getAllByText(/saving/i)).toBeTruthy()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(capturedBody).toMatchObject({
        group_category_id: '1',
        join_level: 'invitation_only',
        name: 'Sleepy Hollow',
      })
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it("allows updating a 'name only' group", async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      let capturedBody = null
      server.use(
        http.put(`/api/v1/groups/${group.id}`, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      const {getByTestId, getAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'nameOnly'}}
          label="Edit Group"
          open={open}
          nameOnly={true}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.clear(getByPlaceholderText('Name'))
      await user.type(getByPlaceholderText('Name'), 'Name Only')
      await user.click(getByTestId('group-modal-save-button'))
      expect(getAllByText(/saving/i)).toBeTruthy()
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(capturedBody).toMatchObject({
        group_category_id: '1',
        name: 'Name Only',
      })
      expect(getAllByText(/success/i)).toBeTruthy()
      expect(onDismiss).toHaveBeenCalled()
      expect(onSave).toHaveBeenCalled()
    })

    it('resets group membership limit', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      let capturedBody = null
      server.use(
        http.put(`/api/v1/groups/${group.id}`, async ({request}) => {
          capturedBody = await request.json()
          return HttpResponse.json({})
        }),
      )
      const {getByTestId, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, name: 'Empty Group Limit', group_limit: 2}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Number'), '{selectall}{backspace}')
      expect(getByPlaceholderText('Number')).toHaveAttribute('value', '')
      await user.click(getByTestId('group-modal-save-button'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(capturedBody).toMatchObject({
        group_category_id: '1',
        isFull: '',
        max_membership: '',
        name: 'Empty Group Limit',
      })
    })
  })

  describe('errors', () => {
    beforeEach(() => {
      vi.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore()
    })

    it('reports an error if the fetch fails', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      server.use(
        http.post(
          `/api/v1/group_categories/${groupCategory.id}/groups`,
          () => new HttpResponse(null, {status: 400}),
        ),
      )
      const {getByText, getByPlaceholderText} = render(
        <GroupModal
          groupCategory={groupCategory}
          group={group}
          label="Add Group"
          open={open}
          requestMethod="POST"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'foo')
      await user.click(getByText('Save'))
      await new Promise(resolve => setTimeout(resolve, 0))
      expect(getByText(/error/i)).toBeInTheDocument()
    })

    it('errors on attempting to save membership limit that is less than its current members', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, findAllByText, getByPlaceholderText} = render(
        <GroupModal
          group={{...group, members_count: 4}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'foo')
      await user.type(getByPlaceholderText('Number'), '{selectall}{backspace}')
      await user.type(getByPlaceholderText('Number'), '3')
      await user.click(getByText('Save'))
      const errors = await findAllByText(
        'Group membership limit must be equal to or greater than current members count.',
      )
      expect(errors[0]).toBeInTheDocument()
    })

    it('errors on attempting to save membership limit that is 1', async () => {
      const user = userEvent.setup(USER_EVENT_OPTIONS)
      const {getByText, findAllByText, getByPlaceholderText, getByLabelText} = render(
        <GroupModal
          group={{...group, members_count: 0}}
          label="Edit Group"
          open={open}
          requestMethod="PUT"
          onSave={onSave}
          onDismiss={onDismiss}
        />,
      )
      await user.type(getByPlaceholderText('Name'), 'foo')
      const input = getByLabelText(/Group Membership/i)
      fireEvent.input(input, {target: {value: '1'}})
      await user.click(getByText('Save'))
      const errors = await findAllByText('Group membership limit must be greater than 1.')
      expect(errors[0]).toBeInTheDocument()
    })
  })
})
