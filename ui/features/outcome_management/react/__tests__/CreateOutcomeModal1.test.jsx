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
import {act, render as rtlRender, fireEvent, waitFor} from '@testing-library/react'
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

jest.useFakeTimers()

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
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
    onCloseHandlerMock = jest.fn()
    onSuccessMock = jest.fn()
    cache = createCache()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const itBehavesLikeAForm = specProps => {
    const getProps = (props = {}) =>
      defaultProps({
        ...props,
        ...specProps,
      })

    describe('CreateOutcomeModal', () => {
      it('shows modal if isOpen prop true', async () => {
        const {getByText} = render(<CreateOutcomeModal {...getProps()} />)
        expect(getByText('Create Outcome')).toBeInTheDocument()
      })

      it('does not show modal if isOpen prop false', async () => {
        const {queryByText} = render(<CreateOutcomeModal {...getProps({isOpen: false})} />)
        expect(queryByText('Create Outcome')).not.toBeInTheDocument()
      })

      it('calls onCloseHandler on Cancel button click', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText} = render(<CreateOutcomeModal {...getProps()} />)
        await user.click(getByText('Cancel'))
        expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      })

      it('calls onCloseHandler on Close (X) button click', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByRole} = render(<CreateOutcomeModal {...getProps()} />)
        await user.click(within(getByRole('dialog')).getByText('Close'))
        expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      })

      it('does not show error message below Name field on initial load', async () => {
        const {queryByText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        expect(queryByText('Cannot be blank')).not.toBeInTheDocument()
      })

      it('shows error message below Name field if no name after user makes changes to name', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: '123'}})
        fireEvent.change(getByLabelText('Name'), {target: {value: ''}})
        expect(getByText('Cannot be blank')).toBeInTheDocument()
      })

      it('shows error message below Name field if name includes only spaces', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: '  '}})
        expect(getByText('Cannot be blank')).toBeInTheDocument()
      })

      it('shows error message below Name field if name > 255 characters', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })

      it('shows error message below displayName field if displayName > 255 characters', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })

      it('shows error message if friendly description > 255 characters', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'a'.repeat(256)},
        })
        await user.click(getByText('Root account folder'))
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
      })

      it('calls onCloseHandler & onSuccess on Create button click', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByLabelText, getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        await user.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      })

      it('displays the root group and its subgroups in the group selection drill down', async () => {
        const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()],
          isMobileView: true,
        })
        await act(async () => jest.runOnlyPendingTimers())
        expect(getByText('Root account folder')).toBeInTheDocument()
        expect(getByText('Account folder 0')).toBeInTheDocument()
      })

      it('displays the lsh group and its subgroups in the group selection drill down if starterGroupId is provided', async () => {
        const starterGroupId = '100'
        const {queryByText} = render(<CreateOutcomeModal {...defaultProps({starterGroupId})} />, {
          mocks: [...smallOutcomeTree()],
          isMobileView: true,
        })
        await act(async () => jest.runOnlyPendingTimers())
        expect(queryByText('Root account folder')).not.toBeInTheDocument()
        expect(queryByText('Account folder 0')).toBeInTheDocument()
        expect(queryByText('Group 100 folder 0')).toBeInTheDocument()
      })

      it('calls onSuccess if create request succeeds', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree('Account'),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly Description value',
            }),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '100',
            }),
          ],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly Description value'},
        })
        await user.click(getByText('Account folder 0'))
        await user.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(onSuccessMock).toHaveBeenCalledTimes(1)
          expect(onSuccessMock).toHaveBeenCalledWith({
            selectedGroupAncestorIds: ['100', '1'],
          })
        })
      })

      it('displays flash confirmation with proper message if create request succeeds', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly Description value',
            }),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '1',
            }),
          ],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly Description value'},
        })
        await user.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: '"Outcome 123" was successfully created.',
            type: 'success',
          })
        })
      })

      it('displays flash error if create request fails', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              failResponse: true,
              groupId: '1',
            }),
          ],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        await user.click(getByText('Create'))
        await waitFor(() => {
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: 'An error occurred while creating this outcome. Please try again.',
            type: 'error',
          })
        })
      })

      it('displays flash error if create mutation fails', async () => {
        const user = userEvent.setup(USER_EVENT_OPTIONS)
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              failMutation: true,
              groupId: '1',
            }),
          ],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        await user.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: 'An error occurred while creating this outcome. Please try again.',
            type: 'error',
          })
        })
      })

      it('handles create outcome failure due to friendly description', async () => {
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
              failResponse: true,
            }),
          ],
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly description'},
        })
        await user.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: 'An error occurred while creating this outcome. Please try again.',
            type: 'error',
          })
        })
      })
    })
  }

  describe('Mobile', () => {
    itBehavesLikeAForm({isMobileView: true})
  })
})
