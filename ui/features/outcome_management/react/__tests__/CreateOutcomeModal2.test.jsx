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
import {within} from '@testing-library/dom'
import CreateOutcomeModal from '../CreateOutcomeModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {
  accountMocks,
  smallOutcomeTree,
  setFriendlyDescriptionOutcomeMock,
  createLearningOutcomeMock,
  createOutcomeGroupMocks,
} from '@canvas/outcomes/mocks/Management'
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
      mocks = accountMocks({childGroupsCount: 0}),
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

  const itBehavesLikeAForm = specProps => {
    const getProps = (props = {}) =>
      defaultProps({
        ...props,
        ...specProps,
      })

    describe('CreateOutcomeModal', () => {
      it('displays an error on failed request for account outcome groups', async () => {
        const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [],
        })
        await act(async () => vi.runOnlyPendingTimers())
        const {getByText} = within(getByTestId('loading-error'))
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
      })

      it('displays an error on failed request for course outcome groups', async () => {
        const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
          contextType: 'Course',
          contextId: '2',
          mocks: [],
        })
        await act(async () => vi.runOnlyPendingTimers())
        const {getByText} = within(getByTestId('loading-error'))
        expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
      })

      it('does not throw error if friendly description mutation succeeds', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '1',
            }),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly description',
            }),
          ],
        })
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly description'},
        })
        await user.click(getByText('Root account folder'))
        await user.click(getByText('Create'))
        await act(async () => vi.runAllTimersAsync())
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: '"Outcome 123" was successfully created.',
          type: 'success',
        })
      })

      it('does not submit form if error in form and click on Create button', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        const friendlyName = getByLabelText('Friendly Name')
        fireEvent.change(friendlyName, {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
        await user.click(getByText('Create'))
        expect(onCloseHandlerMock).not.toHaveBeenCalled()
      })

      it('sets focus on first field with error if multiple errors in form and click on Create button', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText, queryAllByText} = render(
          <CreateOutcomeModal {...defaultProps()} />,
        )
        await act(async () => vi.runOnlyPendingTimers())
        const name = getByLabelText('Name')
        const friendlyName = getByLabelText('Friendly Name')
        const friendlyDescription = getByLabelText(
          'Friendly description (for parent/student display)',
        )
        fireEvent.change(name, {target: {value: 'a'.repeat(256)}})
        fireEvent.change(friendlyName, {target: {value: 'b'.repeat(256)}})
        fireEvent.change(friendlyDescription, {target: {value: 'c'.repeat(256)}})
        expect(queryAllByText('Must be 255 characters or less')).toHaveLength(3)
        await user.click(getByText('Create'))
        expect(friendlyDescription).not.toBe(document.activeElement)
        expect(friendlyName).not.toBe(document.activeElement)
        expect(name).toBe(document.activeElement)
      })

      it('sets focus on create button after creation of a new group', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText, getByTestId} = render(
          <CreateOutcomeModal {...defaultProps()} />,
          {
            friendlyDescriptionFF: false,
            mocks: [
              ...accountMocks({childGroupsCount: 0}),
              ...createOutcomeGroupMocks({
                parentOutcomeGroupId: '1',
                title: 'test',
              }),
            ],
          },
        )
        await act(async () => vi.runOnlyPendingTimers())
        await user.click(getByText('Create New Group'))
        fireEvent.change(getByLabelText('Enter new group name'), {target: {value: 'test'}})
        await user.click(getByText('Create new group'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByTestId('create-button')).toHaveFocus()
      })

      describe('with Friendly Description Feature Flag disabled', () => {
        it('does not display Friendly Description field in modal', async () => {
          const {queryByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            friendlyDescriptionFF: false,
          })
          await act(async () => vi.runOnlyPendingTimers())
          expect(
            queryByLabelText('Friendly description (for parent/student display)'),
          ).not.toBeInTheDocument()
        })

        it('does not call friendly description mutation when creating outcome', async () => {
          const user = userEvent.setup(USER_EVENT_OPTIONS)
          const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            friendlyDescriptionFF: false,
            mocks: [
              ...smallOutcomeTree(),
              createLearningOutcomeMock({
                title: 'Outcome 123',
                displayName: 'Display name',
                description: '',
                groupId: '1',
              }),
            ],
          })
          await act(async () => vi.runOnlyPendingTimers())
          fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
          fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
          await user.click(getByText('Create'))
          await act(async () => vi.runAllTimersAsync())
          // if setFriendlyDescription mutation is called the expectation below will fail
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: '"Outcome 123" was successfully created.',
            type: 'success',
          })
        })
      })

      describe('Account Level Mastery Scales Feature Flag', () => {
        describe('when feature flag enabled', () => {
          it('does not display Calculation Method selection form', async () => {
            const {queryByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
            await act(async () => vi.runOnlyPendingTimers())
            expect(queryByLabelText('Calculation Method')).not.toBeInTheDocument()
          })

          it('does not display Proficiency Ratings selection form', async () => {
            const {queryByTestId} = render(<CreateOutcomeModal {...defaultProps()} />)
            await act(async () => vi.runOnlyPendingTimers())
            expect(queryByTestId('outcome-management-ratings')).not.toBeInTheDocument()
          })
        })
      })
    })
  }

  describe('Mobile', () => {
    itBehavesLikeAForm({isMobileView: true})
  })
})
