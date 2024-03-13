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

import InheritedTable from '../InheritedTable'

describe('InheritedTable', () => {
  let originalENV
  beforeEach(() => {
    originalENV = global.ENV
    global.ENV = {
      FEATURES: {
        enhanced_developer_keys_tables: true,
      },
    }
  })

  afterEach(() => {
    global.ENV = originalENV
  })

  const idFor = n => `1000000000000${n}`

  const devKeyList = (numKeys = 10) => {
    return [...Array(numKeys).keys()].map(n => ({
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
  }

  const component = (keys, props = {}) => {
    return render(
      <InheritedTable
        label="Inherited Keys"
        prefix="inherited"
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

    it('allows sorting by name', async () => {
      const wrapper = component()

      await userEvent.click(wrapper.getByText('Name')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('key-0')

      await userEvent.click(wrapper.getByText('Name')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('key-9')
    })

    it('allows sorting by id', async () => {
      const wrapper = component()

      await userEvent.click(wrapper.getByText('Id')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent(idFor(0))

      await userEvent.click(wrapper.getByText('Id')) // descending
      expect(firstRow(wrapper)).toHaveTextContent(idFor(9))
    })

    it('allows sorting by type', async () => {
      const wrapper = component()

      await userEvent.click(wrapper.getByText('Type')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('key-0')

      await userEvent.click(wrapper.getByText('Type')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('key-3')
    })

    it('allows sorting by state', async () => {
      const wrapper = component()

      await userEvent.click(wrapper.getByText('State')) // ascending
      expect(firstRow(wrapper)).toHaveTextContent('off')

      await userEvent.click(wrapper.getByText('State')) // descending
      expect(firstRow(wrapper)).toHaveTextContent('on')
    })
  })

  describe('when filtering table', () => {
    const waitForDebounce = () => new Promise(resolve => setTimeout(resolve, 400))

    it('filters by selecting type', async () => {
      const wrapper = component()

      await userEvent.click(wrapper.getByRole('combobox'))
      await userEvent.click(wrapper.getByRole('option', {name: 'LTI Keys'}))
      expect(wrapper.getAllByRole('row')).toHaveLength(2)
    })

    it('filters by searching for name', async () => {
      const wrapper = component()

      await userEvent.type(wrapper.getByRole('searchbox'), 'key-1')
      await waitForDebounce()
      expect(wrapper.getAllByRole('row')).toHaveLength(2)
    })

    it('filters by searching for id', async () => {
      const wrapper = component()

      await userEvent.type(wrapper.getByRole('searchbox'), idFor(1))
      await waitForDebounce()
      console.log(wrapper.getAllByRole('row').map(r => r.textContent))
      expect(wrapper.getAllByRole('row')).toHaveLength(2)
    })

    describe('when flag is off', () => {
      beforeEach(() => {
        global.ENV.FEATURES.enhanced_developer_keys_tables = false
      })

      it('does not allow filtering', () => {
        const wrapper = component()

        expect(wrapper.queryByRole('searchbox')).not.toBeInTheDocument()
      })
    })
  })
})
