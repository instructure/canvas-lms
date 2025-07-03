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
import {CompletionRequirement, ModuleProgression, ModuleRequirement} from '../../utils/types'
import {InProgressModuleItemStatus} from '../InProgressModuleItemStatus'

const DEFAULT_COMPLETION_REQUIREMENT = {
  id: '1',
  type: 'must_view',
  minScore: undefined,
  minPercentage: undefined,
} as CompletionRequirement

describe('InProgressModuleItemStatus', () => {
  it('should render must_view text correctly', () => {
    render(<InProgressModuleItemStatus completionRequirement={DEFAULT_COMPLETION_REQUIREMENT} />)
    expect(screen.getByText('Must view the page')).toBeInTheDocument()
  })

  it('should render must_mark_done text correctly', () => {
    const completionRequirement = {...DEFAULT_COMPLETION_REQUIREMENT, type: 'must_mark_done'}
    render(<InProgressModuleItemStatus completionRequirement={completionRequirement} />)
    expect(screen.getByText('Must mark as done')).toBeInTheDocument()
  })

  it('should render must_submit text correctly', () => {
    const completionRequirement = {...DEFAULT_COMPLETION_REQUIREMENT, type: 'must_submit'}
    render(<InProgressModuleItemStatus completionRequirement={completionRequirement} />)
    expect(screen.getByText('Must submit the assignment')).toBeInTheDocument()
  })

  it('should render min_score text correctly', () => {
    const completionRequirement = {
      ...DEFAULT_COMPLETION_REQUIREMENT,
      type: 'min_score',
      minScore: 85,
    }
    render(<InProgressModuleItemStatus completionRequirement={completionRequirement} />)
    expect(screen.getByText('Must score at least a 85')).toBeInTheDocument()
  })

  it('should render min_percentage text correctly', () => {
    const completionRequirement = {
      ...DEFAULT_COMPLETION_REQUIREMENT,
      type: 'min_percentage',
      minPercentage: 85,
    }
    render(<InProgressModuleItemStatus completionRequirement={completionRequirement} />)
    expect(screen.getByText('Must score at least a 85%')).toBeInTheDocument()
  })

  it('should render must_contribute text correctly', () => {
    const completionRequirement = {...DEFAULT_COMPLETION_REQUIREMENT, type: 'must_contribute'}
    render(<InProgressModuleItemStatus completionRequirement={completionRequirement} />)
    expect(screen.getByText('Must contribute to the page')).toBeInTheDocument()
  })

  it('should render a non existent type text correctly', () => {
    const completionRequirement = {...DEFAULT_COMPLETION_REQUIREMENT, type: 'non-existent-type'}
    render(<InProgressModuleItemStatus completionRequirement={completionRequirement} />)
    expect(screen.getByText('Not yet completed')).toBeInTheDocument()
  })
})
