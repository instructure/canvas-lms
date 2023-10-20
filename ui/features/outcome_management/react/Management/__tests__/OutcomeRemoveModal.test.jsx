/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {createCache} from '@canvas/apollo'
import {MockedProvider} from '@apollo/react-testing'
import {render as realRender, fireEvent, waitFor} from '@testing-library/react'
import OutcomeRemoveModal from '../OutcomeRemoveModal'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {accountMocks, deleteOutcomeMock} from '@canvas/outcomes/mocks/Management'

const outcomesGenerator = (startId, count, canUnlink = true, sameGroup = false, title = '') =>
  new Array(count).fill(0).reduce(
    (acc, _curr, idx) => ({
      ...acc,
      [`${startId + idx}`]: {
        _id: `${idx + 100}`,
        linkId: `${startId + idx}`,
        title: title || `Learning Outcome ${startId + idx}`,
        canUnlink,
        parentGroupId: sameGroup ? 1001 : `${1001 + idx}`,
        parentGroupTitle: `Outcome Group ${sameGroup ? 1001 : 1001 + idx}`,
      },
    }),
    {}
  )

describe('OutcomeRemoveModal', () => {
  let onCloseHandlerMock
  let onCleanupHandlerMock
  let onRemoveLearningOutcomesHandlerMock
  let removeOutcomes
  let cache

  const defaultProps = (props = {}) => ({
    outcomes: outcomesGenerator(1, 1),
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onCleanupHandler: onCleanupHandlerMock,
    onRemoveLearningOutcomesHandler: onRemoveLearningOutcomesHandlerMock,
    removeOutcomes,
    ...props,
  })

  beforeEach(() => {
    cache = createCache()
    onCloseHandlerMock = jest.fn()
    onCleanupHandlerMock = jest.fn()
    onRemoveLearningOutcomesHandlerMock = jest.fn()
    removeOutcomes = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '1', mocks = accountMocks()} = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }
  describe('With single outcome provided', () => {
    it('shows modal if isOpen prop true', () => {
      const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
      expect(getByText('Remove Outcome?')).toBeInTheDocument()
    })

    it('does not show modal if isOpen prop false', () => {
      const {queryByText} = render(<OutcomeRemoveModal {...defaultProps({isOpen: false})} />)
      expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
    })

    it('calls onCleanupHandler on Remove button click', async () => {
      const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />, {
        mocks: [deleteOutcomeMock()],
      })
      fireEvent.click(getByText('Remove Outcome'))
      expect(onCleanupHandlerMock).toHaveBeenCalled()
    })

    it('calls onCloseHandler on Cancel button click', () => {
      const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
      fireEvent.click(getByText('Cancel'))
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('calls onCloseHandler on Close (X) button click', () => {
      const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
      fireEvent.click(getByText('Close'))
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('renders component with proper text for Account context', () => {
      const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />)
      expect(
        getByText('Are you sure that you want to remove this outcome from this account?')
      ).toBeInTheDocument()
    })

    it('renders component with proper text for Course context', () => {
      const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      expect(
        getByText('Are you sure that you want to remove this outcome from this course?')
      ).toBeInTheDocument()
    })

    describe('deletes outcome', () => {
      it('calls onRemoveLearningOutcomesHandler after request succedes', async () => {
        const {getByText} = render(<OutcomeRemoveModal {...defaultProps()} />, {
          mocks: [deleteOutcomeMock()],
        })
        fireEvent.click(getByText('Remove Outcome'))

        await waitFor(() => {
          expect(onRemoveLearningOutcomesHandlerMock).toHaveBeenCalledWith(['1'])
        })
      })
    })
  })

  describe('With multiple outcomes provided', () => {
    it('shows modal if isOpen prop true', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2),
          })}
        />
      )
      expect(getByText('Remove Outcomes?')).toBeInTheDocument()
    })

    it('does not show modal if isOpen prop false', () => {
      const {queryByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            isOpen: false,
            outcomes: outcomesGenerator(1, 2),
          })}
        />
      )
      expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
    })

    it('calls onCleanupHandler on Remove button click', async () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2),
          })}
        />,
        {
          mocks: [deleteOutcomeMock()],
        }
      )
      fireEvent.click(getByText('Remove Outcomes'))
      expect(onCleanupHandlerMock).toHaveBeenCalled()
    })

    it('calls onCloseHandler on Cancel button click', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2),
          })}
        />
      )
      fireEvent.click(getByText('Cancel'))
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('calls onCloseHandler on Close (X) button click', () => {
      const {getAllByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2),
          })}
        />
      )
      const closeBtn = getAllByText('Close')[getAllByText('Close').length - 1]
      fireEvent.click(closeBtn)
      expect(onCloseHandlerMock).toHaveBeenCalled()
    })

    it('renders component with proper text for Account context', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2),
          })}
        />
      )
      expect(
        getByText('Are you sure that you want to remove these 2 outcomes from this account?')
      ).toBeInTheDocument()
    })

    it('renders component with proper text for Course context', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2),
          })}
        />,
        {
          contextType: 'Course',
        }
      )
      expect(
        getByText('Are you sure that you want to remove these 2 outcomes from this course?')
      ).toBeInTheDocument()
    })

    it('renders component with proper text when both removable and non-removable outcomes are provided in account context', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: {
              ...outcomesGenerator(1, 3),
              ...outcomesGenerator(1, 2, false),
            },
          })}
        />
      )
      expect(
        getByText(
          'Some of the outcomes that you have selected cannot be removed because they are aligned to content in this account. Do you want to proceed with removing the outcomes without alignments?'
        )
      ).toBeInTheDocument()
    })

    it('renders component with proper text when both removable and non-removable outcomes are provided in course context', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: {
              ...outcomesGenerator(1, 3),
              ...outcomesGenerator(1, 2, false),
            },
          })}
        />,
        {
          contextType: 'Course',
        }
      )
      expect(
        getByText(
          'Some of the outcomes that you have selected cannot be removed because they are aligned to content in this course. Do you want to proceed with removing the outcomes without alignments?'
        )
      ).toBeInTheDocument()
    })

    it('renders component with proper text when only non-removable outcomes are provided in account context', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2, false),
          })}
        />
      )
      expect(
        getByText(
          'The outcomes that you have selected cannot be removed because they are aligned to content in this account.'
        )
      ).toBeInTheDocument()
    })

    it('renders component with proper text when only non-removable outcomes are provided in course context', () => {
      const {getByText} = render(
        <OutcomeRemoveModal
          {...defaultProps({
            outcomes: outcomesGenerator(1, 2, false),
          })}
        />,
        {
          contextType: 'Course',
        }
      )
      expect(
        getByText(
          'The outcomes that you have selected cannot be removed because they are aligned to content in this course.'
        )
      ).toBeInTheDocument()
    })

    it('displays group names in alphanumerical order', async () => {
      const sortedOutcomes = outcomesGenerator(1, 10, true)
      const unsortedOutcomes = {
        9: sortedOutcomes[9],
        5: sortedOutcomes[5],
        3: sortedOutcomes[3],
        7: sortedOutcomes[7],
      }
      const {findAllByText} = render(
        <OutcomeRemoveModal {...defaultProps({outcomes: unsortedOutcomes})} />
      )
      const outcomes = await findAllByText(/Outcome Group/)
      expect(outcomes[0]).toContainHTML('Outcome Group 1003')
      expect(outcomes[1]).toContainHTML('Outcome Group 1005')
      expect(outcomes[2]).toContainHTML('Outcome Group 1007')
      expect(outcomes[3]).toContainHTML('Outcome Group 1009')
    })

    it('displays outcome names in alphanumerical order within a group', async () => {
      const sortedOutcomes = outcomesGenerator(1, 10, true, true)
      const unsortedOutcomes = {
        9: sortedOutcomes[9],
        5: sortedOutcomes[5],
        3: sortedOutcomes[3],
        7: sortedOutcomes[7],
      }
      const {findAllByText} = render(
        <OutcomeRemoveModal {...defaultProps({outcomes: unsortedOutcomes})} />
      )
      const outcomes = await findAllByText(/Learning Outcome/)
      expect(outcomes[0]).toContainHTML('Learning Outcome 3')
      expect(outcomes[1]).toContainHTML('Learning Outcome 5')
      expect(outcomes[2]).toContainHTML('Learning Outcome 7')
      expect(outcomes[3]).toContainHTML('Learning Outcome 9')
    })

    describe('deletes outcomes', () => {
      it('calls onRemoveLearningOutcomesHandler after request succedes', async () => {
        const {getByText} = render(
          <OutcomeRemoveModal
            {...defaultProps({
              outcomes: outcomesGenerator(1, 2, true),
            })}
          />,
          {
            mocks: [deleteOutcomeMock({ids: ['1', '2']})],
          }
        )
        fireEvent.click(getByText('Remove Outcomes'))

        await waitFor(() => {
          expect(onRemoveLearningOutcomesHandlerMock).toHaveBeenCalledWith(['1', '2'])
        })
      })
    })
  })
})
