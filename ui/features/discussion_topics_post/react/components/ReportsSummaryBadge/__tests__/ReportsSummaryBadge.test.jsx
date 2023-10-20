/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {ReportsSummaryBadge} from '../ReportsSummaryBadge'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'

const setup = ({reportTypeCounts = DiscussionEntry.mock().reportTypeCounts} = {}) =>
  render(<ReportsSummaryBadge reportTypeCounts={reportTypeCounts} />)

describe('ReportsSummaryBadge', () => {
  it('renders', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('renders total', () => {
    const container = setup({
      reportTypeCounts: {
        inappropriateCount: 3,
        offensiveCount: 2,
        otherCount: 1,
        total: 6,
      },
    })

    expect(container.getByTestId('reports-total')).toHaveTextContent('6')
  })

  it('renders summary when hovering', () => {
    const container = setup({
      reportTypeCounts: {
        inappropriateCount: 3,
        offensiveCount: 2,
        otherCount: 1,
        total: 6,
      },
    })

    fireEvent.mouseOver(container.getByTestId('reports-total'))

    expect(container.getByTestId('reports-summary-badge')).toBeInTheDocument()
    expect(container.getByText('Inappropriate: 3')).toBeInTheDocument()
    expect(container.getByText('Offensive, abusive: 2')).toBeInTheDocument()
    expect(container.getByText('Other: 1')).toBeInTheDocument()
  })
})
