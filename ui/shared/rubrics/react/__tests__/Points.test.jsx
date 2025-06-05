/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import Points from '../Points'

describe('The Points component', () => {
  const id = {criterion_id: '_7506'}

  const validPoints = text => ({text, valid: true, value: parseFloat(text)})

  it('renders the root component as expected', () => {
    const {getByText} = render(
      <Points assessment={{...id, points: validPoints('1')}} pointsPossible={2} />,
    )
    expect(getByText('1 / 2 pts')).toBeInTheDocument()
  })

  it('renders the component when assessing with the expected layout', () => {
    const {getByRole} = render(
      <Points assessment={{...id, points: validPoints('1')}} assessing={true} pointsPossible={2} />,
    )
    const input = getByRole('textbox')
    expect(input).toBeInTheDocument()
    expect(input.value).toBe('1')
  })

  it('renders the right text for fractional points', () => {
    const {getByText} = render(
      <Points assessment={{...id, points: validPoints('1.1')}} pointsPossible={2} />,
    )
    expect(getByText('1.1 / 2 pts')).toBeInTheDocument()
  })

  it('renders the provided value on page load with no point text', () => {
    const {getByText} = render(
      <Points
        assessment={{...id, points: {text: null, valid: true, value: 1.255}}}
        pointsPossible={2}
      />,
    )
    expect(getByText('1.26 / 2 pts')).toBeInTheDocument()
  })

  it('renders no errors with point text verbatim when valid', () => {
    const {container} = render(
      <Points
        assessing={true}
        assessment={{...id, points: {text: '', valid: true, value: undefined}}}
        pointsPossible={2}
      />,
    )
    const errorMessages = container.querySelectorAll('[data-messages]')
    expect(errorMessages).toHaveLength(0)
  })

  it('renders points possible with no assessment', () => {
    const {getByText} = render(<Points assessing={false} assessment={null} pointsPossible={2} />)
    expect(getByText('2 pts')).toBeInTheDocument()
  })

  const renderWithPoints = points =>
    render(
      <Points
        allowExtraCredit={false}
        assessing={true}
        assessment={{
          ...id,
          points,
        }}
        pointsPossible={5}
      />,
    )

  it('renders an error when valid is false', () => {
    const {getByText} = renderWithPoints({text: 'stringy', valid: false, value: null})
    expect(getByText('Invalid score')).toBeInTheDocument()
  })

  it('renders an error when extra credit cannot be given', () => {
    const {getByText} = renderWithPoints({text: '30', valid: true, value: 30})
    expect(getByText('Cannot give outcomes extra credit')).toBeInTheDocument()
  })

  it('renders no error when valid is true', () => {
    const testCases = [
      ['', undefined],
      [null, undefined],
      [undefined, undefined],
      ['0', 0],
      ['2.2', 2.2],
    ]

    testCases.forEach(([text, value]) => {
      const {container} = renderWithPoints({text, valid: true, value})
      const errorMessages = container.querySelectorAll('[role="alert"]')
      expect(errorMessages).toHaveLength(0)
    })
  })
})
