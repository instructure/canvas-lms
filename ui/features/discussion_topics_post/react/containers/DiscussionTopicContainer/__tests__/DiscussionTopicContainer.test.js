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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {ApolloProvider} from 'react-apollo'
import {DiscussionTopicContainer} from '../DiscussionTopicContainer'
import {fireEvent, render} from '@testing-library/react'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import {waitFor} from '@testing-library/dom'

const discussionTopicMock = {
  discussionTopic: {
    _id: '1',
    id: 'VXNlci0x',
    title: 'Discussion Topic One',
    author: {
      name: 'Chawn Neal',
      avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
    },
    message: '<p> This is the Discussion Topic. </p>',
    postedAt: '2021-04-05T13:40:50Z',
    subscribed: true,
    published: true,
    canUnpublish: true,
    entryCounts: {
      repliesCount: 24,
      unreadCount: 4
    },
    assignment: {
      dueAt: '2021-04-05T13:40:50Z',
      pointsPossible: 5
    },
    permissions: {
      readAsAdmin: true,
      update: true,
      delete: true
    }
  }
}

describe('DiscussionTopicContainer', () => {
  const server = mswServer(handlers)
  beforeAll(() => {
    window.ENV = {context_asset_string: 'course_1'}
    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <DiscussionTopicContainer {...props} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }
  it('publish button is readonly if canUnpublish is false', async () => {
    const {getByText} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, canUnpublish: false}
    })

    expect(getByText('Published').closest('button').hasAttribute('disabled')).toBeTruthy()
  })

  it('renders without optional props', async () => {
    const container = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, assignment: {}}
    })
    expect(await container.queryByText('24 replies, 4 unread')).toBeTruthy()

    expect(await container.queryByTestId('graded-discussion-info')).toBeNull()
    expect(await container.queryByTestId('discussion-topic-reply')).toBeNull()
  })

  it('renders infoText only when there are replies', async () => {
    const container = setup(discussionTopicMock)
    const infoText = await container.findByTestId('replies-counter')
    expect(infoText).toHaveTextContent('24 replies, 4 unread')
  })

  it('does not render unread when there are none', async () => {
    const container = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, unreadCount: 0}
    })
    const infoText = await container.findByTestId('replies-counter')
    expect(infoText).toHaveTextContent('24 replies')
  })

  it('renders Graded info when assignment info exists', async () => {
    const container = setup(discussionTopicMock)
    const gradedDiscussionInfo = await container.findByTestId('graded-discussion-info')
    expect(gradedDiscussionInfo).toHaveTextContent('This is a graded discussion: 5 points possible')
  })

  it('renders Graded info when isGraded', async () => {
    const {findByTestId} = setup(discussionTopicMock)
    const gradedDiscussionInfo = await findByTestId('graded-discussion-info')
    expect(gradedDiscussionInfo).toHaveTextContent('This is a graded discussion: 5 points possible')
  })

  it('renders teacher components when can readAsAdmin', async () => {
    const {getByText, findByText} = setup(discussionTopicMock)

    const manageButton = getByText('Manage Discussion').closest('button')
    fireEvent.click(manageButton)

    expect(await findByText('Edit')).toBeTruthy()
    expect(await findByText('Delete')).toBeTruthy()
    expect(await findByText('Close for Comments')).toBeTruthy()
    expect(await findByText('Send To...')).toBeTruthy()
    expect(await findByText('Copy To...')).toBeTruthy()
  })

  it('Should be able to delete topic', async () => {
    const {getByTestId, findByText} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByTestId('delete'))

    await waitFor(() => {
      expect(findByText('Pinned Discussions')).toBeTruthy()
    })
  })

  it('Should not be able to delete the topic if does not have permission', async () => {
    const {getByTestId, queryByTestId} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {delete: false}}
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(queryByTestId('delete')).toBeNull()
  })

  it('renders a modal to send content', async () => {
    const container = setup(discussionTopicMock)
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const sendToButton = await container.findByText('Send To...')
    fireEvent.click(sendToButton)
    expect(await container.findByText('Send to:')).toBeTruthy()
  })

  it('renders a modal to copy content', async () => {
    const container = setup(discussionTopicMock)
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const copyToButton = await container.findByText('Copy To...')
    fireEvent.click(copyToButton)
    expect(await container.findByText('Select a Course')).toBeTruthy()
  })
})
