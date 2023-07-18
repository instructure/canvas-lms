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
import {fireEvent, render} from '@testing-library/react'

import {WordCountModal, WordCountModalProps} from '../WordCountModal'
import {HEADERS} from '../../utils/tableContent'

const defaultProps: WordCountModalProps = {
  headers: HEADERS,
  rows: [
    {label: 'Words', documentCount: 0, selectionCount: 1},
    {label: 'Characters (no spaces)', documentCount: 2, selectionCount: 3},
    {label: 'Characters', documentCount: 4, selectionCount: 5},
  ],
  onDismiss: jest.fn(),
}

const renderModal = (overrideProps = {}) => {
  return render(<WordCountModal {...defaultProps} {...overrideProps} />)
}

describe('WordCountModal', () => {
  describe('onDismiss', () => {
    it('is called when the header close button is clicked', () => {
      const {getAllByText} = renderModal()
      fireEvent.click(getAllByText(/close/i)[0])
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })

    it('is called when the footer close button is clicked', () => {
      const {getByTestId} = renderModal()
      fireEvent.click(getByTestId('footer-close-button'))
      expect(defaultProps.onDismiss).toHaveBeenCalled()
    })
  })

  describe('headers', () => {
    it('are rendered', () => {
      const {getByRole} = renderModal()
      defaultProps.headers.forEach(header => {
        expect(getByRole('columnheader', {name: header.getLabel()})).toBeInTheDocument()
      })
    })
  })

  describe('rows', () => {
    it('are rendered', () => {
      const {getByRole} = renderModal()
      defaultProps.rows.forEach(({label, documentCount, selectionCount}) => {
        expect(
          getByRole('row', {name: `${label} ${documentCount} ${selectionCount}`})
        ).toBeInTheDocument()
      })
    })
  })
})
