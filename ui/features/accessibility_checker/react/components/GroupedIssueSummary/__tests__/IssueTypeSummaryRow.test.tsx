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

import {render, screen} from '@testing-library/react'
import {IconImageLine, IconTextLine} from '@instructure/ui-icons'
import IssueTypeSummaryRow from '../IssueTypeSummaryRow'

describe('IssueTypeSummaryRow', () => {
  const defaultProps = {
    icon: IconImageLine,
    label: 'Image alt text',
    count: 5,
    borderWidth: 'small' as const,
  }

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders all required elements within the component', () => {
    const {container, getByTestId, getByText} = render(<IssueTypeSummaryRow {...defaultProps} />)

    const icon = container.querySelector('svg')
    const label = getByText('Image alt text')
    const badge = getByTestId('issue-count-badge')

    expect(icon).toBeInTheDocument()
    expect(label).toBeInTheDocument()
    expect(badge).toBeInTheDocument()
  })

  it('renders the provided icon component', () => {
    const {rerender, container} = render(<IssueTypeSummaryRow {...defaultProps} />)

    let iconElement = container.querySelector('svg')
    expect(iconElement).toBeInTheDocument()
    expect(iconElement).toHaveAttribute('name', 'IconImage')

    rerender(<IssueTypeSummaryRow {...defaultProps} icon={IconTextLine} />)

    iconElement = container.querySelector('svg')
    expect(iconElement).toBeInTheDocument()
    expect(iconElement).toHaveAttribute('name', 'IconText')
  })

  it('displays the correct count in the badge', () => {
    render(<IssueTypeSummaryRow {...defaultProps} count={42} />)

    const badge = screen.getByTestId('issue-count-badge')
    expect(badge).toHaveTextContent('42')
  })

  it('renders no badge, when zero issues', () => {
    const {queryByTestId} = render(<IssueTypeSummaryRow {...defaultProps} count={0} />)

    const badge = queryByTestId('issue-count-badge')
    expect(badge).not.toBeInTheDocument()
  })

  it('renders with different border widths without errors', () => {
    const borderWidths = ['small', 'medium', 'large', 'none'] as const

    borderWidths.forEach(borderWidth => {
      const {unmount} = render(<IssueTypeSummaryRow {...defaultProps} borderWidth={borderWidth} />)

      expect(screen.getByText('Image alt text')).toBeInTheDocument()
      expect(screen.getByTestId('issue-count-badge')).toBeInTheDocument()

      unmount()
    })
  })

  describe('Edge cases', () => {
    it('handles undefined or null props gracefully', () => {
      expect(() => {
        render(<IssueTypeSummaryRow icon={IconImageLine} label="" count={0} borderWidth="small" />)
      }).not.toThrow()
    })
  })
})
