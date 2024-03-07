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

import {render} from '@testing-library/react'
import React from 'react'
import {DiscussionTopicAlertManager} from '../DiscussionTopicAlertManager'

import {Discussion} from '../../../../graphql/Discussion'
import {Assignment} from '../../../../graphql/Assignment'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

const setup = props => {
  return render(<DiscussionTopicAlertManager {...props} />)
}

describe('DiscussionTopicAlertManager', () => {
  it('should render post required alert', () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        initialPostRequiredForCurrentUser: true,
      }),
    })
    expect(container.getByTestId('post-required')).toBeTruthy()
  })

  it('should render differentiated group topics alert', () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        assignment: Assignment.mock({onlyVisibleToOverrides: true}),
      }),
    })
    expect(container.queryByTestId('differentiated-group-topics')).toBeTruthy()
  })

  it('should render delayed until alert', () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        delayedPostAt: '3020-11-23T11:40:44-07:00',
        isAnnouncement: true,
      }),
    })
    expect(container.queryByTestId('delayed-until')).toBeTruthy()
  })

  it('should render not avalable for user alert', () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        availableForUser: false,
      }),
    })
    expect(container.queryByTestId('locked-for-user')).toBeTruthy()
  })

  describe('Full anonymous discussion', () => {
    it('should render anon alert when status is present', async () => {
      const {findByTestId} = setup({
        discussionTopic: Discussion.mock({
          anonymousState: 'full_anonymity',
          canReplyAnonymously: true,
        }),
      })
      const anonAlert = await findByTestId('anon-conversation')
      expect(anonAlert.textContent).toEqual(
        'This is an anonymous Discussion. Your name and profile picture will be hidden from other course members. Mentions have also been disabled.'
      )
    })

    it('should render non-anon alert when user is teacher, ta, or designer', async () => {
      const {findByTestId} = setup({
        discussionTopic: Discussion.mock({
          anonymousState: 'full_anonymity',
          canReplyAnonymously: false,
        }),
      })

      const anonAlert = await findByTestId('anon-conversation')
      expect(anonAlert.textContent).toEqual(
        'This is an anonymous Discussion. Though student names and profile pictures will be hidden, your name and profile picture will be visible to all course members. Mentions have also been disabled.'
      )
    })

    it('should render correct alert when user is an observer', async () => {
      window.ENV.current_user_roles = ['User', 'observer']
      const {findByTestId} = setup({
        discussionTopic: Discussion.mock({
          anonymousState: 'full_anonymity',
          canReplyAnonymously: false,
        }),
      })
      const anonAlert = await findByTestId('anon-conversation')
      expect(anonAlert.textContent).toEqual(
        'This is an anonymous Discussion. Student names and profile pictures are hidden.'
      )
    })
  })

  describe('Partial anonymous discussion', () => {
    it('should render partial anon alert when status is present', async () => {
      window.ENV.current_user_roles = ['User', 'student']
      const {findByTestId} = setup({
        discussionTopic: Discussion.mock({
          anonymousState: 'partial_anonymity',
          canReplyAnonymously: true,
        }),
      })
      const anonAlert = await findByTestId('anon-conversation')
      expect(anonAlert.textContent).toEqual(
        'When creating a reply, you will have the option to show your name and profile picture to other course members or remain anonymous. Mentions have also been disabled.'
      )
    })

    it('should render non-anon alert when user is teacher, ta, or designer', async () => {
      window.ENV.current_user_roles = ['User', 'teacher']
      const {findByTestId} = setup({
        discussionTopic: Discussion.mock({
          anonymousState: 'partial_anonymity',
          canReplyAnonymously: false,
        }),
      })
      const anonAlert = await findByTestId('anon-conversation')
      expect(anonAlert.textContent).toEqual(
        'When creating a reply, students will have the option to show their name and profile picture or remain anonymous. Your name and profile picture will be visible to all course members. Mentions have also been disabled.'
      )
    })

    it('should render correct alert when user is an observer', async () => {
      window.ENV.current_user_roles = ['User', 'observer']
      const {findByTestId} = setup({
        discussionTopic: Discussion.mock({
          anonymousState: 'partial_anonymity',
          canReplyAnonymously: false,
        }),
      })
      const anonAlert = await findByTestId('anon-conversation')
      expect(anonAlert.textContent).toEqual(
        'Students have the option to reply anonymously. Some names and profile pictures may be hidden.'
      )
    })
  })
})
