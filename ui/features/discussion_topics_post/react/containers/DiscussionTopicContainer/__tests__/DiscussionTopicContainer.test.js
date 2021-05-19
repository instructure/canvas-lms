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
import {getEditUrl, getSpeedGraderUrl} from '../../../utils'
import {graphql} from 'msw'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import {waitFor} from '@testing-library/dom'
import {Discussion} from '../../../../graphql/Discussion'

jest.mock('@canvas/rce/RichContentEditor')

const defaultTopic = Discussion.mock()

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
      _id: '1337',
      dueAt: '2021-04-05T13:40:50Z',
      pointsPossible: 5
    },
    permissions: {
      update: true,
      delete: true,
      speedGrader: true,
      moderateForum: true
    }
  }
}

describe('DiscussionTopicContainer', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const assignMock = jest.fn()
  let liveRegion = null

  beforeAll(() => {
    delete window.location
    window.location = {assign: assignMock}
    window.ENV = {
      context_asset_string: 'course_1',
      course_id: '1'
    }

    if (!document.getElementById('flash_screenreader_holder')) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }

    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
    assignMock.mockClear()
    server.resetHandlers()
  })

  afterAll(() => {
    if (liveRegion) {
      liveRegion.remove()
    }

    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
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

    expect(
      await container.queryByText('This is a graded discussion: 0 points possible')
    ).toBeTruthy()
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

  it('should be able to send to edit page when canUpdate', async () => {
    const {getByTestId} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByTestId('edit'))
    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getEditUrl('1', '1'))
    })
  })

  it('Should be able to delete topic', async () => {
    window.confirm = jest.fn(() => true)
    const {getByTestId, findByTestId} = setup(discussionTopicMock)
    fireEvent.click(await findByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByTestId('delete'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion topic was successfully deleted.')
    )
    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith('/courses/1/discussion_topics')
    })
  })

  it('Should not be able to delete the topic if does not have permission', async () => {
    const {getByTestId, queryByTestId} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {delete: false}}
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(queryByTestId('delete')).toBeNull()
  })

  it('Should be able to open SpeedGrader', async () => {
    const {getByTestId} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByTestId('speedGrader'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getSpeedGraderUrl('1', '1337'))
    })
  })

  it('Should not be able to open SpeedGrader if the user does not have permission', () => {
    const {getByTestId, queryByTestId} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {speedGrader: false}}
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(queryByTestId('speedGrader')).toBeNull()
  })

  it('Renders Add Rubric in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {addRubric: true}}
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Add Rubric')).toBeInTheDocument()
  })

  it('Renders Show Rubric in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {showRubric: true}}
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Show Rubric')).toBeInTheDocument()
  })

  it('Renders Open for Comments in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {openForComments: true}
      }
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Open for Comments')).toBeInTheDocument()
  })

  it('Renders Close for Comments in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {closeForComments: true}
      }
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Close for Comments')).toBeInTheDocument()
  })

  it('Renders Copy To and Send To in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true}
      }
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Copy To...')).toBeInTheDocument()
    expect(getByText('Send To...')).toBeInTheDocument()
  })

  it('renders a modal to send content', async () => {
    const container = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true}
      }
    })
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const sendToButton = await container.findByText('Send To...')
    fireEvent.click(sendToButton)
    expect(await container.findByText('Send to:')).toBeTruthy()
  })

  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('renders a modal to copy content', async () => {
    const container = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true}
      }
    })
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const copyToButton = await container.findByText('Copy To...')
    fireEvent.click(copyToButton)
    expect(await container.findByText('Select a Course')).toBeTruthy()
  })

  it('renders a reply button if user has reply permission true', async () => {
    const container = setup({discussionTopic: {...defaultTopic}})
    await waitFor(() =>
      expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
    )
    expect(await container.findByTestId('discussion-topic-reply')).toBeInTheDocument()
  })

  it('does not render a reply button if user has reply permission false', async () => {
    defaultTopic.permissions.reply = false
    server.use(
      graphql.query('GetDiscussionQuery', (req, res, ctx) => {
        return res.once(
          ctx.data({
            legacyNode: {...defaultTopic}
          })
        )
      })
    )
    const container = setup({discussionTopic: {...defaultTopic}})
    await waitFor(() =>
      expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
    )

    await waitFor(() => expect(container.queryByTestId('discussion-topic-reply')).toBeNull())
    defaultTopic.permissions.reply = true
  })
})
