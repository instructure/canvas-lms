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

describe('AdminTable', () => {
  const devKeyList = (numKeys = 10) => {
    return [...Array(numKeys).keys()].map(n => ({
      id: `${n}`,
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
      />
    )
  }

  it('renders table with placeholder text if no keys are given', () => {
    const wrapper = component([])
    expect(wrapper.getByRole('table')).toBeInTheDocument()
    expect(wrapper.getByText('Nothing here yet')).toBeInTheDocument()
  })

  it('renders a DeveloperKey for each key', () => {
    const wrapper = component()
    expect(wrapper.getAllByRole('row')).toHaveLength(11)
  })

  describe('when sorting table', () => {
    const firstRow = wrapper => wrapper.getAllByRole('row')[1]
    it('defaults to descending id', () => {
      const wrapper = component()

      expect(firstRow(wrapper)).toHaveTextContent('9')
    })

    it('allows sorting by name', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('Name')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('key-0')

      userEvent.click(wrapper.getByText('Name')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('key-9')
    })

    it('allows sorting by email', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('Owner Email')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('email-0')

      userEvent.click(wrapper.getByText('Owner Email')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('email-9')
    })

    it('allows sorting by id', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('Details')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('0')

      userEvent.click(wrapper.getByText('Details')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('9')
    })

    it('allows sorting by access token count', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('Stats')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('0')

      userEvent.click(wrapper.getByText('Stats')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('18')
    })

    it('allows sorting by type', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('Type')) // ascending (API type)
      expect(firstRow(wrapper)).toHaveTextContent('key-0')

      userEvent.click(wrapper.getByText('Type')) // descending (LTI type)
      expect(firstRow(wrapper)).toHaveTextContent('key-3')
    })

    it('allows sorting by state', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('State')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('off')

      userEvent.click(wrapper.getByText('State')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('on')
    })

    it('does not allow sorting by actions', () => {
      const wrapper = component()

      userEvent.click(wrapper.getByText('Actions')) // "ascending"
      expect(firstRow(wrapper)).toHaveTextContent('key-9')

      userEvent.click(wrapper.getByText('Actions')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('key-9')
    })
  })

  /**
   * Tests for deleting keys and manipulating refs are found in
   * spec/javascripts/jsx/developer_keys/AdminTableSpec.jsx
   */
})
