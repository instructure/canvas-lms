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
import {render, fireEvent} from '@testing-library/react'
import OutcomeRemoveMultiModal from '../OutcomeRemoveMultiModal'

describe('OutcomeRemoveMultiModal', () => {
  let onCloseHandlerMock
  let onRemoveHandlerMock
  const generateOutcomes = (num, canUnlink) =>
    new Array(num).fill(0).reduce(
      (acc, _val, idx) => ({
        ...acc,
        [idx + 1]: {_id: `${idx + 1}`, title: `Outcome ${idx + 1}`, canUnlink}
      }),
      {}
    )
  const defaultProps = (props = {}, canUnlink = true) => ({
    outcomes: generateOutcomes(2, canUnlink),
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onRemoveHandler: onRemoveHandlerMock,
    ...props
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    onRemoveHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('When all outcomes can be deleted', () => {
    it('shows remove outcomes modal if isOpen prop true', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps()} />)
      expect(getByText('Remove Outcomes?')).toBeInTheDocument()
    })

    it('does not show remove outcomes modal if isOpen prop false', () => {
      const {queryByText} = render(<OutcomeRemoveMultiModal {...defaultProps({isOpen: false})} />)
      expect(queryByText('Remove Outcomes?')).not.toBeInTheDocument()
    })

    it('calls onRemoveHandler on Remove button click', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps()} />)
      fireEvent.click(getByText('Remove Outcomes'))
      expect(onRemoveHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('calls onCloseHandler on Cancel button click', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps()} />)
      fireEvent.click(getByText('Cancel'))
      expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('calls onCloseHandler on Close (X) button click', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps()} />)
      fireEvent.click(getByText('Close'))
      expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('renders remove modal with proper content for single outcome', () => {
      const {getByText} = render(
        <OutcomeRemoveMultiModal {...defaultProps({outcomes: generateOutcomes(1, true)})} />
      )
      expect(getByText('Would you like to remove that outcome?')).toBeInTheDocument()
      expect(getByText('Outcome 1')).toBeInTheDocument()
    })

    it('renders remove modal with proper text for multiple outcomes', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps()} />)
      expect(getByText('Would you like to remove these 2 outcomes?')).toBeInTheDocument()
      expect(getByText('Outcome 1')).toBeInTheDocument()
      expect(getByText('Outcome 2')).toBeInTheDocument()
    })
  })

  describe('When some outcomes cannot be deleted', () => {
    it('shows warning outcomes modal if isOpen prop true', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps({}, false)} />)
      expect(getByText('Please Try Again')).toBeInTheDocument()
    })

    it('does not show warning outcomes modal if isOpen prop false', () => {
      const {queryByText} = render(
        <OutcomeRemoveMultiModal {...defaultProps({isOpen: false}, false)} />
      )
      expect(queryByText('Please Try Again')).not.toBeInTheDocument()
    })

    it('calls onCloseHandler on Close button click', () => {
      const {getAllByText} = render(<OutcomeRemoveMultiModal {...defaultProps({}, false)} />)
      fireEvent.click(getAllByText('Close')[1])
      expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('calls onCloseHandler on Close (X) button click', () => {
      const {getAllByText} = render(<OutcomeRemoveMultiModal {...defaultProps({}, false)} />)
      fireEvent.click(getAllByText('Close')[0])
      expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
    })

    it('renders warn modal with proper content for single outcome', () => {
      const {getByText} = render(
        <OutcomeRemoveMultiModal {...defaultProps({outcomes: generateOutcomes(1, false)})} />
      )
      expect(
        getByText(
          'The following outcome cannot be removed because it is aligned to content. Please unselect it and try again.'
        )
      ).toBeInTheDocument()
      expect(getByText('Outcome 1')).toBeInTheDocument()
    })

    it('renders component with proper text for multiple outcomes', () => {
      const {getByText} = render(<OutcomeRemoveMultiModal {...defaultProps({}, false)} />)
      expect(
        getByText(
          'The following outcomes cannot be removed because they are aligned to content. Please unselect them and try again.'
        )
      ).toBeInTheDocument()
      expect(getByText('Outcome 1')).toBeInTheDocument()
      expect(getByText('Outcome 2')).toBeInTheDocument()
    })
  })
})
