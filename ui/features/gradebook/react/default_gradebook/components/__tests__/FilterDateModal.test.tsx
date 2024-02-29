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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FilterDateModal from '../FilterDateModal'

describe('FilterDateModal', () => {
  it('renders', () => {
    const {getByText, getByLabelText} = render(
      <FilterDateModal
        endDate={new Date().toISOString()}
        isOpen={true}
        onCloseDateModal={() => {}}
        onSelectDates={() => {}}
        startDate={new Date().toISOString()}
      />
    )
    expect(getByText('Start & End Dates')).toBeInTheDocument()
    expect(getByLabelText('Start Date')).toBeInTheDocument()
    expect(getByLabelText('End Date')).toBeInTheDocument()
  })

  it('renders valid date options', async () => {
    const startDate = '2023-03-09T20:40:10.882Z'
    const endDate = '2023-03-12T20:40:10.882Z'
    const {getByText, getByLabelText, findByText} = render(
      <FilterDateModal
        endDate={endDate}
        isOpen={true}
        onCloseDateModal={() => {}}
        onSelectDates={() => {}}
        startDate={startDate}
      />
    )
    const startDateInput = getByLabelText('Start Date') as HTMLInputElement

    await userEvent.setup({delay: null}).click(startDateInput)
    expect(await findByText('9')).toBeInTheDocument()
    expect(getByText('10')).toBeInTheDocument()
    expect(getByText('11')).toBeInTheDocument()
  })
})
