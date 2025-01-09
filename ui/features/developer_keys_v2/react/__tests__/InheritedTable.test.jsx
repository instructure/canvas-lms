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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import InheritedTable from '../InheritedTable'
import 'jquery-migrate'

describe('InheritedTable', () => {
  let container

  beforeEach(() => {
    container = document.createElement('div')
    container.id = 'fixtures'
    document.body.appendChild(container)
  })

  afterEach(() => {
    container.remove()
    window.ENV = {}
    jest.clearAllMocks()
  })

  const idFor = n => `1000000000000${n}`

  const devKeyList = (numKeys = 10) => {
    return [...Array(numKeys).keys()].map(n => ({
      id: idFor(n),
      name: `key-${n}`,
      email: `email-${n}`,
      access_token_count: n * 2,
      is_lti_key: n === 3,
      api_key: 'abc12345678',
      created_at: '2023-12-12T20:36:50Z',
      visible: true,
    }))
  }

  const renderComponent = (keyList, props = {}) => {
    return render(
      <InheritedTable
        label="Inherited Keys"
        prefix="inherited"
        store={{dispatch: jest.fn()}}
        actions={{
          makeVisibleDeveloperKey: jest.fn(),
          makeInvisibleDeveloperKey: jest.fn(),
          activateDeveloperKey: jest.fn(),
          deactivateDeveloperKey: jest.fn(),
          deleteDeveloperKey: jest.fn(),
          editDeveloperKey: jest.fn(),
          developerKeysModalOpen: jest.fn(),
          setBindingWorkflowState: jest.fn(),
          updateDeveloperKey: jest.fn(),
        }}
        developerKeysList={keyList || devKeyList()}
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
    const {getByRole, getByText} = renderComponent([])
    expect(getByRole('table')).toBeInTheDocument()
    expect(getByText('Nothing here yet')).toBeInTheDocument()
  })

  it('renders a DeveloperKey for each key', () => {
    const {getAllByRole} = renderComponent()
    expect(getAllByRole('row')).toHaveLength(11) // header + 10 rows
  })

  describe('when sorting table', () => {
    const firstRow = wrapper => wrapper.getAllByRole('row')[1]

    it('defaults to descending id', () => {
      const wrapper = renderComponent()
      expect(firstRow(wrapper)).toHaveTextContent(idFor(9))
    })

    it('allows sorting by name', async () => {
      const wrapper = renderComponent()
      await userEvent.click(wrapper.getByText('Name'))
      expect(firstRow(wrapper)).toHaveTextContent('key-0')

      await userEvent.click(wrapper.getByText('Name'))
      expect(firstRow(wrapper)).toHaveTextContent('key-9')
    })

    it('allows sorting by id', async () => {
      const wrapper = renderComponent()
      await userEvent.click(wrapper.getByText('Id'))
      expect(firstRow(wrapper)).toHaveTextContent(idFor(0))

      await userEvent.click(wrapper.getByText('Id'))
      expect(firstRow(wrapper)).toHaveTextContent(idFor(9))
    })

    it('allows sorting by state', async () => {
      const list = devKeyList().map((key, i) => ({
        ...key,
        developer_key_account_binding: {workflow_state: i % 2 === 0 ? 'on' : 'off'},
      }))
      const wrapper = renderComponent(list)
      await userEvent.click(wrapper.getByText('State'))
      expect(firstRow(wrapper)).toHaveTextContent('off')

      await userEvent.click(wrapper.getByText('State'))
      expect(firstRow(wrapper)).toHaveTextContent('on')
    })
  })

  describe('when filtering table', () => {
    const waitForDebounce = () => new Promise(resolve => setTimeout(resolve, 400))

    it('filters by selecting type', async () => {
      const wrapper = renderComponent()
      await userEvent.click(wrapper.getByRole('combobox'))
      await userEvent.click(wrapper.getByRole('option', {name: 'LTI Keys'}))
      expect(wrapper.getAllByRole('row')).toHaveLength(2) // header + 1 LTI key
    })

    it('filters by searching for name', async () => {
      const wrapper = renderComponent()
      await userEvent.type(wrapper.getByRole('searchbox'), 'key-1')
      await waitForDebounce()
      expect(wrapper.getAllByRole('row')).toHaveLength(2)
    })

    it('filters by searching for id', async () => {
      const wrapper = renderComponent()
      await userEvent.type(wrapper.getByRole('searchbox'), idFor(1))
      await waitForDebounce()
      expect(wrapper.getAllByRole('row')).toHaveLength(2)
    })
  })
})
