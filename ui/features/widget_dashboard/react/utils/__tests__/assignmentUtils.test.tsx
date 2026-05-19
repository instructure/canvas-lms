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

import React from 'react'
import {render, screen} from '@testing-library/react'
import {determineItemType, getTypeIcon} from '../assignmentUtils'

describe('determineItemType', () => {
  it('returns "quiz" when assignment has a quiz association', () => {
    expect(determineItemType({quiz: {_id: '1', title: 'Q'}})).toBe('quiz')
  })

  it('returns "discussion" when assignment has a discussion association', () => {
    expect(determineItemType({discussion: {_id: '1', title: 'D'}})).toBe('discussion')
  })

  it('returns "quiz" when submissionTypes includes "online_quiz"', () => {
    expect(determineItemType({submissionTypes: ['online_quiz']})).toBe('quiz')
  })

  it('returns "discussion" when submissionTypes includes "discussion_topic"', () => {
    expect(determineItemType({submissionTypes: ['discussion_topic']})).toBe('discussion')
  })

  it('returns "peer_review" when submissionTypes is exactly ["peer_review"]', () => {
    expect(determineItemType({submissionTypes: ['peer_review']})).toBe('peer_review')
  })

  it('returns "assignment" as the default', () => {
    expect(determineItemType({submissionTypes: ['online_text_entry']})).toBe('assignment')
    expect(determineItemType({})).toBe('assignment')
  })
})

describe('getTypeIcon', () => {
  it('renders the assignment icon for "assignment"', () => {
    render(<>{getTypeIcon('assignment')}</>)
    expect(screen.getByTestId('assignment-icon')).toBeInTheDocument()
  })

  it('renders the quiz icon for "quiz"', () => {
    render(<>{getTypeIcon('quiz')}</>)
    expect(screen.getByTestId('quiz-icon')).toBeInTheDocument()
  })

  it('renders the discussion icon for "discussion"', () => {
    render(<>{getTypeIcon('discussion')}</>)
    expect(screen.getByTestId('discussion-icon')).toBeInTheDocument()
  })

  it('renders the peer review icon for "peer_review"', () => {
    render(<>{getTypeIcon('peer_review')}</>)
    expect(screen.getByTestId('peer-review-icon')).toBeInTheDocument()
  })
})
