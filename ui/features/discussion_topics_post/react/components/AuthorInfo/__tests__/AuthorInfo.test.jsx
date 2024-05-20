/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {AnonymousUser} from '../../../../graphql/AnonymousUser'
import {AuthorInfo} from '../AuthorInfo'
import {CURRENT_USER, SearchContext} from '../../../utils/constants'
import {render} from '@testing-library/react'
import React from 'react'
import {User} from '../../../../graphql/User'
import {DiscussionEntryVersion} from '../../../../graphql/DiscussionEntryVersion'

const setup = ({
  author = User.mock({
    _id: '2',
    displayName: 'Harry Potter',
    courseRoles: ['StudentEnrollment', 'TaEnrollment'],
    htmlUrl: 'http://test.host/courses/1/users/2',
  }),
  anonymousAuthor = null,
  editor = User.mock({
    _id: '1',
    displayName: 'Severus Snape',
    courseRoles: ['StudentEnrollment'],
    htmlUrl: 'http://test.host/courses/1/users/1',
  }),
  isUnread = false,
  isForcedRead = false,
  isSplitView = false,
  createdAt = '2021-01-01T13:00:00-07:00',
  updatedAt = '2021-02-02T14:00:00-07:00',
  timingDisplay = 'Jan 1 1:00pm',
  editedTimingDisplay = 'Feb 2 2:00pm',
  lastReplyAtDisplay = 'Mar 3 3:00pm',
  showCreatedAsTooltip = false,
  searchTerm = '',
  isTopicAuthor = true,
  discussionEntryVersions = [],
} = {}) =>
  render(
    <SearchContext.Provider value={{searchTerm}}>
      <AuthorInfo
        author={author}
        anonymousAuthor={anonymousAuthor}
        editor={editor}
        isUnread={isUnread}
        isForcedRead={isForcedRead}
        isSplitView={isSplitView}
        createdAt={createdAt}
        updatedAt={updatedAt}
        timingDisplay={timingDisplay}
        editedTimingDisplay={editedTimingDisplay}
        lastReplyAtDisplay={lastReplyAtDisplay}
        showCreatedAsTooltip={showCreatedAsTooltip}
        isTopicAuthor={isTopicAuthor}
        discussionEntryVersions={discussionEntryVersions}
      />
    </SearchContext.Provider>
  )

