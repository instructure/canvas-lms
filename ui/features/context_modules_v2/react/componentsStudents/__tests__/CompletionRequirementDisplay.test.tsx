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
import CompletionRequirementDisplay from '../CompletionRequirementDisplay'
import {CompletionRequirement} from '../../utils/types'

describe('CompletionRequirementDisplay', () => {
  it('renders null if no completion requirement is provided', () => {
    const {container} = render(<CompletionRequirementDisplay completionRequirement={null as any} />)
    expect(container).toBeEmptyDOMElement()
  })

  it('renders min_score requirement correctly when not completed', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'min_score',
      minScore: 8.5,
      completed: false,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Score at least 8.5')).toBeInTheDocument()
    expect(
      screen.getByText('Must score at least 8.5 to complete this module item'),
    ).toBeInTheDocument()
  })

  it('renders min_score requirement correctly when completed', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'min_score',
      minScore: 8.5,
      completed: true,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Scored at least 8.5')).toBeInTheDocument()
    expect(
      screen.getByText('Module item has been completed by scoring at least 8.5'),
    ).toBeInTheDocument()
  })

  it('renders min_percentage requirement correctly when not completed', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'min_percentage',
      minPercentage: 85,
      completed: false,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Score at least 85%')).toBeInTheDocument()
    expect(
      screen.getByText('Must score at least 85% to complete this module item'),
    ).toBeInTheDocument()
  })

  it('renders must_view requirement correctly when completed', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'must_view',
      completed: true,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Viewed')).toBeInTheDocument()
    expect(screen.getByText('Module item has been viewed and is complete')).toBeInTheDocument()
  })

  it('renders must_mark_done requirement correctly when not completed', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'must_mark_done',
      completed: false,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Mark done')).toBeInTheDocument()
    expect(
      screen.getByText('Must mark this module item done in order to complete'),
    ).toBeInTheDocument()
  })

  it('renders must_contribute requirement correctly', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'must_contribute',
      completed: false,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Contribute')).toBeInTheDocument()
  })

  it('renders must_submit requirement correctly', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'must_submit',
      completed: true,
    }
    render(<CompletionRequirementDisplay completionRequirement={completionRequirement} />)

    expect(screen.getByText('Submitted')).toBeInTheDocument()
    expect(screen.getByText('Module item submitted and is complete')).toBeInTheDocument()
  })

  it('renders nothing for unknown requirement types', () => {
    const completionRequirement: CompletionRequirement = {
      id: '1',
      type: 'unknown_type' as any,
      completed: false,
    }
    const {container} = render(
      <CompletionRequirementDisplay completionRequirement={completionRequirement} />,
    )

    expect(container).toBeEmptyDOMElement()
  })
})
