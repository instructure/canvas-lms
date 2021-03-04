/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import $ from 'jquery'
import {MockedProvider} from '@apollo/react-testing'
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
import 'compiled/jquery.rails_flash_notifications'
import React from 'react'
import {createCache} from 'jsx/canvas-apollo'
import OutcomeManagementPanel from '../index'
import OutcomesContext from 'jsx/outcomes/contexts/OutcomesContext'

import {accountMocks, courseMocks, groupDetailMocks, groupMocks} from './mocks'

jest.useFakeTimers()

describe('OutcomeManagementPanel', () => {
  let cache

  beforeEach(() => {
    cache = createCache()
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '1', mocks = accountMocks({childGroupsCount: 0})} = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders the empty billboard for accounts without child outcomes', async () => {
    const {getByText} = render(<OutcomeManagementPanel contextType="Account" contextId="1" />)

    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcomes have not been added to this account yet/)).not.toBeNull()
  })

  it('renders the empty billboard for courses without child outcomes', async () => {
    const {getByText} = render(<OutcomeManagementPanel contextType="Course" contextId="2" />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 0}),
    })
    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcomes have not been added to this course yet/)).not.toBeNull()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText, getAllByText} = render(
      <OutcomeManagementPanel contextType="Account" contextId="1" />,
      {
        mocks: accountMocks({childGroupsCount: 2}),
      }
    )
    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Account folder 1')).toBeInTheDocument()
    expect(getAllByText('2 Groups | 2 Outcomes').length).toBe(2)
  })

  it('loads outcome group data for Course', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 2}),
    })
    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Course folder 0')).toBeInTheDocument()
    expect(getByText('Course folder 1')).toBeInTheDocument()
    expect(getAllByText('10 Groups | 2 Outcomes').length).toBe(2)
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel contextType="Account" contextId="1" />, {
      mocks: [...accountMocks({childGroupsCount: 2}), ...groupMocks({groupId: 100})],
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('displays an error on failed request for course outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText} = render(<OutcomeManagementPanel contextType="Course" contextId="2" />, {
      contextType: 'Course',
      mocks: [],
    })
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading course outcomes.')
    expect(getByText(/course/)).toBeInTheDocument()
  })

  it('displays an error on failed request for account outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText} = render(<OutcomeManagementPanel contextType="Account" contextId="1" />, {
      mocks: [],
    })
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading account outcomes.')
    expect(getByText(/account/)).toBeInTheDocument()
  })

  it('loads group detail data correctly', async () => {
    const {getByText} = render(<OutcomeManagementPanel contextType="Course" contextId="2" />, {
      contextType: 'Course',
      contextId: '2',
      mocks: [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: 200}),
        ...groupDetailMocks({groupId: 200}),
      ],
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Group 200 Outcomes')).toBeInTheDocument()
    expect(getByText('Outcome 1 - Group 200')).toBeInTheDocument()
    expect(getByText('Outcome 2 - Group 200')).toBeInTheDocument()
  })
})
