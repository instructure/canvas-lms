/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import SubmissionAttempts, {SubmissionAttemptsProps} from '../SubmissionAttempts'
import {render} from '@testing-library/react'

describe('SubmissionAttempts', () => {
  const props: SubmissionAttemptsProps = {
    attempts: {
      1: [
        {
          id: '1',
          comment: 'this is a comment',
          created_at: Date(),
          edited_at: Date(),
          updated_at: Date(),
          is_read: false,
          author_name: 'user 123',
          display_updated_at: 'Saturday December 1st',
        },
      ],
      3: [
        {
          id: '5',
          comment: 'this is comment 3',
          is_read: false,
          created_at: Date(),
          edited_at: Date(),
          updated_at: Date(),
          author_name: 'user 123',
          display_updated_at: 'Friday December 2nd',
        },
        {
          id: '6',
          comment: 'this is comment 5',
          is_read: false,
          created_at: Date(),
          edited_at: Date(),
          updated_at: Date(),
          author_name: 'user 222',
          display_updated_at: 'Thursday December 11th',
        },
      ],
      2: [
        {
          id: '2',
          comment: 'this is a comment 2',
          is_read: false,
          created_at: Date(),
          edited_at: Date(),
          updated_at: Date(),
          author_name: 'user 333',
          display_updated_at: 'Saturday December 1st',
        },
      ],
    },
  }

  it('renders the comments sorted by attempts descending', () => {
    const {queryAllByTestId} = render(<SubmissionAttempts {...props} />)
    const submissionAttemptSections = queryAllByTestId('submission-comment-attempt')
    expect(submissionAttemptSections).toHaveLength(3)
    expect(submissionAttemptSections[0].textContent).toEqual('Attempt 3 Feedback:')
    expect(submissionAttemptSections[1].textContent).toEqual('Attempt 2 Feedback:')
    expect(submissionAttemptSections[2].textContent).toEqual('Attempt 1 Feedback:')
    expect(queryAllByTestId('submission-comment')).toHaveLength(4)
    expect(queryAllByTestId('submission-comment-unread')).toHaveLength(4)
    expect(queryAllByTestId('submission-comment-unread')).toHaveLength(4)
    const submissionCommentAuthors = queryAllByTestId('submission-comment-author')
    expect(submissionCommentAuthors).toHaveLength(4)
    expect(submissionCommentAuthors[0]).toHaveTextContent('- user 123')
    expect(submissionCommentAuthors[1]).toHaveTextContent('- user 222')
    expect(submissionCommentAuthors[2]).toHaveTextContent('- user 333')
  })
})