describe('AuthorInfo', () => {
  it('renders the avatar when there is an author', () => {
    const container = setup()
    expect(container.getByTestId('author_avatar')).toBeInTheDocument()
  })

  it('renders the author name when there is an author', () => {
    const container = setup()
    expect(container.getByText('Harry Potter')).toBeInTheDocument()
  })

  it('renders author name with link to the author profile page', () => {
    const container = setup()
    const link = container.getByRole('link', {name: 'Harry Potter'})
    expect(link).toHaveAttribute('href', 'http://test.host/courses/1/users/2')
  })

  it('renders editor name with link to the author profile page', () => {
    const container = setup()
    const link = container.getByRole('link', {name: 'Severus Snape'})
    expect(link).toHaveAttribute('href', 'http://test.host/courses/1/users/1')
  })

  it('has the necessary attributes for the StudentContextCardTrigger component when the author is a student', () => {
    ENV.course_id = '1'
    const container = setup()
    const student_context_card_trigger_container = container.getByTestId(
      'student_context_card_trigger_container_author'
    )
    expect(student_context_card_trigger_container).toHaveAttribute(
      'class',
      'student_context_card_trigger'
    )
    expect(student_context_card_trigger_container).toHaveAttribute('data-student_id', '2')
    expect(student_context_card_trigger_container).toHaveAttribute('data-course_id', '1')
  })

  it('has the necessary attributes for the StudentContextCardTrigger component when the editor is a student', () => {
    ENV.course_id = '1'
    const container = setup()
    const student_context_card_trigger_container = container.getByTestId(
      'student_context_card_trigger_container_editor'
    )
    expect(student_context_card_trigger_container).toHaveAttribute(
      'class',
      'student_context_card_trigger'
    )
    expect(student_context_card_trigger_container).toHaveAttribute('data-student_id', '1')
    expect(student_context_card_trigger_container).toHaveAttribute('data-course_id', '1')
  })

  it('does not have a class of student context card trigger when the author is not a student', () => {
    ENV.course_id = '1'
    const container = setup({author: User.mock({courseRoles: ['TeacherEnrollment']})})
    const student_context_card_trigger_container = container.getByTestId(
      'student_context_card_trigger_container_author'
    )
    expect(student_context_card_trigger_container).toHaveAttribute('class', '')
  })

  it('does not have a class of student context card trigger when the editor is not a student', () => {
    ENV.course_id = '1'
    const container = setup({editor: User.mock({_id: '1', courseRoles: ['TeacherEnrollment']})})
    const student_context_card_trigger_container = container.getByTestId(
      'student_context_card_trigger_container_editor'
    )
    expect(student_context_card_trigger_container).toHaveAttribute('class', '')
  })

  it('does not render the authors pronouns when it is not provided', () => {
    const container = setup()
    expect(container.queryByTestId('author-pronouns')).not.toBeInTheDocument()
  })

  it('renders the authors pronouns when it is provided', () => {
    const container = setup({author: User.mock({pronouns: 'they/them'})})
    expect(container.getByTestId('author-pronouns')).toBeInTheDocument()
  })

  it('renders the author roles when there is an author', () => {
    const container = setup()
    expect(container.getByTestId('mobile-Author')).toBeInTheDocument()
    expect(container.getByTestId('pill-container')).toBeInTheDocument()
    expect(container.getByTestId('mobile-TA')).toBeInTheDocument()
  })

  it('renders the Author role pill even if the user does not have discussionRoles', () => {
    const container = setup({author: User.mock()})
    expect(container.getByTestId('mobile-Author')).toBeInTheDocument()
    expect(container.queryByTestId('mobile-Student')).toBeNull()
    expect(container.queryByTestId('mobile-teacher')).toBeNull()
    expect(container.queryByTestId('mobile-TA')).toBeNull()
  })

  it('does not render the Author pill if isTopicAuthor is false', () => {
    const container = setup({isTopicAuthor: false})
    expect(container.queryByTestId('mobile-Author')).toBeNull()
    expect(container.getByTestId('pill-container')).toBeInTheDocument()
    expect(container.getByTestId('mobile-TA')).toBeInTheDocument()
  })

  it('does not render the avatar when there is no author', () => {
    const container = setup({author: null})
    expect(container.queryByTestId('author_avatar')).toBeNull()
  })

  it('does not render the author name when there is no author', () => {
    const container = setup({author: null})
    expect(container.queryByTestId('author_name')).toBeNull()
  })

  it('does not render roles when there is no author', () => {
    const container = setup({author: null})
    expect(container.queryByTestId('pill-container')).toBeNull()
  })

  it('renders the unread badge when isUnread is true', () => {
    const container = setup({isUnread: true})
    expect(container.getByTestId('is-unread')).toBeInTheDocument()
  })

  it('does not render the unread badge when isUnread is false', () => {
    const container = setup()
    expect(container.queryByTestId('is-unread')).toBeNull()
  })

  it('sets the isForcedRead attribute when isForcedRead is true (the entry was manually marked as unread)', () => {
    const container = setup({isUnread: true, isForcedRead: true})
    expect(container.getByTestId('is-unread').getAttribute('data-isforcedread')).toBe('true')
  })

  it('should highlight terms in the author name', () => {
    const container = setup({searchTerm: 'Harry'})
    expect(container.getByTestId('highlighted-search-item')).toBeInTheDocument()
  })

  describe('timestamps', () => {
    it('renders the created date', () => {
      const container = setup()
      expect(container.getByText('Jan 1 1:00pm')).toBeInTheDocument()
    })

    it('renders the edited date', () => {
      const container = setup()
      const editedByTextElement = container.getByTestId('editedByText')
      expect(editedByTextElement.textContent).toEqual('Edited by Severus Snape Feb 2 2:00pm')
    })

    it('renders the last reply at date', () => {
      const container = setup()
      expect(container.getByText('Last reply Mar 3 3:00pm')).toBeInTheDocument()
    })

    it('renders the created tooltip if showCreatedAsTooltip is true', () => {
      const container = setup({showCreatedAsTooltip: true})
      expect(container.getByTestId('created-tooltip')).toBeInTheDocument()
      expect(container.getByText('Created Jan 1 1:00pm')).toBeInTheDocument()
      expect(container.queryByText('Jan 1 1:00pm')).toBeNull()
    })

    it('renders the created date if showCreatedAsTooltip is true but there is no edit info', () => {
      const container = setup({editedTimingDisplay: null, editor: null})
      expect(container.getByText('Jan 1 1:00pm')).toBeInTheDocument()
    })
  })

  describe('anonymous author', () => {
    beforeAll(() => {
      window.ENV.discussion_anonymity_enabled = true
    })

    afterAll(() => {
      window.ENV.discussion_anonymity_enabled = false
    })

    it('renders the anonymous name', () => {
      const container = setup({author: null, anonymousAuthor: AnonymousUser.mock()})
      expect(container.getByText('Anonymous 1')).toBeInTheDocument()
    })

    it('renders the anonymous avatar', () => {
      const container = setup({author: null, anonymousAuthor: AnonymousUser.mock()})
      expect(container.getByTestId('anonymous_avatar')).toBeInTheDocument()
    })

    it('renders you for the current user if anonymous', () => {
      const container = setup({
        author: null,
        anonymousAuthor: AnonymousUser.mock({shortName: CURRENT_USER}),
      })
      expect(container.getByText('Anonymous 1 (You)')).toBeInTheDocument()
    })

    // happens in optimistic response
    it('removes id if null', () => {
      const container = setup({
        author: null,
        anonymousAuthor: AnonymousUser.mock({shortName: CURRENT_USER, id: null}),
      })
      expect(container.getByText('Anonymous (You)')).toBeInTheDocument()
    })

    it('should not highlight terms in the author name', () => {
      const container = setup({anonymousAuthor: AnonymousUser.mock(), searchTerm: 'Anonymous'})
      expect(container.queryByTestId('highlighted-search-item')).toBeNull()
    })

    it('renders the author instead of the anonymous author if present', () => {
      const container = setup({anonymousAuthor: AnonymousUser.mock()})
      expect(container.getByText('Harry Potter')).toBeInTheDocument()
    })
  })

  describe('when discussion_entry_version_history FF is off', () => {
    beforeAll(() => {
      window.ENV.discussion_entry_version_history = false
    })

    it('does not renders View History link', () => {
      const container = setup({
        discussionEntryVersions: [
          DiscussionEntryVersion.mock({version: 3, message: 'Message 3'}),
          DiscussionEntryVersion.mock({version: 2, message: 'Message 2'}),
          DiscussionEntryVersion.mock({version: 1, message: 'Message 1'}),
        ],
      })

      expect(container.queryByText('View History')).not.toBeInTheDocument()
    })
  })

  describe('when discussion_entry_version_history FF is on', () => {
    beforeAll(() => {
      window.ENV.discussion_entry_version_history = true
    })

    it('renders View History link', () => {
      const container = setup({
        discussionEntryVersions: [
          DiscussionEntryVersion.mock({version: 3, message: 'Message 3'}),
          DiscussionEntryVersion.mock({version: 2, message: 'Message 2'}),
          DiscussionEntryVersion.mock({version: 1, message: 'Message 1'}),
        ],
      })

      expect(container.queryByText('View History')).toBeInTheDocument()
    })

    it('does not renders View History link when there is only one version', () => {
      const container = setup({
        discussionEntryVersions: [DiscussionEntryVersion.mock({version: 1, message: 'Message 1'})],
      })

      expect(container.queryByText('View History')).not.toBeInTheDocument()
    })
  })
})
