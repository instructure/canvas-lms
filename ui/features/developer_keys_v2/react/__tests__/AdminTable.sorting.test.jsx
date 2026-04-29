/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import AdminTable from '../AdminTable'

const USER_EVENT_OPTIONS = {delay: null}

describe('AdminTable sorting tests', () => {
  const idFor = n => `1000000000000${n}`

  const devKeyList = (numKeys = 10) => {
    return [...Array(numKeys).keys()]
      .map(n => ({
        id: idFor(n),
        name: `key-${n}`,
        email: `email-${n}`,
        access_token_count: n * 2,
        is_lti_key: n == 3,
        api_key: 'abc12345678',
        created_at: '2023-12-12T20:36:50Z',
        visible: true,
        developer_key_account_binding: {
          workflow_state: n == 5 ? 'off' : 'on',
        },
      }))
      .reverse()
  }

  const component = (keys, props = {}) => {
    return render(
      <AdminTable
        developerKeysList={keys || devKeyList()}
        store={{dispatch: () => {}}}
        actions={{
          makeVisibleDeveloperKey: () => {},
          makeInvisibleDeveloperKey: () => {},
          activateDeveloperKey: () => {},
          deactivateDeveloperKey: () => {},
          deleteDeveloperKey: () => {},
          editDeveloperKey: () => {},
          developerKeysModalOpen: () => {},
          ltiKeysSetLtiKey: () => {},
          setBindingWorkflowState: () => {},
        }}
        ctx={{
          params: {
            contextId: '',
          },
        }}
        {...props}
      />,
    )
  }

  const firstRow = wrapper => wrapper.getAllByRole('row')[1]

  it('defaults to descending id', () => {
    const wrapper = component()

    expect(firstRow(wrapper)).toHaveTextContent(idFor(9))
  })

  it('allows sorting by name', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('Name')) // ascending
    expect(firstRow(wrapper)).toHaveTextContent('key-0')

    await user.click(wrapper.getByText('Name')) // descending
    expect(firstRow(wrapper)).toHaveTextContent('key-9')
  })

  it('allows sorting by email', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('Owner Email')) // ascending
    expect(firstRow(wrapper)).toHaveTextContent('email-0')

    await user.click(wrapper.getByText('Owner Email')) // descending
    expect(firstRow(wrapper)).toHaveTextContent('email-9')
  })

  it('allows sorting by id', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('Details')) // ascending
    expect(firstRow(wrapper)).toHaveTextContent(idFor(0))

    await user.click(wrapper.getByText('Details')) // descending
    expect(firstRow(wrapper)).toHaveTextContent(idFor(9))
  })

  it('allows sorting by access token count', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('Stats')) // ascending
    expect(firstRow(wrapper)).toHaveTextContent('0')

    await user.click(wrapper.getByText('Stats')) // descending
    expect(firstRow(wrapper)).toHaveTextContent('18')
  })

  it('allows sorting by type', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('Type')) // ascending (API type)
    expect(firstRow(wrapper)).toHaveTextContent('key-9')

    await user.click(wrapper.getByText('Type')) // descending (LTI type)
    expect(firstRow(wrapper)).toHaveTextContent('key-3')
  })

  it('allows sorting by state', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('State')) // ascending
    expect(firstRow(wrapper)).toHaveTextContent('off')

    await user.click(wrapper.getByText('State')) // descending
    expect(firstRow(wrapper)).toHaveTextContent('on')
  })

  it('does not allow sorting by actions', async () => {
    const user = userEvent.setup(USER_EVENT_OPTIONS)
    const wrapper = component()

    await user.click(wrapper.getByText('Actions')) // "ascending"
    expect(firstRow(wrapper)).toHaveTextContent('key-9')

    await user.click(wrapper.getByText('Actions')) // descending
    expect(firstRow(wrapper)).toHaveTextContent('key-9')
  })
})
