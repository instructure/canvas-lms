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

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import GradingPeriodFilter from '../GradingPeriodFilter'

describe('GradingPeriodFilter', () => {
  const defaultProps = {
    disabled: false,
    gradingPeriods: [
      {id: '1501', title: 'Q1'},
      {id: '1502', title: 'Q2'},
    ],
    onSelect: jest.fn(),
    selectedGradingPeriodId: '0',
  }

  const renderGradingPeriodFilter = (props = {}) => {
    return render(<GradingPeriodFilter {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders with the correct label', () => {
    const {getByLabelText} = renderGradingPeriodFilter()
    expect(getByLabelText('Grading Period Filter')).toBeInTheDocument()
  })

  it('displays the selected grading period title', () => {
    const {getByRole} = renderGradingPeriodFilter({
      selectedGradingPeriodId: '1502',
    })
    const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
    expect(combobox).toHaveValue('Q2')
  })

  it('displays "All Grading Periods" when no specific period is selected', () => {
    const {getByRole} = renderGradingPeriodFilter()
    const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
    expect(combobox).toHaveValue('All Grading Periods')
  })

  describe('grading periods list', () => {
    it('shows "All Grading Periods" as the first option', async () => {
      const {getByRole} = renderGradingPeriodFilter()
      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await userEvent.click(combobox)
      const listbox = getByRole('listbox')
      const options = listbox.querySelectorAll('[role="option"]')
      expect(options[0]).toHaveTextContent('All Grading Periods')
    })

    it('shows all grading period options', async () => {
      const {getByRole} = renderGradingPeriodFilter()
      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await userEvent.click(combobox)
      const listbox = getByRole('listbox')
      const options = listbox.querySelectorAll('[role="option"]')
      expect(options[1]).toHaveTextContent('Q1')
      expect(options[2]).toHaveTextContent('Q2')
    })
  })

  describe('selection behavior', () => {
    it('calls onSelect with grading period id when option is selected', async () => {
      const {getByRole} = renderGradingPeriodFilter()
      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await userEvent.click(combobox)
      const listbox = getByRole('listbox')
      const q1Option = listbox.querySelectorAll('[role="option"]')[1]
      await userEvent.click(q1Option)
      expect(defaultProps.onSelect).toHaveBeenCalledWith('1501')
    })

    it('calls onSelect with "0" when "All Grading Periods" is selected', async () => {
      const {getByRole} = renderGradingPeriodFilter({
        selectedGradingPeriodId: '1501',
      })
      const combobox = getByRole('combobox', {name: 'Grading Period Filter'})
      await userEvent.click(combobox)
      const listbox = getByRole('listbox')
      const allPeriodsOption = listbox.querySelectorAll('[role="option"]')[0]
      await userEvent.click(allPeriodsOption)
      expect(defaultProps.onSelect).toHaveBeenCalledWith('0')
    })
  })
})
