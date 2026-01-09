/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {MockedProvider} from '@apollo/client/testing'
import {createCache} from '@canvas/apollo-v3'
import CreateOutcomeModal from '../CreateOutcomeModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {smallOutcomeTree, createLearningOutcomeMock} from '@canvas/outcomes/mocks/Management'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

vi.useFakeTimers()

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(() => vi.fn(() => {})),
}))

const USER_EVENT_OPTIONS = {delay: null, pointerEventsCheck: PointerEventsCheckLevel.Never}

describe('CreateOutcomeModal', () => {
  let onCloseHandlerMock
  let onSuccessMock
  let cache
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onSuccess: onSuccessMock,
    ...props,
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      friendlyDescriptionFF = true,
      accountLevelMasteryScalesFF = true,
      mocks = [],
      isMobileView = false,
      renderer = rtlRender,
      treeBrowserRootGroupId = '1',
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            friendlyDescriptionFF,
            accountLevelMasteryScalesFF,
            isMobileView,
            treeBrowserRootGroupId,
          },
        }}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>,
    )
  }

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
    onSuccessMock = vi.fn()
    cache = createCache()
    vi.clearAllTimers()
  })

  afterEach(() => {
    vi.clearAllMocks()
    vi.clearAllTimers()
  })

  describe('Mobile', () => {
    describe('Account Level Mastery Scales Feature Flag', () => {
      describe('when feature flag disabled - interactions', () => {
        it('creates outcome with calculation method and proficiency ratings', async () => {
          const user = userEvent.setup(USER_EVENT_OPTIONS)
          const {getByText, getByLabelText, getByDisplayValue} = render(
            <CreateOutcomeModal {...defaultProps()} />,
            {
              accountLevelMasteryScalesFF: false,
              isMobileView: true,
              mocks: [
                ...smallOutcomeTree(),
                createLearningOutcomeMock({
                  title: 'Outcome 123',
                  displayName: 'Display name',
                  description: '',
                  groupId: '1',
                  calculationMethod: 'n_mastery',
                  calculationInt: 5,
                  individualCalculation: true,
                  individualRatings: true,
                }),
              ],
            },
          )
          await act(async () => vi.runOnlyPendingTimers())
          fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
          fireEvent.change(getByLabelText('Friendly Name'), {
            target: {value: 'Display name'},
          })
          await user.click(getByDisplayValue('Decaying Average'))
          await user.click(getByText('n Number of Times'))
          await user.click(getByText('Create'))
          await act(async () => vi.runAllTimersAsync())
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: '"Outcome 123" was successfully created.',
            type: 'success',
          })
        })

        it('sets focus on rating description if error in both description and points and click on Create button', async () => {
          const user = userEvent.setup(USER_EVENT_OPTIONS)
          const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            accountLevelMasteryScalesFF: false,
            isMobileView: true,
          })
          fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
          const ratingDescription = getByLabelText('Change description for mastery level 2')
          fireEvent.change(ratingDescription, {target: {value: ''}})
          const ratingPoints = getByLabelText('Change points for mastery level 2')
          fireEvent.change(ratingPoints, {target: {value: '-1'}})
          expect(getByText('Missing required description')).toBeInTheDocument()
          expect(getByText('Negative points')).toBeInTheDocument()
          await user.click(getByText('Create'))
          expect(ratingPoints).not.toBe(document.activeElement)
          expect(ratingDescription).toBe(document.activeElement)
        })

        it('sets focus on mastery points if error in mastery points and calculation method and click on Create button', async () => {
          const user = userEvent.setup(USER_EVENT_OPTIONS)
          const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            accountLevelMasteryScalesFF: false,
            isMobileView: true,
          })
          fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
          const masteryPoints = getByLabelText('Change mastery points')
          fireEvent.change(masteryPoints, {target: {value: '-1'}})
          const calcInt = getByLabelText('Proficiency Calculation')
          fireEvent.change(calcInt, {target: {value: '999'}})
          expect(getByText('Negative points')).toBeInTheDocument()
          expect(getByText('Must be between 1 and 99')).not.toBeNull()
          await user.click(getByText('Create'))
          expect(calcInt).not.toBe(document.activeElement)
          expect(masteryPoints).toBe(document.activeElement)
        })
      })
    })
  })
})
