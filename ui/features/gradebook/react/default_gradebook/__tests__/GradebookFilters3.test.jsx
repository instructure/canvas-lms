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
import '@testing-library/jest-dom'
import GradingPeriodFilter from '../components/content-filters/GradingPeriodFilter'

describe('GradingPeriodFilter', () => {
  const defaultProps = {
    disabled: false,
    gradingPeriods: [
      {id: '1', title: 'First Period', weight: 33},
      {id: '2', title: 'Second Period', weight: 25.75},
    ],
    onSelect: jest.fn(),
    selectedGradingPeriodId: '0',
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  const renderFilter = (props = {}) => {
    return render(<GradingPeriodFilter {...defaultProps} {...props} />)
  }

  describe('Grading Period Filter', () => {
    it('renders with the correct label', () => {
      const {getByLabelText} = renderFilter()
      expect(getByLabelText('Grading Period Filter')).toBeInTheDocument()
    })

    it('displays "All Grading Periods" when no specific period is selected', () => {
      const {getByRole} = renderFilter()
      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      expect(combobox).toHaveValue('All Grading Periods')
    })

    it('displays grading period options in the filter', async () => {
      const user = userEvent.setup()
      const {getByRole, getByText} = renderFilter()

      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await user.click(combobox)

      expect(getByText('First Period')).toBeInTheDocument()
      expect(getByText('Second Period')).toBeInTheDocument()
    })

    it('selects the specified grading period', async () => {
      const {getByRole} = renderFilter({selectedGradingPeriodId: '2'})
      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      expect(combobox).toHaveValue('Second Period')
    })

    it('calls onSelect when a different grading period is selected', async () => {
      const onSelect = jest.fn()
      const user = userEvent.setup()
      const {getByRole, getByText} = renderFilter({onSelect})

      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await user.click(combobox)
      await user.click(getByText('Second Period'))

      expect(onSelect).toHaveBeenCalledWith('2')
    })

    it('does not call onSelect when the same period is selected', async () => {
      const onSelect = jest.fn()
      const user = userEvent.setup()
      const {getByRole, getByText} = renderFilter({
        onSelect,
        selectedGradingPeriodId: '2',
      })

      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await user.click(combobox)
      await user.click(getByText('Second Period'))

      expect(onSelect).not.toHaveBeenCalled()
    })
  })
})
