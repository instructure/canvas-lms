/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {BarChart} from '../BarChart'

vi.mock('chart.js', () => ({
  Chart: class {
    destroy() {}
    static register() {}
  },
  CategoryScale: class {},
  LinearScale: class {},
  BarElement: class {},
  BarController: class {},
  Title: class {},
  Tooltip: class {},
  Legend: class {},
}))

const defaultProps = {
  title: 'Issue status',
  data: [
    {label: '178 open', value: 178, color: 'red' as const, emphasized: true},
    {label: '5 resolved', value: 5, color: 'green' as const},
  ],
}

describe('BarChart', () => {
  it('renders the chart heading', () => {
    render(<BarChart {...defaultProps} />)
    expect(screen.getByText('Issue status')).toBeInTheDocument()
  })

  it('has role="img"', () => {
    render(<BarChart {...defaultProps} />)
    expect(screen.getByRole('img')).toBeInTheDocument()
  })

  it('has aria-label with title and total issue count', () => {
    render(<BarChart {...defaultProps} />)
    expect(screen.getByTestId('bar-chart')).toHaveAttribute(
      'aria-label',
      'Issue status bar chart showing 183 issues.',
    )
  })

  it('has aria-describedby pointing to an element in the DOM', () => {
    render(<BarChart {...defaultProps} />)
    const canvas = screen.getByTestId('bar-chart')
    const descriptionId = canvas.getAttribute('aria-describedby')

    expect(descriptionId).toBeTruthy()
    expect(document.getElementById(descriptionId!)).toBeInTheDocument()
  })

  it('description element contains the chart data summary', () => {
    render(<BarChart {...defaultProps} />)
    const canvas = screen.getByTestId('bar-chart')
    const descriptionId = canvas.getAttribute('aria-describedby')!
    const description = document.getElementById(descriptionId)

    expect(description?.textContent).toContain('178 open')
    expect(description?.textContent).toContain('5 resolved')
  })

  it('shows singular aria-label when total is 1', () => {
    render(
      <BarChart
        title="Issue status"
        data={[
          {label: '1 open', value: 1, color: 'red' as const},
          {label: '0 resolved', value: 0, color: 'green' as const},
        ]}
      />,
    )
    expect(screen.getByTestId('bar-chart')).toHaveAttribute(
      'aria-label',
      'Issue status bar chart showing 1 issue.',
    )
  })

  it('shows fallback description when data is empty', () => {
    render(<BarChart title="Issue status" data={[]} />)
    const canvas = screen.getByTestId('bar-chart')
    const descriptionId = canvas.getAttribute('aria-describedby')!
    const description = document.getElementById(descriptionId)

    expect(description?.textContent).toContain('No data.')
  })
})
