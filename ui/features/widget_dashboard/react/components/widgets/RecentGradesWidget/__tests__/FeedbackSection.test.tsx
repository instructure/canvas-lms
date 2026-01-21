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
import {FeedbackSection} from '../FeedbackSection'
import type {SubmissionComment} from '../../../../types'

describe('FeedbackSection', () => {
  const mockComments: SubmissionComment[] = [
    {
      _id: 'comment1',
      comment: 'Great work on this assignment!',
      htmlComment: '<p>Great work on this assignment!</p>',
      author: {
        _id: 'teacher1',
        name: 'Mr. Smith',
      },
      createdAt: '2025-11-30T14:30:00Z',
    },
    {
      _id: 'comment2',
      comment:
        'This is a very long comment that should be truncated because it exceeds the maximum lines. We want to make sure that the truncation functionality works correctly when displaying long feedback.',
      htmlComment: '<p>This is a very long comment...</p>',
      author: {
        _id: 'teacher2',
        name: 'Mrs. Johnson',
      },
      createdAt: '2025-11-29T10:00:00Z',
    },
  ]

  const mockAssignmentUrl = '/courses/123/assignments/456'

  it('renders feedback section with comments', () => {
    render(
      <FeedbackSection
        comments={mockComments}
        submissionId="sub1"
        totalCommentsCount={2}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    expect(screen.getByTestId('feedback-section-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('feedback-section-heading-sub1')).toHaveTextContent('Feedback')
  })

  it('displays author names', () => {
    render(
      <FeedbackSection
        comments={mockComments}
        submissionId="sub1"
        totalCommentsCount={2}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    expect(screen.getByTestId('feedback-author-comment1')).toHaveTextContent('Mr. Smith')
    expect(screen.getByTestId('feedback-author-comment2')).toHaveTextContent('Mrs. Johnson')
  })

  it('displays comment text', () => {
    render(
      <FeedbackSection
        comments={mockComments}
        submissionId="sub1"
        totalCommentsCount={2}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    const comment1 = screen.getByTestId('feedback-comment-comment1')
    expect(comment1).toBeInTheDocument()
    expect(comment1.textContent).toContain('Great work on this assignment!')
  })

  it('renders "None" when comments array is empty and total count is 0', () => {
    render(
      <FeedbackSection
        comments={[]}
        submissionId="sub1"
        totalCommentsCount={0}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    expect(screen.getByTestId('feedback-none-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('feedback-none-sub1')).toHaveTextContent('None')
  })

  it('shows view inline feedback button with total count and correct URL', () => {
    render(
      <FeedbackSection
        comments={mockComments}
        submissionId="sub1"
        totalCommentsCount={5}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    const button = screen.getByTestId('view-inline-feedback-button-sub1')
    expect(button).toBeInTheDocument()
    expect(button).toHaveTextContent('View all inline feedback (5)')
    expect(button).toHaveAttribute('href', '/courses/123/assignments/456?open_feedback=true')
  })

  it('does not show button when total count is 0', () => {
    render(
      <FeedbackSection
        comments={[]}
        submissionId="sub1"
        totalCommentsCount={0}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    expect(screen.queryByTestId('view-inline-feedback-button-sub1')).not.toBeInTheDocument()
  })

  it('handles comments without authors', () => {
    const commentWithoutAuthor: SubmissionComment = {
      _id: 'comment-no-author',
      comment: 'Anonymous comment',
      htmlComment: '<p>Anonymous comment</p>',
      author: null,
      createdAt: '2025-11-30T14:30:00Z',
    }

    render(
      <FeedbackSection
        comments={[commentWithoutAuthor]}
        submissionId="sub1"
        totalCommentsCount={1}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    expect(screen.queryByTestId('feedback-author-comment-no-author')).not.toBeInTheDocument()
    expect(screen.getByTestId('feedback-comment-comment-no-author')).toBeInTheDocument()
  })

  it('handles empty comment text', () => {
    const emptyComment: SubmissionComment = {
      _id: 'empty-comment',
      comment: null,
      htmlComment: null,
      author: {
        _id: 'teacher1',
        name: 'Mr. Smith',
      },
      createdAt: '2025-11-30T14:30:00Z',
    }

    render(
      <FeedbackSection
        comments={[emptyComment]}
        submissionId="sub1"
        totalCommentsCount={1}
        assignmentUrl={mockAssignmentUrl}
      />,
    )

    expect(screen.getByTestId('feedback-comment-empty-comment')).toBeInTheDocument()
  })
})
