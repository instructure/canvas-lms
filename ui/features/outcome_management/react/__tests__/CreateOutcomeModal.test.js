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
import {MockedProvider} from '@apollo/react-testing'
import {createCache} from '@canvas/apollo'
import {within} from '@testing-library/dom'
import CreateOutcomeModal from '../CreateOutcomeModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {
  accountMocks,
  smallOutcomeTree,
  setFriendlyDescriptionOutcomeMock,
  createLearningOutcomeMock
} from '@canvas/outcomes/mocks/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.useFakeTimers()

describe('CreateOutcomeModal', () => {
  let onCloseHandlerMock
  let onSuccessMock
  let cache
  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onSuccess: onSuccessMock,
    ...props
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      friendlyDescriptionFF = true,
      individualOutcomeRatingAndCalculationFF = false,
      mocks = accountMocks({childGroupsCount: 0}),
      isMobileView = false,
      renderer = rtlRender,
      treeBrowserRootGroupId = '1'
    } = {}
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            friendlyDescriptionFF,
            individualOutcomeRatingAndCalculationFF,
            isMobileView,
            treeBrowserRootGroupId
          }
        }}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
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
        ...specProps
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
        const {getByText} = render(<CreateOutcomeModal {...getProps()} />)
        fireEvent.click(getByText('Cancel'))
        expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      })

      it('calls onCloseHandler on Close (X) button click', async () => {
        const {getByRole} = render(<CreateOutcomeModal {...getProps()} />)
        fireEvent.click(within(getByRole('dialog')).getByText('Close'))
        expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      })

      it('does not show error message below Name field on initial load and disables Create button', async () => {
        const {getByText, queryByText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
        expect(queryByText('Cannot be blank')).not.toBeInTheDocument()
      })

      it('shows error message below Name field if no name after user makes changes to name and disables Create button', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: '123'}})
        fireEvent.change(getByLabelText('Name'), {target: {value: ''}})
        expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
        expect(getByText('Cannot be blank')).toBeInTheDocument()
      })

      it('shows error message below Name field if name includes only spaces and disables Create button', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: '  '}})
        expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
        expect(getByText('Cannot be blank')).toBeInTheDocument()
      })

      it('shows error message below Name field if name > 255 characters and disables Create button', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
        expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
      })

      it('shows error message below displayName field if displayName > 255 characters and disables Create button', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...getProps()} />)
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'a'.repeat(256)}})
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
        expect(getByText('Create').closest('button')).toHaveAttribute('disabled')
      })

      it('shows error message if friendly description > 255 characters', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly description'}
        })
        fireEvent.click(getByText('Root account folder'))
        // make sure good FD doesnt disable
        expect(getByText('Create').closest('button')).not.toBeDisabled()

        // but a bad one does
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'a'.repeat(256)}
        })
        expect(getByText('Must be 255 characters or less')).toBeInTheDocument()
        expect(getByText('Create').closest('button')).toBeDisabled()
      })

      it('calls onCloseHandler & onSuccess on Create button click', async () => {
        const {getByLabelText, getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
      })

      it('displays the root group and its subgroups in the group selection drill down', async () => {
        const {getByText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()],
          isMobileView: true
        })
        await act(async () => jest.runOnlyPendingTimers())
        expect(getByText('Root account folder')).toBeInTheDocument()
        expect(getByText('Account folder 0')).toBeInTheDocument()
      })

      it('displays the lsh group and its subgroups in the group selection drill down if starterGroupId is provided', async () => {
        const starterGroupId = '100'
        const {queryByText} = render(<CreateOutcomeModal {...defaultProps({starterGroupId})} />, {
          mocks: [...smallOutcomeTree()],
          isMobileView: true
        })
        await act(async () => jest.runOnlyPendingTimers())
        expect(queryByText('Root account folder')).not.toBeInTheDocument()
        expect(queryByText('Account folder 0')).toBeInTheDocument()
        expect(queryByText('Group 100 folder 0')).toBeInTheDocument()
      })

      it('enables Create button when name is entered and group is selected', async () => {
        const {getByLabelText, getByRole} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [...smallOutcomeTree()]
        })
        await act(async () => jest.runOnlyPendingTimers())
        expect(within(getByRole('dialog')).getByText('Create').closest('button')).toBeDisabled()
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        expect(within(getByRole('dialog')).getByText('Create').closest('button')).not.toBeDisabled()
      })

      it('calls onSuccess if create request succeeds', async () => {
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree('Account'),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly Description value'
            }),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '100'
            })
          ]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly Description value'}
        })
        fireEvent.click(getByText('Account folder 0'))
        fireEvent.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(onSuccessMock).toHaveBeenCalledTimes(1)
          expect(onSuccessMock).toHaveBeenCalledWith({
            selectedGroupAncestorIds: ['100', '1']
          })
        })
      })

      it('displays flash confirmation with proper message if create request succeeds', async () => {
        const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly Description value'
            }),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '1'
            })
          ]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly Description value'}
        })
        fireEvent.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlertSpy).toHaveBeenCalledWith({
            message: '"Outcome 123" was successfully created.',
            type: 'success'
          })
        })
      })

      it('displays flash error if create request fails', async () => {
        const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              failResponse: true,
              groupId: '1'
            })
          ]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.click(getByText('Create'))
        await waitFor(() => {
          expect(showFlashAlertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while creating this outcome. Please try again.',
            type: 'error'
          })
        })
      })

      it('displays flash error if create mutation fails', async () => {
        const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              failMutation: true,
              groupId: '1'
            })
          ]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while creating this outcome. Please try again.',
            type: 'error'
          })
        })
      })

      it('handles create outcome failure due to friendly description', async () => {
        const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '1'
            }),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly description',
              failResponse: true
            })
          ]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly description'}
        })
        fireEvent.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlertSpy).toHaveBeenCalledWith({
            message: 'An error occurred while creating this outcome. Please try again.',
            type: 'error'
          })
        })
      })

      it('displays an error on failed request for account outcome groups', async () => {
        const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: []
        })
        await act(async () => jest.runOnlyPendingTimers())
        const {getByText} = within(getByTestId('loading-error'))
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
      })

      it('displays an error on failed request for course outcome groups', async () => {
        const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
          contextType: 'Course',
          contextId: '2',
          mocks: []
        })
        await act(async () => jest.runOnlyPendingTimers())
        const {getByText} = within(getByTestId('loading-error'))
        expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
      })

      it('does not throw error if friendly description mutation succeeds', async () => {
        const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
        const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
          mocks: [
            ...smallOutcomeTree(),
            createLearningOutcomeMock({
              title: 'Outcome 123',
              displayName: 'Display name',
              description: '',
              groupId: '1'
            }),
            setFriendlyDescriptionOutcomeMock({
              inputDescription: 'Friendly description'
            })
          ]
        })
        await act(async () => jest.runOnlyPendingTimers())
        fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
        fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
        fireEvent.change(getByLabelText('Friendly description (for parent/student display)'), {
          target: {value: 'Friendly description'}
        })
        fireEvent.click(getByText('Root account folder'))
        fireEvent.click(getByText('Create'))
        await act(async () => jest.runOnlyPendingTimers())
        await waitFor(() => {
          expect(showFlashAlertSpy).toHaveBeenCalledWith({
            message: '"Outcome 123" was successfully created.',
            type: 'success'
          })
        })
      })

      describe('with Friendly Description Feature Flag disabled', () => {
        it('does not display Friendly Description field in modal', async () => {
          const {queryByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            friendlyDescriptionFF: false
          })
          await act(async () => jest.runOnlyPendingTimers())
          expect(
            queryByLabelText('Friendly description (for parent/student display)')
          ).not.toBeInTheDocument()
        })

        it('does not call friendly description mutation when creating outcome', async () => {
          const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
          const {getByText, getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
            friendlyDescriptionFF: false,
            mocks: [
              ...smallOutcomeTree(),
              createLearningOutcomeMock({
                title: 'Outcome 123',
                displayName: 'Display name',
                description: '',
                groupId: '1'
              })
            ]
          })
          await act(async () => jest.runOnlyPendingTimers())
          fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
          fireEvent.change(getByLabelText('Friendly Name'), {target: {value: 'Display name'}})
          fireEvent.click(getByText('Create'))
          await act(async () => jest.runOnlyPendingTimers())
          // if setFriendlyDescription mutation is called the expectation below will fail
          await waitFor(() => {
            expect(showFlashAlertSpy).toHaveBeenCalledWith({
              message: '"Outcome 123" was successfully created.',
              type: 'success'
            })
          })
        })
      })

      describe('Invidiual Outcome Proficiency and Calculation Feature Flag', () => {
        describe('when feature flag enabled', () => {
          it('displays Calculation Method selection form', async () => {
            const {getByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />, {
              individualOutcomeRatingAndCalculationFF: true
            })
            await act(async () => jest.runOnlyPendingTimers())
            expect(getByLabelText('Calculation Method')).toBeInTheDocument()
          })

          it('displays Proficiency Ratings selection form', async () => {
            const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
              individualOutcomeRatingAndCalculationFF: true
            })
            await act(async () => jest.runOnlyPendingTimers())
            expect(getByTestId('outcome-management-ratings')).toBeInTheDocument()
          })

          it('creates outcome with calculation method and proficiency ratings', async () => {
            const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
            const {getByText, getByLabelText, getByDisplayValue} = render(
              <CreateOutcomeModal {...defaultProps()} />,
              {
                individualOutcomeRatingAndCalculationFF: true,
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
                    individualRatings: true
                  })
                ]
              }
            )
            await act(async () => jest.runOnlyPendingTimers())
            fireEvent.change(getByLabelText('Name'), {target: {value: 'Outcome 123'}})
            fireEvent.change(getByLabelText('Friendly Name'), {
              target: {value: 'Display name'}
            })
            fireEvent.click(getByDisplayValue('Decaying Average'))
            fireEvent.click(getByText('n Number of Times'))
            fireEvent.click(getByText('Create'))
            await act(async () => jest.runOnlyPendingTimers())
            await waitFor(() => {
              expect(showFlashAlertSpy).toHaveBeenCalledWith({
                message: '"Outcome 123" was successfully created.',
                type: 'success'
              })
            })
          })

          it('displays horizontal divider between ratings and calculation method which is hidden from screen readers', async () => {
            const {getByTestId} = render(<CreateOutcomeModal {...defaultProps()} />, {
              individualOutcomeRatingAndCalculationFF: true
            })
            await act(async () => jest.runOnlyPendingTimers())
            expect(getByTestId('outcome-create-modal-horizontal-divider')).toBeInTheDocument()
          })
        })

        describe('when feature flag disabled', () => {
          it('does not display Calculation Method selection form', async () => {
            const {queryByLabelText} = render(<CreateOutcomeModal {...defaultProps()} />)
            await act(async () => jest.runOnlyPendingTimers())
            expect(queryByLabelText('Calculation Method')).not.toBeInTheDocument()
          })

          it('does not display Proficiency Ratings selection form', async () => {
            const {queryByTestId} = render(<CreateOutcomeModal {...defaultProps()} />)
            await act(async () => jest.runOnlyPendingTimers())
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
