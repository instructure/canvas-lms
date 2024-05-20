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
import SubmissionAttempts, {type SubmissionAttemptsProps} from '../SubmissionAttempts'
import {render} from '@testing-library/react'

describe('SubmissionAttempts', () => {
  const props: SubmissionAttemptsProps = {
    attempts: {
      1: [
        {
          id: '1',
          comment: 'this is a comment',
          is_read: false,
          author_name: 'user 123',
          display_updated_at: 'Saturday December 1st',
          attachments: [],
          media_object: {
            id: 'm-someid',
            media_sources: [
              {
                height: '1080',
                width: '1920',
                url: 'https://www.youtube.com/watch?v=123',
                content_type: 'video/mp4',
              },
            ],
            media_tracks: [
              {
                id: '1',
                content: 'English',
                kind: 'subtitles',
                locale: 'en',
              },
            ],
            title: 'test',
          },
        },
      ],
      3: [
        {
          id: '5',
          comment: 'this is comment 3',
          is_read: false,
          author_name: 'user 123',
          display_updated_at: 'Friday December 2nd',
          attachments: [],
        },
        {
          id: '6',
          comment: 'this is comment 5',
          is_read: false,
          author_name: 'user 222',
          display_updated_at: 'Thursday December 11th',
          attachments: [
            {
              id: '10',
              mime_class: 'pdf',
              display_name: 'test.pdf',
            },
          ],
          media_object: {
            id: 'm-someid',
            media_sources: [
              {
                height: '1080',
                width: '1920',
                url: 'https://www.youtube.com/watch?v=123',
                content_type: 'video/mp4',
              },
            ],
            media_tracks: [
              {
                id: '1',
                content: 'English',
                kind: 'subtitles',
                locale: 'en',
              },
            ],
            title: 'test',
          },
        },
      ],
      2: [
        {
          id: '2',
          comment: 'this is a comment 2',
          is_read: false,
          author_name: 'user 333',
          display_updated_at: 'Saturday December 1st',
          attachments: [],
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
    const attachmentSection = queryAllByTestId('attachment-10')
    expect(attachmentSection).toHaveLength(1)
    expect(attachmentSection[0]).toHaveTextContent('test.pdf')
    const mediaObjectSection = queryAllByTestId('submission-comment-media')
    expect(mediaObjectSection).toHaveLength(2)
  })
})
