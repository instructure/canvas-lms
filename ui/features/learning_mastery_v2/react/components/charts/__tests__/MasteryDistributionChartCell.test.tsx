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
import userEvent from '@testing-library/user-event'
import {
  MasteryDistributionChartCell,
  MasteryDistributionChartCellProps,
} from '../MasteryDistributionChartCell'
import {MOCK_OUTCOMES, MOCK_STUDENTS} from '../../../__fixtures__/rollups'
import {
  OutcomeDistribution,
  RatingDistribution,
} from '@canvas/outcomes/react/types/mastery_distribution'

vi.mock('../MasteryDistributionChart', () => ({
  MasteryDistributionChart: ({outcome, distributionData, isPreview}: any) => (
    <div data-testid="mastery-distribution-chart">
      <span data-testid="chart-outcome">{outcome.title}</span>
      <span data-testid="chart-data">{JSON.stringify(distributionData)}</span>
      <span data-testid="chart-preview">{String(isPreview)}</span>
    </div>
  ),
}))

vi.mock('../../popovers/OutcomeDistributionPopover', () => ({
  OutcomeDistributionPopover: ({outcome, isOpen, onCloseHandler, courseId, renderTrigger}: any) => (
    <div>
      {renderTrigger}
      {isOpen && (
        <div data-testid="outcome-distribution-popover">
          <span data-testid="popover-outcome">{outcome.title}</span>
          <span data-testid="popover-course-id">{courseId}</span>
          <button data-testid="popover-close" onClick={onCloseHandler}>
            Close
          </button>
        </div>
      )}
    </div>
  ),
}))

describe('MasteryDistributionChartCell', () => {
  const outcome = MOCK_OUTCOMES[0]
  const user = userEvent.setup({pointerEventsCheck: 0})

  const distributionData: RatingDistribution[] = [
    {description: 'Exceeds', points: 5, color: '#127A1B', count: 3, student_ids: ['1', '2', '3']},
    {description: 'Meets', points: 3, color: '#0B874B', count: 2, student_ids: ['4', '5']},
  ]

  const outcomeDistribution: OutcomeDistribution = {
    outcome_id: '1',
    ratings: distributionData,
    total_students: 5,
  }

  const defaultProps = (): MasteryDistributionChartCellProps => ({
    outcome,
    distributionData,
    outcomeDistribution,
    distributionStudents: MOCK_STUDENTS,
    courseId: '5',
    isLoading: false,
  })

  it('renders the chart with distribution data', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} />)
    expect(screen.getByTestId('mastery-distribution-chart')).toBeInTheDocument()
    expect(screen.getByTestId('chart-outcome')).toHaveTextContent('outcome 1')
    expect(screen.getByTestId('chart-preview')).toHaveTextContent('true')
  })

  it('renders a spinner when loading', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} isLoading={true} />)
    expect(screen.getByText('Loading distribution')).toBeInTheDocument()
    expect(screen.queryByTestId('mastery-distribution-chart')).not.toBeInTheDocument()
  })

  it('renders a custom loading title', () => {
    render(
      <MasteryDistributionChartCell
        {...defaultProps()}
        isLoading={true}
        loadingTitle="Loading alignment distribution"
      />,
    )
    expect(screen.getByText('Loading alignment distribution')).toBeInTheDocument()
  })

  it('renders the chart with empty data when distributionData is undefined', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} distributionData={undefined} />)
    expect(screen.getByTestId('chart-data')).toHaveTextContent('[]')
  })

  it('renders the expand button when courseId is provided', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} />)
    expect(
      screen.getByRole('button', {name: 'Expand distribution for outcome 1'}),
    ).toBeInTheDocument()
  })

  it('does not render the expand button when courseId is not provided', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} courseId={undefined} />)
    expect(
      screen.queryByRole('button', {name: 'Expand distribution for outcome 1'}),
    ).not.toBeInTheDocument()
  })

  it('shows the expand button when isHovered is true', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} isHovered={true} />)

    const expandButton = screen.getByRole('button', {
      name: 'Expand distribution for outcome 1',
    })
    expect(expandButton.closest('div[style]')).toHaveStyle({opacity: '1'})
  })

  it('hides the expand button when not hovered', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} />)

    const expandButton = screen.getByRole('button', {
      name: 'Expand distribution for outcome 1',
    })
    expect(expandButton.closest('div[style]')).toHaveStyle({opacity: '0'})
  })

  it('opens the popover when expand button is clicked', async () => {
    render(<MasteryDistributionChartCell {...defaultProps()} isHovered={true} />)
    await user.click(screen.getByRole('button', {name: 'Expand distribution for outcome 1'}))

    expect(screen.getByTestId('outcome-distribution-popover')).toBeInTheDocument()
    expect(screen.getByTestId('popover-outcome')).toHaveTextContent('outcome 1')
    expect(screen.getByTestId('popover-course-id')).toHaveTextContent('5')
  })

  it('closes the popover when close handler is called', async () => {
    render(<MasteryDistributionChartCell {...defaultProps()} isHovered={true} />)
    await user.click(screen.getByRole('button', {name: 'Expand distribution for outcome 1'}))
    expect(screen.getByTestId('outcome-distribution-popover')).toBeInTheDocument()

    await user.click(screen.getByTestId('popover-close'))
    expect(screen.queryByTestId('outcome-distribution-popover')).not.toBeInTheDocument()
  })

  it('does not render the popover initially', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} />)
    expect(screen.queryByTestId('outcome-distribution-popover')).not.toBeInTheDocument()
  })

  it('does not show expand button during loading', () => {
    render(<MasteryDistributionChartCell {...defaultProps()} isLoading={true} />)
    expect(
      screen.queryByRole('button', {name: 'Expand distribution for outcome 1'}),
    ).not.toBeInTheDocument()
  })

  it('shows the expand button when the expand button is focused', async () => {
    render(<MasteryDistributionChartCell {...defaultProps()} />)
    const expandButton = screen.getByRole('button', {name: 'Expand distribution for outcome 1'})

    await user.tab()
    expect(expandButton).toHaveFocus()
    expect(expandButton.closest('div[style]')).toHaveStyle({opacity: '1'})
  })

  it('hides the expand button after focus moves away', async () => {
    render(<MasteryDistributionChartCell {...defaultProps()} />)
    const expandButton = screen.getByRole('button', {name: 'Expand distribution for outcome 1'})

    await user.tab()
    expect(expandButton).toHaveFocus()
    await user.tab()
    expect(expandButton).not.toHaveFocus()
    expect(expandButton.closest('div[style]')).toHaveStyle({opacity: '0'})
  })

  it('closes the popover without needing the cursor to re-enter the cell', async () => {
    render(<MasteryDistributionChartCell {...defaultProps()} isHovered={true} />)
    await user.click(screen.getByRole('button', {name: 'Expand distribution for outcome 1'}))
    expect(screen.getByTestId('outcome-distribution-popover')).toBeInTheDocument()

    await user.click(screen.getByTestId('popover-close'))
    expect(screen.queryByTestId('outcome-distribution-popover')).not.toBeInTheDocument()
    // button visibility is now driven by isHovered prop (true here), so button stays visible
    expect(
      screen.getByRole('button', {name: 'Expand distribution for outcome 1'}).closest('div[style]'),
    ).toHaveStyle({opacity: '1'})
  })
})
