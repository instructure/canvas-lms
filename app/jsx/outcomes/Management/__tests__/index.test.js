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
import {within} from '@testing-library/dom'
import 'compiled/jquery.rails_flash_notifications'
import React from 'react'
import {createCache} from 'jsx/canvas-apollo'
import OutcomeManagementPanel from '../index'
import OutcomesContext from 'jsx/outcomes/contexts/OutcomesContext'
import {accountMocks, courseMocks, groupDetailMocks, groupMocks} from './mocks'
import * as api from '../api'
import * as FlashAlert from '../../../shared/FlashAlert'

jest.useFakeTimers()

describe('OutcomeManagementPanel', () => {
  let cache

  beforeEach(() => {
    cache = createCache()
  })

  const groupDetailDefaultProps = {
    contextType: 'Course',
    contextId: '2',
    mocks: [
      ...courseMocks({childGroupsCount: 2}),
      ...groupMocks({groupId: 200}),
      ...groupDetailMocks({groupId: 200})
    ]
  }

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

  const renderWithGroupDetail = children =>
    render(children, {
      contextType: 'Course',
      contextId: '2',
      mocks: [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: 200}),
        ...groupDetailMocks({groupId: 200})
      ]
    })

  it('renders the empty billboard for accounts without child outcomes', async () => {
    const {getByText} = render(<OutcomeManagementPanel />)
    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcomes have not been added to this account yet/)).not.toBeNull()
  })

  it('renders the empty billboard for courses without child outcomes', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 0})
    })
    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcomes have not been added to this course yet/)).not.toBeNull()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
      mocks: accountMocks({childGroupsCount: 2})
    })
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
      mocks: courseMocks({childGroupsCount: 2})
    })
    await act(async () => jest.runAllTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Course folder 0')).toBeInTheDocument()
    expect(getByText('Course folder 1')).toBeInTheDocument()
    expect(getAllByText('10 Groups | 2 Outcomes').length).toBe(2)
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: [
        ...accountMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: 100}),
        ...groupDetailMocks({groupId: 100})
      ]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('displays an error on failed request for course outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading course outcomes.')
    expect(getByText(/course/)).toBeInTheDocument()
  })

  it('displays an error on failed request for account outcome groups', async () => {
    const flashMock = jest.spyOn($, 'flashError').mockImplementation()
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: []
    })
    await act(async () => jest.runAllTimers())
    expect(flashMock).toHaveBeenCalledWith('An error occurred while loading account outcomes.')
    expect(getByText(/account/)).toBeInTheDocument()
  })

  it('loads group detail data correctly', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Group 200 Outcomes')).toBeInTheDocument()
    expect(getByText('Outcome 1 - Group 200')).toBeInTheDocument()
    expect(getByText('Outcome 2 - Group 200')).toBeInTheDocument()
  })

  it('shows remove group modal if remove option from group menu is selected', async () => {
    const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Outcome Group Menu'))
    fireEvent.click(within(getByRole('menu')).getByText('Remove'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Remove Group?')).toBeInTheDocument()
  })

  describe('Moving a group', () => {
    it('shows move group modal if move option from group menu is selected', async () => {
      const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(getByText('Outcome Group Menu'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => jest.runAllTimers())
      expect(getByText('Where would you like to move this group?')).toBeInTheDocument()
    })

    it('shows successful flash message when moving a group succeeds', async () => {
      // Flash alert & API mocks
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      jest.spyOn(api, 'moveOutcomeGroup').mockImplementation(() => Promise.resolve({status: 200}))

      const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runAllTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runAllTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Outcome Group Menu'))
      fireEvent.click(within(getByRole('menu')).getByText('Move'))
      await act(async () => jest.runAllTimers())
      // Move Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runAllTimers())
      // moveOutcomeGroup API call & success flash alert
      expect(api.moveOutcomeGroup).toHaveBeenCalledWith('Course', '2', 200, 201)
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: '"Group 200" has been moved to "Course folder 1".',
        type: 'success'
      })
    })

    it('shows error flash message when moving a group fails', async () => {
      // Flash alert & API mocks
      const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
      jest
        .spyOn(api, 'moveOutcomeGroup')
        .mockImplementation(() => Promise.reject(new Error('Network error')))

      const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runAllTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runAllTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Outcome Group Menu'))
      fireEvent.click(within(getByRole('menu')).getByText('Move'))
      await act(async () => jest.runAllTimers())
      // Move Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runAllTimers())
      // moveOutcomeGroup API call & error flash alert
      expect(api.moveOutcomeGroup).toHaveBeenCalledWith('Course', '2', 200, 201)
      await act(async () => jest.runAllTimers())
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'An error occurred moving group "Group 200": Network error',
        type: 'error'
      })
    })
  })

  it('selects/unselects outcome via checkbox', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Select outcome')[0])
    expect(getByText('1 Outcome Selected')).toBeInTheDocument()
    fireEvent.click(getAllByText('Select outcome')[0])
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
  })

  it('shows remove outcome modal if remove option from individual outcome menu is selected', async () => {
    const {getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Remove'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Remove Outcome?')).toBeInTheDocument()
  })

  it('shows edit outcome modal if edit option from individual outcome menu is selected', async () => {
    const {getByText, getAllByText, getByRole} = renderWithGroupDetail(
      <OutcomeManagementPanel contextType="Course" contextId="2" />
    )
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('clears selected outcome when edit outcome modal is closed', async () => {
    const {getByText, getAllByText, queryByText, getByRole} = renderWithGroupDetail(
      <OutcomeManagementPanel contextType="Course" contextId="2" />
    )
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Edit Outcome')).not.toBeInTheDocument()
  })

  it('clears selected outcome when remove outcome modal is closed', async () => {
    const {getByText, getAllByText, queryByText, getByRole} = renderWithGroupDetail(
      <OutcomeManagementPanel contextType="Course" contextId="2" />
    )
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Remove'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
  })
})
