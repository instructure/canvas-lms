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
import {render} from '@testing-library/react'
import {ModuleHeaderSupplementalInfoStudent} from '../ModuleHeaderSupplementalInfoStudent'
import {CompletionRequirement, ModuleStatistics} from '../../utils/types'

type Props = {
  completionRequirements?: CompletionRequirement[]
  requirementCount?: number
  submissionStatistics?: ModuleStatistics
  moduleCompleted?: boolean
}

const buildDefaultProps = (overrides: Partial<Props> = {}) => {
  return {
    completionRequirements: overrides.completionRequirements || [],
    requirementCount: overrides.requirementCount !== undefined ? overrides.requirementCount : 0,
    submissionStatistics: overrides.submissionStatistics || {
      latestDueAt: null,
      missingAssignmentCount: 0,
    },
    moduleCompleted: overrides?.moduleCompleted || false,
  }
}

const setUp = (props = buildDefaultProps()) => {
  return render(
    <ModuleHeaderSupplementalInfoStudent
      completionRequirements={props.completionRequirements}
      requirementCount={props.requirementCount}
      submissionStatistics={props.submissionStatistics}
      moduleCompleted={props.moduleCompleted}
    />,
  )
}

describe('ModuleHeaderSupplementalInfoStudent', () => {
  it('renders date, missing count, and requirement', () => {
    const testDate = new Date(Date.now() - 72 * 60 * 60 * 1000)
    const container = setUp(
      buildDefaultProps({
        completionRequirements: [
          {
            id: '1',
            type: 'assignment',
            minScore: 100,
            minPercentage: 100,
          },
        ],
        submissionStatistics: {
          latestDueAt: testDate.toISOString(),
          missingAssignmentCount: 1,
        },
      }),
    )
    expect(container.container).toBeInTheDocument()
    expect(
      container.getByText(/Due: \w+ \d+,?/, {selector: '.visible-desktop'}),
    ).toBeInTheDocument()
    expect(container.getByText('1 Missing Assignment')).toBeInTheDocument()
    expect(container.getByText('Requirement: Complete All Items')).toBeInTheDocument()
    expect(container.getAllByText('|')).toHaveLength(2)
  })

  it('renders date', () => {
    const testDate = new Date(Date.now() + 72 * 60 * 60 * 1000)
    const container = setUp(
      buildDefaultProps({
        submissionStatistics: {
          latestDueAt: testDate.toISOString(),
          missingAssignmentCount: 0,
        },
      }),
    )
    expect(container.container).toBeInTheDocument()
    expect(
      container.getByText(/Due: \w+ \d+,?/, {selector: '.visible-desktop'}),
    ).toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(0)
  })

  it('renders requirement', () => {
    const container = setUp(
      buildDefaultProps({
        completionRequirements: [
          {
            id: '1',
            type: 'assignment',
            minScore: 100,
            minPercentage: 100,
          },
        ],
        requirementCount: 1,
      }),
    )
    expect(container.container).toBeInTheDocument()
    expect(container.getByText('Requirement: Complete One Item')).toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(0)
  })

  it('renders due date and missing count', () => {
    const testDate = new Date(Date.now() - 72 * 60 * 60 * 1000)
    const container = setUp(
      buildDefaultProps({
        submissionStatistics: {
          latestDueAt: testDate.toISOString(),
          missingAssignmentCount: 1,
        },
      }),
    )
    expect(container.container).toBeInTheDocument()
    expect(
      container.getByText(/Due: \w+ \d+,?/, {selector: '.visible-desktop'}),
    ).toBeInTheDocument()
    expect(container.getByText('1 Missing Assignment')).toBeInTheDocument()
    expect(container.queryAllByText('|')).toHaveLength(1)
  })
})
