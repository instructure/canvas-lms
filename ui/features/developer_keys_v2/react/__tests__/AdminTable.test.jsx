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

import AdminTable from '../AdminTable'

describe('AdminTable', () => {
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

  it('renders table with placeholder text if no keys are given', () => {
    const wrapper = component([])
    expect(wrapper.getByRole('table')).toBeInTheDocument()
    expect(wrapper.getByText('Nothing here yet')).toBeInTheDocument()
  })

  it('renders a DeveloperKey for each key', () => {
    const wrapper = component()
    expect(wrapper.getAllByRole('row')).toHaveLength(11)
  })

  /**
   * Tests for deleting keys and manipulating refs are found in
   * spec/javascripts/jsx/developer_keys/AdminTableSpec.jsx
   */
})
