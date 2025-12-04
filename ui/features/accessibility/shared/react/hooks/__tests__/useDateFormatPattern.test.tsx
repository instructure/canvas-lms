/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useDateFormatPattern} from '../useDateFormatPattern'

const TestComponent = () => {
  const datePattern = useDateFormatPattern()
  return <div data-testid="date-pattern">{datePattern}</div>
}

describe('useDateFormatPattern', () => {
  beforeEach(() => {
    ENV.LOCALE = 'en-US'
  })

  it('returns a date format pattern string', () => {
    const {getByTestId} = render(<TestComponent />)
    const pattern = getByTestId('date-pattern').textContent

    expect(pattern).toBeTruthy()
    expect(typeof pattern).toBe('string')
  })

  it('returns a pattern containing YYYY, MM, and DD placeholders', () => {
    const {getByTestId} = render(<TestComponent />)
    const pattern = getByTestId('date-pattern').textContent

    expect(pattern).toContain('YYYY')
    expect(pattern).toContain('MM')
    expect(pattern).toContain('DD')
  })

  it('returns MM/DD/YYYY format for en-US locale', () => {
    ENV.LOCALE = 'en-US'
    const {getByTestId} = render(<TestComponent />)
    const pattern = getByTestId('date-pattern').textContent

    expect(pattern).toBe('MM/DD/YYYY')
  })

  it('returns DD/MM/YYYY format for en-GB locale', () => {
    ENV.LOCALE = 'en-GB'
    const {getByTestId} = render(<TestComponent />)
    const pattern = getByTestId('date-pattern').textContent

    expect(pattern).toBe('DD/MM/YYYY')
  })

  it('returns DD.MM.YYYY format for de locale', () => {
    ENV.LOCALE = 'de'
    const {getByTestId} = render(<TestComponent />)
    const pattern = getByTestId('date-pattern').textContent

    expect(pattern).toBe('DD.MM.YYYY')
  })
})
