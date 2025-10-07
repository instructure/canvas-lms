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

import React from 'react'
import {render, screen} from '@testing-library/react'
import {OutcomePopoverDisplay} from '../OutcomePopoverDisplay'
import type {GetRubricOutcomeQuery} from '@canvas/graphql/codegen/graphql'

const mockOutcome: GetRubricOutcomeQuery['learningOutcome'] = {
  id: '1',
  title: 'Test Outcome',
  displayName: 'Test Display Name',
  description: 'Test description',
  calculationMethod: 'average',
  calculationInt: null,
  masteryPoints: 3,
  contextType: 'Course',
  contextId: '123',
}

const mockAccountOutcome: GetRubricOutcomeQuery['learningOutcome'] = {
  id: '2',
  title: 'Account Outcome',
  displayName: 'Account Display Name',
  description: 'Account description',
  calculationMethod: 'highest',
  calculationInt: null,
  masteryPoints: 4,
  contextType: 'Account',
  contextId: '456',
}

describe('OutcomePopoverDisplay', () => {
  it('renders outcome information correctly', () => {
    render(<OutcomePopoverDisplay outcome={mockOutcome} />)

    expect(screen.getByTestId('outcome-popover-display')).toBeInTheDocument()
    expect(screen.getByTestId('outcome-popover-display-name')).toHaveTextContent(
      'Test Display Name',
    )
    expect(screen.getByTestId('outcome-popover-title')).toHaveTextContent('Test Outcome')
  })

  it('renders course context tag when outcome has course context', () => {
    render(<OutcomePopoverDisplay outcome={mockOutcome} />)

    const contextTag = screen.getByTestId('outcome-context-tag')
    expect(contextTag).toBeInTheDocument()
    expect(contextTag).toHaveTextContent('Course')
  })

  it('does not render context tag when context information is missing', () => {
    const outcomeWithoutContext = {
      ...mockOutcome,
      contextType: null,
      contextId: null,
    }

    render(<OutcomePopoverDisplay outcome={outcomeWithoutContext} />)

    expect(screen.queryByTestId('outcome-context-tag')).not.toBeInTheDocument()
  })

  it('does not render when outcome is null or undefined', () => {
    const nullResult = render(<OutcomePopoverDisplay outcome={null} />)
    expect(nullResult.container.firstChild).toBeNull()

    const undefinedResult = render(<OutcomePopoverDisplay outcome={undefined} />)
    expect(undefinedResult.container.firstChild).toBeNull()
  })
})
