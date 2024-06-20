/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, cleanup} from '@testing-library/react'
import SearchGradingPeriodsField from '../SearchGradingPeriodsField'
import userEvent from '@testing-library/user-event'

jest.mock('lodash', () => ({
  ...jest.requireActual('lodash'),
  debounce: jest.fn(fn => fn),
}))

describe('SearchGradingPeriodsField', () => {
  let changeSearchText

  beforeEach(() => {
    changeSearchText = jest.fn()
  })

  afterEach(cleanup)

  it('onChange trims the search text and sends it to the parent component to filter', async () => {
    const {getByRole} = render(<SearchGradingPeriodsField changeSearchText={changeSearchText} />)
    const input = getByRole('textbox')
    expect(input).toBeInTheDocument()
    await userEvent.type(input, '   i love spaces!   ')
    await userEvent.tab()
    expect(changeSearchText).toHaveBeenCalledWith('i love spaces!')
  })
})
