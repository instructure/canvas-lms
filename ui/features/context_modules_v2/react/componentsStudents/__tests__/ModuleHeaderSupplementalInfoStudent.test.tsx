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
    submissionStatistics: overrides.submissionStatistics || {
      latestDueAt: null,
      missingAssignmentCount: 0,
    },
  }
}

const setUp = (props = buildDefaultProps()) => {
  return render(
    <ModuleHeaderSupplementalInfoStudent submissionStatistics={props.submissionStatistics} />,
  )
}

describe('ModuleHeaderSupplementalInfoStudent', () => {
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
  })
})
